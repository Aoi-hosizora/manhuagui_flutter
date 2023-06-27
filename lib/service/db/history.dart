import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/service/db/db_manager.dart';
import 'package:manhuagui_flutter/service/db/query_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/utils/utils.dart';

class HistoryDao {
  HistoryDao._();

  static const _tblHistory = 'tbl_history';
  static const _colUsername = 'username';
  static const _colMangaId = 'id';
  static const _colMangaTitle = 'manga_title';
  static const _colMangaCover = 'manga_cover';
  static const _colMangaUrl = 'manga_url';
  static const _colChapterId = 'chapter_id';
  static const _colChapterTitle = 'chapter_title';
  static const _colChapterPage = 'chapter_page';
  static const _colLastChapterId = 'last_chapter_id';
  static const _colLastChapterTitle = 'last_chapter_title';
  static const _colLastChapterPage = 'last_chapter_page';
  static const _colLastTime = 'last_time';

  static const metadata = TableMetadata(
    tableName: _tblHistory,
    primaryKeys: [_colUsername, _colMangaId],
    columns: [_colUsername, _colMangaId, _colMangaTitle, _colMangaCover, _colMangaUrl, _colChapterId, _colChapterTitle, _colChapterPage, _colLastChapterId, _colLastChapterTitle, _colLastChapterPage, _colLastTime],
  );

  static const _tblFootprint = 'tbl_footprint';
  static const _colFUsername = 'username';
  static const _colFMangaId = 'id';
  static const _colFChapterId = 'chapter_id';
  static const _colFCreatedAt = 'created_at';

  static const footprintMetadata = TableMetadata(
    tableName: _tblFootprint,
    primaryKeys: [_colFUsername, _colFMangaId, _colFChapterId],
    columns: [_colFUsername, _colFMangaId, _colFChapterId, _colFCreatedAt],
  );

  static Future<void> createForVer1(Database db) async {
    await db.safeExecute('''
      CREATE TABLE $_tblHistory(
        $_colUsername VARCHAR(1023),
        $_colMangaId INTEGER,
        $_colMangaTitle VARCHAR(1023),
        $_colMangaCover VARCHAR(1023),
        $_colMangaUrl VARCHAR(1023),
        $_colChapterId INTEGER,
        $_colChapterTitle VARCHAR(1023),
        $_colChapterPage INTEGER,
        $_colLastTime DATETIME,
        PRIMARY KEY ($_colUsername, $_colMangaId)
      )''');
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
    await db.safeExecute('ALTER TABLE $_tblHistory ADD COLUMN $_colLastChapterId INTEGER');
    await db.safeExecute('ALTER TABLE $_tblHistory ADD COLUMN $_colLastChapterTitle VARCHAR(1023)');
    await db.safeExecute('ALTER TABLE $_tblHistory ADD COLUMN $_colLastChapterPage INTEGER');
    await db.safeExecute('UPDATE $_tblHistory SET $_colLastChapterId = 0 WHERE $_colLastChapterId IS NULL');
    await db.safeExecute('UPDATE $_tblHistory SET $_colLastChapterTitle = "" WHERE $_colLastChapterTitle IS NULL');
    await db.safeExecute('UPDATE $_tblHistory SET $_colLastChapterPage = 1 WHERE $_colLastChapterPage IS NULL');
    await db.safeExecute('''
      CREATE TABLE $_tblFootprint(
        $_colFUsername VARCHAR(1023),
        $_colFMangaId INTEGER,
        $_colFChapterId INTEGER,
        $_colFCreatedAt DATETIME,
        PRIMARY KEY ($_colFUsername, $_colFMangaId, $_colFChapterId)
      )''');
    await db.safeExecute('''
      INSERT INTO $_tblFootprint ($_colFUsername, $_colFMangaId, $_colFChapterId, $_colFCreatedAt)
      SELECT $_colUsername, $_colMangaId, $_colChapterId, $_colLastTime AS $_colFCreatedAt 
      FROM $_tblHistory WHERE $_tblHistory.$_colChapterId <> 0
    ''');
  }

  static Tuple2<String, List<String>>? _buildLikeStatement({String? keyword, bool pureSearch = false, bool includeWHERE = false, bool includeAND = false}) {
    return QueryHelper.buildLikeStatement(
      [_colMangaTitle, if (!pureSearch) _colMangaId],
      keyword,
      includeWHERE: includeWHERE,
      includeAND: includeAND,
    );
  }

