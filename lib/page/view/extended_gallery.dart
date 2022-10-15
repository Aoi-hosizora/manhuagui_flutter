import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:photo_view/photo_view.dart';

class ExtendedPhotoGalleryView extends StatefulWidget {
  const ExtendedPhotoGalleryView({
    Key? key,
    required this.imageCount,
    required this.firstPageBuilder,
    required this.imagePageBuilder,
    required this.lastPageBuilder,
    this.backgroundDecoration,
    this.wantKeepAlive = false,
    this.gaplessPlayback = false,
    this.reverse = false,
    this.keepViewportWidth = true,
    this.pageController,
    this.onPageChanged,
    this.scaleStateChangedCallback,
    this.enableRotation = false,
    this.scrollPhysics,
    this.scrollDirection = Axis.horizontal,
    this.customSize,
    this.pageMainAxisAverageSize,
    this.preloadPagesCount = 0,
    this.onPointerMove,
  }) : super(key: key);

  final int imageCount;
  final Widget Function(BuildContext context) firstPageBuilder;
  final ReloadablePhotoViewGalleryPageOptions Function(BuildContext context, int index) imagePageBuilder;
  final Widget Function(BuildContext context) lastPageBuilder;
  final ScrollPhysics? scrollPhysics;
  final BoxDecoration? backgroundDecoration;
  final bool wantKeepAlive;
  final bool gaplessPlayback;
  final bool reverse;
  final bool keepViewportWidth;
  final PageController? pageController;
  final void Function(int index)? onPageChanged;
  final ValueChanged<PhotoViewScaleState>? scaleStateChangedCallback;
  final bool enableRotation;
  final Size? customSize;
  final Axis scrollDirection;
  final double? pageMainAxisAverageSize;
  final int preloadPagesCount;
  final void Function(PointerMoveEvent)? onPointerMove; // <<<

  @override
  State<StatefulWidget> createState() => ExtendedPhotoGalleryViewState();
}

class ExtendedPhotoGalleryViewState extends State<ExtendedPhotoGalleryView> {
  late var _controller = widget.pageController ?? PageController();

  // reload notifiers, without extra pages, starts from 0.
  late List<ValueNotifier<String>> _notifiers = List.generate(widget.imageCount, (index) => ValueNotifier(''));

  // current page index, with extra pages, starts from 0.
  int get currentPage => _controller.hasClients ? _controller.page!.floor() : 0;

  // page total, with extra pages, starts from 0.
  int get pageCount => widget.imageCount + 2;

  // reload image page, without extra pages, starts from 0.
  void reload(int index) {
    _notifiers[index].value = DateTime.now().microsecondsSinceEpoch.toString();
  }

  @override
  void didUpdateWidget(covariant ExtendedPhotoGalleryView oldWidget) {
    if (widget.imageCount != oldWidget.imageCount) {
      _notifiers = List.generate(widget.imageCount, (index) => ValueNotifier(''));
    }
    if (widget.pageController != oldWidget.pageController) {
      _controller = widget.pageController ?? PageController(); // <<<
    }
    super.didUpdateWidget(oldWidget);
  }

  void _scaleStateChangedCallback(PhotoViewScaleState scaleState) {
    if (widget.scaleStateChangedCallback != null) {
      widget.scaleStateChangedCallback!(scaleState);
    }
  }

  // without extra pages, starts from 0.
  Widget _buildItem(BuildContext context, int index) {
    final pageOption = widget.imagePageBuilder(context, index);
    final view = ClipRect(
      child: ValueListenableBuilder<String>(
        valueListenable: _notifiers[index], // <<<
        builder: (_, v, __) => PhotoView(
          key: ValueKey('$index-$v') /* ObjectKey(index) */,
          imageProvider: pageOption.imageProviderBuilder(ValueKey('$index-$v')),
          backgroundDecoration: widget.backgroundDecoration,
          wantKeepAlive: widget.wantKeepAlive,
          controller: pageOption.controller,
          scaleStateController: pageOption.scaleStateController,
          customSize: widget.customSize,
          gaplessPlayback: widget.gaplessPlayback,
          heroAttributes: pageOption.heroAttributes,
          scaleStateChangedCallback: _scaleStateChangedCallback,
          enableRotation: widget.enableRotation,
          initialScale: pageOption.initialScale,
          minScale: pageOption.minScale,
          maxScale: pageOption.maxScale,
          scaleStateCycle: pageOption.scaleStateCycle,
          onTapUp: pageOption.onTapUp,
          onTapDown: pageOption.onTapDown,
          onScaleEnd: pageOption.onScaleEnd,
          gestureDetectorBehavior: pageOption.gestureDetectorBehavior,
          tightMode: pageOption.tightMode,
          filterQuality: pageOption.filterQuality,
          basePosition: pageOption.basePosition,
          disableGestures: pageOption.disableGestures,
          loadingBuilder: pageOption.loadingBuilder,
          errorBuilder: pageOption.errorBuilder,
        ),
      ),
    );

    if (widget.onPointerMove != null) {
      return Listener(
        onPointerMove: widget.onPointerMove, // <<<
        child: view,
      );
    }
    return view;
  }

  @override
  Widget build(BuildContext context) {
    return PhotoViewGestureDetectorScope(
      axis: widget.scrollDirection,
      child: PreloadablePageView.builder(
        reverse: widget.reverse,
        controller: _controller,
        onPageChanged: widget.onPageChanged,
        itemCount: widget.imageCount + 2,
        itemBuilder: (context, index) => FractionallySizedBox(
          widthFactor: widget.keepViewportWidth ? 1 / (widget.pageController?.viewportFraction ?? 1) : 1,
          child: index == 0
              ? widget.firstPageBuilder(context)
              : index == widget.imageCount + 1
                  ? widget.lastPageBuilder(context)
                  : _buildItem(context, index - 1), // <<< without extra pages, starts from 0
        ),
        scrollDirection: widget.scrollDirection,
        physics: widget.scrollPhysics,
        pageMainAxisAverageSize: widget.pageMainAxisAverageSize,
        preloadPagesCount: widget.preloadPagesCount,
      ),
    );
  }
}
