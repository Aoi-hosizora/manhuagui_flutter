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
  static const _colLmUsername = 'username';
  static const _colLmMangaId = 'id';
  static const _colLmMangaTitle = 'manga_title';
  static const _colLmMangaCover = 'manga_cover';
  static const _colLmMangaUrl = 'manga_url';
  static const _colLmNewestChapter = 'newest_chapter';
  static const _colLmNewestDate = 'newest_date';
  static const _colLmCreatedAt = 'created_at';

  static const laterMangaMetadata = TableMetadata(
    tableName: _tblLaterManga,
    primaryKeys: [_colLmUsername, _colLmMangaId],
    columns: [_colLmUsername, _colLmMangaId, _colLmMangaTitle, _colLmMangaCover, _colLmMangaUrl, _colLmNewestChapter, _colLmNewestDate, _colLmCreatedAt],
  );

  static const _tblLaterChapter = 'tbl_later_chapter';
  static const _colLcUsername = 'username';
  static const _colLcMangaId = 'manga_id';
  static const _colLcChapterId = 'chapter_id';
  static const _colLcChapterTitle = 'chapter_title';
  static const _colLcCreatedAt = 'created_at';

  static const laterChapterMetadata = TableMetadata(
    tableName: _tblLaterChapter,
    primaryKeys: [_colLcUsername, _colLcMangaId, _colLcChapterId],
    columns: [_colLcUsername, _colLcMangaId, _colLcChapterId, _colLcChapterTitle, _colLcCreatedAt],
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
        $_colLmUsername VARCHAR(1023),
        $_colLmMangaId INTEGER,
        $_colLmMangaTitle VARCHAR(1023),
        $_colLmMangaCover VARCHAR(1023),
        $_colLmMangaUrl VARCHAR(1023),
        $_colLmNewestChapter VARCHAR(1023),
        $_colLmNewestDate VARCHAR(1023),
        $_colLmCreatedAt DATETIME,
        PRIMARY KEY ($_colLmUsername, $_colLmMangaId)
      )''');
  }

  static Future<void> upgradeFromVer5To6(Database db) async {
    await db.safeExecute('''
      CREATE TABLE $_tblLaterChapter(
        $_colLcUsername VARCHAR(1023),
        $_colLcMangaId INTEGER,
        $_colLcChapterId INTEGER,
        $_colLcChapterTitle VARCHAR(1023),
        $_colLcCreatedAt DATETIME,
        PRIMARY KEY ($_colLcUsername, $_colLcMangaId, $_colLcChapterId)
      )''');
  }

  static Tuple2<String, List<String>>? _buildLikeStatement({String? keyword, bool pureSearch = false, bool includeWHERE = false, bool includeAND = false}) {
    return QueryHelper.buildLikeStatement(
      [_colLmMangaTitle, if (!pureSearch) _colLmMangaId],
      keyword,
      includeWHERE: includeWHERE,
      includeAND: includeAND,
    );
  }

  static String _buildOrderByStatement({required SortMethod sortMethod, bool includeORDERBY = false}) {
    return QueryHelper.buildOrderByStatement(
          sortMethod,
          idColumn: _colLmMangaId,
          nameColumn: _colLmMangaTitle,
          timeColumn: _colLmCreatedAt,
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
         WHERE $_colLmUsername = ? ${like?.item1 ?? ''}''',
      [username, ...(like?.item2 ?? [])],
    );
    if (results == null) {
      return null;
    }
    return firstIntValue(results);
  }

  static Future<int?> getLaterChapterCount({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblLaterChapter
         WHERE $_colLcUsername = ? AND $_colLcMangaId = ?''',
      [username, mid],
    );
    if (results == null) {
      return null;
    }
    return firstIntValue(results);
  }

  static Future<bool?> checkExistence({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT($_colLmMangaId)
         FROM $_tblLaterManga
         WHERE $_colLmUsername = ? AND $_colLmMangaId = ?
         ORDER BY $_colLmCreatedAt DESC''',
      [username, mid],
    );
    if (results == null || results.isEmpty) {
      return null;
    }
    return firstIntValue(results)! > 0;
  }

  static Future<bool?> checkChapterExistence({required String username, required int mid, required int cid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT($_colLcChapterId)
         FROM $_tblLaterChapter
         WHERE $_colLcUsername = ? AND $_colLcMangaId = ? AND $_colLcChapterId = ?
         ORDER BY $_colLcCreatedAt DESC''',
      [username, mid, cid],
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
      '''SELECT $_colLmMangaId, $_colLmMangaTitle, $_colLmMangaCover, $_colLmMangaUrl, $_colLmNewestChapter, $_colLmNewestDate, $_colLmCreatedAt
         FROM $_tblLaterManga
         WHERE $_colLmUsername = ? ${like?.item1 ?? ''}
         ORDER BY $orderBy, $_colLmCreatedAt DESC
         LIMIT $limit OFFSET $offset''',
      [username, ...(like?.item2 ?? [])],
    );
    if (results == null) {
      return null;
    }
    var out = <LaterManga>[];
    for (var r in results) {
      out.add(LaterManga(
        mangaId: r[_colLmMangaId]! as int,
        mangaTitle: r[_colLmMangaTitle]! as String,
        mangaCover: r[_colLmMangaCover]! as String,
        mangaUrl: r[_colLmMangaUrl]! as String,
        newestChapter: r[_colLmNewestChapter] as String?,
        newestDate: r[_colLmNewestDate] as String?,
        createdAt: DateTime.parse(r[_colLmCreatedAt]! as String),
      ));
    }
    return out;
  }

  static Future<List<LaterChapter>?> getLaterChapters({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT $_colLcChapterId, $_colLcChapterTitle, $_colLcCreatedAt
         FROM $_tblLaterChapter
         WHERE $_colLcUsername = ? AND $_colLcMangaId = ?
         ORDER BY $_colLcCreatedAt DESC, $_colLcChapterId DESC''',
      [username, mid],
    );
    if (results == null) {
      return null;
    }
    var out = <LaterChapter>[];
    for (var r in results) {
      out.add(LaterChapter(
        mangaId: mid,
        chapterId: r[_colLcChapterId]! as int,
        chapterTitle: r[_colLcChapterTitle]! as String,
        createdAt: DateTime.parse(r[_colLcCreatedAt]! as String),
      ));
    }
    return out;
  }

  static Future<Map<int, LaterChapter>?> getLaterChaptersSet({required String username, required int mid}) async {
    var laters = await getLaterChapters(username: username, mid: mid);
    if (laters == null) {
      return null;
    }
    return <int, LaterChapter>{for (var l in laters) l.chapterId: l};
  }


  static Future<LaterManga?> getLaterManga({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT $_colLmMangaTitle, $_colLmMangaCover, $_colLmMangaUrl, $_colLmNewestChapter, $_colLmNewestDate, $_colLmCreatedAt
         FROM $_tblLaterManga
         WHERE $_colLmUsername = ? AND $_colLmMangaId = ?
         ORDER BY $_colLmCreatedAt DESC
         LIMIT 1''',
      [username, mid],
    );
    if (results == null || results.isEmpty) {
      return null;
    }
    var r = results.first;
    return LaterManga(
      mangaId: mid,
      mangaTitle: r[_colLmMangaTitle]! as String,
      mangaCover: r[_colLmMangaCover]! as String,
      mangaUrl: r[_colLmMangaUrl]! as String,
      newestChapter: r[_colLmNewestChapter] as String?,
      newestDate: r[_colLmNewestDate] as String?,
      createdAt: DateTime.parse(r[_colLmCreatedAt]! as String),
    );
  }

  static Future<List<DateTime>> getLaterMangaDates({required String username}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT DISTINCT DATE($_colLmCreatedAt) AS date
         FROM $_tblLaterManga
         WHERE $_colLmUsername = ?
         ORDER BY $_colLmCreatedAt DESC''',
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
         WHERE $_colLmUsername = ? AND DATE($_colLmCreatedAt) = ?''',
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
      '''SELECT $_colLmMangaId, $_colLmMangaTitle, $_colLmMangaCover, $_colLmMangaUrl, $_colLmNewestChapter, $_colLmNewestDate, $_colLmCreatedAt
         FROM $_tblLaterManga
         WHERE $_colLmUsername = ? AND DATE($_colLmCreatedAt) = ?
         ORDER BY $orderBy, $_colLmCreatedAt DESC
         LIMIT $limit OFFSET $offset''',
      [username, formatDatetimeAndDuration(datetime, FormatPattern.barredDate)],
    );
    if (results == null) {
      return null;
    }
    var out = <LaterManga>[];
    for (var r in results) {
      out.add(LaterManga(
        mangaId: r[_colLmMangaId]! as int,
        mangaTitle: r[_colLmMangaTitle]! as String,
        mangaCover: r[_colLmMangaCover]! as String,
        mangaUrl: r[_colLmMangaUrl]! as String,
        newestChapter: r[_colLmNewestChapter] as String?,
        newestDate: r[_colLmNewestDate] as String?,
        createdAt: DateTime.parse(r[_colLmCreatedAt]! as String),
      ));
    }
    return out;
  }

  static Future<LaterChapter?> getLaterChapter({required String username, required int mid, required int cid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT $_colLcChapterTitle, $_colLcCreatedAt
         FROM $_tblLaterChapter
         WHERE $_colLcUsername = ? AND $_colLcMangaId = ? AND $_colLcChapterId = ?
         ORDER BY $_colLcCreatedAt DESC
         LIMIT 1''',
      [username, mid, cid],
    );
    if (results == null || results.isEmpty) {
      return null;
    }
    var r = results.first;
    return LaterChapter(
      mangaId: mid,
      chapterId: cid,
      chapterTitle: r[_colLcChapterTitle]! as String,
      createdAt: DateTime.parse(r[_colLcCreatedAt]! as String),
    );
  }

  static Future<bool> addOrUpdateLaterManga({required String username, required LaterManga manga}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblLaterManga
         WHERE $_colLmUsername = ? AND $_colLmMangaId = ?''',
      [username, manga.mangaId],
    );
    if (results == null) {
      return false;
    }
    var count = firstIntValue(results);

    int? rows = 0;
    if (count == 0) {
      rows = await db.safeRawInsert(
        '''INSERT INTO $_tblLaterManga ($_colLmUsername, $_colLmMangaId, $_colLmMangaTitle, $_colLmMangaCover, $_colLmMangaUrl, $_colLmNewestChapter, $_colLmNewestDate, $_colLmCreatedAt)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        [username, manga.mangaId, manga.mangaTitle, manga.mangaCover, manga.mangaUrl, manga.newestChapter, manga.newestDate, manga.createdAt.toIso8601String()],
      );
    } else {
      rows = await db.safeRawUpdate(
        '''UPDATE $_tblLaterManga
           SET $_colLmMangaTitle = ?, $_colLmMangaCover = ?, $_colLmMangaUrl = ?, $_colLmNewestChapter = ?, $_colLmNewestDate = ?, $_colLmCreatedAt = ?
           WHERE $_colLmUsername = ? AND $_colLmMangaId = ?''',
        [manga.mangaTitle, manga.mangaCover, manga.mangaUrl, manga.newestChapter, manga.newestDate, manga.createdAt.toIso8601String(), username, manga.mangaId],
      );
    }
    return rows != null && rows >= 1;
  }

  static Future<bool> addOrUpdateLaterChapter({required String username, required LaterChapter chapter}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblLaterChapter
         WHERE $_colLcUsername = ? AND $_colLcMangaId = ? AND $_colLcChapterId = ?''',
      [username, chapter.mangaId, chapter.chapterId],
    );
    if (results == null) {
      return false;
    }
    var count = firstIntValue(results);

    int? rows = 0;
    if (count == 0) {
      rows = await db.safeRawInsert(
        '''INSERT INTO $_tblLaterChapter ($_colLcUsername, $_colLcMangaId, $_colLcChapterId, $_colLcChapterTitle, $_colLcCreatedAt)
           VALUES (?, ?, ?, ?, ?)''',
        [username, chapter.mangaId, chapter.chapterId, chapter.chapterTitle, chapter.createdAt.toIso8601String()],
      );
    } else {
      rows = await db.safeRawUpdate(
        '''UPDATE $_tblLaterChapter
           SET $_colLcChapterTitle = ?, $_colLcCreatedAt = ?
           WHERE $_colLcUsername = ? AND $_colLcMangaId = ? AND $_colLcChapterId = ?''',
        [chapter.chapterTitle, chapter.createdAt.toIso8601String(), username, chapter.mangaId, chapter.chapterId],
      );
    }
    return rows != null && rows >= 1;
  }

  static Future<bool> clearLaterMangas({required String username}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblLaterManga
         WHERE $_colLmUsername = ?''',
      [username],
    );
    return rows != null && rows >= 1;
  }

  static Future<bool> deleteLaterManga({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblLaterManga
         WHERE $_colLmUsername = ? AND $_colLmMangaId = ?''',
      [username, mid],
    );
    return rows != null && rows >= 1;
  }

  static Future<bool> clearLaterChapters({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblLaterChapter
         WHERE $_colLcUsername = ? AND $_colLcMangaId''',
      [username, mid],
    );
    return rows != null && rows >= 1;
  }

  static Future<bool> deleteLaterChapter({required String username, required int mid, required int cid}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblLaterChapter
         WHERE $_colLcUsername = ? AND $_colLcMangaId = ? AND $_colLcChapterId = ?''',
      [username, mid, cid],
    );
    return rows != null && rows >= 1;
  }
}
