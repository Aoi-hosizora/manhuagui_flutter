import 'package:queue/queue.dart';

class QueueManager {
  QueueManager._();

  static QueueManager? _instance;

  static QueueManager get instance {
    _instance ??= QueueManager._();
    return _instance!;
  }

  Queue? _queue;

  Queue get queue {
    _queue ??= Queue();
    return _queue!;
  }

  Future<T?> enqueue<T>(QueueTask<T> task) {
    return queue.add<T?>(() {
      if (!task.canceled) {
        return task.task();
      }
      return Future.value(null);
    });
  }

  void cancel() {
    queue.cancel();
  }
}

class QueueTask<T> {
  QueueTask({
    required this.task,
  }) : canceled = false;

  final Future<T?> Function() task;
  bool canceled;

  void cancel() {
    canceled = true;
  }
}
