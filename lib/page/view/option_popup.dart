import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

/// 可弹出扩展选项的 Widget
class OptionPopupView<T> extends StatefulWidget {
  const OptionPopupView({
    Key? key,
    required this.title,
    this.top = 4.0,
    this.height = 26.0,
    this.width = 88.0,
    required this.items,
    required this.value,
    required this.optionBuilder,
    required this.onSelect,
    this.highlightable = false,
    this.enable = true,
  }) : super(key: key);

  final String title;
  final double top; // TODO
  final double height;
  final double width;
  final List<T> items;
  final T value;
  final String Function(BuildContext, T) optionBuilder;
  final void Function(T) onSelect;
  final bool highlightable;
  final bool enable;

  @override
  _OptionPopupRouteViewState<T> createState() => _OptionPopupRouteViewState<T>();
}

class _OptionPopupRouteViewState<T> extends State<OptionPopupView<T>> {
  var _selected = false;

  void _onTap() async {
    final itemBox = context.findRenderObject()! as RenderBox;
    final itemRect = itemBox.localToGlobal(Offset.zero) & itemBox.size;
    _selected = true;
    if (mounted) setState(() {});

    var result = await Navigator.of(context).push(
      _OptionPopupRoute<T>(
        // buttonRect: itemRect,
        // top: widget.top,
        rect: Rect.fromLTRB(itemRect.left, itemRect.top + widget.top, itemRect.right, itemRect.bottom), // TODO
        value: widget.value,
        items: widget.items,
        optionBuilder: widget.optionBuilder,
      ),
    );

    _selected = false;
    if (mounted) setState(() {});
    if (result != null) {
      widget.onSelect(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.enable ? _onTap : null,
        child: Container(
          height: widget.height, // 26
          width: widget.width, // 88
          child: IconText(
            alignment: IconTextAlignment.r2l,
            mainAxisAlignment: MainAxisAlignment.center,
            space: 0,
            textPadding: EdgeInsets.only(left: 10),
            icon: Icon(
              Icons.arrow_drop_down,
              color: !widget.enable ? Colors.grey[300] : Colors.grey[700],
            ),
            text: Text(
              widget.title,
              style: TextStyle(
                color: !widget.enable
                    ? Colors.grey
                    : _selected && widget.highlightable
                        ? Colors.orange
                        : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 弹出扩展选项的路由设置
class _OptionPopupRoute<T> extends PopupRoute<T> {
  _OptionPopupRoute({
    // required this.buttonRect,
    // required this.top,
    required this.rect,
    required this.value,
    required this.items,
    required this.optionBuilder,
  });

  // final Rect buttonRect;
  // final double top; // TODO
  final Rect rect;
  final T value;
  final List<T> items;
  final String Function(BuildContext, T) optionBuilder;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  String get barrierLabel => MaterialLocalizations.of(navigator!.context).modalBarrierDismissLabel;

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => Colors.black54;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return LayoutBuilder(
      builder: (c, _) => CustomSingleChildLayout(
        delegate: _OptionPopupRouteLayout<T>(
          // buttonRect: buttonRect,
          // top: top,
          rect: rect, // TODO
        ),
        child: MediaQuery.removePadding(
          context: c,
          removeTop: true,
          removeBottom: true,
          removeLeft: true,
          removeRight: true,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Interval(0, 0.25),
              reverseCurve: Interval(0.75, 1),
            ),
            child: _OptionPopupRouteView<T>(
              value: value,
              items: items,
              optionBuilder: optionBuilder,
              transitionDuration: transitionDuration,
            ),
          ),
        ),
      ),
    );
  }
}

/// 路由需要指定的布局设置，主要是显示位置
class _OptionPopupRouteLayout<T> extends SingleChildLayoutDelegate {
  _OptionPopupRouteLayout({
    // required this.buttonRect,
    // required this.top,
    required this.rect,
  });

  // final Rect buttonRect;
  // final double top;
  final Rect rect;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: 0.0,
      // maxWidth: constraints.maxWidth,
      minHeight: 0.0,
      // maxHeight: constraints.maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // double left = buttonRect.left.clamp(0.0, size.width - childSize.width);
    // double top = buttonRect.top.clamp(0.0, size.height - childSize.height);
    // return Offset(left, top + buttonRect.height + this.top);
    double left = rect.left.clamp(0.0, size.width - childSize.width);
    double top = rect.top.clamp(0.0, size.height - childSize.height);
    return Offset(left, top + rect.height); // TODO
  }

  @override
  bool shouldRelayout(_OptionPopupRouteLayout<T> oldDelegate) {
    // return buttonRect != oldDelegate.buttonRect || top != oldDelegate.top;
    return rect != oldDelegate.rect;
  }
}

/// 扩展选项的具体 Widget
class _OptionPopupRouteView<T> extends StatefulWidget {
  const _OptionPopupRouteView({
    Key? key,
    required this.value,
    required this.items,
    required this.optionBuilder,
    required this.transitionDuration,
  }) : super(key: key);

  final T value;
  final List<T> items;
  final String Function(BuildContext, T) optionBuilder;
  final Duration transitionDuration;

  @override
  _OptionPopupViewRouteState<T> createState() => _OptionPopupViewRouteState<T>();
}

class _OptionPopupViewRouteState<T> extends State<_OptionPopupRouteView<T>> {
  final _containerKey = GlobalKey();
  var _showBarrier = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _showBarrier = true;
      if (mounted) setState(() {});
    });
  }

  Widget _buildItem({required T value, required double width, required double height}) {
    var selected = widget.value != null && widget.value == value;
    return Container(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: selected ? Theme.of(context).primaryColor : Colors.white,
        ),
        child: OutlinedButton(
          child: Text(
            widget.optionBuilder(context, value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(value),
          style: OutlinedButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupItems({required double hPadding}) {
    const hSpace = 6.0;
    const vSpace = 9.0;

    var width = (MediaQuery.of(context).size.width - 2 * hPadding - 3 * hSpace) / 4; // |   ▢ ▢ ▢ ▢   |
    var widgets = <Widget>[];
    for (var item in widget.items) {
      widgets.add(
        _buildItem(
          value: item,
          width: width,
          height: 36,
        ),
      );
    }

    return Wrap(
      spacing: hSpace,
      runSpacing: vSpace,
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          key: _containerKey,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(100),
                blurRadius: 8,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: _buildGroupItems(
                  hPadding: 15,
                ),
              ),
            ],
          ),
        ),
        // ****************************************************************
        // 背景
        // ****************************************************************
        // TODO 需要嗎，如何优化 ???
        if (_showBarrier)
          AnimatedOpacity(
            opacity: _showBarrier ? 1.0 : 0.0,
            duration: widget.transitionDuration,
            child: Builder(
              builder: (c) {
                final box = _containerKey.currentContext!.findRenderObject()! as RenderBox;
                final size = box.size;
                final position = box.localToGlobal(Offset.zero);
                final paddingV = MediaQuery.of(context).padding.top + MediaQuery.of(context).padding.bottom;
                return GestureDetector(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height - paddingV - position.dy - size.height,
                    color: Colors.black.withAlpha(100),
                  ),
                  onTap: () => Navigator.pop(context),
                );
              },
            ),
          ),
      ],
    );
  }
}
