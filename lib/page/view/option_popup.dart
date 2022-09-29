import 'package:flutter/material.dart';
import 'package:flutter_ahlib/widget.dart';

class OptionPopupView<T> extends StatefulWidget {
  const OptionPopupView({
    Key? key,
    required this.title,
    this.top,
    this.height = 26.0,
    this.width = 88.0,
    required this.value,
    required this.items,
    this.doHighlight = false,
    required this.optionBuilder,
    required this.onSelect,
    this.enable = true,
  })  : assert(title != null),
        assert(value != null),
        assert(doHighlight != null),
        assert(items != null),
        assert(onSelect != null),
        assert(optionBuilder != null),
        assert(enable != null),
        super(key: key);

  final String title;
  final double top;
  final double height;
  final double width;
  final bool doHighlight;
  final T value;
  final List<T> items;
  final String Function(BuildContext, T) optionBuilder;
  final void Function(T) onSelect;
  final bool enable;

  @override
  _OptionPopupRouteViewState<T> createState() => _OptionPopupRouteViewState<T>();
}

class _OptionPopupRouteViewState<T> extends State<OptionPopupView<T>> {
  var _selected = false;

  void _onTap() {
    final itemBox = context.findRenderObject() as RenderBox;
    final itemRect = itemBox.localToGlobal(Offset.zero) & itemBox.size;
    _selected = true;
    if (mounted) setState(() {});
    // ****************************************************************
    // 弹出选项路由
    // ****************************************************************
    var result = Navigator.of(context).push(
      _OptionPopupRoute<T>(
        buttonRect: itemRect,
        transitionDuration: Duration(milliseconds: 300),
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        top: widget.top,
        value: widget.value,
        items: widget.items,
        optionBuilder: widget.optionBuilder,
      ),
    );
    result.then((T r) {
      _selected = false;
      if (mounted) setState(() {});
      if (r != null) {
        widget.onSelect(r);
      }
    });
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
                    : _selected && widget.doHighlight
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

class _OptionPopupRoute<T> extends PopupRoute<T> {
  _OptionPopupRoute({
    required this.buttonRect,
    required this.transitionDuration,
    this.barrierLabel,
    this.top,
    required this.value,
    required this.items,
    required this.optionBuilder,
  })  : assert(buttonRect != null),
        assert(transitionDuration != null),
        assert(value != null),
        assert(items != null),
        assert(optionBuilder != null);

  final Rect buttonRect;
  final double top;
  final T value;
  final List<T> items;
  final String Function(BuildContext, T) optionBuilder;

  @override
  final Duration transitionDuration;

  @override
  final String barrierLabel;

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => null;

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
              curve: Interval(0, 0.25),
              reverseCurve: Interval(0.75, 1),
            ),
            // ****************************************************************
            // 选项界面
            // ****************************************************************
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

class _OptionPopupRouteLayout<T> extends SingleChildLayoutDelegate {
  _OptionPopupRouteLayout({
    required this.buttonRect,
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
    return buttonRect != oldDelegate.buttonRect || top != oldDelegate.top;
  }
}

class _OptionPopupRouteView<T> extends StatefulWidget {
  const _OptionPopupRouteView({
    Key? key,
    required this.value,
    required this.items,
    required this.optionBuilder,
    required this.transitionDuration,
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
  _OptionPopupViewRouteState<T> createState() => _OptionPopupViewRouteState<T>();
}

class _OptionPopupViewRouteState<T> extends State<_OptionPopupRouteView<T>> {
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

  Widget _buildGridItem(T value, int index, {double hSpace, double width, double height}) {
    var selected = widget.value != null && widget.value == value;
    // ****************************************************************
    // 每个选项
    // ****************************************************************
    return Container(
      width: width,
      height: height,
      margin: index == 0
          ? EdgeInsets.only(right: hSpace)
          : index == 3
              ? EdgeInsets.only(left: hSpace)
              : EdgeInsets.symmetric(horizontal: hSpace),
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
            onPressed: () => Navigator.of(context).pop(value),
            child: Text(
              widget.optionBuilder(context, value),
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
    var hPadding = 15.0;
    var vPadding = 10.0;
    var hSpace = 3.0;
    var vSpace = 2 * hSpace;
    var width = (MediaQuery.of(context).size.width - 2 * hPadding - 6 * hSpace) / 4; // |   ▢  ▢  ▢  ▢   |
    var height = 36.0;

    var gridRows = <Widget>[];
    var rows = (widget.items.length.toDouble() / 4).ceil();
    for (var r = 0; r < rows; r++) {
      var columns = <T>[
        for (var i = 4 * r; i < 4 * (r + 1) && i < widget.items.length; i++) widget.items[i],
      ];
      gridRows.add(
        // ****************************************************************
        // 选项中的每一行
        // ****************************************************************
        Row(
          children: [
            for (var i = 0; i < columns.length; i++)
              _buildGridItem(
                columns[i],
                i,
                hSpace: hSpace,
                width: width,
                height: height,
              ),
          ],
        ),
      );
      if (r != rows - 1) {
        gridRows.add(
          SizedBox(height: vSpace),
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
              // ****************************************************************
              // 所有选项
              // ****************************************************************
              Container(
                padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...gridRows,
                  ],
                ),
              ),
            ],
          ),
        ),
        // ****************************************************************
        // 背景
        // ****************************************************************
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
