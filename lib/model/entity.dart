class MangaHistory {
  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final int chapterId; // 0 表示还没开始阅读（点进漫画页），非0 表示开始阅读（点进章节页）
  final String chapterTitle;
  final int chapterPage;
  final DateTime lastTime;

  const MangaHistory({
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.chapterId,
    required this.chapterTitle,
    required this.chapterPage,
    required this.lastTime,
  });

  bool get read => chapterId != 0;

  MangaHistory copyWith({
    int? mangaId,
    String? mangaTitle,
    String? mangaCover,
    String? mangaUrl,
    int? chapterId,
    String? chapterTitle,
    int? chapterPage,
    DateTime? lastTime,
  }) {
    return MangaHistory(
      mangaId: mangaId ?? this.mangaId,
      mangaTitle: mangaTitle ?? this.mangaTitle,
      mangaCover: mangaCover ?? this.mangaCover,
      mangaUrl: mangaUrl ?? this.mangaUrl,
      chapterId: chapterId ?? this.chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      chapterPage: chapterPage ?? this.chapterPage,
      lastTime: lastTime ?? this.lastTime,
    );
  }

  bool equals(MangaHistory o) {
    return mangaId == o.mangaId && //
        mangaTitle == o.mangaTitle &&
        mangaCover == o.mangaCover &&
        mangaUrl == o.mangaUrl &&
        chapterId == o.chapterId &&
        chapterTitle == o.chapterTitle &&
        chapterPage == o.chapterPage &&
        lastTime == o.lastTime;
  }
}

class DownloadedManga {
  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final DateTime updatedAt;
  final List<DownloadedChapter> downloadedChapters;

  const DownloadedManga({
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.updatedAt,
    required this.downloadedChapters,
  });

  List<int> get totalChapterIds => //
      downloadedChapters.map((el) => el.chapterId).toList();

  List<int> get startedChapterIds => //
      downloadedChapters.where((el) => el.startedPageCount > 0).map((el) => el.chapterId).toList();

  List<int> get successChapterIds => //
      downloadedChapters.where((el) => el.successPageCount == el.totalPageCount).map((el) => el.chapterId).toList();

  int get failedPageCountInAll => //
      downloadedChapters.map((el) => el.totalPageCount - el.successPageCount).reduce((val, el) => val + el);
}

class DownloadedChapter {
  final int mangaId;
  final int chapterId;
  final String chapterTitle;
  final String chapterGroup;
  final int totalPageCount;
  final int startedPageCount;
  final int successPageCount;

  bool get success => successPageCount == totalPageCount;

  const DownloadedChapter({
    required this.mangaId,
    required this.chapterId,
    required this.chapterTitle,
    required this.chapterGroup,
    required this.totalPageCount,
    required this.startedPageCount,
    required this.successPageCount,
  });
}
