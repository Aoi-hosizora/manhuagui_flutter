import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:photo_view/photo_view.dart';

class HorizontalGalleryView extends ExtendedPhotoGallery {
  HorizontalGalleryView({
    Key? key,
    required int imageCount,
    required ExtendedPhotoGalleryPageOptions Function(BuildContext, int) imagePageBuilder,
    required Widget Function(BuildContext context) firstPageBuilder, // <<<
    required Widget Function(BuildContext context) lastPageBuilder, // <<<
    void Function()? onImageLongPressed, // <<<
    BoxDecoration? backgroundDecoration,
    bool wantKeepAlive = false,
    bool gaplessPlayback = false,
    bool reverse = false,
    PageController? pageController,
    void Function(int)? onPageChanged,
    bool changePageWhenFinished = false,
    bool keepViewportMainAxisSize = true,
    double? fractionWidthFactor,
    double? fractionHeightFactor,
    void Function(PhotoViewScaleState)? scaleStateChangedCallback,
    bool enableRotation = false,
    ScrollPhysics? scrollPhysics,
    Axis scrollDirection = Axis.horizontal,
    Size? customSize,
    Widget Function(BuildContext, ImageChunkEvent?)? loadingBuilder,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
    double? pageMainAxisHintSize,
    int preloadPagesCount = 0,
  }) : super.advanced(
          key: key,
          pageCount: imageCount + 2,
          builder: imagePageBuilder,
          advancedBuilder: (c, index, builder) {
            if (index == 0) {
              return firstPageBuilder(c); // <<<
            }
            if (index == imageCount + 1) {
              return lastPageBuilder(c); // <<<
            }
            return GestureDetector(
              onLongPress: onImageLongPressed, // <<<
              child: builder(c, index - 1),
            );
            // return builder(c, index - 1);
          },
          backgroundDecoration: backgroundDecoration,
          wantKeepAlive: wantKeepAlive,
          gaplessPlayback: gaplessPlayback,
          reverse: reverse,
          pageController: pageController,
          onPageChanged: onPageChanged,
          changePageWhenFinished: changePageWhenFinished,
          keepViewportMainAxisSize: keepViewportMainAxisSize,
          fractionWidthFactor: fractionWidthFactor,
          fractionHeightFactor: fractionHeightFactor,
          scaleStateChangedCallback: scaleStateChangedCallback,
          enableRotation: enableRotation,
          scrollPhysics: scrollPhysics,
          scrollDirection: scrollDirection,
          customSize: customSize,
          loadingBuilder: loadingBuilder,
          errorBuilder: errorBuilder,
          pageMainAxisHintSize: pageMainAxisHintSize,
          preloadPagesCount: preloadPagesCount,
        );
}

class VerticalGalleryView extends StatefulWidget {
  const VerticalGalleryView({
    Key? key,
    required this.imageCount,
    required this.imagePageBuilder,
    required this.firstPageBuilder,
    required this.lastPageBuilder,
    this.onImageLongPressed, // x
    this.backgroundDecoration,
    this.wantKeepAlive = false,
    this.gaplessPlayback = false,
    this.reverse = false, // x
    this.pageController, // x
    this.onPageChanged, // x
    this.changePageWhenFinished = false, // x
    this.keepViewportMainAxisSize = true, // x
    this.viewportMainAxisFactor, // x
    this.scaleStateChangedCallback,
    this.enableRotation = false,
    this.scrollPhysics, // x
    this.scrollDirection = Axis.horizontal, // x
    this.customSize,
    this.loadingBuilder,
    this.errorBuilder,
    this.pageMainAxisHintSize, // x
    this.preloadPagesCount = 0, // x
    this.betweenPageSpace = 0.0, // <<<
  }) : super(key: key);

  final int imageCount;
  final ExtendedPhotoGalleryPageOptions Function(BuildContext, int) imagePageBuilder;
  final Widget Function(BuildContext context) firstPageBuilder;
  final Widget Function(BuildContext context) lastPageBuilder;
  final void Function()? onImageLongPressed; // TODO
  final BoxDecoration? backgroundDecoration;
  final bool wantKeepAlive;
  final bool gaplessPlayback;
  final bool reverse; // TODO
  final PageController? pageController; // TODO
  final void Function(int)? onPageChanged; // TODO
  final bool changePageWhenFinished; // TODO
  final bool keepViewportMainAxisSize; // TODO
  final double? viewportMainAxisFactor; // TODO
  final void Function(PhotoViewScaleState)? scaleStateChangedCallback;
  final bool enableRotation;
  final ScrollPhysics? scrollPhysics; // TODO
  final Axis scrollDirection; // TODO
  final Size? customSize;
  final Widget Function(BuildContext, ImageChunkEvent?)? loadingBuilder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final double? pageMainAxisHintSize; // TODO
  final int preloadPagesCount; // TODO
  final double betweenPageSpace; // <<<

