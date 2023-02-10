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
  const HistoryUpdatedEvent({required this.mangaId, required this.reason, this.fromHistoryPage = false, this.fromSepHistoryPage = false, this.fromMangaPage = false});

  final int mangaId;
  final UpdateReason reason;
  final bool fromHistoryPage;
  final bool fromSepHistoryPage;
  final bool fromMangaPage;
}

class ShelfUpdatedEvent {
  const ShelfUpdatedEvent({required this.mangaId, required this.added, this.fromShelfPage = false, this.fromSepShelfPage = false, this.fromMangaPage = false});

  final int mangaId;
  final bool added;
  final bool fromShelfPage;
  final bool fromSepShelfPage;
  final bool fromMangaPage;
}

class FavoriteUpdatedEvent {
  const FavoriteUpdatedEvent({required this.mangaId, required this.group, this.oldGroup, required this.reason, this.fromFavoritePage = false, this.fromSepFavoritePage = false, this.fromMangaPage = false});

  final int mangaId;
  final String group;
  final String? oldGroup; // means move to group
  final UpdateReason reason;
  final bool fromFavoritePage;
  final bool fromSepFavoritePage;
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
