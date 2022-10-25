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

class MangaDownloadProgressChangedEvent {
  const MangaDownloadProgressChangedEvent({required this.progress, required this.result});

  final MangaDownloadProgress? progress;
  final MangaDownloadTaskResult? result;
}
