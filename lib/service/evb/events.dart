// ======================
// To XXX Requested Event
// ======================

class ToShelfRequestedEvent {
  const ToShelfRequestedEvent();
}

class ToFavoriteRequestedEvent {
  const ToFavoriteRequestedEvent();
}

class ToHistoryRequestedEvent {
  const ToHistoryRequestedEvent();
}

class ToRecentRequestedEvent {
  const ToRecentRequestedEvent();
}

class ToRankingRequestedEvent {
  const ToRankingRequestedEvent();
}

// =================
// XXX Updated Event
// =================

enum UpdateReason { added, updated, deleted }

class HistoryUpdatedEvent {
  const HistoryUpdatedEvent({required this.mangaId, required this.reason, this.fromHistoryPage = false, this.fromMangaPage = false});

  final int mangaId;
  final UpdateReason reason;
  final bool fromHistoryPage;
  final bool fromMangaPage;
}

class ShelfUpdatedEvent {
  const ShelfUpdatedEvent({required this.mangaId, required this.added, this.fromShelfPage = false, this.fromMangaPage = false});

  final int mangaId;
  final bool added;
  final bool fromShelfPage;
  final bool fromMangaPage;
}

class FavoriteUpdatedEvent {
  const FavoriteUpdatedEvent({required this.mangaId, required this.group, required this.reason, this.fromFavoritePage = false, this.fromMangaPage = false});

  final int mangaId;
  final String group;
  final UpdateReason reason;
  final bool fromFavoritePage;
  final bool fromMangaPage;
}

class DownloadUpdatedEvent {
  const DownloadUpdatedEvent({required this.mangaId, this.fromDownloadPage = false, this.fromMangaPage = false, this.fromDownloadMangaPage = false});

  final int mangaId;
  final bool fromDownloadPage;
  final bool fromMangaPage;
  final bool fromDownloadMangaPage;
}

class ShelfCacheUpdatedEvent {
  const ShelfCacheUpdatedEvent({required this.mangaId, required this.added, this.fromShelfCachePage = false});

  final int mangaId;
  final bool added;
  final bool fromShelfCachePage;
}

class FavoriteAuthorUpdatedEvent {
  const FavoriteAuthorUpdatedEvent({required this.authorId, required this.reason, this.fromFavoritePage = false, this.fromAuthorPage = false});

  final int authorId;
  final UpdateReason reason;
  final bool fromFavoritePage;
  final bool fromAuthorPage;
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
