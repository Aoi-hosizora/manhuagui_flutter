import 'dart:convert';
import 'dart:io' show File, Directory;

import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/service/db/db_manager.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
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
  if (name != null) {
    return PathUtils.joinPath([directoryPath, 'manhuagui_data', name]);
  }
  return PathUtils.joinPath([directoryPath, 'manhuagui_data']);
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

// ======
// export
// ======

Future<String?> exportData(List<ExportDataType> types) async {
  try {
    var timeToken = getTimestampTokenForFilename(DateTime.now(), 'yyyy-MM-dd-HH-mm-ss-SSS');
    var dbFile = File(await _getDBDataFilePath(timeToken));
    var prefsFile = File(await _getPrefsDataFilePath(timeToken));

    var ok1 = await _exportDB(dbFile, types);
    var ok2 = await _exportPrefs(prefsFile, types);
    if (!ok1 || !ok2) {
      var dataDirectory = Directory(await _getDataDirectoryPath());
      if (await dataDirectory.exists()) {
        await dataDirectory.delete(recursive: true);
      }
      globalLogger.w('exportData, exportDB: $ok1, exportPrefs: $ok2');
      return null;
    }

    return PathUtils.getDirname(dbFile.path);
  } catch (e, s) {
    globalLogger.e('exportData', e, s);
    return null;
  }
}

Future<bool> _exportDB(File dbFile, List<ExportDataType> types) async {
  final db = await DBManager.instance.getDB();
  var anotherDB = await DBManager.instance.openDB(dbFile.path);

  var ok = await db.safeTransaction(
    (tx, _) async {
      // read histories
      if (types.contains(ExportDataType.readHistories)) {
        var rows = await tx.copyTo(anotherDB, HistoryDao.tableName, HistoryDao.columns);
        if (rows == null) {
          return false;
        }
      }
      // download records
      if (types.contains(ExportDataType.downloadRecords)) {
        var rows = await tx.copyTo(anotherDB, DownloadDao.mangaTableName, DownloadDao.mangaColumns);
        if (rows == null) {
          return false;
        }
        rows = await tx.copyTo(anotherDB, DownloadDao.chapterTableName, DownloadDao.chapterColumns);
        if (rows == null) {
          return false;
        }
      }
      return true;
    },
    exclusive: true,
  );
  ok ??= false;

  await anotherDB.close();
  return ok;
}

Future<bool> _exportPrefs(File prefsFile, List<ExportDataType> types) async {
  final prefs = await PrefsManager.instance.loadPrefs();
  var anotherMap = <String, dynamic>{};

  var ok = await () async {
    // search histories
    if (types.contains(ExportDataType.searchHistories)) {
      var rows = await prefs.copyTo(anotherMap, SearchHistoryPrefs.keys);
      if (rows == null) {
        return false;
      }
    }
    // app setting
    if (types.contains(ExportDataType.appSetting)) {
      var rows = await prefs.copyTo(anotherMap, AppSettingPrefs.keys);
      if (rows == null) {
        return false;
      }
    }
    return true;
  }();

  if (!ok) {
    return false;
  }
  ok = await anotherMap.saveToFile(prefsFile, indent: '  ');
  return ok;
}

// ======
// import
// ======

Future<List<ExportDataType>?> importData(String name) async {
  try {
    var dbFile = File(await _getDBDataFilePath(name));
    var prefsFile = File(await _getPrefsDataFilePath(name));

    final db = await DBManager.instance.getDB();
    var types = await db.safeTransaction(
      (tx, rollback) async {
        var types1 = await _importDB(dbFile, tx); // may failed
        var types2 = await _importPrefs(prefsFile); // almost success
        if (types1 == null || types2 == null) {
          globalLogger.w('importData, importDB: ${types1 != null}, importPrefs: ${types2 != null}');
          rollback(msg: 'importData');
          return null;
        }
        return [...types1, ...types2];
      },
      exclusive: true,
    );

    return types;
  } catch (e, s) {
    globalLogger.e('importData', e, s);
    return null;
  }
}

