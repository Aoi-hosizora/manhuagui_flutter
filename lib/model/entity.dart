import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:intl/intl.dart';
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

  String get formattedLastTime => DateFormat('yyyy-MM-dd HH:mm:ss').format(lastTime);

  String get formattedLastDuration {
    var du = DateTime.now().difference(lastTime);
    if (du.inDays > 0) {
      return '${du.inDays}天前';
    }
    if (du.inHours != 0) {
      return '${du.inHours}小时前';
    }
    if (du.inMinutes != 0) {
      return '${du.inMinutes}分钟前';
    }
    return '不到1分钟前';
  }

  String get formattedLastTimeWithDuration {
    var long = DateFormat('yyyy-MM-dd HH:mm:ss').format(lastTime);
    var short = DateFormat('HH:mm:ss').format(lastTime);

    var du = DateTime.now().difference(lastTime);
    if (du.inDays > 0) {
      return long;
    }
    if (du.inHours != 0) {
      return '${du.inHours}小时前 ($short)';
    }
    if (du.inMinutes != 0) {
      return '${du.inMinutes}分钟前 ($short)';
    }
    return '不到1分钟前 ($short)';
  }

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

class ShelfCache {
  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final DateTime cachedAt;

  const ShelfCache({
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.cachedAt,
  });

  String get formattedCachedAt => DateFormat('yyyy-MM-dd HH:mm').format(cachedAt);

