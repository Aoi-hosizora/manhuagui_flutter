import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:photo_view/photo_view.dart';

/// 漫画画廊展示，自定义 [ReloadablePhotoViewGallery]，在 [MangaViewerPage] 使用
class MangaGalleryView extends StatefulWidget {
  const MangaGalleryView({
    Key? key,
    required this.itemCount,
    required this.builder,
    this.backgroundDecoration,
    this.wantKeepAlive = false,
    this.gaplessPlayback = false,
    this.reverse = false,
    this.viewportFraction = 1.0,
    this.pageController,
    this.onPageChanged,
    this.scaleStateChangedCallback,
    this.enableRotation = false,
    this.scrollPhysics,
    this.scrollDirection = Axis.horizontal,
    this.customSize,
    this.preloadPagesCount = 0,
  }) : super(key: key);

  final int itemCount;
  final ReloadablePhotoViewGalleryPageOptions Function(BuildContext context, int index) builder;
  final ScrollPhysics? scrollPhysics;
  final BoxDecoration? backgroundDecoration;
  final bool wantKeepAlive;
  final bool gaplessPlayback;
  final bool reverse;
  final double viewportFraction;
  final PageController? pageController;
  final void Function(int index)? onPageChanged;
  final ValueChanged<PhotoViewScaleState>? scaleStateChangedCallback;
  final bool enableRotation;
  final Size? customSize;
  final Axis scrollDirection;
  final int preloadPagesCount;

  @override
  State<StatefulWidget> createState() => MangaGalleryViewState();
}

class MangaGalleryViewState extends State<MangaGalleryView> {
  late final PageController _controller = widget.pageController ?? PageController();
  late List<ValueNotifier<String>> _notifiers = List.generate(widget.itemCount, (index) => ValueNotifier(''));

  int get currentPage => _controller.hasClients ? _controller.page!.floor() : 0;

  int get itemCount => widget.itemCount;

  void reload(int index) {
    _notifiers[index].value = DateTime.now().microsecondsSinceEpoch.toString();
  }

  @override
  void didUpdateWidget(covariant MangaGalleryView oldWidget) {
    if (widget.itemCount != oldWidget.itemCount) {
      _notifiers = List.generate(widget.itemCount, (index) => ValueNotifier(''));
    }
    super.didUpdateWidget(oldWidget);
  }

  void _scaleStateChangedCallback(PhotoViewScaleState scaleState) {
    if (widget.scaleStateChangedCallback != null) {
      widget.scaleStateChangedCallback!(scaleState);
    }
  }

  ReloadablePhotoViewGalleryPageOptions _buildPageOption(BuildContext context, int index) {
    return widget.builder(context, index);
  }

  Widget _buildItem(BuildContext context, int index) {
    final pageOption = _buildPageOption(context, index);
    return ClipRect(
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
  }

  @override
  Widget build(BuildContext context) {
    // Enable corner hit test
    return PhotoViewGestureDetectorScope(
      axis: widget.scrollDirection,
      child: PreloadablePageView.builder(
        reverse: widget.reverse,
        controller: _controller,
        onPageChanged: widget.onPageChanged,
        itemCount: widget.itemCount,
        // itemBuilder: _buildItem,
        itemBuilder: (context, index) => FractionallySizedBox(
          widthFactor: 1 / widget.viewportFraction,
          child: _buildItem(context, index),
        ),
        scrollDirection: widget.scrollDirection,
        physics: widget.scrollPhysics,
        preloadPagesCount: widget.preloadPagesCount,
      ),
    );
  }
}
