import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/service/db/db_manager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/utils/utils.dart';

class FavoriteDao {
  FavoriteDao._();

  static const _tblFavorite = 'tbl_favorite';
  static const _colUsername = 'username';
  static const _colMangaId = 'id';
  static const _colMangaTitle = 'manga_title';
  static const _colMangaCover = 'manga_cover';
  static const _colMangaUrl = 'manga_url';
  static const _colRemark = 'remark';
  static const _colListOrder = 'list_order';
  static const _colCreatedAt = 'created_at';

  static const metadata = TableMetadata(
    tableName: _tblFavorite,
    primaryKeys: [_colUsername, _colMangaId],
    columns: [_colUsername, _colMangaId, _colMangaTitle, _colMangaCover, _colMangaUrl, _colRemark, _colListOrder, _colCreatedAt],
  );

  static Future<void> createForVer1(Database db) async {
    // pass
  }

  static Future<void> upgradeFromVer1To2(Database db) async {
    // pass
  }

  static Future<void> upgradeFromVer2To3(Database db) async {
    // pass
  }

  static Future<void> upgradeFromVer3To4(Database db) async {
    await db.safeExecute('''
      CREATE TABLE $_tblFavorite(
        $_colUsername VARCHAR(1023),
        $_colMangaId INTEGER,
        $_colMangaTitle VARCHAR(1023),
        $_colMangaCover VARCHAR(1023),
        $_colMangaUrl VARCHAR(1023),
        $_colRemark VARCHAR(1023),
        $_colListOrder INTEGER,
        $_colCreatedAt DATETIME,
        PRIMARY KEY ($_colUsername, $_colMangaId)
      )''');
  }

  static Future<int?> getFavoriteCount({required String username}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblFavorite
         WHERE $_colUsername = ?''',
      [username],
    );
    if (results == null) {
      return null;
    }
    return firstIntValue(results);
  }

  static Future<bool?> checkExistence({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT($_colMangaId)
         FROM $_tblFavorite
         WHERE $_colUsername = ? AND $_colMangaId = ?''',
      [username, mid],
    );
    if (results == null || results.isEmpty) {
      return null;
    }
    return firstIntValue(results)! > 0;
  }

  static Future<int?> getMinMaxOrder({required String username, required bool getMin}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT ${getMin ? 'MIN' : 'MAX'}($_colListOrder)
         FROM $_tblFavorite
         WHERE $_colUsername = ?''',
      [username],
    );
    if (results == null) {
      return null;
    }
    return firstIntValue(results);
  }

  static Future<FavoriteManga?> getFavorite({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colRemark, $_colListOrder, $_colCreatedAt
         FROM $_tblFavorite
         WHERE $_colUsername = ? AND $_colMangaId = ?
         ORDER BY $_colCreatedAt DESC
         LIMIT 1''',
      [username, mid],
    );
    if (results == null || results.isEmpty) {
      return null;
    }
    var r = results.first;
    return FavoriteManga(
      mangaId: mid,
      mangaTitle: r[_colMangaTitle]! as String,
      mangaCover: r[_colMangaCover]! as String,
      mangaUrl: r[_colMangaUrl]! as String,
      remark: r[_colRemark]! as String,
      order: r[_colListOrder]! as int,
      createdAt: DateTime.parse(r[_colCreatedAt]! as String),
    );
  }

  static Future<List<FavoriteManga>?> getFavorites({required String username, required int page, int limit = 20, int offset = 0}) async {
    final db = await DBManager.instance.getDB();
    offset = limit * (page - 1) - offset;
    if (offset < 0) {
      offset = 0;
    }
    var results = await db.safeRawQuery(
      '''SELECT $_colMangaId, $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colRemark, $_colListOrder, $_colCreatedAt 
         FROM $_tblFavorite
         WHERE $_colUsername = ?
         ORDER BY $_colListOrder ASC, $_colCreatedAt DESC
         LIMIT $limit OFFSET $offset''',
      [username],
    );
    if (results == null) {
      return null;
    }
    var out = <FavoriteManga>[];
    for (var r in results) {
      out.add(FavoriteManga(
        mangaId: r[_colMangaId]! as int,
        mangaTitle: r[_colMangaTitle]! as String,
        mangaCover: r[_colMangaCover]! as String,
        mangaUrl: r[_colMangaUrl]! as String,
        remark: r[_colRemark]! as String,
        order: r[_colListOrder]! as int,
        createdAt: DateTime.parse(r[_colCreatedAt]! as String),
      ));
    }
    return out;
  }

  static Future<bool> addOrUpdateFavorite({required String username, required FavoriteManga favorite}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblFavorite
         WHERE $_colUsername = ? AND $_colMangaId = ?''',
      [username, favorite.mangaId],
    );
    if (results == null) {
      return false;
    }
    var count = firstIntValue(results);

    int? rows = 0;
    if (count == 0) {
      rows = await db.safeRawInsert(
        '''INSERT INTO $_tblFavorite ($_colUsername, $_colMangaId, $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colRemark, $_colListOrder, $_colCreatedAt)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        [username, favorite.mangaId, favorite.mangaTitle, favorite.mangaCover, favorite.mangaUrl, favorite.remark, favorite.order, favorite.createdAt.toIso8601String()],
      );
    } else {
      rows = await db.safeRawUpdate(
        '''UPDATE $_tblFavorite
           SET $_colMangaTitle = ?, $_colMangaCover = ?, $_colMangaUrl = ?, $_colRemark = ?, $_colListOrder = ?, $_colCreatedAt = ?
           WHERE $_colUsername = ? AND $_colMangaId = ?''',
        [favorite.mangaTitle, favorite.mangaCover, favorite.mangaUrl, favorite.remark, favorite.order, favorite.createdAt.toIso8601String(), username, favorite.mangaId],
      );
    }
    return rows != null && rows >= 1;
  }

  static Future<bool> deleteFavorite({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblFavorite
         WHERE $_colUsername = ? AND $_colMangaId = ?''',
      [username, mid],
    );
    return rows != null && rows >= 1;
  }
}
