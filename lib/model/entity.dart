import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';

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
  final bool error;
  final DateTime updatedAt;
  final List<DownloadedChapter> downloadedChapters;

  const DownloadedManga({
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.error,
    required this.updatedAt,
    required this.downloadedChapters,
  });

  List<int> get totalChapterIds => //
      downloadedChapters.map((el) => el.chapterId).toList();

  List<int> get triedChapterIds => //
      downloadedChapters.where((el) => el.tried).map((el) => el.chapterId).toList();

  List<int> get successChapterIds => //
      downloadedChapters.where((el) => el.succeeded).map((el) => el.chapterId).toList();

  int get failedChapterCount => //
      downloadedChapters.where((el) => !el.succeeded).length;

  int get totalPageCountInAll => //
      downloadedChapters.map((el) => el.totalPageCount).let((it) => it.isEmpty ? 0 : it.reduce((val, el) => val + el));

  int get triedPageCountInAll => //
      downloadedChapters.map((el) => el.triedPageCount).let((it) => it.isEmpty ? 0 : it.reduce((val, el) => val + el));

  int get successPageCountInAll => //
      downloadedChapters.map((el) => el.successPageCount).let((it) => it.isEmpty ? 0 : it.reduce((val, el) => val + el));

  int get failedPageCountInAll => //
      downloadedChapters.map((el) => el.totalPageCount - el.successPageCount).let((it) => it.isEmpty ? 0 : it.reduce((val, el) => val + el));

  DownloadedManga copyWith({
    int? mangaId,
    String? mangaTitle,
    String? mangaCover,
    String? mangaUrl,
    bool? error,
    DateTime? updatedAt,
    List<DownloadedChapter>? downloadedChapters,
  }) {
    return DownloadedManga(
      mangaId: mangaId ?? this.mangaId,
      mangaTitle: mangaTitle ?? this.mangaTitle,
      mangaCover: mangaCover ?? this.mangaCover,
      mangaUrl: mangaUrl ?? this.mangaUrl,
      error: error ?? this.error,
      updatedAt: updatedAt ?? this.updatedAt,
      downloadedChapters: downloadedChapters ?? this.downloadedChapters,
    );
  }
}

class DownloadedChapter {
  final int mangaId;
  final int chapterId;
  final String chapterTitle;
  final String chapterGroup;
  final int totalPageCount;
  final int triedPageCount;
  final int successPageCount;

  bool get tried => triedPageCount > 0;

  bool get succeeded => successPageCount == totalPageCount;

  bool get allTried => triedPageCount == totalPageCount;

  const DownloadedChapter({
    required this.mangaId,
    required this.chapterId,
    required this.chapterTitle,
    required this.chapterGroup,
    required this.totalPageCount,
    required this.triedPageCount,
    required this.successPageCount,
  });

  DownloadedChapter copyWith({
    int? mangaId,
    int? chapterId,
    String? chapterTitle,
    String? chapterGroup,
    int? totalPageCount,
    int? triedPageCount,
    int? successPageCount,
  }) {
    return DownloadedChapter(
      mangaId: mangaId ?? this.mangaId,
      chapterId: chapterId ?? this.chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      chapterGroup: chapterGroup ?? this.chapterGroup,
      totalPageCount: totalPageCount ?? this.totalPageCount,
      triedPageCount: triedPageCount ?? this.triedPageCount,
      successPageCount: successPageCount ?? this.successPageCount,
    );
  }

  TinyMangaChapter toTiny() {
    return TinyMangaChapter(
      cid: chapterId,
      title: chapterTitle,
      mid: mangaId,
      url: '',
      pageCount: totalPageCount,
      isNew: false,
    );
  }
}
