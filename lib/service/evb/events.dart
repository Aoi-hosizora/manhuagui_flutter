class ToShelfRequestedEvent {
  const ToShelfRequestedEvent();
}

class ToHistoryRequestedEvent {
  const ToHistoryRequestedEvent();
}

class ToGenreRequestedEvent {
  const ToGenreRequestedEvent();
}

class ToRecentRequestedEvent {
  const ToRecentRequestedEvent();
}

class ToRankingRequestedEvent {
  const ToRankingRequestedEvent();
}

class HistoryUpdatedEvent {
  const HistoryUpdatedEvent();
}

class SubscribeUpdatedEvent {
  const SubscribeUpdatedEvent({required this.mangaId, required this.subscribe});

  final int mangaId;
  final bool subscribe;
}

class DownloadMangaProgressChangedEvent {
  const DownloadMangaProgressChangedEvent({required this.mangaId, required this.finished});

  final int mangaId;
  final bool finished;
}

class DownloadedMangaEntityChangedEvent {
  const DownloadedMangaEntityChangedEvent({required this.mangaId});

  final int mangaId;
}
