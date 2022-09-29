import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/service/db/db_manager.dart';
import 'package:sqflite/utils/utils.dart';

const _tblHistory = 'tbl_history';
const _colUsername = 'username';
const _colMangaId = 'id';
const _colMangaTitle = 'manga_title';
const _colMangaCover = 'manga_cover';
const _colMangaUrl = 'manga_url';
const _colChapterId = 'chapter_id';
const _colChapterTitle = 'chapter_title';
const _colChapterPage = 'chapter_page';
const _colLastTime = 'last_time';

const createTblHistory = '''
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

Future<int> getHistoryCount({required String username}) async {
  var db = await DBManager.instance.getDB();
  var count = firstIntValue(await db.rawQuery(
    '''SELECT COUNT(*) 
       FROM $_tblHistory 
       WHERE $_colUsername = ?''',
    [username],
  ));
  return count!;
}

Future<MangaHistory?> getHistory({required String username, required int mid}) async {
  var db = await DBManager.instance.getDB();
  var maps = await db.rawQuery(
    '''SELECT $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colChapterId, $_colChapterTitle, $_colChapterPage, $_colLastTime
       FROM $_tblHistory
       WHERE $_colUsername = ? AND $_colMangaId = ?
       ORDER BY $_colLastTime DESC
       LIMIT 1''',
    [username, mid],
  );
  if (maps.isEmpty) {
    return null;
  }
  var m = maps.first;
  return MangaHistory(
    mangaId: mid,
    mangaTitle: m[_colMangaTitle]! as String,
    mangaCover: m[_colMangaCover]! as String,
    mangaUrl: m[_colMangaUrl]! as String,
    chapterId: m[_colChapterId]! as int,
    chapterTitle: m[_colChapterTitle]! as String,
    chapterPage: m[_colChapterPage]! as int,
    lastTime: DateTime.parse(m[_colLastTime]! as String),
  );
}

Future<List<MangaHistory>> getHistories({required String username, required int page, int limit = 20, int offset = 0}) async {
  offset = limit * (page - 1) - offset;
  if (offset < 0) {
    offset = 0;
  }
  var db = await DBManager.instance.getDB();
  var maps = await db.rawQuery(
    '''SELECT $_colMangaId, $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colChapterId, $_colChapterTitle, $_colChapterPage, $_colLastTime 
       FROM $_tblHistory
       WHERE $_colUsername = ?
       ORDER BY $_colLastTime DESC
       LIMIT $limit OFFSET $offset''',
    [username],
  );
  var out = <MangaHistory>[];
  for (var m in maps) {
    out.add(MangaHistory(
      mangaId: m[_colMangaId]! as int,
      mangaTitle: m[_colMangaTitle]! as String,
      mangaCover: m[_colMangaCover]! as String,
      mangaUrl: m[_colMangaUrl]! as String,
      chapterId: m[_colChapterId]! as int,
      chapterTitle: m[_colChapterTitle]! as String,
      chapterPage: m[_colChapterPage]! as int,
      lastTime: DateTime.parse(m[_colLastTime]! as String),
    ));
  }
  return out;
}

Future<bool> addHistory({required String username, required MangaHistory history}) async {
  var db = await DBManager.instance.getDB();
  var count = firstIntValue(await db.rawQuery(
    '''SELECT COUNT(*)
       FROM $_tblHistory
       WHERE $_colUsername = ? AND $_colMangaId = ?''',
    [username, history.mangaId],
  ));

  var rows = 0;
  if (count == 0) {
    // INSERT
    rows = await db.rawInsert(
      '''INSERT INTO $_tblHistory ($_colUsername, $_colMangaId, $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colChapterId, $_colChapterTitle, $_colChapterPage, $_colLastTime)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [username, history.mangaId, history.mangaTitle, history.mangaCover, history.mangaUrl, history.chapterId, history.chapterTitle, history.chapterPage, history.lastTime.toIso8601String()],
    ).catchError((_) {});
  } else {
    // UPDATE
    rows = await db.rawUpdate(
      '''UPDATE $_tblHistory
         SET $_colMangaTitle = ?, $_colMangaCover = ?, $_colMangaUrl = ?, $_colChapterId = ?, $_colChapterTitle = ?, $_colChapterPage = ?, $_colLastTime = ?
         WHERE $_colUsername = ? AND $_colMangaId = ?''',
      [history.mangaTitle, history.mangaCover, history.mangaUrl, history.chapterId, history.chapterTitle, history.chapterPage, history.lastTime.toIso8601String(), username, history.mangaId],
    ).catchError((_) {});
  }
  return rows >= 1;
}

Future<bool> updateHistory({required String username, required MangaHistory history}) async {
  var db = await DBManager.instance.getDB();
  var rows = await db.rawUpdate(
    '''UPDATE $_tblHistory
         SET $_colMangaTitle = ?, $_colMangaCover = ?, $_colMangaUrl = ?
         WHERE $_colUsername = ? AND $_colMangaId = ?''',
    [history.mangaTitle, history.mangaCover, history.mangaUrl, username, history.mangaId],
  ).catchError((_) {});
  return rows >= 1;
}

Future<bool> deleteHistory({required String username, required int mid}) async {
  var db = await DBManager.instance.getDB();
  var rows = await db.rawDelete(
    '''DELETE FROM $_tblHistory
       WHERE $_colUsername = ? AND $_colMangaId = ?''',
    [username, mid],
  ).catchError((_) {});
  return rows >= 1;
}
