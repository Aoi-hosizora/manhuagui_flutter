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
