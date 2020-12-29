import 'package:flutter/foundation.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/service/database/database.dart';
import 'package:sqflite/utils/utils.dart';

final _tblHistory = 'tbl_history';
final _colUsername = 'username';
final _colMangaId = 'id';
final _colMangaTitle = 'manga_title';
final _colMangaCover = 'manga_cover';
final _colMangaUrl = 'manga_url';
final _colChapterId = 'chapter_id';
final _colChapterTitle = 'chapter_title';
final _colChapterPage = 'chapter_page';
final _colLastTime = 'last_time';

final createTblHistory = '''
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

Future<int> getHistoryCount({@required String username}) async {
  username ??= '';

  var db = await DBProvider.instance.getDB();
  var count = firstIntValue(await db.rawQuery(
    '''SELECT COUNT(*) 
       FROM $_tblHistory 
       WHERE $_colUsername = ?''',
    [username],
  ));
  return count;
}

Future<MangaHistory> getHistory({@required String username, @required int mid}) async {
  username ??= '';
  assert(mid != null);

  var db = await DBProvider.instance.getDB();
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
    mangaTitle: m[_colMangaTitle],
    mangaCover: m[_colMangaCover],
    mangaUrl: m[_colMangaUrl],
    chapterId: m[_colChapterId],
    chapterTitle: m[_colChapterTitle],
    chapterPage: m[_colChapterPage],
    lastTime: m[_colLastTime],
  );
}

Future<List<MangaHistory>> getHistories({@required String username, @required int page, int limit = 20}) async {
  username ??= '';
  assert(page == null || page >= 0);
  page ??= 1;

  var db = await DBProvider.instance.getDB();
  var maps = await db.rawQuery(
    '''SELECT $_colMangaId, $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colChapterId, $_colChapterTitle, $_colChapterPage, $_colLastTime 
       FROM $_tblHistory
       WHERE $_colUsername = ?
       ORDER BY $_colLastTime DESC
       LIMIT $limit OFFSET ${limit * (page - 1)}''',
    [username],
  );
  var out = <MangaHistory>[];
  for (var m in maps) {
    out.add(MangaHistory(
      mangaId: m[_colMangaId],
      mangaTitle: m[_colMangaTitle],
      mangaCover: m[_colMangaCover],
      mangaUrl: m[_colMangaUrl],
      chapterId: m[_colChapterId],
      chapterTitle: m[_colChapterTitle],
      chapterPage: m[_colChapterPage],
      lastTime: DateTime.parse(m[_colLastTime]),
    ));
  }
  return out;
}

Future<bool> addHistory({@required String username, @required MangaHistory history}) async {
  username ??= '';
  assert(history != null && history.mangaId != null && history.chapterId != null);
  history.lastTime ??= DateTime.now();

  var db = await DBProvider.instance.getDB();
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
    );
  } else {
    // UPDATE
    rows = await db.rawUpdate(
      '''UPDATE $_tblHistory
         SET $_colMangaTitle = ?, $_colMangaCover = ?, $_colMangaUrl = ?, $_colChapterId = ?, $_colChapterTitle = ?, $_colChapterPage = ?, $_colLastTime = ?
         WHERE $_colUsername = ? AND $_colMangaId = ?''',
      [history.mangaTitle, history.mangaCover, history.mangaUrl, history.chapterId, history.chapterTitle, history.chapterPage, history.lastTime.toIso8601String()],
    );
  }
  return rows >= 1;
}

Future<bool> deleteHistory({@required String username, @required int mid}) async {
  username ??= '';
  assert(mid != null);

  var db = await DBProvider.instance.getDB();
  var rows = await db.rawDelete(
    '''DELETE FROM $_tblHistory
       WHERE $_colUsername = ? AND $_colMangaId = ?''',
    [username, mid],
  );
  return rows >= 1;
}
