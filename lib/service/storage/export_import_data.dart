import 'dart:convert';
import 'dart:io' show File, Directory;

import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/service/db/db_manager.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/android.dart';
import 'package:manhuagui_flutter/service/prefs/app_setting.dart';
import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:manhuagui_flutter/service/prefs/search_history.dart';
import 'package:manhuagui_flutter/service/storage/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

// ====
// path
// ====

Future<String> _getDataDirectoryPath([String? name]) async {
  var directoryPath = await lowerThanAndroidR()
      ? await getPublicStorageDirectoryPath() // /storage/emulated/0/Manhuagui/manhuagui_data/...
      : await getPrivateStorageDirectoryPath(); // /storage/emulated/0/android/com.aoihosizora.manhuagui/files/manhuagui_data/...
  if (name == null) {
    return PathUtils.joinPath([directoryPath, 'manhuagui_data']);
  }
  return PathUtils.joinPath([directoryPath, 'manhuagui_data', name]);
}

Future<String> _getDBDataFilePath(String name) async {
  return PathUtils.joinPath([await _getDataDirectoryPath(name), 'data.db']);
}

Future<String> _getPrefsDataFilePath(String name) async {
  return PathUtils.joinPath([await _getDataDirectoryPath(name), 'data.json']);
}

Future<List<String>> getImportDataNames() async {
  try {
    var directory = Directory(await _getDataDirectoryPath());
    if (!(await directory.exists())) {
      return [];
    }
    var directories = await directory.list().toList();
    var names = directories.map((d) => PathUtils.getBasename(d.path)).toList();
    names.sort((i, j) => i.compareTo(j));
    return names;
  } catch (e, s) {
    globalLogger.e('getImportDataNames', e, s);
    return [];
  }
}

Future<bool> deleteImportData(String name) async {
  try {
    var directory = Directory(await _getDataDirectoryPath(name));
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    return true;
  } catch (e, s) {
    globalLogger.e('deleteImportData', e, s);
    return false;
  }
}

// ======
// export
// ======

Future<Tuple2<String, ExportDataTypeCounter>?> exportData(List<ExportDataType> types) async {
  try {
    var timeToken = getTimestampTokenForFilename(DateTime.now(), 'yyyy-MM-dd-HH-mm-ss-SSS');
    var dbFile = File(await _getDBDataFilePath(timeToken));
    var prefsFile = File(await _getPrefsDataFilePath(timeToken));

    var counter = ExportDataTypeCounter();
    var ok1 = await _exportDB(dbFile, types, counter);
    var ok2 = await _exportPrefs(prefsFile, types, counter);
    if (!ok1 || !ok2) {
      var dataDirectory = Directory(await _getDataDirectoryPath(timeToken));
      if (await dataDirectory.exists()) {
        await dataDirectory.delete(recursive: true);
      }
      globalLogger.w('exportData, exportDB: $ok1, exportPrefs: $ok2');
      return null;
    }

    var name = PathUtils.getDirname(dbFile.path);
    return Tuple2(name, counter);
  } catch (e, s) {
    globalLogger.e('exportData', e, s);
    return null;
  }
}

Future<bool> _exportDB(File dbFile, List<ExportDataType> types, ExportDataTypeCounter counter) async {
  final db = await DBManager.instance.getDB();
  var anotherDB = await DBManager.instance.openDB(dbFile.path); // Database

  var ok = await db.exclusiveTransaction((tx, _) async {
    // read histories
    if (types.contains(ExportDataType.readHistories)) {
      var rows = await _copyToDB(tx, anotherDB, HistoryDao.metadata);
      if (rows == null) {
        return false;
      }
      counter.readHistories = rows;
    }
    // download records
    if (types.contains(ExportDataType.downloadRecords)) {
      var mangaRows = await _copyToDB(tx, anotherDB, DownloadDao.mangaMetadata);
      if (mangaRows == null) {
        return false;
      }
      var chapterRows = await _copyToDB(tx, anotherDB, DownloadDao.chapterMetadata);
      if (chapterRows == null) {
        return false;
      }
      counter.downloadRecords = mangaRows;
    }
    // favorite mangas
    if (types.contains(ExportDataType.favoriteMangas)) {
      var favoriteRows = await _copyToDB(tx, anotherDB, FavoriteDao.favoriteMetadata);
      if (favoriteRows == null) {
        return false;
      }
      var groupRows = await _copyToDB(tx, anotherDB, FavoriteDao.groupMetadata);
      if (groupRows == null) {
        return false;
      }
      counter.favoriteMangas = favoriteRows;
    }
    return true;
  });
  ok ??= false;

  await anotherDB.close();
  return ok;
}