Future<List<ExportDataType>?> _importDB(File dbFile, Transaction tx) async {
  if (!(await dbFile.exists())) {
    return [];
  }

  var anotherDB = await DBManager.instance.openDB(dbFile.path);
  var historyRows = await anotherDB.copyTo(tx, HistoryDao.tableName, HistoryDao.columns) ?? 0;
  var downloadRows = await anotherDB.copyTo(tx, DownloadDao.mangaTableName, DownloadDao.mangaColumns) ?? 0;
  var _ = await anotherDB.copyTo(tx, DownloadDao.chapterTableName, DownloadDao.chapterColumns);

  return [
    if (historyRows > 0) ExportDataType.readHistories,
    if (downloadRows > 0) ExportDataType.downloadRecords,
  ];
}

Future<List<ExportDataType>?> _importPrefs(File prefsFile) async {
  if (!(await prefsFile.exists())) {
    return [];
  }

  final prefs = await PrefsManager.instance.loadPrefs();
  var anotherMap = <String, dynamic>{};
  var ok = await anotherMap.readFromFile(prefsFile);
  if (!ok) {
    return null;
  }

  var historyRows = await anotherMap.copyTo(prefs, SearchHistoryPrefs.keys) ?? 0;
  var settingRows = await anotherMap.copyTo(prefs, AppSettingPrefs.keys) ?? 0;
  if (settingRows > 0) {
    await AppSettingPrefs.loadAllSettings();
  }

  return [
    if (historyRows > 0) ExportDataType.searchHistories,
    if (settingRows > 0) ExportDataType.appSetting,
  ];
}

// ======
// helper
// ======

extension _DatabaseExecutorExtension on DatabaseExecutor {
  Future<int?> copyTo(DatabaseExecutor anotherDB, String tableName, List<String> columns) async {
    // export db to db / import db to db
    try {
      // TODO replace or merge ???
      await anotherDB.rawDelete('DELETE FROM $tableName');
      var results = await rawQuery('SELECT ${columns.join(', ')} FROM $tableName');
      for (var r in results) {
        await anotherDB.rawInsert(
          'INSERT INTO $tableName (${columns.join(', ')}) VALUES (${columns.map((_) => '?').join(', ')})',
          columns.map((col) => r[col]!).toList(),
        );
      }
      return results.length;
    } catch (e, s) {
      globalLogger.e('copyTo_db', e, s);
      return null;
    }
  }
}

extension _SharedPreferencesExtension on SharedPreferences {
  Future<int?> copyTo(Map<String, dynamic> map, List<TypedKey> keys) async {
    // export prefs to map
    try {
      var rows = 0;
      for (var key in keys) {
        var value = safeGet(key, canThrow: true);
        if (value != null) {
          map[key.key] = value;
          rows++;
        }
      }
      return rows;
    } catch (e, s) {
      globalLogger.e('copyTo_map', e, s);
      return null;
    }
  }
}

extension _JsonMapExtension on Map<String, dynamic> {
  Future<int?> copyTo(SharedPreferences prefs, List<TypedKey> keys) async {
    // import map to prefs
    try {
      // TODO replace or merge ???
      var rows = 0;
      for (var key in keys) {
        var value = this[key.key];
        if (value != null) {
          await prefs.safeSet(key, value, canThrow: true);
          rows++;
        }
      }
      return rows;
    } catch (e, s) {
      globalLogger.e('copyTo_prefs', e, s);
      return null;
    }
  }

  Future<bool> saveToFile(File f, {String? indent}) async {
    try {
      var encoder = JsonEncoder.withIndent(indent);
      var content = encoder.convert(this);
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
      clear();
      for (var kv in m.entries) {
        this[kv.key] = kv.value;
      }
      return true;
    } catch (e, s) {
      globalLogger.e('readFromFile', e, s);
      return false;
    }
  }
}
