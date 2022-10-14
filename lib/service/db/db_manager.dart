import 'package:manhuagui_flutter/config.dart';
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
        version: 1,
        onCreate: (db, ver) async {
          await db.execute(HistoryDao.createTblHistory);
        },
        onUpgrade: (db, oldVer, newVer) async {},
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
  /// Executes a raw SQL SELECT query and returns a list
  /// of the rows that were found.
  ///
  /// ```
  /// List<Map> list = await database.rawQuery('SELECT * FROM Test');
  /// ```
  Future<List<Map<String, Object?>>?> safeRawQuery(String sql, [List<Object?>? arguments]) async {
    try {
      return await rawQuery(sql, arguments);
    } catch (e, s) {
      print('===> exception when rawQuery:\n$e\n$s');
      return null;
    }
  }

  /// Executes a raw SQL INSERT query and returns the last inserted row ID.
  ///
  /// ```
  /// int id1 = await database.rawInsert(
  ///   'INSERT INTO Test(name, value, num) VALUES("some name", 1234, 456.789)');
  /// ```
  ///
  /// 0 could be returned for some specific conflict algorithms if not inserted.
  Future<int?> safeRawInsert(String sql, [List<Object?>? arguments]) async {
    try {
      return await rawInsert(sql, arguments);
    } catch (e, s) {
      print('===> exception when rawInsert:\n$e\n$s');
      return null;
    }
  }

  /// Executes a raw SQL UPDATE query and returns
  /// the number of changes made.
  ///
  /// ```
  /// int count = await database.rawUpdate(
  ///   'UPDATE Test SET name = ?, value = ? WHERE name = ?',
  ///   ['updated name', '9876', 'some name']);
  /// ```
  Future<int?> safeRawUpdate(String sql, [List<Object?>? arguments]) async {
    try {
      return await rawUpdate(sql, arguments);
    } catch (e, s) {
      print('===> exception when rawUpdate:\n$e\n$s');
      return null;
    }
  }

  /// Executes a raw SQL DELETE query and returns the
  /// number of changes made.
  ///
  /// ```
  /// int count = await database
  ///   .rawDelete('DELETE FROM Test WHERE name = ?', ['another name']);
  /// ```
  Future<int?> safeRawDelete(String sql, [List<Object?>? arguments]) async {
    try {
      return await rawDelete(sql, arguments);
    } catch (e, s) {
      print('===> exception when rawDelete:\n$e\n$s');
      return null;
    }
  }
}
