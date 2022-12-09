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
      var filepath = join(await getDatabasesPath(), DB_NAME); // /data/user/0/.../databases/db_xxx
      _database ??= await openDB(filepath);
    }
    return _database!;
  }

  Future<void> closeDB() async {
    await _database?.close();
    _database = null;
  }

  static const _newestVersion = 2;

  Future<Database> openDB(String filepath) async {
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
}

class TableMetadata {
  const TableMetadata({required this.tableName, required this.primaryKeys, required this.columns});

  final String tableName;
  final List<String> primaryKeys;
  final List<String> columns;
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
}

extension DatabaseExtension on Database {
  Future<T?> exclusiveTransaction<T>(Future<T> Function(Transaction tx, void Function({Object? msg}) rollback) action) async {
    try {
      return await transaction<T?>(
        (tx) async {
          return await action(tx, ({msg}) => throw 'Rollback: $msg');
        },
        exclusive: true,
      );
    } catch (e, s) {
      globalLogger.e('safeTransaction', e, s);
      return null;
    }
  }
}
