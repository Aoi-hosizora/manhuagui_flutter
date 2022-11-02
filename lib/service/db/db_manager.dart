import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBManager {
  DBManager._();

  static DBManager? _instance;

  static DBManager get instance {
    _instance ??= DBManager._();
    return _instance!;
  }

  Database? _database; // global Database instance

  Future<Database> getDB() async {
    if (_database == null || !_database!.isOpen) {
      var path = await getDatabasesPath();
      _database = await openDatabase(
        join(path, DB_NAME),
        version: 2,
        onCreate: (db, _) async {
          await HistoryDao.createTable(db);
          await DownloadDao.createTable(db);
        },
        onUpgrade: (db, version, _) async {
          if (version <= 1) {
            version = 2; // 1 -> 2 upgrade
            await HistoryDao.upgradeFromVer1To2(db);
            await DownloadDao.upgradeFromVer1To2(db);
          }
          if (version == 2) {
            // ...
          }
        },
      );
    }
    return _database!;
  }

  Future<void> closeDB() async {
    await _database?.close();
    _database = null;
  }
}

extension DatabaseExtension on Database {
  Future<List<Map<String, Object?>>?> safeRawQuery(String sql, [List<Object?>? arguments]) async {
    try {
      return await rawQuery(sql, arguments);
    } catch (e, s) {
      print('===> exception when rawQuery:\n$e\n$s');
      return null;
    }
  }

  Future<int?> safeRawInsert(String sql, [List<Object?>? arguments]) async {
    try {
      return await rawInsert(sql, arguments);
    } catch (e, s) {
      print('===> exception when rawInsert:\n$e\n$s');
      return null;
    }
  }

  Future<int?> safeRawUpdate(String sql, [List<Object?>? arguments]) async {
    try {
      return await rawUpdate(sql, arguments);
    } catch (e, s) {
      print('===> exception when rawUpdate:\n$e\n$s');
      return null;
    }
  }

  Future<int?> safeRawDelete(String sql, [List<Object?>? arguments]) async {
    try {
      return await rawDelete(sql, arguments);
    } catch (e, s) {
      print('===> exception when rawDelete:\n$e\n$s');
      return null;
    }
  }

  Future<void> safeExecute(String sql, [List<Object?>? arguments]) async {
    try {
      return await execute(sql, arguments);
    } catch (e, s) {
      print('===> exception when execute:\n$e\n$s');
    }
  }
}