  static Future<int?> getHistoryCount({required String username, bool includeUnread = true, String? keyword, bool pureSearch = false}) async {
    final db = await DBManager.instance.getDB();
    var like = _buildLikeStatement(keyword: keyword, pureSearch: pureSearch, includeAND: true);
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblHistory
         WHERE $_colUsername = ? ${includeUnread ? '' : 'AND $_colChapterId <> 0'} ${like?.item1 ?? ''}''',
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
         FROM $_tblHistory
         WHERE $_colUsername = ? AND $_colMangaId = ?''',
      [username, mid],
    );
    if (results == null || results.isEmpty) {
      return null;
    }
    return firstIntValue(results)! > 0;
  }

  static Future<MangaHistory?> getHistory({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colChapterId, $_colChapterTitle, $_colChapterPage, $_colLastChapterId, $_colLastChapterTitle, $_colLastChapterPage, $_colLastTime
         FROM $_tblHistory
         WHERE $_colUsername = ? AND $_colMangaId = ?
         ORDER BY $_colLastTime DESC
         LIMIT 1''',
      [username, mid],
    );
    if (results == null || results.isEmpty) {
      return null;
    }
    var r = results.first;
    return MangaHistory(
      mangaId: mid,
      mangaTitle: r[_colMangaTitle]! as String,
      mangaCover: r[_colMangaCover]! as String,
      mangaUrl: r[_colMangaUrl]! as String,
      chapterId: r[_colChapterId]! as int,
      chapterTitle: r[_colChapterTitle]! as String,
      chapterPage: r[_colChapterPage]! as int,
      lastChapterId: r[_colLastChapterId]! as int,
      lastChapterTitle: r[_colLastChapterTitle]! as String,
      lastChapterPage: r[_colLastChapterPage]! as int,
      lastTime: DateTime.parse(r[_colLastTime]! as String),
    );
  }

  static Future<List<MangaHistory>?> getHistories({required String username, bool includeUnread = true, String? keyword, bool pureSearch = false, required int page, int limit = 20, int offset = 0}) async {
    final db = await DBManager.instance.getDB();
    offset = limit * (page - 1) - offset;
    if (offset < 0) {
      offset = 0;
    }
    var like = _buildLikeStatement(keyword: keyword, pureSearch: pureSearch, includeAND: true);
    var results = await db.safeRawQuery(
      '''SELECT $_colMangaId, $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colChapterId, $_colChapterTitle, $_colChapterPage, $_colLastChapterId, $_colLastChapterTitle, $_colLastChapterPage, $_colLastTime 
         FROM $_tblHistory
         WHERE $_colUsername = ? ${includeUnread ? '' : 'AND $_colChapterId <> 0'} ${like?.item1 ?? ''}
         ORDER BY $_colLastTime DESC
         LIMIT $limit OFFSET $offset''',
      [username, ...(like?.item2 ?? [])],
    );
    if (results == null) {
      return null;
    }
    var out = <MangaHistory>[];
    for (var r in results) {
      out.add(MangaHistory(
        mangaId: r[_colMangaId]! as int,
        mangaTitle: r[_colMangaTitle]! as String,
        mangaCover: r[_colMangaCover]! as String,
        mangaUrl: r[_colMangaUrl]! as String,
        chapterId: r[_colChapterId]! as int,
        chapterTitle: r[_colChapterTitle]! as String,
        chapterPage: r[_colChapterPage]! as int,
        lastChapterId: r[_colLastChapterId]! as int,
        lastChapterTitle: r[_colLastChapterTitle]! as String,
        lastChapterPage: r[_colLastChapterPage]! as int,
        lastTime: DateTime.parse(r[_colLastTime]! as String),
      ));
    }
    return out;
  }

  static Future<bool> addOrUpdateHistory({required String username, required MangaHistory history}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblHistory
         WHERE $_colUsername = ? AND $_colMangaId = ?''',
      [username, history.mangaId],
    );
    if (results == null) {
      return false;
    }
    var count = firstIntValue(results);

    int? rows = 0;
    if (count == 0) {
      rows = await db.safeRawInsert(
        '''INSERT INTO $_tblHistory ($_colUsername, $_colMangaId, $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colChapterId, $_colChapterTitle, $_colChapterPage, $_colLastChapterId, $_colLastChapterTitle, $_colLastChapterPage, $_colLastTime)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [username, history.mangaId, history.mangaTitle, history.mangaCover, history.mangaUrl, history.chapterId, history.chapterTitle, history.chapterPage, history.lastChapterId, history.lastChapterTitle, history.lastChapterPage, history.lastTime.toIso8601String()],
      );
    } else {
      rows = await db.safeRawUpdate(
        '''UPDATE $_tblHistory
           SET $_colMangaTitle = ?, $_colMangaCover = ?, $_colMangaUrl = ?, $_colChapterId = ?, $_colChapterTitle = ?, $_colChapterPage = ?, $_colLastChapterId = ?, $_colLastChapterTitle = ?, $_colLastChapterPage = ?, $_colLastTime = ?
           WHERE $_colUsername = ? AND $_colMangaId = ?''',
        [history.mangaTitle, history.mangaCover, history.mangaUrl, history.chapterId, history.chapterTitle, history.chapterPage, history.lastChapterId, history.lastChapterTitle, history.lastChapterPage, history.lastTime.toIso8601String(), username, history.mangaId],
      );
    }
    return rows != null && rows >= 1;
  }

  static Future<bool> deleteHistory({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblHistory
         WHERE $_colUsername = ? AND $_colMangaId = ?''',
      [username, mid],
    );
    return rows != null && rows >= 1;
  }

  static Future<bool> clearHistories({required String username}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblHistory
         WHERE $_colUsername = ?''',
      [username],
    );
    return rows != null;
  }

  static Future<int?> getMangaFootprintsCount({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblFootprint
         WHERE $_colFUsername = ? AND $_colFMangaId = ?''',
      [username, mid],
    );
    if (results == null) {
      return null;
    }
    return firstIntValue(results);
  }

  static Future<bool?> checkFootprintExistence({required String username, required int mid, required int cid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblFootprint
         WHERE $_colFUsername = ? AND $_colFMangaId = ? AND $_colFChapterId = ?''',
      [username, mid, cid],
    );
    if (results == null || results.isEmpty) {
      return null;
    }
    return firstIntValue(results)! > 0;
  }

  static Future<List<ChapterFootprint>?> getMangaFootprints({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT $_colFChapterId, $_colFCreatedAt
         FROM $_tblFootprint
         WHERE $_colFUsername = ? AND $_colFMangaId = ?
         ORDER BY $_colFCreatedAt DESC''',
      [username, mid],
    );
    if (results == null) {
      return null;
    }
    var out = <ChapterFootprint>[];
    for (var r in results) {
      out.add(ChapterFootprint(
        mangaId: mid,
        chapterId: r[_colFChapterId]! as int,
        createdAt: DateTime.parse(r[_colFCreatedAt]! as String),
      ));
    }
    return out;
  }

  static Future<Map<int, ChapterFootprint>?> getMangaFootprintsSet({required String username, required int mid}) async {
    var footprints = await getMangaFootprints(username: username, mid: mid);
    if (footprints == null) {
      return null;
    }
    return <int, ChapterFootprint>{for (var fp in footprints) fp.chapterId: fp};
  }

  static Future<ChapterFootprint?> getFootprint({required String username, required int mid, required int cid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT $_colFCreatedAt
         FROM $_tblFootprint
         WHERE $_colFUsername = ? AND $_colFMangaId = ? AND $_colFChapterId = ?''',
      [username, mid, cid],
    );
    if (results == null || results.isEmpty) {
      return null;
    }
    var r = results.first;
    return ChapterFootprint(
      mangaId: mid,
      chapterId: cid,
      createdAt: DateTime.parse(r[_colFCreatedAt]! as String),
    );
  }

  static Future<bool> addOrUpdateFootprint({required String username, required ChapterFootprint footprint}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblFootprint
         WHERE $_colFUsername = ? AND $_colFMangaId = ? AND $_colFChapterId = ?''',
      [username, footprint.mangaId, footprint.chapterId],
    );
    if (results == null) {
      return false;
    }
    var count = firstIntValue(results);

    int? rows = 0;
    if (count == 0) {
      rows = await db.safeRawInsert(
        '''INSERT INTO $_tblFootprint ($_colFUsername, $_colFMangaId, $_colFChapterId, $_colFCreatedAt)
           VALUES (?, ?, ?, ?)''',
        [username, footprint.mangaId, footprint.chapterId, footprint.createdAt.toIso8601String()],
      );
    } else {
      rows = await db.safeRawUpdate(
        '''UPDATE $_tblFootprint
           SET $_colFCreatedAt = ?
           WHERE $_colFUsername = ? AND $_colFMangaId = ? AND $_colFChapterId = ?''',
        [footprint.createdAt.toIso8601String(), username, footprint.mangaId, footprint.chapterId],
      );
    }
    return rows != null && rows >= 1;
  }

  static Future<bool> deleteFootprint({required String username, required int mid, required int cid}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblFootprint
         WHERE $_colUsername = ? AND $_colFMangaId = ? AND $_colFChapterId = ?''',
      [username, mid, cid],
    );
    return rows != null && rows >= 1;
  }

  static Future<bool> clearMangaFootprints({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblFootprint
         WHERE $_colUsername = ? AND $_colFMangaId = ?''',
      [username, mid],
    );
    return rows != null;
  }

  static Future<bool> clearAllFootprints({required String username}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblFootprint
         WHERE $_colUsername = ?''',
      [username],
    );
    return rows != null;
  }
}
