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

  ListenerBuilder listenOnce() {
    return ListenerBuilder._();
  }

  void fire(dynamic event) {
    eventBus.fire(event);
  }
}

class ListenerBuilder {
  ListenerBuilder._();

  final _identifier = ListenerIdentifier();

  ListenerBuilder withListener<T>(void Function(T event) onData) {
    _identifier._listeners[T] = (event) {
      if (event is T) {
        onData.call(event as T);
      }
    };
    return this;
  }

  ListenerIdentifier build() {
    _identifier._enabled = true;
    return _identifier;
  }
}

class ListenerIdentifier {
  ListenerIdentifier();

  final _listeners = <Type, void Function(Object event)>{};
  var _enabled = false;

  void call<T extends Object>(T event) {
    _listeners[T]?.call(event);
  }

  bool enabled() {
    return _enabled;
  }

  void cancel() {
    _enabled = false;
  }
}
