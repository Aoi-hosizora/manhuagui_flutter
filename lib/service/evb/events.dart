import 'package:manhuagui_flutter/service/storage/download_manga.dart';

class ToShelfRequestedEvent {
  const ToShelfRequestedEvent();
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
  const SubscribeUpdatedEvent({required this.mid, required this.subscribe});

  final int mid;
  final bool subscribe;
}

class DownloadMangaProgressChangedEvent {
  const DownloadMangaProgressChangedEvent({required this.task, required this.finished});

  final DownloadMangaQueueTask task;
  final bool finished;
}

class DownloadedMangaEntityChangedEvent {
  const DownloadedMangaEntityChangedEvent({required this.mid});

  final int mid;
}
