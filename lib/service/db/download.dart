import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/service/db/db_manager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/utils/utils.dart';

class DownloadDao {
  static const _tblDownloadManga = 'tbl_download_manga';
  static const _colDmMangaId = 'mid';
  static const _colDmMangaTitle = 'title';
  static const _colDmMangaCover = 'cover';
  static const _colDmMangaUrl = 'url';
  static const _colDmUpdatedAt = 'updated_at';

  static const _createTblDownloadManga = '''
    CREATE TABLE $_tblDownloadManga(
      $_colDmMangaId INTEGER,
      $_colDmMangaTitle VARCHAR(1023),
      $_colDmMangaCover VARCHAR(1023),
      $_colDmMangaUrl VARCHAR(1023),
      $_colDmUpdatedAt DATETIME,
      PRIMARY KEY ($_colDmMangaId)
    )''';

  static const _tblDownloadChapter = 'tbl_download_chapter';
  static const _colDcMangaId = 'mid';
  static const _colDcChapterId = 'cid';
  static const _colDcChapterTitle = 'title';
  static const _tblDcChapterGroup = 'group_name';
  static const _colDcTotalCount = 'total_count';
  static const _colDcStartedCount = 'started_count'; // <<<
  static const _colDcSuccessCount = 'success_count';

  static const _createTblDownloadChapter = '''
    CREATE TABLE $_tblDownloadChapter(
      $_colDcMangaId INTEGER,
      $_colDcChapterId INTEGER,
      $_colDcChapterTitle VARCHAR(1023),
      $_tblDcChapterGroup VARCHAR(1023),
      $_colDcTotalCount INTEGER,
      $_colDcStartedCount INTEGER,
      $_colDcSuccessCount INTEGER,
      PRIMARY KEY ($_colDcMangaId, $_colDcChapterId)
    )''';

  static Future<void> createTable(Database db) async {
    // await db.safeExecute('DROP TABLE tbl_download_manga');
    // await db.safeExecute('DROP TABLE tbl_download_chapter');
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
      '''SELECT $_colDmMangaId, $_colDmMangaTitle, $_colDmMangaCover, $_colDmMangaUrl, $_colDmUpdatedAt
         FROM $_tblDownloadManga
         ORDER BY $_colDmUpdatedAt DESC''',
    );
    if (mangaResults == null) {
      return null;
    }
    var chapterResults = await db.safeRawQuery(
      '''SELECT $_colDcMangaId, $_colDcTotalCount, $_colDcStartedCount, $_colDcSuccessCount
         FROM $_tblDownloadChapter''',
    );
    if (chapterResults == null) {
      return null;
    }

