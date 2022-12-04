import 'package:flutter_ahlib/flutter_ahlib.dart';
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
      _database ??= await _openDatabase(path);
    }
    return _database!;
  }

  Future<Database> getAnotherDB(String path) async {
    return await _openDatabase(path);
  }

  Future<Database> _openDatabase(String path) async {
    return await openDatabase(
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

  Future<void> closeDB() async {
    await _database?.close();
    _database = null;
  }
}

extension DatabaseExtension on DatabaseExecutor {
  Future<List<Map<String, Object?>>?> safeRawQuery(String sql, [List<Object?>? arguments]) async {
    try {
      return await rawQuery(sql, arguments);
    } catch (e, s) {
      globalLogger.e('safeRawQuery', e, s);
      return null;
    }
  }

  Future<int?> safeRawInsert(String sql, [List<Object?>? arguments]) async {
    try {
      return await rawInsert(sql, arguments);
    } catch (e, s) {
      globalLogger.e('safeRawInsert', e, s);
      return null;
    }
  }

  Future<int?> safeRawUpdate(String sql, [List<Object?>? arguments]) async {
    try {
      return await rawUpdate(sql, arguments);
    } catch (e, s) {
      globalLogger.e('safeRawUpdate', e, s);
      return null;
    }
  }

  Future<int?> safeRawDelete(String sql, [List<Object?>? arguments]) async {
    try {
      return await rawDelete(sql, arguments);
    } catch (e, s) {
      globalLogger.e('safeRawDelete', e, s);
      return null;
    }
  }

  Future<void> safeExecute(String sql, [List<Object?>? arguments]) async {
    try {
      return await execute(sql, arguments);
    } catch (e, s) {
      globalLogger.e('safeExecute', e, s);
    }
  }

  Future<int?> copyToDB(Database anotherDB, String tableName, List<String> columns) async {
    try {
      var results = await rawQuery('SELECT ${HistoryDao.columns.join(', ')} FROM ${HistoryDao.tableName}');
      for (var r in results) {
        await anotherDB.rawInsert(
          'INSERT INTO ${HistoryDao.tableName} (${HistoryDao.columns.join(', ')}) VALUES (${HistoryDao.columns.map((_) => '?').join(', ')})',
          HistoryDao.columns.map((col) => r[col]!).toList(),
        );
      }
      return results.length;
    } catch (e, s) {
      globalLogger.e('copyToAnotherDB', e, s);
      return null;
    }
  }
}
