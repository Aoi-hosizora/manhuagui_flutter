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

class HistoryUpdatedEvent {
  const HistoryUpdatedEvent({required this.mangaId});

  final int mangaId;
}

class SubscribeUpdatedEvent {
  const SubscribeUpdatedEvent({required this.mangaId, this.inShelf, this.inFavorite, this.changedGroup});

  final int mangaId;
  final bool? inShelf;
  final bool? inFavorite;
  final String? changedGroup;
}

class DownloadMangaProgressChangedEvent {
  const DownloadMangaProgressChangedEvent({required this.mangaId, required this.finished});

  final int mangaId;
  final bool finished;
}

class DownloadedMangaEntityChangedEvent {
  const DownloadedMangaEntityChangedEvent({required this.mangaId, this.byDeleting = false});

  final int mangaId;
  final bool byDeleting;
}

class AppSettingChangedEvent {
  const AppSettingChangedEvent();
}