Future<bool> _exportPrefs(File prefsFile, List<ExportDataType> types, ExportDataTypeCounter counter) async {
  final prefs = await PrefsManager.instance.loadPrefs();
  var anotherPrefs = _SharedPreferencesMap.empty(); // SharedPreferences

  var ok = await () async {
    // search histories
    if (types.contains(ExportDataType.searchHistories)) {
      var rows = await _copyToPrefs(prefs, anotherPrefs, SearchHistoryPrefs.keys);
      if (rows == null) {
        return false;
      }
      counter.searchHistories = (await SearchHistoryPrefs.getSearchHistories()).length; // use history list length as rows
    }
    // app setting
    if (types.contains(ExportDataType.appSetting)) {
      var rows = await _copyToPrefs(prefs, anotherPrefs, AppSettingPrefs.keys);
      if (rows == null) {
        return false;
      }
      counter.appSetting = rows;
    }
    return true;
  }();

  ok = ok && await anotherPrefs.setVersion(prefs.getVersion());
  ok = ok && await anotherPrefs.saveToFile(prefsFile);
  return ok;
}

// ======
// import
// ======

Future<ExportDataTypeCounter?> importData(String name, {bool merge = false}) async {
  try {
    var dbFile = File(await _getDBDataFilePath(name));
    var prefsFile = File(await _getPrefsDataFilePath(name));
    var tmpDBFile = await dbFile.copy('${dbFile.path}_temp'); // create backup
    var tmpPrefsFile = await prefsFile.copy('${prefsFile.path}_temp');

    final db = await DBManager.instance.getDB();
    final prefs = await PrefsManager.instance.loadPrefs();
    var counter = await db.exclusiveTransaction((tx, rollback) async {
      var counter = ExportDataTypeCounter();
      var ok1 = await _importDB(tmpDBFile, tx, counter, merge); // may fail
      var ok2 = await _importPrefs(tmpPrefsFile, prefs, counter, merge); // almost succeed
      if (!ok1 || !ok2) {
        globalLogger.w('importData, importDB: $ok1, importPrefs: $ok2');
        rollback(msg: 'importData');
        return null;
      }
      return counter;
    });

    await tmpDBFile.delete(); // delete backup
    await tmpPrefsFile.delete();
    return counter; // maybe null
  } catch (e, s) {
    globalLogger.e('importData', e, s);
    return null;
  }
}

Future<bool> _importDB(File dbFile, Transaction db, ExportDataTypeCounter counter, bool merge) async {
  if (!(await dbFile.exists())) {
    return false;
  }
  Database exportedDB;
  try {
    exportedDB = await DBManager.instance.openDB(dbFile.path); // will also upgrade
  } catch (e, s) {
    globalLogger.e('_importDB', e, s);
    return false;
  }

  var ok = await () async {
    // read histories
    var readHistoryRows = await _copyToDB(exportedDB, db, HistoryDao.metadata, merge);
    if (readHistoryRows == null) {
      return false;
    }
    if (readHistoryRows > 0) {
      counter.readHistories = readHistoryRows;
    }
    // download records
    var downloadMangaRows = await _copyToDB(exportedDB, db, DownloadDao.mangaMetadata, merge);
    if (downloadMangaRows == null) {
      return false;
    }
    var downloadChapterRows = await _copyToDB(exportedDB, db, DownloadDao.chapterMetadata, merge);
    if (downloadChapterRows == null) {
      return false;
    }
    if (downloadMangaRows > 0) {
      counter.downloadRecords = downloadMangaRows;
    }
    // favorite mangas
    var favoriteMangaRows = await _copyToDB(exportedDB, db, FavoriteDao.favoriteMetadata, merge);
    if (favoriteMangaRows == null) {
      return false;
    }
    var favoriteGroupRows = await _copyToDB(exportedDB, db, FavoriteDao.groupMetadata, merge);
    if (favoriteGroupRows == null) {
      return false;
    }
    if (readHistoryRows > 0) {
      counter.favoriteMangas = favoriteMangaRows;
    }
    return true;
  }();

  if (ok && counter.readHistories != null && counter.readHistories! > 0) {
    // notify manga read history is changed
    EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: -1));
  }
  await exportedDB.close();
  return ok;
}

Future<bool> _importPrefs(File prefsFile, SharedPreferences prefs, ExportDataTypeCounter counter, bool merge) async {
  if (!(await prefsFile.exists())) {
    return false;
  }
  var exportedPrefs = _SharedPreferencesMap.empty();
  var ok = await exportedPrefs.readFromFile(prefsFile);
  if (!ok) {
    return false;
  }
  await PrefsManager.instance.upgradePrefs(exportedPrefs); // upgrade prefs manually

  ok = await () async {
    // search histories
    var searchHistoryRows = await _copyToPrefs(exportedPrefs, prefs, SearchHistoryPrefs.keys, merge);
    if (searchHistoryRows == null) {
      return false;
    }
    if (searchHistoryRows > 0) {
      var exportedHistories = (await SearchHistoryPrefs.getSearchHistories(prefs: exportedPrefs));
      if (exportedHistories.isNotEmpty) {
        counter.searchHistories = exportedHistories.length; // use history list length as rows
      }
    }
    // app setting
    var settingRows = await _copyToPrefs(exportedPrefs, prefs, AppSettingPrefs.keys, merge);
    if (settingRows == null) {
      return false;
    }
    if (settingRows > 0) {
      counter.appSetting = settingRows;
    }
    return true;
  }();

  if (ok && counter.appSetting != null && counter.appSetting! > 0) {
    // apply data to AppSetting
    await AppSettingPrefs.loadAllSettings();
  }
  return ok;
}

