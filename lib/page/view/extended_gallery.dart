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
    void Function(int index)? onImageLongPressed, // <<<
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
              onLongPress: onImageLongPressed == null ? null : () => onImageLongPressed(index - 1), // <<<
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
    this.onImageTapDown,
    this.onImageTapUp,
    this.onImageLongPressed,
    this.backgroundDecoration,
    this.wantKeepAlive = false,
    this.gaplessPlayback = false,
    this.onPageChanged,
    this.betweenPageSpace = 0.0,
    this.scaleStateChangedCallback,
    this.enableRotation = false,
    this.scrollPhysics,
    this.customSize,
    this.loadingBuilder,
    this.errorBuilder,
    this.pageMainAxisHintSize,
    this.preloadPagesCount = 0,
  }) : super(key: key);

  final int imageCount;
  final ExtendedPhotoGalleryPageOptions Function(BuildContext, int) imagePageBuilder;
  final Widget Function(BuildContext context) firstPageBuilder;
  final Widget Function(BuildContext context) lastPageBuilder;
  final void Function(int index, TapDownDetails details)? onImageTapDown;
  final void Function(int index, TapUpDetails details)? onImageTapUp;
  final void Function(int index)? onImageLongPressed;
  final BoxDecoration? backgroundDecoration;
  final bool wantKeepAlive;
  final bool gaplessPlayback;
  final void Function(int)? onPageChanged;
  final double betweenPageSpace;
  final void Function(PhotoViewScaleState)? scaleStateChangedCallback;
  final bool enableRotation;
  final ScrollPhysics? scrollPhysics;
  final Size? customSize;
  final Widget Function(BuildContext, ImageChunkEvent?)? loadingBuilder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final double? pageMainAxisHintSize;
  final int preloadPagesCount;

  @override
  State<VerticalGalleryView> createState() => VerticalGalleryViewState();
}

