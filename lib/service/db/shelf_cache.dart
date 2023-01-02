import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/service/db/db_manager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/utils/utils.dart';

class ShelfCacheDao {
  ShelfCacheDao._();

  static const _tblShelfCache = 'tbl_shelf_cache';
  static const _colUsername = 'username';
  static const _colMangaId = 'id';
  static const _colMangaTitle = 'manga_title';
  static const _colMangaCover = 'manga_cover';
  static const _colMangaUrl = 'manga_url';
  static const _colCachedAt = 'cached_at';

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
      CREATE TABLE $_tblShelfCache(
        $_colUsername VARCHAR(1023),
        $_colMangaId INTEGER,
        $_colMangaTitle VARCHAR(1023),
        $_colMangaCover VARCHAR(1023),
        $_colMangaUrl VARCHAR(1023),
        $_colCachedAt DATETIME,
        PRIMARY KEY ($_colUsername, $_colMangaId)
      )''');
  }

  static Future<bool?> checkExistence({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT($_colMangaId)
         FROM $_tblShelfCache
         WHERE $_colUsername = ? AND $_colMangaId = ?
         ORDER BY $_colCachedAt DESC''',
      [username, mid],
    );
    if (results == null || results.isEmpty) {
      return null;
    }
    return firstIntValue(results)! > 0;
  }

  static Future<List<ShelfCache>?> getShelfCaches({required String username}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT $_colMangaId, $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colCachedAt
         FROM $_tblShelfCache
         WHERE $_colUsername = ?
         ORDER BY $_colCachedAt DESC''',
      [username],
    );
    if (results == null) {
      return null;
    }
    var out = <ShelfCache>[];
    for (var r in results) {
      out.add(ShelfCache(
        mangaId: r[_colMangaId]! as int,
        mangaTitle: r[_colMangaTitle]! as String,
        mangaCover: r[_colMangaCover]! as String,
        mangaUrl: r[_colMangaUrl]! as String,
        cachedAt: DateTime.parse(r[_colCachedAt]! as String),
      ));
    }
    return out;
  }

  static Future<bool> addOrUpdateShelfCache({required String username, required ShelfCache cache}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblShelfCache
         WHERE $_colUsername = ? AND $_colMangaId = ?''',
      [username, cache.mangaId],
    );
    if (results == null) {
      return false;
    }
    var count = firstIntValue(results);

    int? rows = 0;
    if (count == 0) {
      rows = await db.safeRawInsert(
        '''INSERT INTO $_tblShelfCache ($_colUsername, $_colMangaId, $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colCachedAt)
           VALUES (?, ?, ?, ?, ?, ?)''',
        [username, cache.mangaId, cache.mangaTitle, cache.mangaCover, cache.mangaUrl, cache.cachedAt.toIso8601String()],
      );
    } else {
      rows = await db.safeRawUpdate(
        '''UPDATE $_tblShelfCache
           SET $_colMangaTitle = ?, $_colMangaCover = ?, $_colMangaUrl = ?, $_colCachedAt = ?
           WHERE $_colUsername = ? AND $_colMangaId = ?''',
        [cache.mangaTitle, cache.mangaCover, cache.mangaUrl, cache.cachedAt.toIso8601String(), username, cache.mangaId],
      );
    }
    return rows != null && rows >= 1;
  }

  static Future<bool> clearShelfCaches({required String username}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblShelfCache
         WHERE $_colUsername = ?''',
      [username],
    );
    return rows != null && rows >= 1;
  }

  static Future<bool> deleteShelfCache({required String username, required int mangaId}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblShelfCache
         WHERE $_colUsername = ? AND $_colMangaId = ?''',
      [username, mangaId],
    );
    return rows != null && rows >= 1;
  }
}
