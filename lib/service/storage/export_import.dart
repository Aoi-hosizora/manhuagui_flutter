import 'dart:convert';
import 'dart:io' show File;

import 'package:intl/intl.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/service/db/db_manager.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/native/android.dart';
import 'package:manhuagui_flutter/service/prefs/app_setting.dart';
import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:manhuagui_flutter/service/prefs/search_history.dart';
import 'package:manhuagui_flutter/service/storage/storage.dart';

// ====
// path
// ====

Future<String> _getDataDirectoryPath() async {
  var directoryPath = await lowerThanAndroidR()
      ? await getPublicStorageDirectoryPath() // /storage/emulated/0/Manhuagui/manhuagui_data/...
      : await getPrivateStorageDirectoryPath(); // /storage/emulated/0/android/com.aoihosizora.manhuagui/files/manhuagui_data/...
  return PathUtils.joinPath([directoryPath, 'manhuagui_data']);
}

Future<String> _getDataFilePath(DateTime time, String extension) async {
  final df = DateFormat('yyyy-MM-dd-HH-mm-ss-SSS');
  var basename = df.format(time);
  var filename = '$basename.$extension';
  return PathUtils.joinPath([await _getDataDirectoryPath(), filename]);
}

// ======
// export
// ======

Future<String?> exportData(List<ExportDataType> types) async {
  var now = DateTime.now();
  var dbFilePath = await _getDataFilePath(now, 'db');
  var prefsFilePath = await _getDataFilePath(now, 'json');
  var dbFile = File(dbFilePath);
  var prefsFile = File(prefsFilePath);

  var ok1 = await _exportDB(dbFile, types);
  var ok2 = await _exportPrefs(prefsFile, types);
  if (!ok1 || !ok2) {
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    if (await prefsFile.exists()) {
      await prefsFile.delete();
    }
    return null;
  }

  return dbFilePath.split('.')[0];
}

Future<bool> _exportDB(File dbFile, List<ExportDataType> types) async {
  final db = await DBManager.instance.getDB();
  var anotherDB = await DBManager.instance.getAnotherDB(dbFile.path);

  var ok = await db.transaction((tx) async {
    // read histories
    if (types.contains(ExportDataType.readHistories)) {
      var rows = await tx.copyToDB(anotherDB, HistoryDao.tableName, HistoryDao.columns);
      if (rows == null) {
        return false;
      }
    }

    // download records
    if (types.contains(ExportDataType.downloadRecords)) {
      var rows = await tx.copyToDB(anotherDB, DownloadDao.mangaTableName, DownloadDao.mangaColumns);
      if (rows == null) {
        return false;
      }
      rows = await tx.copyToDB(anotherDB, DownloadDao.chapterTableName, DownloadDao.chapterColumns);
      if (rows == null) {
        return false;
      }
    }

    return true;
  }, exclusive: true);

  await anotherDB.close();
  return ok;
}

Future<bool> _exportPrefs(File prefsFile, List<ExportDataType> types) async {
  final prefs = await PrefsManager.instance.loadPrefs();
  var anotherMap = <String, Object>{};

  var ok = () {
    // search histories
    if (types.contains(ExportDataType.searchHistories)) {
      var rows = prefs.copyToMap(anotherMap, SearchHistoryPrefs.keys);
      if (rows == null) {
        return false;
      }
    }

    // app setting
    if (types.contains(ExportDataType.appSetting)) {
      var rows = prefs.copyToMap(anotherMap, AppSettingPrefs.keys);
      if (rows == null) {
        return false;
      }
    }

    return true;
  }();

  if (ok) {
    prefsFile.writeAsString(json.encode(anotherMap));
  }
  return ok;
}

// ======
// import
// ======

Future<List<String>> getImportDataNames() async {
  return ['TODO'];
}

Future<List<ExportDataType>?> importData(String name) async {
  return ExportDataType.values;
}
