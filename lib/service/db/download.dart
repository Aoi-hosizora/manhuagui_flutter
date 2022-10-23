class DownloadDao {
  static const _tblDownload = 'tbl_download';
  static const _colMangaId = 'mid';
  static const _colMangaTitle = 'title';

  static const createTblDownload = '''
    CREATE TABLE $_tblDownload(
      $_colMangaId INTEGER,
      $_colMangaTitle VARCHAR(1023),
      PRIMARY KEY ($_colMangaId)
    )''';
}
