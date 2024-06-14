import 'package:event_bus/event_bus.dart';

class EventBusManager {
  EventBusManager._();

  static EventBusManager? _instance;

  static EventBusManager get instance {
    _instance ??= EventBusManager._();
    return _instance!;
  }

  EventBus? _eventBus; // global EventBus instance

  EventBus get eventBus {
    _eventBus ??= EventBus();
    return _eventBus!;
  }

  void Function() listen<T extends Object>(void Function(T event) onData) {
    var stream = eventBus.on<T>().listen(onData);
    return () => stream.cancel();
  }

  void fire<T extends Object>(T event) {
    eventBus.fire(event);
  }
}
