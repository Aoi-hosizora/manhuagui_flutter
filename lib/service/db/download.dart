import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/service/db/db_manager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/utils/utils.dart';

class DownloadDao {
  DownloadDao._();

  static const _tblDownloadManga = 'tbl_download_manga';
  static const _colDmMangaId = 'mid';
  static const _colDmMangaTitle = 'title';
  static const _colDmMangaCover = 'cover';
  static const _colDmMangaUrl = 'url';
  static const _colDmError = 'error';
  static const _colDmUpdatedAt = 'updated_at';

  static const _createTblDownloadManga = '''
    CREATE TABLE $_tblDownloadManga(
      $_colDmMangaId INTEGER,
      $_colDmMangaTitle VARCHAR(1023),
      $_colDmMangaCover VARCHAR(1023),
      $_colDmMangaUrl VARCHAR(1023),
      $_colDmError TINYINT,
      $_colDmUpdatedAt DATETIME,
      PRIMARY KEY ($_colDmMangaId)
    )''';

  static const _tblDownloadChapter = 'tbl_download_chapter';
  static const _colDcMangaId = 'mid';
  static const _colDcChapterId = 'cid';
  static const _colDcChapterTitle = 'title';
  static const _tblDcChapterGroup = 'group_name';
  static const _colDcTotalCount = 'total_count';
  static const _colDcTriedCount = 'tried_count';
  static const _colDcSuccessCount = 'success_count';

  static const _createTblDownloadChapter = '''
    CREATE TABLE $_tblDownloadChapter(
      $_colDcMangaId INTEGER,
      $_colDcChapterId INTEGER,
      $_colDcChapterTitle VARCHAR(1023),
      $_tblDcChapterGroup VARCHAR(1023),
      $_colDcTotalCount INTEGER,
      $_colDcTriedCount INTEGER,
      $_colDcSuccessCount INTEGER,
      PRIMARY KEY ($_colDcMangaId, $_colDcChapterId)
    )''';

  static Future<void> createTable(Database db) async {
    await db.safeExecute(_createTblDownloadManga);
    await db.safeExecute(_createTblDownloadChapter);
  }