// ======
// helper
// ======

Future<int?> _copyToDB(DatabaseExecutor db, DatabaseExecutor db2, TableMetadata metadata, [bool merge = false]) async {
  try {
    var results = await db.rawQuery('SELECT ${metadata.columns.join(', ')} FROM ${metadata.tableName}');
    if (results.isEmpty) {
      return 0;
    }

    if (!merge) {
      await db2.rawDelete('DELETE FROM ${metadata.tableName}');
    }
    for (var r in results) {
      if (merge) {
        var whereStat = metadata.primaryKeys.map((col) => '$col == ?').join(' AND ');
        var whereArgs = metadata.primaryKeys.map((col) => r[col]!).toList();
        await db2.rawDelete('DELETE FROM ${metadata.tableName} WHERE $whereStat', whereArgs);
      }
      var valueStat = metadata.columns.map((_) => '?').join(', ');
      var valueArgs = metadata.columns.map((col) => r[col]!).toList();
      await db2.rawInsert('INSERT INTO ${metadata.tableName} (${metadata.columns.join(', ')}) VALUES ($valueStat)', valueArgs);
    }
    return results.length;
  } catch (e, s) {
    globalLogger.e('_copyToDB', e, s);
    return null;
  }
}

Future<int?> _copyToPrefs(SharedPreferences prefs, SharedPreferences prefs2, List<TypedKey> keys, [bool merge = false]) async {
  try {
    var rows = 0;
    for (var key in keys) {
      var value = prefs.safeGet(key, canThrow: true);
      if (value == null) {
        continue;
      }

      if (merge && key is TypedKey<List> && value is List) {
        var existedValues = prefs2.safeGet(key) ?? [];
        if (existedValues.isNotEmpty) {
          value.addAll(existedValues.where((v) => !value.contains(v)));
        }
      }
      var ok = await prefs2.safeSet(key, value, canThrow: true);
      if (ok) {
        rows++;
      }
    }
    return rows;
  } catch (e, s) {
    globalLogger.e('_copyToPrefs', e, s);
    return null;
  }
}

class _SharedPreferencesMap implements SharedPreferences {
  _SharedPreferencesMap.empty() : _data = {};

  final Map<String, Object> _data;

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  int? getInt(String key) => _data[key] as int?;

  @override
  double? getDouble(String key) => _data[key] as double?;

  @override
  List<String>? getStringList(String key) {
    var list = _data[key] as List?;
    if (list != null && list is! List<String>) {
      list = list.cast<String>().toList(); // keep the same as SharedPreferences source code
      _data[key] = list;
    }
    return list?.toList() as List<String>?;
  }

  @override
  Future<bool> setString(String key, String value) => set(key, value);

  @override
  Future<bool> setBool(String key, bool value) => set(key, value);

  @override
  Future<bool> setInt(String key, int value) => set(key, value);

  @override
  Future<bool> setDouble(String key, double value) => set(key, value);

  @override
  Future<bool> setStringList(String key, List<String> value) => set(key, value);

  @override
  Object? get(String key) => _data[key];

  Future<bool> set(String key, Object value) {
    _data[key] = value;
    return Future.value(true);
  }

  @override
  Set<String> getKeys() => Set<String>.from(_data.keys);

  @override
  bool containsKey(String key) => _data.containsKey(key);

  @override
  Future<bool> remove(String key) => Future(() => _data.remove(key)).then((_) => true);

  @override
  Future<bool> clear() => Future(() => _data.clear()).then((_) => true);

  @override
  Future<void> reload() => Future.value(null);

  @override
  Future<bool> commit() => Future.value(true);

  Future<bool> saveToFile(File f) async {
    try {
      var encoder = JsonEncoder.withIndent('  ');
      var content = encoder.convert(_data);
      await f.writeAsString(content, flush: true);
      return true;
    } catch (e, s) {
      globalLogger.e('saveToFile', e, s);
      return false;
    }
  }

  Future<bool> readFromFile(File f) async {
    try {
      var content = await f.readAsString();
      var m = json.decode(content) as Map<String, dynamic>;
      _data.clear();
      for (var kv in m.entries) {
        if (kv.value != null) {
          _data[kv.key] = kv.value!;
        }
      }
      return true;
    } catch (e, s) {
      globalLogger.e('readFromFile', e, s);
      return false;
    }
  }
}
