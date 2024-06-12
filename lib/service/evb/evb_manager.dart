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

  void fire<T extends Object>(T event, [ListenerIdentifier? identifier, bool onceOnce = false]) {
    eventBus.fire(event);
    if (identifier != null) {
      identifier.invoke<T>(event, onceOnce: onceOnce);
    }
  }
}

class ListenerIdentifierBuilder {
  ListenerIdentifierBuilder._();

  static ListenerIdentifierBuilder create() {
    return ListenerIdentifierBuilder._();
  }

  final _identifier = ListenerIdentifier._();

  ListenerIdentifierBuilder withListener<T extends Object>(void Function(T event) onData) {
    _identifier._addListener<T>(onData);
    return this;
  }

  ListenerIdentifier build() {
    _identifier._enable();
    return _identifier;
  }
}

class ListenerIdentifier {
  ListenerIdentifier._();

  final _listeners = <Type, void Function(Object event)>{};
  var _enabled = false;

  void _addListener<T extends Object>(void Function(T event) onData) {
    _listeners[T] = (event) {
      if (event is T) {
        onData.call(event);
      }
    };
  }

  void invoke<T extends Object>(T event, {bool onceOnce = false}) {
    _listeners[T]?.call(event);
    if (onceOnce) {
      _listeners.remove(T);
    }
  }

  void _enable() {
    _enabled = true;
  }

  bool enabled() {
    return _enabled;
  }

  void cancel() {
    _enabled = false;
  }
}