    var countMap = <int, List<int>>{}; // <<<
    for (var r in chapterResults) {
      var mid = r[_colDcMangaId]! as int;
      var totalPages = r[_colDcTotalCount]! as int;
      var startedPages = r[_colDcStartedCount]! as int;
      var successPages = r[_colDcSuccessCount]! as int;
      countMap[mid] = [
        (countMap[mid]?[0] ?? 0) + 1, // total
        (countMap[mid]?[1] ?? 0) + (startedPages > 0 ? 1 : 0), // started
        (countMap[mid]?[2] ?? 0) + (successPages == totalPages ? 1 : 0), // success
        (countMap[mid]?[3] ?? 0) + totalPages - successPages, // failed pages
      ];
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
          updatedAt: DateTime.parse(r[_colDmUpdatedAt]! as String),
          totalChapterCount: countMap[mid]?[0] ?? 0,
          startedChapterCount: countMap[mid]?[1] ?? 0,
          successChapterCount: countMap[mid]?[2] ?? 0,
          failedPageCountInAll: countMap[mid]?[3] ?? 0,
        ),
      );
    }
    return out;
  }

  static Future<DownloadedManga?> getManga({required int mid}) async {
    final db = await DBManager.instance.getDB();
    var mangaResults = await db.safeRawQuery(
      '''SELECT $_colDmMangaId, $_colDmMangaTitle, $_colDmMangaCover, $_colDmMangaUrl, $_colDmUpdatedAt
         FROM $_tblDownloadManga
         WHERE $_colDmMangaId = ?''',
      [mid],
    );
    if (mangaResults == null || mangaResults.isEmpty) {
      return null;
    }
    var chapterResults = await db.safeRawQuery(
      '''SELECT $_colDcMangaId, $_colDcTotalCount, $_colDcStartedCount, $_colDcSuccessCount
         FROM $_tblDownloadChapter
         WHERE $_colDcMangaId = ?''',
      [mid],
    );
    if (chapterResults == null || chapterResults.isEmpty) {
      return null;
    }

    var totalChapters = 0; // <<<
    var startedChapters = 0;
    var successChapters = 0;
    var failedPages = 0;
    for (var r in chapterResults) {
      var totalPages = r[_colDcTotalCount]! as int;
      var startedPages = r[_colDcStartedCount]! as int;
      var successPages = r[_colDcSuccessCount]! as int;
      totalChapters += 1;
      startedChapters += startedPages > 0 ? 1 : 0;
      successChapters += successPages == totalPages ? 1 : 0;
      failedPages += totalPages - successPages;
    }

    var r = mangaResults.first;
    return DownloadedManga(
      mangaId: mid,
      mangaTitle: r[_colDmMangaTitle]! as String,
      mangaCover: r[_colDmMangaCover]! as String,
      mangaUrl: r[_colDmMangaUrl]! as String,
      updatedAt: DateTime.parse(r[_colDmUpdatedAt]! as String),
      totalChapterCount: totalChapters,
      startedChapterCount: startedChapters,
      successChapterCount: successChapters,
      failedPageCountInAll: failedPages,
    );
  }

  static Future<List<DownloadedChapter>?> getChapters({required int mid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT $_colDcMangaId, $_colDcChapterId, $_colDcChapterTitle, $_tblDcChapterGroup, $_colDcTotalCount, $_colDcStartedCount, $_colDcSuccessCount
         FROM $_tblDownloadChapter
         WHERE $_colDcMangaId = ?''',
      [mid],
    );
    if (results == null) {
      return null;
    }

    var out = <DownloadedChapter>[];
    for (var r in results) {
      out.add(
        DownloadedChapter(
          mangaId: r[_colDcMangaId]! as int,
          chapterId: r[_colDcChapterId]! as int,
          chapterTitle: r[_colDcChapterTitle]! as String,
          chapterGroup: r[_tblDcChapterGroup]! as String,
          totalPageCount: r[_colDcTotalCount]! as int,
          startedPageCount: r[_colDcStartedCount]! as int,
          successPageCount: r[_colDcSuccessCount]! as int,
        ),
      );
    }
    return out;
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
           ($_colDmMangaId, $_colDmMangaTitle, $_colDmMangaCover, $_colDmMangaUrl, $_colDmUpdatedAt)
           VALUES (?, ?, ?, ?, ?)''',
        [manga.mangaId, manga.mangaTitle, manga.mangaCover, manga.mangaUrl, manga.updatedAt.toIso8601String()],
      );
    } else {
      rows = await db.safeRawUpdate(
        '''UPDATE $_tblDownloadManga
           SET $_colDmMangaTitle = ?, $_colDmMangaCover = ?, $_colDmMangaUrl = ?, $_colDmUpdatedAt = ?
           WHERE $_colDmMangaId = ?''',
        [manga.mangaTitle, manga.mangaCover, manga.mangaUrl, manga.updatedAt.toIso8601String(), manga.mangaId],
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
           ($_colDcMangaId, $_colDcChapterId, $_colDcChapterTitle, $_tblDcChapterGroup, $_colDcTotalCount, $_colDcStartedCount, $_colDcSuccessCount)
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [chapter.mangaId, chapter.chapterId, chapter.chapterTitle, chapter.chapterGroup, chapter.totalPageCount, chapter.startedPageCount, chapter.successPageCount],
      );
    } else {
      rows = await db.safeRawUpdate(
        '''UPDATE $_tblDownloadChapter
           SET $_colDcChapterTitle = ?, $_tblDcChapterGroup = ?, $_colDcTotalCount = ?, $_colDcStartedCount = ?, $_colDcSuccessCount = ?
           WHERE $_colDcMangaId = ? AND $_colDcChapterId = ?''',
        [chapter.chapterTitle, chapter.chapterGroup, chapter.totalPageCount, chapter.startedPageCount, chapter.successPageCount, chapter.mangaId, chapter.chapterId],
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
