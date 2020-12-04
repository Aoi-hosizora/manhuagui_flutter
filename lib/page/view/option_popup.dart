import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

class OptionPopupView<T> extends StatefulWidget {
  const OptionPopupView({
    Key key,
    @required this.title,
    this.top,
    @required this.value,
    @required this.items,
    @required this.optionBuilder,
    @required this.onSelected,
  })  : assert(title != null),
        assert(value != null),
        assert(items != null),
        assert(onSelected != null),
        assert(optionBuilder != null),
        super(key: key);

  final String title;
  final double top;
  final T value;
  final List<T> items;
  final String Function(BuildContext, T) optionBuilder;
  final void Function(T) onSelected;

  @override
  _OptionPopupViewState<T> createState() => _OptionPopupViewState<T>();
}

class _OptionPopupViewState<T> extends State<OptionPopupView<T>> {
  var _selected = false;

  void _onTap() {
    final itemBox = context.findRenderObject() as RenderBox;
    final itemRect = itemBox.localToGlobal(Offset.zero) & itemBox.size;
    var result = Navigator.of(context).push(
      _OptionPopupRoute<T>(
        buttonRect: itemRect,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        top: widget.top,
        value: widget.value,
        items: widget.items,
        optionBuilder: widget.optionBuilder,
      ),
    );
    result.then((T r) {
      if (r != null) {
        widget.onSelected(r);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onTap,
        child: Container(
          height: 26,
          width: 88,
          padding: EdgeInsets.only(left: 10),
          child: IconText(
            alignment: IconTextAlignment.r2l,
            space: 0,
            icon: Icon(
              Icons.arrow_drop_down,
              color: Colors.grey[700],
            ),
            text: Text(
              widget.title,
              style: TextStyle(color: _selected ? Colors.orange : Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionPopupRoute<T> extends PopupRoute<T> {
  _OptionPopupRoute({
    @required this.buttonRect,
    this.barrierLabel,
    this.top,
    @required this.value,
    @required this.items,
    @required this.optionBuilder,
  })  : assert(buttonRect != null),
        assert(value != null),
        assert(items != null),
        assert(optionBuilder != null);

  final Rect buttonRect;
  final double top;
  final T value;
  final List<T> items;
  final String Function(BuildContext, T) optionBuilder;

  @override
  Duration get transitionDuration => Duration(milliseconds: 300);

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => null;

  // @override
  // Color get barrierColor => Colors.black.withAlpha(100);

  @override
  final String barrierLabel;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return LayoutBuilder(
      builder: (c, _) => CustomSingleChildLayout(
        delegate: _OptionPopupRouteLayout<T>(
          buttonRect: buttonRect,
          top: top,
        ),
        child: MediaQuery.removePadding(
          context: c,
          removeTop: true,
          removeBottom: true,
          removeLeft: true,
          removeRight: true,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: this.animation,
              curve: Interval(0.0, 0.25),
              reverseCurve: Interval(0.75, 1.0),
            ),
            child: _OptionPopupView(
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

class _OptionPopupRouteLayout<T> extends SingleChildLayoutDelegate {
  _OptionPopupRouteLayout({
    @required this.buttonRect,
    this.top,
  }) : assert(buttonRect != null);

  final Rect buttonRect;
  final double top;

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
    double left = buttonRect.left.clamp(0.0, size.width - childSize.width);
    double top = buttonRect.top.clamp(0.0, size.height - childSize.height);
    return Offset(left, top + buttonRect.height + this.top ?? 0);
  }

  @override
  bool shouldRelayout(_OptionPopupRouteLayout<T> oldDelegate) {
    return buttonRect != oldDelegate.buttonRect;
  }
}

class _OptionPopupView<T> extends StatefulWidget {
  const _OptionPopupView({
    Key key,
    @required this.value,
    @required this.items,
    @required this.optionBuilder,
    @required this.transitionDuration,
  })  : assert(value != null),
        assert(items != null),
        assert(optionBuilder != null),
        assert(transitionDuration != null),
        super(key: key);

  final T value;
  final List<T> items;
  final String Function(BuildContext, T) optionBuilder;
  final Duration transitionDuration;

  @override
  __OptionPopupViewState<T> createState() => __OptionPopupViewState<T>();
}

class __OptionPopupViewState<T> extends State<_OptionPopupView<T>> {
  var _containerKey = GlobalKey();
  var _showBarrier = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBarrier = true;
      if (mounted) setState(() {});
    });
  }

  Widget _buildGrid(T t, int index, {double padding, double height, double width}) {
    var selected = widget.value != null && widget.value == t;
    return Container(
      height: height,
      width: width,
      margin: index == 0
          ? EdgeInsets.only(right: padding)
          : index == 3
              ? EdgeInsets.only(left: padding)
              : EdgeInsets.symmetric(horizontal: padding),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: selected ? Theme.of(context).primaryColor : Colors.white,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            buttonTheme: ButtonTheme.of(context).copyWith(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          child: OutlineButton(
            onPressed: () => Navigator.of(context).pop(t),
            child: Text(
              widget.optionBuilder(context, t),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var hPadding = 12.0;
    var vPadding = 10.0;
    var padding = 3.0;
    var width = (MediaQuery.of(context).size.width - 2 * hPadding - 6 * padding) / 4;
    var height = 36.0;

    var gridViews = <Widget>[];
    var rows = (widget.items.length.toDouble() / 4).ceil();
    for (var r = 0; r < rows; r++) {
      var columns = <T>[
        for (var i = 4 * r; i < 4 * (r + 1) && i < widget.items.length; i++) widget.items[i],
      ];
      gridViews.add(
        Row(
          children: [
            for (var i = 0; i < columns.length; i++)
              _buildGrid(
                columns[i],
                i,
                padding: padding,
                width: width,
                height: height,
              ),
          ],
        ),
      );
      if (r != rows - 1) {
        gridViews.add(
          SizedBox(height: padding * 2),
        );
      }
    }

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
              Container(
                padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...gridViews,
                  ],
                ),
              ),
              // Divider(height: 1, thickness: 1),
            ],
          ),
        ),
        if (_showBarrier)
          AnimatedOpacity(
            opacity: _showBarrier ? 1 : 0,
            duration: widget.transitionDuration,
            child: Builder(
              builder: (c) {
                final box = _containerKey.currentContext.findRenderObject() as RenderBox;
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
