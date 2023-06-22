import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/common.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/service/db/db_manager.dart';
import 'package:manhuagui_flutter/service/db/query_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/utils/utils.dart';

class LaterMangaDao {
  LaterMangaDao._();

  static const _tblLaterManga = 'tbl_later_manga';
  static const _colUsername = 'username';
  static const _colMangaId = 'id';
  static const _colMangaTitle = 'manga_title';
  static const _colMangaCover = 'manga_cover';
  static const _colMangaUrl = 'manga_url';
  static const _colNewestChapter = 'newest_chapter';
  static const _colNewestDate = 'newest_date';
  static const _colCreatedAt = 'created_at';

  static const laterMangaMetadata = TableMetadata(
    tableName: _tblLaterManga,
    primaryKeys: [_colUsername, _colMangaId],
    columns: [_colUsername, _colMangaId, _colMangaTitle, _colMangaCover, _colMangaUrl, _colNewestChapter, _colNewestDate, _colCreatedAt],
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
    // pass
  }

  static Future<void> upgradeFromVer4To5(Database db) async {
    await db.safeExecute('''
      CREATE TABLE $_tblLaterManga(
        $_colUsername VARCHAR(1023),
        $_colMangaId INTEGER,
        $_colMangaTitle VARCHAR(1023),
        $_colMangaCover VARCHAR(1023),
        $_colMangaUrl VARCHAR(1023),
        $_colNewestChapter VARCHAR(1023),
        $_colNewestDate VARCHAR(1023),
        $_colCreatedAt DATETIME,
        PRIMARY KEY ($_colUsername, $_colMangaId)
      )''');
  }

  static Tuple2<String, List<String>>? _buildLikeStatement({String? keyword, bool pureSearch = false, bool includeWHERE = false, bool includeAND = false}) {
    return QueryHelper.buildLikeStatement(
      [_colMangaTitle, if (!pureSearch) _colMangaId],
      keyword,
      includeWHERE: includeWHERE,
      includeAND: includeAND,
    );
  }

  static String _buildOrderByStatement({required SortMethod sortMethod, bool includeORDERBY = false}) {
    return QueryHelper.buildOrderByStatement(
          sortMethod,
          idColumn: _colMangaId,
          nameColumn: _colMangaTitle,
          timeColumn: _colCreatedAt,
          orderColumn: null,
          includeORDERBY: includeORDERBY,
        ) ??
        '';
  }

