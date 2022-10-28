import 'package:queue/queue.dart';

class QueueManager {
  QueueManager._();

  static QueueManager? _instance;

  static QueueManager get instance {
    _instance ??= QueueManager._();
    return _instance!;
  }

  Queue? _queue;
  List<QueueTask<dynamic>>? _tasks;

  Queue get queue {
    if (_queue == null) {
      _queue = Queue(parallel: 1);
      _tasks = <QueueTask<dynamic>>[];
    }
    return _queue!;
  }

  List<QueueTask<dynamic>> get tasks {
    var _ = queue;
    return _tasks!;
  }

  Future<T?> addTask<T>(QueueTask<T> task) async {
    tasks.add(task);
    try {
      var result = await queue.add<T?>(() async {
        if (task.canceled) {
          return null; // canceled when not started
        }
        return await task.doTask();
      });
      return result;
    } catch (e, s) {
      if (e is QueueCancelledException) {
        return Future.value(null);
      }
      return Future.error(e, s);
    } finally {
      tasks.remove(task);
      await task.doDefer();
    }
  }
}

abstract class QueueTask<T> {
  var _canceled = false;

  bool get canceled => _canceled;

  void cancel() {
    _canceled = true;
  }

  Future<T?> doTask();

  Future<void> doDefer() {
    return Future.value(null);
  }
}

class FuncQueueTask<T> extends QueueTask {
  FuncQueueTask({
    required this.task,
    this.defer,
  });

  final Future<T?> Function() task;
  final Future<void> Function()? defer;

  @override
  Future<T?> doTask() {
    return task.call();
  }

  @override
  Future<void> doDefer() {
    return defer?.call() ?? Future.value(null);
  }
}
