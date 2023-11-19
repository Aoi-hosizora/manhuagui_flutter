// ======================
// To XXX Requested Event
// ======================

class ToRecommendRequestedEvent {
  const ToRecommendRequestedEvent();
}

class ToShelfRequestedEvent {
  const ToShelfRequestedEvent();
}

class ToFavoriteRequestedEvent {
  const ToFavoriteRequestedEvent();
}

class ToLaterRequestedEvent {
  const ToLaterRequestedEvent();
}

class ToHistoryRequestedEvent {
  const ToHistoryRequestedEvent();
}

class ToRecentRequestedEvent {
  const ToRecentRequestedEvent();
}

class ToCategoryRequestedEvent {
  const ToCategoryRequestedEvent();
}

class ToRankingRequestedEvent {
  const ToRankingRequestedEvent();
}

// =============
// related enums
// =============

enum UpdateReason { added, updated, deleted }

// TODO improve checking event source and event fields

enum EventSource {
  general,
  shelfPage,
  sepShelfPage,
  favoritePage,
  sepFavoritePage,
  laterPage,
  sepLaterPage,
  historyPage,
  sepHistoryPage,
  mangaPage,
  mangaTocPage,
  mangaViewerPage,
  mangaHistoryPage,
  authorPage,
  authorFavoritePage,
  downloadPage,
  downloadMangaPage,
  shelfCachePage,
}

extension EventSourceExtension on EventSource {
  bool isGeneral() => this == EventSource.general;

  bool isShelfPage() => this == EventSource.shelfPage;

  bool isSepShelfPage() => this == EventSource.sepShelfPage;

  bool isFavoritePage() => this == EventSource.favoritePage;

  bool isSepFavoritePage() => this == EventSource.sepFavoritePage;

  bool isLaterPage() => this == EventSource.laterPage;

  bool isSepLaterPage() => this == EventSource.sepLaterPage;

  bool isHistoryPage() => this == EventSource.historyPage;

  bool isSepHistoryPage() => this == EventSource.sepHistoryPage;

  bool isMangaPage() => this == EventSource.mangaPage;

  bool isMangaTocPage() => this == EventSource.mangaTocPage;

  bool isMangaViewerPage() => this == EventSource.mangaViewerPage;

  bool isMangaHistoryPage() => this == EventSource.mangaHistoryPage;

  bool isAuthorPage() => this == EventSource.authorPage;

  bool isAuthorFavoritePage() => this == EventSource.authorFavoritePage;

  bool isDownloadPage() => this == EventSource.downloadPage;

  bool isDownloadMangaPage() => this == EventSource.downloadMangaPage;

  bool isShelfCachePage() => this == EventSource.shelfCachePage;
}

// =================
// XXX Updated Event
// =================

class HistoryUpdatedEvent {
  const HistoryUpdatedEvent({required this.mangaId, required this.reason, this.source = EventSource.general});

  final int mangaId;
  final UpdateReason reason;
  final EventSource source; // HistoryPage | SepHistoryPage | MangaPage | MangaViewerPage | MangaHistoryPage
}

class ShelfUpdatedEvent {
  const ShelfUpdatedEvent({required this.mangaId, required this.added, this.source = EventSource.general});

  final int mangaId;
  final bool added;
  final EventSource source; // ShelfPage | SepShelfPage | MangaPage
}

class FavoriteUpdatedEvent {
  const FavoriteUpdatedEvent({required this.mangaId, required this.group, this.oldGroup, required this.reason, this.source = EventSource.general});

  final int mangaId;
  final String group;
  final String? oldGroup; // means move to group
  final UpdateReason reason;
  final EventSource source; // FavoritePage | SepFavoritePage | MangaPage
}

class DownloadUpdatedEvent {
  const DownloadUpdatedEvent({required this.mangaId, this.source = EventSource.general});

  final int mangaId;
  final EventSource source; // DownloadPage | MangaPage | MangaViewerPage | DownloadMangaPage
}

class ShelfCacheUpdatedEvent {
  const ShelfCacheUpdatedEvent({required this.mangaId, required this.added, this.source = EventSource.general});

  final int mangaId;
  final bool added;
  final EventSource source; // ShelfCachePage
}

class FavoriteOrderUpdatedEvent {
  const FavoriteOrderUpdatedEvent({required this.groupName});

  final String groupName;
}

class FavoriteGroupUpdatedEvent {
  const FavoriteGroupUpdatedEvent({required this.changedGroups, required this.newGroups});

  final Map<String, String?> changedGroups;
  final List<String> newGroups;
}

class FavoriteAuthorUpdatedEvent {
  const FavoriteAuthorUpdatedEvent({required this.authorId, required this.reason, this.source = EventSource.general});

  final int authorId;
  final UpdateReason reason;
  final EventSource source; // FavoriteAuthorPage | AuthorPage
}

class LaterUpdatedEvent {
  const LaterUpdatedEvent({required this.mangaId, required this.added, this.source = EventSource.general});

  final int mangaId;
  final bool added;
  final EventSource source; // LaterPage | SepLaterPage | MangaPage
}

class FootprintUpdatedEvent {
  const FootprintUpdatedEvent({required this.mangaId, required this.chapterIds, required this.reason, this.source = EventSource.general});

  final int mangaId;
  final List<int>? chapterIds;
  final UpdateReason reason;
  final EventSource source; // MangaPage | MangaTocPage | MangaHistoryPage
}

class LaterChapterUpdatedEvent {
  const LaterChapterUpdatedEvent({required this.mangaId, required this.chapterId, required this.added, this.source = EventSource.general});

  final int mangaId;
  final int chapterId;
  final bool added;
  final EventSource source; // MangaPage | MangaTocPage | MangaHistoryPage
}

class MarkedCategoryUpdatedEvent {
  const MarkedCategoryUpdatedEvent({required this.categoryName, required this.added});

  final String categoryName;
  final bool added;
}

// ============
// Other Events
// ============

class DownloadProgressChangedEvent {
  const DownloadProgressChangedEvent({required this.mangaId, required this.finished});

  final int mangaId;
  final bool finished;
}

class AppSettingChangedEvent {
  const AppSettingChangedEvent();
}
