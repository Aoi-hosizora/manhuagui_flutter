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
      var filepath = join(await getDatabasesPath(), DB_NAME);
      _database ??= await _openDatabase(filepath);
    }
    return _database!;
  }

  Future<void> closeDB() async {
    await _database?.close();
    _database = null;
  }

  static const _newestVersion = 2;

  Future<Database> _openDatabase(String filepath) async {
    return await openDatabase(
      filepath,
      version: _newestVersion,
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

  Future<Database> getAnotherDB(String filepath) async {
    return await _openDatabase(filepath);
  }
}

extension DatabaseExecutorExtension on DatabaseExecutor {
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

  Future<int?> copyTo(DatabaseExecutor anotherDB, String tableName, List<String> columns) async {
    try {
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

extension DatabaseExtension on Database {
  Future<T?> safeTransaction<T>(
    Future<T> Function(Transaction txn, void Function({Object? msg}) rollback) action, {
    bool? exclusive,
  }) async {
    try {
      return await transaction<T?>(
        (txn) async {
          return await action(txn, ({msg}) => throw (msg ?? 'rollback'));
        },
        exclusive: exclusive,
      );
    } catch (e, s) {
      globalLogger.e('safeTransaction', e, s);
      return null;
    }
  }
}
