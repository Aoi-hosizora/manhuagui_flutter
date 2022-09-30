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
