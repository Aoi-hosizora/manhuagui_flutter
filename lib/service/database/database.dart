import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/service/database/history.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBProvider {
  DBProvider._();

  static DBProvider _instance;

  static DBProvider get instance {
    if (_instance == null) {
      _instance = DBProvider._();
    }
    return _instance;
  }

  Database _database;

  Future<Database> getDB() async {
    if (_database == null || !_database.isOpen) {
      var path = await getDatabasesPath();
      _database = await openDatabase(
        join(path, DB_NAME),
        version: 1,
        onCreate: (db, ver) async {
          await db.execute(createTblHistory);
        },
        onUpgrade: (db, oldVer, newVer) async {},
      );
    }
    return _database;
  }

  Future<void> closeDB() async {
    await _database?.close();
    _database = null;
  }
}
