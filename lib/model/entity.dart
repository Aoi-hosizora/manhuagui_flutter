import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/common.dart';

class MangaHistory {
  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final int chapterId; // 0表示还没开始阅读（点进漫画页），非0表示开始阅读（点进章节页）
  final String chapterTitle;
  final int chapterPage;
  final int lastChapterId; // 本字段表示上次的漫画阅读历史，该字段的值也可以为零
  final String lastChapterTitle;
  final int lastChapterPage;
  final DateTime lastTime;

  const MangaHistory({
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.chapterId,
    required this.chapterTitle,
    required this.chapterPage,
    required this.lastChapterId,
    required this.lastChapterTitle,
    required this.lastChapterPage,
    required this.lastTime,
  });

  bool get read => chapterId != 0;

  String get shortChapterTitle => chapterTitle.trim().split(' ')[0];

  String get formattedLastTime => // for manga page
      formatDatetimeAndDuration(lastTime, FormatPattern.datetime);

  String get formattedLastTimeWithDuration => // for history line
      formatDatetimeAndDuration(lastTime, FormatPattern.durationDatetimeOrDateTime);

  String get formattedLastTimeAndFullDuration => // for manga page
      formatDatetimeAndDuration(lastTime, FormatPattern.datetimeDuration);

  String get formattedLastTimeOrDuration => // for favorite line and shelf line
      formatDatetimeAndDuration(lastTime, FormatPattern.durationOrDate);

  MangaHistory copyWith({
    int? mangaId,
    String? mangaTitle,
    String? mangaCover,
    String? mangaUrl,
    int? chapterId,
    String? chapterTitle,
    int? chapterPage,
    int? lastChapterId,
    String? lastChapterTitle,
    int? lastChapterPage,
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
      lastChapterId: lastChapterId ?? this.lastChapterId,
      lastChapterTitle: lastChapterTitle ?? this.lastChapterTitle,
      lastChapterPage: lastChapterPage ?? this.lastChapterPage,
      lastTime: lastTime ?? this.lastTime,
    );
  }

  MangaHistory copyWithNoCurrChapterOnly({DateTime? lastTime}) {
    return copyWith(
      chapterId: lastChapterId /* last延续上来 */,
      chapterTitle: lastChapterTitle,
      chapterPage: lastChapterPage,
      lastChapterId: 0 /* 未开始阅读 */,
      lastChapterTitle: '',
      lastChapterPage: 1,
      lastTime: lastTime,
    );
  }

  MangaHistory copyWithNoLastChapterOnly({DateTime? lastTime}) {
    return copyWith(
      lastChapterId: 0 /* 未开始阅读 */,
      lastChapterTitle: '',
      lastChapterPage: 1,
      lastTime: lastTime,
    );
  }

  MangaHistory copyWithNoCurrChapterAndLastChapter({DateTime? lastTime}) {
    return copyWith(
      chapterId: 0 /* 未开始阅读 */,
      chapterTitle: '',
      chapterPage: 1,
      lastChapterId: 0 /* 未开始阅读 */,
      lastChapterTitle: '',
      lastChapterPage: 1,
      lastTime: lastTime,
    );
  }

  bool equals(MangaHistory o, {bool includeCover = true}) {
    return mangaId == o.mangaId && //
        mangaTitle == o.mangaTitle &&
        (!includeCover || mangaCover == o.mangaCover) &&
        mangaUrl.checkEqualityConsideringLastSlash(o.mangaUrl) &&
        chapterId == o.chapterId &&
        chapterTitle == o.chapterTitle &&
        chapterPage == o.chapterPage &&
        lastTime == o.lastTime;
  }
}

class ChapterFootprint {
  final int mangaId;
  final int chapterId; // 仅记录 cid，其他字段由 manga 的 chapter group 获取
  final DateTime createdAt;

  const ChapterFootprint({
    required this.mangaId,
    required this.chapterId,
    required this.createdAt,
  });

  String get formattedCreatedAt => //
      formatDatetimeAndDuration(createdAt, FormatPattern.durationOrDate);