class VerticalGalleryViewState extends State<VerticalGalleryView> {
  final _listKey = GlobalKey<State<StatefulWidget>>();
  late final _controller = ScrollController()..addListener(_onScrollChanged);
  late List<ValueNotifier<String>> _notifiers = List.generate(widget.imageCount, (index) => ValueNotifier(''));
  late List<GlobalKey<State<StatefulWidget>>> _listKeys = List.generate(widget.imageCount + 2, (index) => GlobalKey<State<StatefulWidget>>());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _onScrollChanged());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void reload(int index) {
    _notifiers[index].value = DateTime.now().microsecondsSinceEpoch.toString();
    // no need to setState
  }

  void _onScrollChanged() {
    if (_controller.offset == 0) {
      widget.onPageChanged?.call(0);
    } else if (_controller.offset == _controller.position.maxScrollExtent) {
      widget.onPageChanged?.call(widget.imageCount + 1);
    } else {
      var scrollRect = _listKey.currentContext?.findRenderObject()?.getBoundInRootAncestorCoordinate();
      if (scrollRect != null) {
        var index = _getVisibleTargetItemIndex(scrollRect);
        if (index != null) {
          widget.onPageChanged?.call(index);
        }
      }
    }
  }

  Future<void> jumpToPage(int page) async {
    var scrollRect = _listKey.currentContext?.findRenderObject()?.getBoundInRootAncestorCoordinate();
    if (scrollRect != null) {
      if (await _scrollToTargetIndex(scrollRect, page)) {
        // TODO jump no smooth ???
        widget.onPageChanged?.call(page);
      }
    }
  }

  int? _getVisibleTargetItemIndex(Rect scrollRect) {
    int outIndex = -1;
    for (var i = 0; i < widget.imageCount + 2; i++) {
      var itemRect = _listKeys[i].currentContext?.findRenderObject()?.getBoundInRootAncestorCoordinate();
      if (itemRect != null) {
        if (itemRect.top <= scrollRect.top && itemRect.bottom > scrollRect.top) {
          outIndex = i;
          break;
        }
      }
    }
    if (outIndex < 0 || outIndex >= widget.imageCount + 2) {
      return null;
    }
    return outIndex;
  }

  // TODO move _scrollToTargetIndex and manhuagui's _scrollToTargetIndex to flutter_ahlib

  Future<bool> _scrollToTargetIndex(Rect scrollRect, int targetIndex) async {
    Rect? getItemRect(int index) {
      if (index < 0 || index >= widget.imageCount + 2) {
        return null;
      }
      return _listKeys[index].currentContext?.findRenderObject()?.getBoundInRootAncestorCoordinate();
    }

    // automatically scroll the data view, to make sure if the target item rect is not null
    var targetItemRect = getItemRect(targetIndex);
    while (targetItemRect == null) {
      // get current visible item and check validity
      var currIndex = _getVisibleTargetItemIndex(scrollRect) ?? -1;
      if (currIndex < 0) {
        return false; // almost unreachable
      }
      if (currIndex == targetIndex) {
        targetItemRect = getItemRect(targetIndex);
        break; // almost unreachable
      }

      // automatically scroll (almost the real height of scroll view)
      var direction = currIndex > targetIndex ? -1 : 1;
      await _controller.jumpToAndWait(_controller.offset + direction * scrollRect.height * 0.95); // jump and wait for widget building
      if (_controller.offset < 0 || _controller.offset > 500000) {
        return false; // almost unreachable, only for exception
      }
      targetItemRect = getItemRect(targetIndex);
    }
    if (targetItemRect == null) {
      return false; // almost unreachable
    }

    // scroll to target index in new data view style
    await _controller.jumpToAndWait(_controller.offset + targetItemRect.top - scrollRect.top);
    return true;
  }

  @override
  void didUpdateWidget(covariant VerticalGalleryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageCount != oldWidget.imageCount) {
      _notifiers = List.generate(widget.imageCount, (index) => ValueNotifier(''));
      _listKeys = List.generate(widget.imageCount + 2, (index) => GlobalKey<State<StatefulWidget>>());
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
          onTapUp: null /* pageOption.onTapUp */,
          onTapDown: null /* pageOption.onTapDown */,
          onScaleEnd: pageOption.onScaleEnd,
          gestureDetectorBehavior: pageOption.gestureDetectorBehavior,
          tightMode: true /* pageOption.tightMode */,
          filterQuality: pageOption.filterQuality,
          basePosition: pageOption.basePosition,
          disableGestures: true /* pageOption.disableGestures */,
          enablePanAlways: pageOption.enablePanAlways,
          loadingBuilder: pageOption.loadingBuilder ?? widget.loadingBuilder,
          errorBuilder: pageOption.errorBuilder ?? widget.errorBuilder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageMainAxisHintSize = widget.pageMainAxisHintSize ?? MediaQuery.of(context).size.height;
    return ListView(
      key: _listKey,
      controller: _controller,
      padding: EdgeInsets.zero,
      physics: widget.scrollPhysics,
      cacheExtent: widget.preloadPagesCount < 1 ? 0 : pageMainAxisHintSize * widget.preloadPagesCount - 1,
      children: [
        // 1
        Padding(
          key: _listKeys[0],
          padding: EdgeInsets.only(top: 0),
          child: widget.firstPageBuilder(context),
        ),

        // 2
        for (var i = 0; i < widget.imageCount; i++)
          Padding(
            key: _listKeys[i + 1],
            padding: EdgeInsets.only(top: widget.betweenPageSpace),
            child: GestureDetector(
              onLongPress: widget.onImageLongPressed == null ? null : () => widget.onImageLongPressed!(i) /* <<< */,
              onTapDown: widget.onImageTapDown == null ? null : (d) => widget.onImageTapDown!(i, d) /* <<< */,
              onTapUp: widget.onImageTapUp == null ? null : (d) => widget.onImageTapUp!(i, d) /* <<< */,
              child: _buildPhotoItem(context, i),
            ),
          ),

        // 3
        Padding(
          key: _listKeys[widget.imageCount + 1],
          padding: EdgeInsets.only(top: widget.betweenPageSpace),
          child: widget.lastPageBuilder(context),
        ),
      ],
    );
  }
}
