import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

final PageController _defaultPageController = PageController();
const PageScrollPhysics _kPagePhysics = PageScrollPhysics();

/// A [PageView] with [preloadPagesCount].
class PreLoadPageView extends StatefulWidget {
  PreLoadPageView({
    Key? key,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    PageController controller,
    this.physics,
    this.pageSnapping = true,
    this.onPageChanged,
    List<Widget> children = const <Widget>[],
    this.dragStartBehavior = DragStartBehavior.start,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.preloadPagesCount = 1,
  })  : assert(clipBehavior != null),
        controller = controller ?? _defaultPageController,
        childrenDelegate = SliverChildListDelegate(children),
        super(key: key);

  PreLoadPageView.builder({
    Key? key,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    PageController controller,
    this.physics,
    this.pageSnapping = true,
    this.onPageChanged,
    required IndexedWidgetBuilder itemBuilder,
    int itemCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.preloadPagesCount = 1,
  })  : assert(clipBehavior != null),
        controller = controller ?? _defaultPageController,
        childrenDelegate = SliverChildBuilderDelegate(itemBuilder, childCount: itemCount),
        super(key: key);

  PreLoadPageView.custom({
    Key? key,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    PageController controller,
    this.physics,
    this.pageSnapping = true,
    this.onPageChanged,
    required this.childrenDelegate,
    this.dragStartBehavior = DragStartBehavior.start,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.preloadPagesCount = 1,
  })  : assert(childrenDelegate != null),
        assert(clipBehavior != null),
        controller = controller ?? _defaultPageController,
        super(key: key);

  final String restorationId;
  final Axis scrollDirection;
  final bool reverse;
  final PageController controller;
  final ScrollPhysics physics;
  final bool pageSnapping;
  final ValueChanged<int> onPageChanged;
  final SliverChildDelegate childrenDelegate;
  final DragStartBehavior dragStartBehavior;
  final Clip clipBehavior;
  final int preloadPagesCount;

  @override
  _PreLoadPageViewState createState() => _PreLoadPageViewState();
}

class _PreLoadPageViewState extends State<PreLoadPageView> {
  int _lastReportedPage = 0;

  @override
  void initState() {
    super.initState();
    _lastReportedPage = widget.controller.initialPage;
  }

  AxisDirection _getDirection(BuildContext context) {
    switch (widget.scrollDirection) {
      case Axis.horizontal:
        assert(debugCheckHasDirectionality(context));
        final TextDirection textDirection = Directionality.of(context);
        final AxisDirection axisDirection = textDirectionToAxisDirection(textDirection);
        return widget.reverse ? flipAxisDirection(axisDirection) : axisDirection;
      case Axis.vertical:
        return widget.reverse ? AxisDirection.up : AxisDirection.down;
      default:
        throw ArgumentError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AxisDirection axisDirection = _getDirection(context);
    final ScrollPhysics physics = widget.pageSnapping ? _kPagePhysics.applyTo(widget.physics) : widget.physics;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.depth == 0 && widget.onPageChanged != null && notification is ScrollUpdateNotification) {
          final PageMetrics metrics = notification.metrics as PageMetrics;
          final int currentPage = metrics.page.round();
          if (currentPage != _lastReportedPage) {
            _lastReportedPage = currentPage;
            widget.onPageChanged(currentPage);
          }
        }
        return false;
      },
      child: Scrollable(
        dragStartBehavior: widget.dragStartBehavior,
        axisDirection: axisDirection,
        controller: widget.controller,
        physics: physics,
        restorationId: widget.restorationId,
        viewportBuilder: (BuildContext context, ViewportOffset position) {
          // see https://github.com/octomato/preload_page_view/blob/90bf545d49/lib/preload_page_view.dart#L592
          return Viewport(
            cacheExtent: widget.preloadPagesCount == null || widget.preloadPagesCount < 1
                ? 0
                : widget.scrollDirection == Axis.horizontal
                    ? MediaQuery.of(context).size.width * widget.preloadPagesCount - 1
                    : MediaQuery.of(context).size.height * widget.preloadPagesCount - 1,
            // cacheExtentStyle: CacheExtentStyle.viewport,
            axisDirection: axisDirection,
            offset: position,
            clipBehavior: widget.clipBehavior,
            slivers: <Widget>[
              SliverFillViewport(
                viewportFraction: widget.controller.viewportFraction,
                delegate: widget.childrenDelegate,
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(EnumProperty<Axis>('scrollDirection', widget.scrollDirection));
    description.add(FlagProperty('reverse', value: widget.reverse, ifTrue: 'reversed'));
    description.add(DiagnosticsProperty<PageController>('controller', widget.controller, showName: false));
    description.add(DiagnosticsProperty<ScrollPhysics>('physics', widget.physics, showName: false));
    description.add(FlagProperty('pageSnapping', value: widget.pageSnapping, ifFalse: 'snapping disabled'));
  }
}