  static Future<int?> getLaterMangaCount({required String username, String? keyword, bool pureSearch = false}) async {
    final db = await DBManager.instance.getDB();
    var like = _buildLikeStatement(keyword: keyword, pureSearch: pureSearch, includeAND: true);
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblLaterManga
         WHERE $_colUsername = ? ${like?.item1 ?? ''}''',
      [username, ...(like?.item2 ?? [])],
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
         FROM $_tblLaterManga
         WHERE $_colUsername = ? AND $_colMangaId = ?
         ORDER BY $_colCreatedAt DESC''',
      [username, mid],
    );
    if (results == null || results.isEmpty) {
      return null;
    }
    return firstIntValue(results)! > 0;
  }

  static Future<List<LaterManga>?> getLaterMangas({required String username, String? keyword, bool pureSearch = false, SortMethod sortMethod = SortMethod.byTimeDesc, required int page, int limit = 20, int offset = 0}) async {
    final db = await DBManager.instance.getDB();
    var like = _buildLikeStatement(keyword: keyword, pureSearch: pureSearch, includeAND: true);
    var orderBy = _buildOrderByStatement(sortMethod: sortMethod, includeORDERBY: false);
    offset = limit * (page - 1) - offset;
    if (offset < 0) {
      offset = 0;
    }
    var results = await db.safeRawQuery(
      '''SELECT $_colMangaId, $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colNewestChapter, $_colNewestDate, $_colCreatedAt
         FROM $_tblLaterManga
         WHERE $_colUsername = ? ${like?.item1 ?? ''}
         ORDER BY $orderBy, $_colCreatedAt DESC
         LIMIT $limit OFFSET $offset''',
      [username, ...(like?.item2 ?? [])],
    );
    if (results == null) {
      return null;
    }
    var out = <LaterManga>[];
    for (var r in results) {
      out.add(LaterManga(
        mangaId: r[_colMangaId]! as int,
        mangaTitle: r[_colMangaTitle]! as String,
        mangaCover: r[_colMangaCover]! as String,
        mangaUrl: r[_colMangaUrl]! as String,
        newestChapter: r[_colNewestChapter] as String?,
        newestDate: r[_colNewestDate] as String?,
        createdAt: DateTime.parse(r[_colCreatedAt]! as String),
      ));
    }
    return out;
  }

  static Future<LaterManga?> getLaterManga({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colNewestChapter, $_colNewestDate, $_colCreatedAt
         FROM $_tblLaterManga
         WHERE $_colUsername = ? AND $_colMangaId = ?
         ORDER BY $_colCreatedAt DESC
         LIMIT 1''',
      [username, mid],
    );
    if (results == null || results.isEmpty) {
      return null;
    }
    var r = results.first;
    return LaterManga(
      mangaId: mid,
      mangaTitle: r[_colMangaTitle]! as String,
      mangaCover: r[_colMangaCover]! as String,
      mangaUrl: r[_colMangaUrl]! as String,
      newestChapter: r[_colNewestChapter] as String?,
      newestDate: r[_colNewestDate] as String?,
      createdAt: DateTime.parse(r[_colCreatedAt]! as String),
    );
  }

  static Future<List<DateTime>> getLaterMangaDates({required String username}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT DISTINCT DATE($_colCreatedAt) AS date
         FROM $_tblLaterManga
         WHERE $_colUsername = ?
         ORDER BY $_colCreatedAt DESC''',
      [username],
    );
    if (results == null) {
      return [];
    }
    var out = <DateTime>{};
    for (var r in results) {
      var dt = DateTime.parse(r['date']! as String);
      out.add(DateTime(dt.year, dt.month, dt.day));
    }
    return out.toList();
  }

  static Future<int?> getLaterMangaCountByDate({required String username, required DateTime datetime}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblLaterManga
         WHERE $_colUsername = ? AND DATE($_colCreatedAt) = ?''',
      [username, formatDatetimeAndDuration(datetime, FormatPattern.barredDate)],
    );
    if (results == null) {
      return null;
    }
    return firstIntValue(results);
  }

  static Future<List<LaterManga>?> getLaterMangasByDate({required String username, required DateTime datetime, SortMethod sortMethod = SortMethod.byTimeDesc, required int page, int limit = 20, int offset = 0}) async {
    final db = await DBManager.instance.getDB();
    var orderBy = _buildOrderByStatement(sortMethod: sortMethod, includeORDERBY: false);
    offset = limit * (page - 1) - offset;
    if (offset < 0) {
      offset = 0;
    }
    var results = await db.safeRawQuery(
      '''SELECT $_colMangaId, $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colNewestChapter, $_colNewestDate, $_colCreatedAt
         FROM $_tblLaterManga
         WHERE $_colUsername = ? AND DATE($_colCreatedAt) = ?
         ORDER BY $orderBy, $_colCreatedAt DESC
         LIMIT $limit OFFSET $offset''',
      [username, formatDatetimeAndDuration(datetime, FormatPattern.barredDate)],
    );
    if (results == null) {
      return null;
    }
    var out = <LaterManga>[];
    for (var r in results) {
      out.add(LaterManga(
        mangaId: r[_colMangaId]! as int,
        mangaTitle: r[_colMangaTitle]! as String,
        mangaCover: r[_colMangaCover]! as String,
        mangaUrl: r[_colMangaUrl]! as String,
        newestChapter: r[_colNewestChapter] as String?,
        newestDate: r[_colNewestDate] as String?,
        createdAt: DateTime.parse(r[_colCreatedAt]! as String),
      ));
    }
    return out;
  }

  static Future<bool> addOrUpdateLaterManga({required String username, required LaterManga manga}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblLaterManga
         WHERE $_colUsername = ? AND $_colMangaId = ?''',
      [username, manga.mangaId],
    );
    if (results == null) {
      return false;
    }
    var count = firstIntValue(results);

    int? rows = 0;
    if (count == 0) {
      rows = await db.safeRawInsert(
        '''INSERT INTO $_tblLaterManga ($_colUsername, $_colMangaId, $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colNewestChapter, $_colNewestDate, $_colCreatedAt)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        [username, manga.mangaId, manga.mangaTitle, manga.mangaCover, manga.mangaUrl, manga.newestChapter, manga.newestDate, manga.createdAt.toIso8601String()],
      );
    } else {
      rows = await db.safeRawUpdate(
        '''UPDATE $_tblLaterManga
           SET $_colMangaTitle = ?, $_colMangaCover = ?, $_colMangaUrl = ?, $_colNewestChapter = ?, $_colNewestDate = ?, $_colCreatedAt = ?
           WHERE $_colUsername = ? AND $_colMangaId = ?''',
        [manga.mangaTitle, manga.mangaCover, manga.mangaUrl, manga.newestChapter, manga.newestDate, manga.createdAt.toIso8601String(), username, manga.mangaId],
      );
    }
    return rows != null && rows >= 1;
  }

  static Future<bool> clearLaterMangas({required String username}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblLaterManga
         WHERE $_colUsername = ?''',
      [username],
    );
    return rows != null && rows >= 1;
  }

  static Future<bool> deleteLaterManga({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblLaterManga
         WHERE $_colUsername = ? AND $_colMangaId = ?''',
      [username, mid],
    );
    return rows != null && rows >= 1;
  }
}