  ShelfCache copyWith({
    int? mangaId,
    String? mangaTitle,
    String? mangaCover,
    String? mangaUrl,
    DateTime? cachedAt,
  }) {
    return ShelfCache(
      mangaId: mangaId ?? this.mangaId,
      mangaTitle: mangaTitle ?? this.mangaTitle,
      mangaCover: mangaCover ?? this.mangaCover,
      mangaUrl: mangaUrl ?? this.mangaUrl,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  bool equals(ShelfCache o) {
    return mangaId == o.mangaId && //
        mangaTitle == o.mangaTitle &&
        mangaCover == o.mangaCover &&
        mangaUrl == o.mangaUrl &&
        cachedAt == o.cachedAt;
  }
}

class FavoriteManga {
  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final String remark;
  final String groupName;
  final int order;
  final DateTime createdAt;

  const FavoriteManga({
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.remark,
    required this.groupName,
    required this.order,
    required this.createdAt,
  });

  String get formattedCreatedAt => DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt);

  String get checkedGroupName => groupName.trim().isEmpty ? '默认分组' : groupName.trim();

  FavoriteManga copyWith({
    int? mangaId,
    String? mangaTitle,
    String? mangaCover,
    String? mangaUrl,
    String? remark,
    String? groupName,
    int? order,
    DateTime? createdAt,
  }) {
    return FavoriteManga(
      mangaId: mangaId ?? this.mangaId,
      mangaTitle: mangaTitle ?? this.mangaTitle,
      mangaCover: mangaCover ?? this.mangaCover,
      mangaUrl: mangaUrl ?? this.mangaUrl,
      remark: remark ?? this.remark,
      groupName: groupName ?? this.groupName,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool equals(FavoriteManga o) {
    return mangaId == o.mangaId && //
        mangaTitle == o.mangaTitle &&
        mangaCover == o.mangaCover &&
        mangaUrl == o.mangaUrl &&
        remark == o.remark &&
        groupName == o.groupName &&
        order == o.order &&
        createdAt == o.createdAt;
  }
}

class FavoriteGroup {
  final String groupName;
  final int order;
  final DateTime createdAt;

  const FavoriteGroup({
    required this.groupName,
    required this.order,
    required this.createdAt,
  });

  String get checkedGroupName => groupName.trim().isEmpty ? '默认分组' : groupName.trim();

  static bool isDefaultName(String s) => s.trim() == '默认' || s.trim() == '默认分组';

  String get formattedCreatedAt => DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt);

  FavoriteGroup copyWith({
    String? groupName,
    int? order,
    DateTime? createdAt,
  }) {
    return FavoriteGroup(
      groupName: groupName ?? this.groupName,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool equals(FavoriteGroup o) {
    return groupName == o.groupName && //
        order == o.order &&
        createdAt == o.createdAt;
  }
}

class FavoriteAuthor {
  final int authorId;
  final String authorName;
  final String authorCover;
  final String authorUrl;
  final String remark;
  final DateTime createdAt;

  const FavoriteAuthor({
    required this.authorId,
    required this.authorName,
    required this.authorCover,
    required this.authorUrl,
    required this.remark,
    required this.createdAt,
  });

  String get formattedCreatedAt => DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt);

  FavoriteAuthor copyWith({
    int? authorId,
    String? authorName,
    String? authorCover,
    String? authorUrl,
    String? remark,
    DateTime? createdAt,
  }) {
    return FavoriteAuthor(
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorCover: authorCover ?? this.authorCover,
      authorUrl: authorUrl ?? this.authorUrl,
      remark: remark ?? this.remark,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool equals(FavoriteAuthor o) {
    return authorId == o.authorId && //
        authorName == o.authorName &&
        authorCover == o.authorCover &&
        authorUrl == o.authorUrl &&
        remark == o.remark &&
        createdAt == o.createdAt;
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
  final bool needUpdate;

  const DownloadedManga({
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.error,
    required this.updatedAt,
    required this.downloadedChapters,
    required this.needUpdate,
  });

  bool get allChaptersSucceeded => totalChapterIds.length == successChapterIds.length;

  DownloadedChapter? findChapter(int cid) => //
      downloadedChapters.where((chapter) => chapter.chapterId == cid).firstOrNull;

  // chapter related

  List<int> get totalChapterIds => //
      downloadedChapters.map((el) => el.chapterId).toList();

  List<int> get triedChapterIds => //
      downloadedChapters.where((el) => el.tried).map((el) => el.chapterId).toList();

  List<int> get successChapterIds => //
      downloadedChapters.where((el) => el.succeeded).map((el) => el.chapterId).toList();

  int get failedChapterCount => //
      downloadedChapters.where((el) => !el.succeeded).length;

  // page related

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
    bool? needUpdate,
  }) {
    return DownloadedManga(
      mangaId: mangaId ?? this.mangaId,
      mangaTitle: mangaTitle ?? this.mangaTitle,
      mangaCover: mangaCover ?? this.mangaCover,
      mangaUrl: mangaUrl ?? this.mangaUrl,
      error: error ?? this.error,
      updatedAt: updatedAt ?? this.updatedAt,
      downloadedChapters: downloadedChapters ?? this.downloadedChapters,
      needUpdate: needUpdate ?? this.needUpdate,
    );
  }

  bool equals(DownloadedManga o) {
    return mangaId == o.mangaId && //
        mangaTitle == o.mangaTitle &&
        mangaCover == o.mangaCover &&
        mangaUrl == o.mangaUrl &&
        error == o.error &&
        updatedAt == o.updatedAt &&
        downloadedChapters == o.downloadedChapters &&
        needUpdate == o.needUpdate;
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
  final bool needUpdate;

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
    required this.needUpdate,
  });

  DownloadedChapter copyWith({
    int? mangaId,
    int? chapterId,
    String? chapterTitle,
    String? chapterGroup,
    int? totalPageCount,
    int? triedPageCount,
    int? successPageCount,
    bool? needUpdate,
  }) {
    return DownloadedChapter(
      mangaId: mangaId ?? this.mangaId,
      chapterId: chapterId ?? this.chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      chapterGroup: chapterGroup ?? this.chapterGroup,
      totalPageCount: totalPageCount ?? this.totalPageCount,
      triedPageCount: triedPageCount ?? this.triedPageCount,
      successPageCount: successPageCount ?? this.successPageCount,
      needUpdate: needUpdate ?? this.needUpdate,
    );
  }

  bool equals(DownloadedChapter o) {
    return mangaId == o.mangaId && //
        chapterId == o.chapterId &&
        chapterTitle == o.chapterTitle &&
        chapterGroup == o.chapterGroup &&
        totalPageCount == o.totalPageCount &&
        triedPageCount == o.triedPageCount &&
        successPageCount == o.successPageCount &&
        needUpdate == o.needUpdate;
  }

  TinyMangaChapter toTiny() {
    return TinyMangaChapter(
      cid: chapterId,
      title: chapterTitle,
      mid: mangaId,
      url: 'https://www.manhuagui.com/comic/$mangaId/$chapterId.html',
      pageCount: totalPageCount,
      isNew: false,
    );
  }
}
