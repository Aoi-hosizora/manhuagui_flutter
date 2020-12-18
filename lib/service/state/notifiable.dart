import 'package:flutter/cupertino.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

mixin NotifiableMixin {
  String get key;
}

abstract class NotifiableData {
  String get dataKey;

  var _listeners = <Tuple3<NotifiableMixin, String, Function()>>[];

  void notifyAll() {
    _listeners.forEach((tuple) => tuple.item3?.call());
  }

  void registerListener(NotifiableMixin widget, Function() handler) {
    register(widget, dataKey, handler);
  }

  void unregisterListener(NotifiableMixin widget) {
    unregister(widget, dataKey);
  }

  @protected
  void register(NotifiableMixin widget, String dataKey, Function() handler) {
    assert(
      !_listeners.any((tuple) => tuple.item1.key == widget.key && tuple.item2 == dataKey),
      'Duplicate key: (${widget.key}, $dataKey)',
    );
    _listeners.add(Tuple3(widget, dataKey, handler));
  }

  @protected
  void unregister(NotifiableMixin widget, String dataKey) {
    _listeners.removeWhere((tuple) => tuple.item1.key == widget.key && tuple.item2 == dataKey);
  }
}
