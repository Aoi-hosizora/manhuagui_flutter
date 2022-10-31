import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:photo_view/photo_view.dart';

class HorizontalGalleryView extends StatefulWidget {
  const HorizontalGalleryView({
    Key? key,
    required this.imageCount /* <<< */,
    required this.imagePageBuilder /* <<< */,
    required this.firstPageBuilder /* <<< */,
    required this.lastPageBuilder /* <<< */,
    this.onImageLongPressed /* <<< */,
    this.backgroundDecoration,
    this.wantKeepAlive = false,
    this.gaplessPlayback = false,
    this.reverse = false,
    this.initialPage = 0 /* <<< */,
    this.onPageChanged,
    this.viewportFraction = 1.0 /* <<< */,
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
  final void Function(int index)? onImageLongPressed;
  final ScrollPhysics? scrollPhysics;
  final BoxDecoration? backgroundDecoration;
  final bool wantKeepAlive;
  final bool gaplessPlayback;
  final bool reverse;
  final int initialPage;
  final void Function(int index)? onPageChanged;
  final double viewportFraction;
  final ValueChanged<PhotoViewScaleState>? scaleStateChangedCallback;
  final bool enableRotation;
  final Size? customSize;
  final LoadingPlaceholderBuilder? loadingBuilder;
  final ErrorPlaceholderBuilder? errorBuilder;
  final double? pageMainAxisHintSize;
  final int preloadPagesCount;

  @override
  State<HorizontalGalleryView> createState() => HorizontalGalleryViewState();
}

class HorizontalGalleryViewState extends State<HorizontalGalleryView> {
  final _key = GlobalKey<ExtendedPhotoGalleryState>();
  late var _controller = PageController(
    initialPage: widget.initialPage,
    viewportFraction: widget.viewportFraction,
  );
  late var _currentPageIndex = widget.initialPage;

  @override
  void didUpdateWidget(covariant HorizontalGalleryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewportFraction != oldWidget.viewportFraction) {
      var oldController = _controller;
      _controller = PageController(
        initialPage: _currentPageIndex,
        viewportFraction: widget.viewportFraction,
      );
      WidgetsBinding.instance?.addPostFrameCallback((_) => oldController.dispose());
    }
  }

  void reload(int page) {
    _key.currentState?.reload(page);
  }

  void jumpToPage(int page, {bool animated = false}) {
    if (animated) {
      _controller.defaultAnimateToPage(page);
    } else {
      _controller.jumpToPage(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedPhotoGallery.advanced(
      key: _key,
      pageCount: widget.imageCount + 2,
      builder: widget.imagePageBuilder,
      advancedBuilder: (c, index, builder) {
        if (index == 0) {
          return widget.firstPageBuilder(c);
        }
        if (index == widget.imageCount + 1) {
          return widget.lastPageBuilder(c);
        }
        return GestureDetector(
          onLongPress: widget.onImageLongPressed == null ? null : () => widget.onImageLongPressed!(index - 1),
          child: builder(c, index - 1),
        );
      },
      backgroundDecoration: widget.backgroundDecoration,
      wantKeepAlive: widget.wantKeepAlive,
      gaplessPlayback: widget.gaplessPlayback,
      reverse: widget.reverse,
      pageController: _controller,
      onPageChanged: (i) {
        _currentPageIndex = i;
        widget.onPageChanged?.call(i);
      },
      changePageWhenFinished: true,
      keepViewportMainAxisSize: true,
      fractionWidthFactor: null,
      fractionHeightFactor: null,
      scaleStateChangedCallback: widget.scaleStateChangedCallback,
      enableRotation: widget.enableRotation,
      scrollPhysics: widget.scrollPhysics,
      scrollDirection: Axis.horizontal,
      customSize: widget.customSize,
      loadingBuilder: widget.loadingBuilder,
      errorBuilder: widget.errorBuilder,
      pageMainAxisHintSize: widget.pageMainAxisHintSize,
      preloadPagesCount: widget.preloadPagesCount,
    );
  }
}

class VerticalGalleryView extends StatefulWidget {
  const VerticalGalleryView({
    Key? key,
    required this.imageCount /* <<< */,
    required this.imagePageBuilder /* <<< */,
    required this.firstPageBuilder /* <<< */,
    required this.lastPageBuilder /* <<< */,
    this.onImageTapDown /* <<< */,
    this.onImageTapUp /* <<< */,
    this.onImageLongPressed /* <<< */,
    this.backgroundDecoration,
    this.wantKeepAlive = false,
    this.gaplessPlayback = false,
    this.initialPage = 0 /* <<< */,
    this.onPageChanged,
    this.viewportPageSpace = 0.0 /* <<< */,
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
  final void Function(TapDownDetails details)? onImageTapDown;
  final void Function(TapUpDetails details)? onImageTapUp;
  final void Function(int index)? onImageLongPressed;
  final BoxDecoration? backgroundDecoration;
  final bool wantKeepAlive;
  final bool gaplessPlayback;
  final int initialPage;
  final void Function(int)? onPageChanged;
  final double viewportPageSpace;
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

const _kMaskDuration = Duration(milliseconds: 150);

class VerticalGalleryViewState extends State<VerticalGalleryView> {
  final _listKey = GlobalKey<State<StatefulWidget>>();
  late final _controller = ScrollController()..addListener(_onScrollChanged);
  late List<ValueNotifier<String>> _notifiers = List.generate(widget.imageCount, (index) => ValueNotifier(''));
  late List<GlobalKey<State<StatefulWidget>>> _itemKeys = List.generate(widget.imageCount + 2, (index) => GlobalKey<State<StatefulWidget>>());

  @override
  void initState() {
    super.initState();
    _masking = true;
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      if (widget.initialPage > 0) {
        await jumpToPage(widget.initialPage, masked: true);
      }
      _masking = false;
      if (mounted) setState(() {});
      _onScrollChanged();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VerticalGalleryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageCount != oldWidget.imageCount) {
      _notifiers = List.generate(widget.imageCount, (index) => ValueNotifier(''));
      _itemKeys = List.generate(widget.imageCount + 2, (index) => GlobalKey<State<StatefulWidget>>());
    }
  }

  void reload(int index) {
    _notifiers[index].value = DateTime.now().microsecondsSinceEpoch.toString();
    // no need to setState
  }

  void _onScrollChanged() {
    if (_jumping) {
      return;
    }
    if (_controller.offset == 0) {
      widget.onPageChanged?.call(0);
    } else if (_controller.offset == _controller.position.maxScrollExtent) {
      widget.onPageChanged?.call(widget.imageCount + 1);
    } else {
      var scrollRect = _ScrollHelper.getScrollViewRect(_listKey);
      if (scrollRect != null) {
        var index = _ScrollHelper.getVisibleTargetItemIndex(_itemKeys, scrollRect);
        if (index != null) {
          widget.onPageChanged?.call(index);
        }
      }
    }
  }

  var _jumping = false;
  var _masking = false;

  Future<void> jumpToPage(int page, {bool masked = false}) async {
    var scrollRect = _ScrollHelper.getScrollViewRect(_listKey);
    if (scrollRect == null) {
      return;
    }

    _jumping = true;
    _masking = masked;
    if (mounted) setState(() {});
    await Future.delayed(_kMaskDuration);
    var ok = await _ScrollHelper.scrollToTargetIndex(_itemKeys, scrollRect, _controller, page, widget.viewportPageSpace);
    _jumping = false;
    _masking = false;
    if (mounted) setState(() {});
    if (ok) {
      widget.onPageChanged?.call(page);
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
    final pageMainAxisHintSize = widget.pageMainAxisHintSize ?? MediaQuery.of(context).size.height; // using this height is inaccuracy
    return Stack(
      children: [
        Positioned.fill(
          child: ListView(
            key: _listKey,
            controller: _controller,
            padding: EdgeInsets.zero,
            physics: widget.scrollPhysics,
            cacheExtent: widget.preloadPagesCount < 1 ? 0 : pageMainAxisHintSize * widget.preloadPagesCount - 1,
            children: [
              // 1
              Padding(
                key: _itemKeys[0],
                padding: EdgeInsets.only(top: 0),
                child: widget.firstPageBuilder(context),
              ),

              // 2
              for (var i = 0; i < widget.imageCount; i++)
                GestureDetector(
                  key: _itemKeys[i + 1],
                  behavior: HitTestBehavior.opaque,
                  onTapDown: widget.onImageTapDown /* <<< */,
                  onTapUp: widget.onImageTapUp /* <<< */,
                  onLongPress: widget.onImageLongPressed == null ? null : () => widget.onImageLongPressed!(i) /* <<< */,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: i == 0
                          ? math.max(widget.viewportPageSpace, 10) // for first page, space must be larger than 10
                          : widget.viewportPageSpace /* for remaining pages */,
                    ),
                    child: _buildPhotoItem(context, i),
                  ),
                ),

              // 3
              Padding(
                key: _itemKeys[widget.imageCount + 1],
                padding: EdgeInsets.only(
                  top: math.max(widget.viewportPageSpace, 10), // for last page, space must be larger than 10
                ),
                child: widget.lastPageBuilder(context),
              ),
            ],
          ),
        ),

        // <<<
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: _kMaskDuration,
            child: !_masking
                ? SizedBox(height: 0)
                : Container(
                    decoration: widget.backgroundDecoration,
                    child: Center(
                      child: SizedBox(
                        height: 50,
                        width: 50,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ScrollHelper {
  static Rect? getScrollViewRect<T extends State>(GlobalKey<T> key) {
    var scrollRect = key.currentContext?.findRenderObject()?.getBoundInRootAncestorCoordinate();
    return scrollRect;
  }

  static int? getVisibleTargetItemIndex<T extends State>(List<GlobalKey<T>> itemKeys, Rect scrollRect) {
    int outIndex = -1;
    for (var i = 0; i < itemKeys.length; i++) {
      var itemRect = itemKeys[i].currentContext?.findRenderObject()?.getBoundInRootAncestorCoordinate();
      if (itemRect != null) {
        if (itemRect.top <= scrollRect.top && itemRect.bottom > scrollRect.top) {
          outIndex = i;
          break;
        }
      }
    }
    if (outIndex < 0 || outIndex >= itemKeys.length) {
      return null;
    }
    return outIndex;
  }

  static Future<bool> scrollToTargetIndex<T extends State>(
    List<GlobalKey<T>> itemKeys,
    Rect scrollRect,
    ScrollController controller,
    int targetIndex, [
    double additionalOffset = 0,
  ]) async {
    Rect? getItemRect(int index) {
      if (index < 0 || index >= itemKeys.length) {
        return null;
      }
      return itemKeys[index].currentContext?.findRenderObject()?.getBoundInRootAncestorCoordinate();
    }

    // automatically scroll the data view, to make sure if the target item rect is not null
    var targetItemRect = getItemRect(targetIndex);
    while (targetItemRect == null) {
      // get current visible item and check validity
      var currIndex = getVisibleTargetItemIndex(itemKeys, scrollRect) ?? -1;
      if (currIndex < 0) {
        return false; // almost unreachable
      }
      if (currIndex == targetIndex) {
        targetItemRect = getItemRect(targetIndex);
        break; // almost unreachable
      }

      // automatically scroll (almost the real height of scroll view)
      var direction = currIndex > targetIndex ? -1 : 1;
      await controller.jumpToAndWait(controller.offset + direction * scrollRect.height * 0.95); // jump and wait for widget building
      if (controller.offset < 0 || controller.offset > 500000) {
        return false; // almost unreachable, only for exception
      }
      targetItemRect = getItemRect(targetIndex);
    }
    if (targetItemRect == null) {
      return false; // almost unreachable
    }

    // scroll to target index in new data view style
    await controller.jumpToAndWait(controller.offset + targetItemRect.top - scrollRect.top + additionalOffset + 1);
    return true;
  }
}