  ChapterFootprint? copyWith({
    int? mangaId,
    int? chapterId,
    DateTime? createdAt,
  }) {
    return ChapterFootprint(
      mangaId: mangaId ?? this.mangaId,
      chapterId: chapterId ?? this.chapterId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool equals(ChapterFootprint o) {
    return mangaId == o.mangaId && //
        chapterId == o.chapterId &&
        createdAt == o.createdAt;
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

  String get formattedCachedAt => //
      formatDatetimeAndDuration(cachedAt, FormatPattern.datetimeNoSec);

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

  bool equals(ShelfCache o, {bool includeCover = true}) {
    return mangaId == o.mangaId && //
        mangaTitle == o.mangaTitle &&
        (!includeCover || mangaCover == o.mangaCover) &&
        mangaUrl.checkEqualityConsideringLastSlash(o.mangaUrl) &&
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

  String get checkedGroupName => groupName.trim().isEmpty ? '默认分组' : groupName.trim();

  String get formattedCreatedAt => //
      formatDatetimeAndDuration(createdAt, FormatPattern.datetime);

  String get formattedCreatedAtWithDuration => //
      formatDatetimeAndDuration(createdAt, FormatPattern.durationDatetimeOrDateTime);

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

  bool equals(FavoriteManga o, {bool includeCover = true}) {
    return mangaId == o.mangaId && //
        mangaTitle == o.mangaTitle &&
        (!includeCover || mangaCover == o.mangaCover) &&
        mangaUrl.checkEqualityConsideringLastSlash(o.mangaUrl) &&
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

  static bool isValidName(String s) => s.trim().isNotEmpty && s.trim() != '默认' && s.trim() != '默认分组';

  String get formattedCreatedAt => //
      formatDatetimeAndDuration(createdAt, FormatPattern.datetime);

  String get formattedCreatedAtWithDuration => //
      formatDatetimeAndDuration(createdAt, FormatPattern.durationDatetimeOrDateTime);

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
  final String authorZone;
  final String remark;
  final DateTime createdAt;

  const FavoriteAuthor({
    required this.authorId,
    required this.authorName,
    required this.authorCover,
    required this.authorUrl,
    required this.authorZone,
    required this.remark,
    required this.createdAt,
  });

  String get formattedCreatedAt => //
      formatDatetimeAndDuration(createdAt, FormatPattern.datetime);

  String get formattedCreatedAtWithDuration => //
      formatDatetimeAndDuration(createdAt, FormatPattern.durationDatetimeOrDateTime);

  FavoriteAuthor copyWith({
    int? authorId,
    String? authorName,
    String? authorCover,
    String? authorUrl,
    String? authorZone,
    String? remark,
    DateTime? createdAt,
  }) {
    return FavoriteAuthor(
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorCover: authorCover ?? this.authorCover,
      authorUrl: authorUrl ?? this.authorUrl,
      authorZone: authorZone ?? this.authorZone,
      remark: remark ?? this.remark,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool equals(FavoriteAuthor o, {bool includeCover = true}) {
    return authorId == o.authorId && //
        authorName == o.authorName &&
        (!includeCover || authorCover == o.authorCover) &&
        authorUrl == o.authorUrl &&
        authorZone == o.authorZone &&
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
  final List<DownloadedChapter> downloadedChapters; // default in cid ascending order
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

  String get formattedUpdatedAt => //
      formatDatetimeAndDuration(updatedAt, FormatPattern.datetime);

  String get formattedUpdatedAtWithDuration => //
      formatDatetimeAndDuration(updatedAt, FormatPattern.durationDatetimeOrDateTime);

  // chapter related

  DownloadedChapter? findChapter(int cid) => //
      downloadedChapters.where((chapter) => chapter.chapterId == cid).firstOrNull;

  List<int> get totalChapterIds => //
      downloadedChapters.map((el) => el.chapterId).toList();

  List<int> get triedChapterIds => //
      downloadedChapters.where((el) => el.tried).map((el) => el.chapterId).toList();

  List<int> get successChapterIds => //
      downloadedChapters.where((el) => el.succeeded && !el.needUpdate).map((el) => el.chapterId).toList();

  List<int> get notFinishedChapterIds => //
      downloadedChapters.where((el) => !el.succeeded || el.needUpdate).map((el) => el.chapterId).toList();

  int get totalChaptersCount => totalChapterIds.length;

  int get triedChaptersCount => triedChapterIds.length;

  int get successChaptersCount => successChapterIds.length;

  int get notFinishedChaptersCount => notFinishedChapterIds.length;

  // success checking related

  bool get allChaptersSucceeded => //
      totalChaptersCount == successChaptersCount;

  bool get allChaptersEitherSucceededOrNeedUpdate => //
      totalChaptersCount == downloadedChapters.where((el) => el.succeeded).map((el) => el.chapterId).toList().length;

  // page related

  int _sumCount(Iterable<int> it) => //
      it.isEmpty ? 0 : it.reduce((val, el) => val + el);

  int get totalPageCountInAll => //
      downloadedChapters.map((el) => el.totalPageCount).let(_sumCount);

  int get triedPageCountInAll => //
      downloadedChapters.map((el) => el.triedPageCount).let(_sumCount);

  int get successPageCountInAll => //
      downloadedChapters.map((el) => el.successPageCount).let(_sumCount);

  int get notFinishedPageCountInAll => //
      downloadedChapters.map((el) => el.totalPageCount - el.successPageCount).let(_sumCount);

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

  bool equals(DownloadedManga o, {bool includeCover = true}) {
    return mangaId == o.mangaId && //
        mangaTitle == o.mangaTitle &&
        (!includeCover || mangaCover == o.mangaCover) &&
        mangaUrl.checkEqualityConsideringLastSlash(o.mangaUrl) &&
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

  String get chapterUrl => 'https://www.manhuagui.com/comic/$mangaId/$chapterId.html';

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

  TinyMangaChapter toTiny({bool? isNew, int? number}) {
    return TinyMangaChapter(
      cid: chapterId,
      title: chapterTitle,
      mid: mangaId,
      url: chapterUrl,
      pageCount: totalPageCount,
      isNew: isNew ?? false,
      group: chapterGroup,
      number: number ?? chapterId, // <<< use chapterId as number
    );
  }
}

extension DownloadedChapterListExtension on List<DownloadedChapter> {
  List<MangaChapterGroup> toChapterGroup({List<MangaChapterGroup>? origin}) {
    // build origin chapter map
    origin ??= <MangaChapterGroup>[];
    var originChapterMap = <int, TinyMangaChapter>{
      for (var c in origin.allChapters) c.cid: c,
    };

    // extract chapter groups to list
    var groupMap = <String, List<TinyMangaChapter>>{
      for (var g in origin) g.title: [],
    };
    for (var chapter in this) {
      if (!groupMap.containsKey(chapter.chapterGroup)) {
        groupMap[chapter.chapterGroup] = [];
      }
      groupMap[chapter.chapterGroup]?.add(
        chapter.toTiny(
          isNew: originChapterMap[chapter.chapterId]?.isNew,
          number: originChapterMap[chapter.chapterId]?.number,
        ),
      );
    }

    // find all group names in order
    var groupNames = <String>[];
    for (var originGroup in origin) {
      groupNames.add(originGroup.title);
    }
    for (var title in groupMap.keys) {
      if (!groupNames.contains(title)) {
        groupNames.add(title);
      }
    }

    // combine chapter groups to map
    var groups = <MangaChapterGroup>[];
    for (var groupName in groupNames) {
      var group = groupMap[groupName] ?? [];
      if (group.isNotEmpty) {
        groups.add(MangaChapterGroup(title: groupName, chapters: group));
      }
    }
    groups = groups.makeSureRegularGroupIsFirst();
    return groups;
  }
}

class DownloadChapterMetadata {
  const DownloadChapterMetadata({required this.pages, required this.nextCid, required this.prevCid, required this.updatedAt});

  // version: 1
  final List<String> pages;
  final int? nextCid;
  final int? prevCid;
  final DateTime? updatedAt;

  DownloadChapterMetadata copyWith({
    List<String>? pages,
    int? nextCid,
    int? prevCid,
    DateTime? updatedAt,
  }) {
    return DownloadChapterMetadata(
      pages: pages ?? this.pages,
      nextCid: nextCid ?? this.nextCid,
      prevCid: prevCid ?? this.prevCid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool equals(DownloadChapterMetadata o) {
    return o.nextCid == nextCid && //
        o.prevCid == prevCid &&
        // o.updatedAt == updatedAt &&
        o.pages.length == pages.length &&
        o.pages.join(',,,') == pages.join(',,,');
  }
}

class LaterManga {
  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final String? newestChapter; // TODO add isUpdated field and update silently, and add later chapter table
  final String? newestDate;
  final DateTime createdAt;

  const LaterManga({
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.newestChapter,
    required this.newestDate,
    required this.createdAt,
  });

  String get formattedNewestDateOrDuration => //
      parseDurationOrDateString(newestDate ?? '').let((r) => r.duration ?? r.date);

  String get formattedCreatedAt => //
      formatDatetimeAndDuration(createdAt, FormatPattern.datetimeNoSec);

  String get formattedCreatedAtWithDuration => //
      formatDatetimeAndDuration(createdAt, FormatPattern.durationDatetimeOrDateTime);

  String get formattedCreatedAtAndFullDuration => //
      formatDatetimeAndDuration(createdAt, FormatPattern.datetimeDuration);

  LaterManga copyWith({
    int? mangaId,
    String? mangaTitle,
    String? mangaCover,
    String? mangaUrl,
    String? newestChapter,
    String? newestDate,
    DateTime? createdAt,
  }) {
    return LaterManga(
      mangaId: mangaId ?? this.mangaId,
      mangaTitle: mangaTitle ?? this.mangaTitle,
      mangaCover: mangaCover ?? this.mangaCover,
      mangaUrl: mangaUrl ?? this.mangaUrl,
      newestChapter: newestChapter ?? this.newestChapter,
      newestDate: newestDate ?? this.newestDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool equals(LaterManga o, {bool includeCover = true}) {
    return mangaId == o.mangaId && //
        mangaTitle == o.mangaTitle &&
        (!includeCover || mangaCover == o.mangaCover) &&
        mangaUrl.checkEqualityConsideringLastSlash(o.mangaUrl) &&
        createdAt == o.createdAt &&
        newestChapter == o.newestChapter &&
        newestDate == o.newestDate;
  }
}
