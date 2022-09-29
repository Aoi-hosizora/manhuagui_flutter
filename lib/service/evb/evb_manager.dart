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

  Stream<T> on<T>() {
    return eventBus.on<T>();
  }

  void fire(dynamic event) {
    eventBus.fire(event);
  }
}
