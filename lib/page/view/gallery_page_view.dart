import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/page/view/preload_page_view.dart';
import 'package:photo_view/photo_view.dart';

typedef GalleryPageViewPageChangedCallback = void Function(int index);
typedef GalleryPageViewBuilder = GalleryPageViewPageOptions Function(BuildContext context, int index);

/// A [PhotoViewGallery] with [FractionallySizedBox] for [itemBuilder].
class GalleryPageView extends StatefulWidget {
  const GalleryPageView({
    Key key,
    @required this.itemCount,
    @required this.builder,
    this.loadingBuilder,
    this.loadFailedChild,
    this.backgroundDecoration,
    this.gaplessPlayback = false,
    this.reverse = false,
    @required this.pageController,
    this.onPageChanged,
    this.scaleStateChangedCallback,
    this.enableRotation = false,
    this.scrollPhysics,
    this.scrollDirection = Axis.horizontal,
    this.customSize,
    this.preloadPagesCount = 1,
  })  : assert(itemCount != null),
        assert(builder != null),
        assert(pageController != null),
        super(key: key);

  final int itemCount;
  final GalleryPageViewBuilder builder;
  final ScrollPhysics scrollPhysics;
  final LoadingBuilder loadingBuilder;
  final Widget loadFailedChild;
  final Decoration backgroundDecoration;
  final bool gaplessPlayback;
  final bool reverse;
  final PageController pageController;
  final GalleryPageViewPageChangedCallback onPageChanged;
  final ValueChanged<PhotoViewScaleState> scaleStateChangedCallback;
  final bool enableRotation;
  final Size customSize;
  final Axis scrollDirection;
  final int preloadPagesCount;

  @override
  State<StatefulWidget> createState() {
    return _GalleryPageViewState();
  }
}

class _GalleryPageViewState extends State<GalleryPageView> {
  @override
  Widget build(BuildContext context) {
    return PhotoViewGestureDetectorScope(
      axis: widget.scrollDirection,
      child: PreLoadPageView.builder(
        reverse: widget.reverse,
        controller: widget.pageController,
        onPageChanged: widget.onPageChanged,
        itemCount: widget.itemCount,
        itemBuilder: (context, index) => FractionallySizedBox(
          widthFactor: 1 / widget.pageController.viewportFraction, // <<<
          child: _buildItem(context, index),
        ),
        preloadPagesCount: widget.preloadPagesCount ?? 1, // <<<
        scrollDirection: widget.scrollDirection,
        physics: widget.scrollPhysics,
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final pageOption = widget.builder(context, index);
    return ClipRect(
      child: PhotoView(
        key: ObjectKey(index),
        imageProvider: pageOption.imageProvider,
        loadingBuilder: widget.loadingBuilder,
        loadFailedChild: widget.loadFailedChild,
        backgroundDecoration: widget.backgroundDecoration,
        controller: pageOption.controller,
        scaleStateController: pageOption.scaleStateController,
        customSize: widget.customSize,
        gaplessPlayback: widget.gaplessPlayback,
        heroAttributes: pageOption.heroAttributes,
        scaleStateChangedCallback: (s) => widget.scaleStateChangedCallback?.call(s),
        enableRotation: widget.enableRotation,
        initialScale: pageOption.initialScale,
        minScale: pageOption.minScale,
        maxScale: pageOption.maxScale,
        scaleStateCycle: pageOption.scaleStateCycle,
        onTapUp: pageOption.onTapUp,
        onTapDown: pageOption.onTapDown,
        gestureDetectorBehavior: pageOption.gestureDetectorBehavior,
        tightMode: pageOption.tightMode,
        filterQuality: pageOption.filterQuality,
        basePosition: pageOption.basePosition,
        disableGestures: pageOption.disableGestures,
      ),
    );
  }
}

class GalleryPageViewPageOptions {
  const GalleryPageViewPageOptions({
    Key key,
    @required this.imageProvider,
    this.heroAttributes,
    this.minScale,
    this.maxScale,
    this.initialScale,
    this.controller,
    this.scaleStateController,
    this.basePosition,
    this.scaleStateCycle,
    this.onTapUp,
    this.onTapDown,
    this.gestureDetectorBehavior,
    this.tightMode,
    this.filterQuality,
    this.disableGestures,
  }) : assert(imageProvider != null);

  final ImageProvider imageProvider;
  final PhotoViewHeroAttributes heroAttributes;
  final dynamic minScale;
  final dynamic maxScale;
  final dynamic initialScale;
  final PhotoViewController controller;
  final PhotoViewScaleStateController scaleStateController;
  final Alignment basePosition;
  final ScaleStateCycle scaleStateCycle;
  final PhotoViewImageTapUpCallback onTapUp;
  final PhotoViewImageTapDownCallback onTapDown;
  final HitTestBehavior gestureDetectorBehavior;
  final bool tightMode;
  final bool disableGestures;
  final FilterQuality filterQuality;
}
