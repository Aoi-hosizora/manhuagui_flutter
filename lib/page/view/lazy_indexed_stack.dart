import 'package:flutter/material.dart';

class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    Key key,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.sizing = StackFit.loose,
    this.index = 0,
    @required this.itemCount,
    @required this.itemBuilder,
  })  : assert(itemCount != null),
        assert(itemBuilder != null),
        super(key: key);

  final AlignmentGeometry alignment;
  final TextDirection textDirection;
  final StackFit sizing;
  final int index;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  _LazyIndexedStackState createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  var _children = <Widget>[];
  var _loaded = <bool>[];

  @override
  void initState() {
    for (var i = 0; i < widget.itemCount; i++) {
      if (i == widget.index) {
        _children.add(widget.itemBuilder(context, i));
        _loaded.add(true);
      } else {
        _children.add(Container());
        _loaded.add(false);
      }
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant LazyIndexedStack oldWidget) {
    for (var i = 0; i < widget.itemCount; i++) {
      if (i != widget.index) {
        continue;
      }
      if (_loaded[i]) {
        continue;
      }
      _children[i] = widget.itemBuilder(context, i);
      _loaded[i] = true;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      alignment: widget.alignment,
      textDirection: widget.textDirection,
      sizing: widget.sizing,
      index: widget.index,
      children: _children,
    );
  }
}
