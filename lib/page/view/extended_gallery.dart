import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

/// 使用 [ExtendedPhotoGallery] 和 [ReloadablePhotoView] 扩展的横向/纵向画廊展示，在 [MangaGalleryView] 使用

class HorizontalGalleryView extends StatefulWidget {
  const HorizontalGalleryView({
    Key? key,
    required this.imageCount /* <<< */,
    required this.imagePageBuilder /* <<< */,
    required this.firstPageBuilder /* <<< */,
    required this.lastPageBuilder /* <<< */,
    this.onImageLongPressed /* <<< */,
    this.fallbackOptions,
    this.onPageChanged,
    this.reverse = false,
    this.preloadPagesCount = 0,
    this.initialPage = 0 /* <<< */,
    this.viewportFraction = 1.0 /* <<< */,
  }) : super(key: key);

  final int imageCount;
  final ExtendedPhotoGalleryPageOptions Function(BuildContext, int) imagePageBuilder;
  final Widget Function(BuildContext context) firstPageBuilder;
  final Widget Function(BuildContext context) lastPageBuilder;
  final void Function(int index)? onImageLongPressed;

  final PhotoViewOptions? fallbackOptions;
  final void Function(int index)? onPageChanged;
  final bool reverse;
  final int preloadPagesCount;

  final int initialPage;
  final double viewportFraction;

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
    _key.currentState?.reloadPhoto(page);
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
        // 0 => first
        // 1 ~ l => images
        // l+1 => last
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
      fallbackOptions: widget.fallbackOptions,
      onPageChanged: (i) {
        _currentPageIndex = i;
        widget.onPageChanged?.call(i);
      },
      pageController: _controller,
      reverse: widget.reverse,
      scrollDirection: Axis.horizontal,
      scrollPhysics: AlwaysScrollableScrollPhysics(),
      changePageWhenFinished: true,
      keepViewportMainAxisSize: true,
      fractionWidthFactor: null,
      fractionHeightFactor: null,
      pageMainAxisHintSize: null,
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
    this.fallbackOptions,
    this.onPageChanged,
    this.preloadPagesCount = 0,
    this.initialPage = 0 /* <<< */,
    this.viewportPageSpace = 0.0 /* <<< */,
  }) : super(key: key);

  final int imageCount;
  final ExtendedPhotoGalleryPageOptions Function(BuildContext, int) imagePageBuilder;
  final Widget Function(BuildContext context) firstPageBuilder;
  final Widget Function(BuildContext context) lastPageBuilder;
  final void Function(TapDownDetails details)? onImageTapDown;
  final void Function(TapUpDetails details)? onImageTapUp;
  final void Function(int index)? onImageLongPressed;

  final PhotoViewOptions? fallbackOptions;
  final void Function(int)? onPageChanged;
  final int preloadPagesCount;

  final int initialPage;
  final double viewportPageSpace;

  @override
  State<VerticalGalleryView> createState() => VerticalGalleryViewState();
}

const _kMaskDuration = Duration(milliseconds: 150);

class VerticalGalleryViewState extends State<VerticalGalleryView> {
  late final _controller = ScrollController()..addListener(_onScrollChanged);
  late var _photoViewKeys = List.generate(widget.imageCount, (index) => GlobalKey<ReloadablePhotoViewState>());

  final _listKey = GlobalKey<State<StatefulWidget>>();
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
      _photoViewKeys = List.generate(widget.imageCount, (index) => GlobalKey<ReloadablePhotoViewState>());
      _itemKeys = List.generate(widget.imageCount + 2, (index) => GlobalKey<State<StatefulWidget>>());
    }
  }

  void reload(int index) {
    if (index >= 0 && index < widget.imageCount) {
      _photoViewKeys[index].currentState?.reload();
    }
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

    // TODO not accurate !!!
    var ok = await _ScrollHelper.scrollToTargetIndex(_itemKeys, scrollRect, _controller, page, widget.viewportPageSpace);
    _jumping = false;
    _masking = false;
    if (mounted) setState(() {});
    if (ok) {
      widget.onPageChanged?.call(page);
    }
  }

  Widget _buildPhotoItem(BuildContext context, int index) {
    final pageOptions = widget.imagePageBuilder(context, index); // index excludes non-PhotoView pages
    final options = PhotoViewOptions.merge(pageOptions, widget.fallbackOptions);
    return ClipRect(
      child: ReloadablePhotoView(
        key: _photoViewKeys[index],
        imageProviderBuilder: pageOptions.imageProviderBuilder,
        initialScale: options.initialScale,
        minScale: options.minScale,
        maxScale: options.maxScale,
        backgroundDecoration: options.backgroundDecoration,
        filterQuality: options.filterQuality,
        onTapDown: null,
        onTapUp: null,
        loadingBuilder: options.loadingBuilder,
        errorBuilder: options.errorBuilder,
        basePosition: options.basePosition,
        controller: options.controller,
        customSize: options.customSize,
        disableGestures: true,
        enablePanAlways: options.enablePanAlways,
        enableRotation: options.enableRotation,
        gaplessPlayback: options.gaplessPlayback,
        gestureDetectorBehavior: options.gestureDetectorBehavior,
        heroAttributes: options.heroAttributes,
        onScaleEnd: options.onScaleEnd,
        scaleStateController: options.scaleStateController,
        scaleStateChangedCallback: options.scaleStateChangedCallback,
        scaleStateCycle: options.scaleStateCycle,
        tightMode: true,
        wantKeepAlive: options.wantKeepAlive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ListView(
            key: _listKey,
            controller: _controller,
            padding: EdgeInsets.zero,
            physics: AlwaysScrollableScrollPhysics(),
            cacheExtent: widget.preloadPagesCount < 1
                ? 0 //
                : MediaQuery.of(context).size.height * widget.preloadPagesCount - 1 /* using this height is inaccuracy */,
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
                ? const SizedBox.shrink()
                : Container(
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: 50,
                      width: 50,
                      child: CircularProgressIndicator(),
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
    var scrollRect = key.currentContext?.findRenderObject()?.getBoundInAncestorCoordinate();
    return scrollRect;
  }

  static int? getVisibleTargetItemIndex<T extends State>(List<GlobalKey<T>> itemKeys, Rect scrollRect) {
    int outIndex = -1;
    for (var i = 0; i < itemKeys.length; i++) {
      var itemRect = itemKeys[i].currentContext?.findRenderObject()?.getBoundInAncestorCoordinate();
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
      return itemKeys[index].currentContext?.findRenderObject()?.getBoundInAncestorCoordinate();
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
      controller.jumpTo(controller.offset + direction * scrollRect.height * 0.95); // jump and wait for widget building
      await WidgetsBinding.instance?.endOfFrame; // TODO not accurate, add duration ???
      if (controller.offset < 0 || controller.offset > 500000) {
        return false; // almost unreachable, only for exception
      }
      targetItemRect = getItemRect(targetIndex);
    }
    if (targetItemRect == null) {
      return false; // almost unreachable
    }

    // scroll to target index in new data view style
    controller.jumpTo(controller.offset + targetItemRect.top - scrollRect.top + additionalOffset + 1);
    await WidgetsBinding.instance?.endOfFrame;
    return true;
  }
}