  @override
  State<VerticalGalleryView> createState() => _VerticalGalleryViewState();
}

class _VerticalGalleryViewState extends State<VerticalGalleryView> {
  late List<ValueNotifier<String>> _notifiers = List.generate(widget.imageCount, (index) => ValueNotifier(''));

  void reload(int index) {
    _notifiers[index].value = DateTime.now().microsecondsSinceEpoch.toString();
    // no need to setState
  }

  @override
  void didUpdateWidget(covariant VerticalGalleryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageCount != oldWidget.imageCount) {
      _notifiers = List.generate(widget.imageCount, (index) => ValueNotifier(''));
    }
  }

  Widget _buildPhotoItem(BuildContext context, int index) {
    final pageOption = widget.imagePageBuilder(context, index); // index excludes non-PhotoView pages
    return ClipRect(
      child: ValueListenableBuilder<String>(
        valueListenable: _notifiers[index], // <<<
        builder: (_, v, __) => PhotoView(
          key: ValueKey('$index-$v'),
          imageProvider: pageOption.imageProviderBuilder(ValueKey('$index-$v')),
          backgroundDecoration: widget.backgroundDecoration,
          wantKeepAlive: widget.wantKeepAlive,
          controller: pageOption.controller,
          scaleStateController: pageOption.scaleStateController,
          customSize: widget.customSize,
          gaplessPlayback: widget.gaplessPlayback,
          heroAttributes: pageOption.heroAttributes,
          scaleStateChangedCallback: (state) => widget.scaleStateChangedCallback?.call(state),
          enableRotation: widget.enableRotation,
          initialScale: pageOption.initialScale,
          minScale: pageOption.minScale,
          maxScale: pageOption.maxScale,
          scaleStateCycle: pageOption.scaleStateCycle,
          onTapUp: pageOption.onTapUp,
          onTapDown: pageOption.onTapDown,
          onScaleEnd: pageOption.onScaleEnd,
          gestureDetectorBehavior: pageOption.gestureDetectorBehavior,
          // tightMode: pageOption.tightMode,
          tightMode: true,
          filterQuality: pageOption.filterQuality,
          basePosition: pageOption.basePosition,
          // disableGestures: pageOption.disableGestures,
          disableGestures: true,
          enablePanAlways: pageOption.enablePanAlways,
          // loadingBuilder: (_, __) => Container(height: 200, color: Colors.yellow, child: Text('loading $index')),
          // errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.blue, child: Text('error $index')),
          loadingBuilder: pageOption.loadingBuilder ?? widget.loadingBuilder,
          errorBuilder: pageOption.errorBuilder ?? widget.errorBuilder,
        ),
      ),
    );
  }

  // TODO

  final controller = ScrollController();
  var atTop = false;

  @override
  Widget build(BuildContext context) {
    // controller ...
    // scroll to page ...

    return ListView(
      // TODO cacheExtent 上下都包括？
      padding: EdgeInsets.zero,
      children: [
        widget.firstPageBuilder(context),
        SizedBox(height: widget.betweenPageSpace),
        for (var i = 0; i < widget.imageCount; i++)
          Container(
            margin: EdgeInsets.only(bottom: widget.betweenPageSpace),
            child: _buildPhotoItem(context, i),
          ),
        widget.firstPageBuilder(context),
      ],
    );

    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 2.0,
      constrained: false,
      scaleEnabled: true,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
        child: Listener(
          onPointerMove: (e) {
            // print('onPointerMove, ${DateTime.now()} ${e.delta}');
            if (atTop && e.delta.dy > 0) {
              atTop = false;
              if (mounted) setState(() {});
            }
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (e) {
              // print('onNotification, ${DateTime.now()}, ${e.metrics.pixels} ');
              if (e.metrics.pixels == e.metrics.minScrollExtent) {
                atTop = true;
                if (mounted) setState(() {});
              }
              return false;
            },
            child: ListView(
              physics: !atTop ? AlwaysScrollableScrollPhysics() : NeverScrollableScrollPhysics(),
              controller: controller,
              cacheExtent: MediaQuery.of(context).size.height,
              children: [
                // SizedBox(
                //   width: MediaQuery.of(context).size.width,
                //   child: widget.firstPageBuilder(context),
                // ),
                // SizedBox(height: widget.betweenPageSpace),
                for (var i = 0; i < widget.imageCount; i++)
                  StatefulBuilder(
                    builder: (c, _setState) {
                      // WidgetsBinding.instance?.addPostFrameCallback((_) {
                      //   var rect = c.findRenderObject()?.getBoundInRootAncestorCoordinate();
                      //   print('$i: $rect');
                      // });
                      // print('build $i');
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.only(top: i == 0 ? 0 : widget.betweenPageSpace),
                        child: _buildPhotoItem(context, i),
                      );
                    },
                  ),
                // SizedBox(
                //   width: MediaQuery.of(context).size.width,
                //   child: widget.lastPageBuilder(context),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