  static Future<int?> getMangaCount() async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblDownloadManga''',
    );
    if (results == null) {
      return null;
    }
    return firstIntValue(results);
  }

  static Future<int?> getChapterCount({required int mid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblDownloadChapter
         WHERE $_colDcMangaId = ?''',
      [mid],
    );
    if (results == null) {
      return null;
    }
    return firstIntValue(results);
  }

  static Future<List<DownloadedManga>?> getMangas() async {
    final db = await DBManager.instance.getDB();
    var mangaResults = await db.safeRawQuery(
      '''SELECT $_colDmMangaId, $_colDmMangaTitle, $_colDmMangaCover, $_colDmMangaUrl, $_colDmError, $_colDmUpdatedAt
         FROM $_tblDownloadManga
         ORDER BY $_colDmUpdatedAt DESC''',
    );
    if (mangaResults == null) {
      return null;
    }
    var chapterResults = await db.safeRawQuery(
      '''SELECT $_colDcMangaId, $_colDcChapterId, $_colDcChapterTitle, $_tblDcChapterGroup, $_colDcTotalCount, $_colDcTriedCount, $_colDcSuccessCount
         FROM $_tblDownloadChapter''',
    );
    if (chapterResults == null) {
      return null;
    }

    var chaptersMap = <int, List<DownloadedChapter>>{};
    for (var r in chapterResults) {
      var mangaId = r[_colDcMangaId]! as int;
      chaptersMap[mangaId] ??= [];
      chaptersMap[mangaId]!.add(
        DownloadedChapter(
          mangaId: mangaId,
          chapterId: r[_colDcChapterId]! as int,
          chapterTitle: r[_colDcChapterTitle]! as String,
          chapterGroup: r[_tblDcChapterGroup]! as String,
          totalPageCount: r[_colDcTotalCount]! as int,
          triedPageCount: r[_colDcTriedCount]! as int,
          successPageCount: r[_colDcSuccessCount]! as int,
        ),
      );
    }

    var out = <DownloadedManga>[];
    for (var r in mangaResults) {
      var mid = r[_colDmMangaId]! as int;
      out.add(
        DownloadedManga(
          mangaId: mid,
          mangaTitle: r[_colDmMangaTitle]! as String,
          mangaCover: r[_colDmMangaCover]! as String,
          mangaUrl: r[_colDmMangaUrl]! as String,
          error: r[_colDmError]! as int > 0,
          updatedAt: DateTime.parse(r[_colDmUpdatedAt]! as String),
          downloadedChapters: chaptersMap[mid] ?? [],
        ),
      );
    }
    return out;
  }

  static Future<DownloadedManga?> getManga({required int mid}) async {
    final db = await DBManager.instance.getDB();
    var mangaResults = await db.safeRawQuery(
      '''SELECT $_colDmMangaId, $_colDmMangaTitle, $_colDmMangaCover, $_colDmMangaUrl, $_colDmError, $_colDmUpdatedAt
         FROM $_tblDownloadManga
         WHERE $_colDmMangaId = ?''',
      [mid],
    );
    if (mangaResults == null || mangaResults.isEmpty) {
      return null;
    }
    var chapterResults = await db.safeRawQuery(
      '''SELECT $_colDcMangaId, $_colDcChapterId, $_colDcChapterTitle, $_tblDcChapterGroup, $_colDcTotalCount, $_colDcTriedCount, $_colDcSuccessCount
         FROM $_tblDownloadChapter
         WHERE $_colDcMangaId = ?''',
      [mid],
    );
    if (chapterResults == null) {
      return null;
    }

    var chapters = <DownloadedChapter>[];
    for (var r in chapterResults) {
      chapters.add(
        DownloadedChapter(
          mangaId: r[_colDcMangaId]! as int,
          chapterId: r[_colDcChapterId]! as int,
          chapterTitle: r[_colDcChapterTitle]! as String,
          chapterGroup: r[_tblDcChapterGroup]! as String,
          totalPageCount: r[_colDcTotalCount]! as int,
          triedPageCount: r[_colDcTriedCount]! as int,
          successPageCount: r[_colDcSuccessCount]! as int,
        ),
      );
    }

    var r = mangaResults.first;
    return DownloadedManga(
      mangaId: mid,
      mangaTitle: r[_colDmMangaTitle]! as String,
      mangaCover: r[_colDmMangaCover]! as String,
      mangaUrl: r[_colDmMangaUrl]! as String,
      error: r[_colDmError]! as int > 0,
      updatedAt: DateTime.parse(r[_colDmUpdatedAt]! as String),
      downloadedChapters: chapters,
    );
  }

  static Future<bool> addOrUpdateManga({required DownloadedManga manga}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblDownloadManga
         WHERE $_colDmMangaId = ?
      ''',
      [manga.mangaId],
    );
    if (results == null) {
      return false;
    }
    var count = firstIntValue(results);

    int? rows = 0;
    if (count == 0) {
      rows = await db.safeRawInsert(
        '''INSERT INTO $_tblDownloadManga
           ($_colDmMangaId, $_colDmMangaTitle, $_colDmMangaCover, $_colDmMangaUrl, $_colDmError, $_colDmUpdatedAt)
           VALUES (?, ?, ?, ?, ?, ?)''',
        [manga.mangaId, manga.mangaTitle, manga.mangaCover, manga.mangaUrl, manga.error ? 1 : 0, manga.updatedAt.toIso8601String()],
      );
    } else {
      rows = await db.safeRawUpdate(
        '''UPDATE $_tblDownloadManga
           SET $_colDmMangaTitle = ?, $_colDmMangaCover = ?, $_colDmMangaUrl = ?, $_colDmError = ?, $_colDmUpdatedAt = ?
           WHERE $_colDmMangaId = ?''',
        [manga.mangaTitle, manga.mangaCover, manga.mangaUrl, manga.error ? 1 : 0, manga.updatedAt.toIso8601String(), manga.mangaId],
      );
    }
    return rows != null && rows >= 1;
  }

  static Future<bool> addOrUpdateChapter({required DownloadedChapter chapter}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblDownloadChapter
         WHERE $_colDcMangaId = ? AND $_colDcChapterId = ?''',
      [chapter.mangaId, chapter.chapterId],
    );
    if (results == null) {
      return false;
    }
    var count = firstIntValue(results);

    int? rows = 0;
    if (count == 0) {
      rows = await db.safeRawInsert(
        '''INSERT INTO $_tblDownloadChapter
           ($_colDcMangaId, $_colDcChapterId, $_colDcChapterTitle, $_tblDcChapterGroup, $_colDcTotalCount, $_colDcTriedCount, $_colDcSuccessCount)
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [chapter.mangaId, chapter.chapterId, chapter.chapterTitle, chapter.chapterGroup, chapter.totalPageCount, chapter.triedPageCount, chapter.successPageCount],
      );
    } else {
      rows = await db.safeRawUpdate(
        '''UPDATE $_tblDownloadChapter
           SET $_colDcChapterTitle = ?, $_tblDcChapterGroup = ?, $_colDcTotalCount = ?, $_colDcTriedCount = ?, $_colDcSuccessCount = ?
           WHERE $_colDcMangaId = ? AND $_colDcChapterId = ?''',
        [chapter.chapterTitle, chapter.chapterGroup, chapter.totalPageCount, chapter.triedPageCount, chapter.successPageCount, chapter.mangaId, chapter.chapterId],
      );
    }
    return rows != null && rows >= 1;
  }

  static Future<bool?> deleteManga({required int mid}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblDownloadManga
         WHERE $_colDmMangaId = ?''',
      [mid],
    );
    return rows != null && rows >= 1;
  }

  static Future<bool?> deleteAllChapters({required int mid}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblDownloadChapter
         WHERE $_colDcMangaId = ?''',
      [mid],
    );
    return rows != null && rows >= 1;
  }

  static Future<bool?> deleteChapter({required int mid, required int cid}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblDownloadChapter
         WHERE $_colDcMangaId = ? AND $_colDcChapterId = ?''',
      [mid, cid],
    );
    return rows != null && rows >= 1;
  }

  static Future<void> upgradeFromVer1To2(Database db) async {
    await createTable(db);
  }
}
