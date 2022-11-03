import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/service/db/db_manager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/utils/utils.dart';

class HistoryDao {
  static const _tblHistory = 'tbl_history';
  static const _colUsername = 'username';
  static const _colMangaId = 'id';
  static const _colMangaTitle = 'manga_title';
  static const _colMangaCover = 'manga_cover';
  static const _colMangaUrl = 'manga_url';
  static const _colChapterId = 'chapter_id';
  static const _colChapterTitle = 'chapter_title';
  static const _colChapterPage = 'chapter_page';
  static const _colLastTime = 'last_time';

  static const _createTblHistory = '''
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
    )''';

  static Future<void> createTable(Database db) async {
    await db.safeExecute(_createTblHistory);
  }

  static Future<int?> getHistoryCount({required String username}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblHistory
         WHERE $_colUsername = ?''',
      [username],
    );
    if (results == null) {
      return null;
    }
    return firstIntValue(results);
  }

  static Future<MangaHistory?> getHistory({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colChapterId, $_colChapterTitle, $_colChapterPage, $_colLastTime
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
      lastTime: DateTime.parse(r[_colLastTime]! as String),
    );
  }

  static Future<List<MangaHistory>?> getHistories({required String username, required int page, int limit = 20, int offset = 0}) async {
    final db = await DBManager.instance.getDB();
    offset = limit * (page - 1) - offset;
    if (offset < 0) {
      offset = 0;
    }
    var results = await db.safeRawQuery(
      '''SELECT $_colMangaId, $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colChapterId, $_colChapterTitle, $_colChapterPage, $_colLastTime 
         FROM $_tblHistory
         WHERE $_colUsername = ?
         ORDER BY $_colLastTime DESC
         LIMIT $limit OFFSET $offset''',
      [username],
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
        '''INSERT INTO $_tblHistory ($_colUsername, $_colMangaId, $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colChapterId, $_colChapterTitle, $_colChapterPage, $_colLastTime)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [username, history.mangaId, history.mangaTitle, history.mangaCover, history.mangaUrl, history.chapterId, history.chapterTitle, history.chapterPage, history.lastTime.toIso8601String()],
      );
    } else {
      rows = await db.safeRawUpdate(
        '''UPDATE $_tblHistory
           SET $_colMangaTitle = ?, $_colMangaCover = ?, $_colMangaUrl = ?, $_colChapterId = ?, $_colChapterTitle = ?, $_colChapterPage = ?, $_colLastTime = ?
           WHERE $_colUsername = ? AND $_colMangaId = ?''',
        [history.mangaTitle, history.mangaCover, history.mangaUrl, history.chapterId, history.chapterTitle, history.chapterPage, history.lastTime.toIso8601String(), username, history.mangaId],
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

  static Future<void> upgradeFromVer1To2(Database db) async {
    // skip
  }
}
