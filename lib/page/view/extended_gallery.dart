import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/page/view/image_load.dart';
import 'package:photo_view/reloadable_photo_view.dart' as reloadable_photo_view;
import 'package:synchronized/synchronized.dart';

/// 使用 [ExtendedPhotoGallery] 和 [ReloadablePhotoView] 扩展的横向/纵向画廊，在 [MangaGalleryView] 使用
/// (带首页和末页的 GalleryView，允许传入一些界面风格的参数)

class HorizontalGalleryView extends StatefulWidget {
  const HorizontalGalleryView({
    Key? key,
    required this.imageCount, // <<<
    required this.imagePageBuilder, // <<<
    required this.firstPageBuilder, // <<<
    required this.lastPageBuilder, // <<<
    this.onImageLongPressed, // <<< // exclude extra pages, start from 0
    this.fallbackOptions,
    this.onPageChanged, // include extra pages, start from 0
    this.reverse = false,
    this.preloadPagesCount = 0,
    this.initialImageIndex = 0, // <<<
    this.viewportFraction = 1.0, // <<<
  }) : super(key: key);

  final int imageCount;
  final ExtendedPhotoGalleryPageOptions Function(BuildContext context, int imageIndex) imagePageBuilder;
  final Widget Function(BuildContext context) firstPageBuilder;
  final Widget Function(BuildContext context) lastPageBuilder;
  final void Function(int imageIndex)? onImageLongPressed;

  final PhotoViewOptions? fallbackOptions;
  final void Function(int pageIndex)? onPageChanged;
  final bool reverse;
  final int preloadPagesCount;

  final int initialImageIndex;
  final double viewportFraction;

  @override
  State<HorizontalGalleryView> createState() => HorizontalGalleryViewState();
}

class HorizontalGalleryViewState extends State<HorizontalGalleryView> {
  final _key = GlobalKey<ExtendedPhotoGalleryState>();
  late var _controller = PageController(
    initialPage: widget.initialImageIndex + 1,
    viewportFraction: widget.viewportFraction,
  );
  late var _currentPageIndex = widget.initialImageIndex;

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

  /// reload, exclude extra pages, start from 0
  void reload(int imageIndex, {bool alsoEvict = true}) {
    if (imageIndex >= 0 && imageIndex < widget.imageCount) {
      _key.currentState?.reloadPhoto(imageIndex, alsoEvict: alsoEvict);
    }
  }

  /// jumpToPage, include extra pages, start from 0
  void jumpToPage(int pageIndex, {bool animated = false}) {
    if (animated) {
      _controller.defaultAnimateToPage(pageIndex);
    } else {
      _controller.jumpToPage(pageIndex);
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
      callPageChangedAtEnd: true,
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
    required this.imageCount, // <<<
    required this.imagePageBuilder, // <<<
    required this.firstPageBuilder, // <<<
    required this.lastPageBuilder, // <<<
    this.minScale = 1.0, // <<<
    this.maxScale = 1.0, // <<<
    this.onImageTapDown, // <<<
    this.onImageTapUp, // <<<
    this.onImageLongPressed, // <<< // exclude extra pages, start from 0
    this.fallbackOptions,
    this.onPageChanged, // include extra pages, start from 0
    this.preloadPagesCount = 0,
    this.initialImageIndex = 0, // <<<
    this.viewportPageSpace = 0.0, // <<<
    this.pageNoPosition, // <<<
    this.customPageBuilder, // <<<
  }) : super(key: key);

  final int imageCount;
  final ExtendedPhotoGalleryPageOptions Function(BuildContext context, int imageIndex) imagePageBuilder;
  final Widget Function(BuildContext context) firstPageBuilder;
  final Widget Function(BuildContext context) lastPageBuilder;
  final double minScale;
  final double maxScale;
  final void Function(TapDownDetails details)? onImageTapDown;
  final void Function(TapUpDetails details)? onImageTapUp;
  final void Function(int imageIndex)? onImageLongPressed;

  final PhotoViewOptions? fallbackOptions;
  final void Function(int pageIndex)? onPageChanged;
  final int preloadPagesCount;

  final int initialImageIndex;
  final double viewportPageSpace;
  final PageNoPosition? pageNoPosition;
  final Widget Function(BuildContext context, Widget photoView, int imageIndex)? customPageBuilder;

  @override
  State<VerticalGalleryView> createState() => VerticalGalleryViewState();
}

const _kMaskAnimDuration = Duration(milliseconds: 150);

class VerticalGalleryViewState extends State<VerticalGalleryView> {
  late final _controller = ScrollController()..addListener(_onScrollChanged);
  late var _currentPageIndex = widget.initialImageIndex + 1;

  final _firstPageKey = GlobalKey<State<StatefulWidget>>();
  final _lastPageKey = GlobalKey<State<StatefulWidget>>();
  var _firstPageHeight = 0.0;
  var _lastPageHeight = 0.0;

  late final _imagePageKeys = List.generate(widget.imageCount, (_) => GlobalKey<State<StatefulWidget>>());
  late final _imageViewKeys = List.generate(widget.imageCount, (_) => GlobalKey<reloadable_photo_view.ReloadablePhotoViewState>());
  final _imageViewWidgets = <Widget>[];
  late final _imageViewLoaded = List.generate(widget.imageCount, (_) => false);
  late final _imagePageHeights = List.generate(widget.imageCount, (_) => 0.0);

  int get _totalPageCount => widget.imageCount + 2;

  GlobalKey<State<StatefulWidget>> _getPageKey(int pageIndex) => pageIndex == 0
      ? _firstPageKey
      : pageIndex == _totalPageCount - 1
          ? _lastPageKey
          : _imagePageKeys[pageIndex - 1];

  @override
  void initState() {
    super.initState();

    for (var imageIndex = 0; imageIndex < widget.imageCount; imageIndex++) {
      if (imageIndex == widget.initialImageIndex) {
        _imageViewWidgets.add(_buildImageView(context: context, imageIndex: imageIndex));
        _imageViewLoaded[imageIndex] = true;
      } else {
        _imageViewWidgets.add(_buildImageView(context: context, imageIndex: imageIndex, onlyForPlaceholder: true));
      }
    }

    _masking = true;
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      for (var pageIndex = 0; pageIndex < _totalPageCount; pageIndex++) {
        var renderBox = _getPageKey(pageIndex).currentContext?.findRenderBox();
        var height = renderBox != null && renderBox.hasSize ? renderBox.size.height : 0.0;
        if (pageIndex == 0) {
          _firstPageHeight = height;
        } else if (pageIndex == _totalPageCount - 1) {
          _lastPageHeight = height;
        } else {
          _imagePageHeights[pageIndex - 1] = height;
        }
      }

      if (widget.initialImageIndex >= 0 && widget.initialImageIndex < widget.imageCount) {
        await jumpToPage(widget.initialImageIndex + 1, masked: true);
      }
      _masking = false;
      _jumping = false;
      if (mounted) setState(() {});
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
    assert(
      widget.imageCount == oldWidget.imageCount,
      'VerticalGalleryView is not allowed for dynamic image pages! '
      '(previous image count: ${oldWidget.imageCount}, current image count: ${widget.imageCount})',
    );
    if (widget.viewportPageSpace != oldWidget.viewportPageSpace) {
      var pageIndex = _currentPageIndex;
      if (mounted) setState(() {});
      WidgetsBinding.instance?.addPostFrameCallback((_) async {
        for (var imageIndex = 0; imageIndex < widget.imageCount; imageIndex++) {
          var renderBox = _imagePageKeys[imageIndex].currentContext?.findRenderBox();
          var height = renderBox != null && renderBox.hasSize ? renderBox.size.height : 0.0;
          _imagePageHeights[imageIndex] = height; // update image page heights
        }
        await jumpToPage(pageIndex, masked: false); // adjust offset
      });
    }
    if (widget.pageNoPosition != oldWidget.pageNoPosition) {
      for (var imageIndex = 0; imageIndex < widget.imageCount; imageIndex++) {
        _imageViewKeys[imageIndex].currentState?.setState(() {}); // update photo view state
      }
    }
  }

  /// reload, excludes extra page, start from 0
  void reload(int imageIndex, {bool alsoEvict = true}) {
    if (imageIndex >= 0 && imageIndex < widget.imageCount) {
      _imageViewKeys[imageIndex].currentState?.reload(alsoEvict: alsoEvict);
    }
  }

  var _jumping = false;
  var _masking = false;
  final _jumpLock = Lock();

  /// jumpToPage, include extra pages, start from 0
  Future<void> jumpToPage(int pageIndex, {bool masked = false}) async {
    _jumping = true;
    _masking = masked;
    if (mounted) setState(() {});
    if (masked) await Future.delayed(_kMaskAnimDuration);

    var cumulatedOffset = 0.0;
    if (pageIndex > 0) {
      cumulatedOffset += _firstPageHeight;
    }
    for (var imageIndex = 0; imageIndex < widget.imageCount; imageIndex++) {
      if (pageIndex - 1 > imageIndex) {
        cumulatedOffset += _imagePageHeights[imageIndex]; // cumulate offset
      }
    }
    if (pageIndex > _totalPageCount - 1) {
      cumulatedOffset += _lastPageHeight;
    }

    await _jumpLock.synchronized(() async {
      _controller.jumpTo(cumulatedOffset + widget.viewportPageSpace + 1); // <<<
      await WidgetsBinding.instance?.endOfFrame;
    });

    _jumping = false;
    _masking = false;
    if (mounted) setState(() {});

    if (_currentPageIndex != pageIndex) {
      _currentPageIndex = pageIndex;
      widget.onPageChanged?.call(pageIndex);
    }
    _onScrollChanged();
  }

  void _onScrollChanged() {
    if (_jumping) {
      return; // ignore scroll changed when jumping
    }

    // 1. update _currentPageIndex and call onPageChanged (by checking offset and cumulating offset)
    var newPageIndex = 0;
    if (_controller.offset == 0) {
      newPageIndex = 0;
    } else if (_controller.offset == _controller.position.maxScrollExtent) {
      newPageIndex = _totalPageCount - 1;
    } else {
      var currentOffset = _controller.offset;
      var cumulatedOffset = _firstPageHeight;
      var pageIndex = widget.imageCount;
      for (var imageIndex = 0; imageIndex < widget.imageCount; imageIndex++) {
        cumulatedOffset += _imagePageHeights[imageIndex]; // cumulate offset
        if (cumulatedOffset > currentOffset) {
          // <<< itemRect.top <= scrollRect.top && itemRect.bottom > scrollRect.top
          pageIndex = imageIndex + 1;
          break;
        }
      }
      newPageIndex = pageIndex.clamp(1, widget.imageCount);
    }
    if (_currentPageIndex != newPageIndex) {
      _currentPageIndex = newPageIndex;
      widget.onPageChanged?.call(newPageIndex);
    }

    // 2. load current page's neighbor image pages
    var currentImageIndex = _currentPageIndex - 1;
    for (var imageIndex = currentImageIndex - widget.preloadPagesCount; imageIndex <= currentImageIndex + widget.preloadPagesCount; imageIndex++) {
      if (imageIndex >= 0 && imageIndex <= widget.imageCount - 1) {
        if (!_imageViewLoaded[imageIndex]) {
          // <<< load neighbor pages
          // print('Loading image page ${imageIndex + 1}');
          _imageViewWidgets[imageIndex] = _buildImageView(context: context, imageIndex: imageIndex);
          _imageViewLoaded[imageIndex] = true;
        }
      }
    }
    if (mounted) setState(() {});
  }

  Widget _buildImageView({required BuildContext context, required int imageIndex, bool onlyForPlaceholder = false}) {
    if (onlyForPlaceholder) {
      return ImageLoadingView(title: '${imageIndex + 1}', event: null);
    }
    final pageOptions = widget.imagePageBuilder(context, imageIndex); // index excludes non-PhotoView pages
    final options = PhotoViewOptions.merge(pageOptions, widget.fallbackOptions);
    return ClipRect(
      child: reloadable_photo_view.ReloadablePhotoView(
        key: _imageViewKeys[imageIndex],
        imageProviderBuilder: pageOptions.imageProviderBuilder,
        initialScale: options.initialScale,
        minScale: options.minScale,
        maxScale: options.maxScale,
        backgroundDecoration: options.backgroundDecoration,
        filterQuality: options.filterQuality,
        onTapDown: null /* >>> */,
        onTapUp: null /* >>> */,
        loadingBuilder: options.loadingBuilder,
        errorBuilder: options.errorBuilder,
        basePosition: options.basePosition,
        controller: options.controller,
        customSize: options.customSize,
        disableGestures: true /* !!! */,
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
        customBuilder /* <<< this property is added in process_deps.sh */ : (c, view) => widget.customPageBuilder?.call(c, view, imageIndex) ?? view,
        onLoadingStateChanged /* <<< this property is added in process_deps.sh */ : () => WidgetsBinding.instance?.addPostFrameCallback((_) async {
          var renderBox = _imagePageKeys[imageIndex].currentContext?.findRenderBox();
          var newHeight = renderBox != null && renderBox.hasSize ? renderBox.size.height : 0.0;
          var oldHeight = _imagePageHeights[imageIndex];
          if (oldHeight == newHeight) return;
          // print('Image ${imageIndex + 1} new height: $oldHeight -> $newHeight');
          _imagePageHeights[imageIndex] = newHeight;
          if (_currentPageIndex > imageIndex + 1 && newHeight != oldHeight) {
            // <<< some pages before current page has its height changed, need to jump back to the previous offset
            await _jumpLock.synchronized(() async {
              _jumping = true;
              _controller.jumpTo(_controller.offset + (newHeight - oldHeight));
              await WidgetsBinding.instance?.endOfFrame;
              _jumping = false;
            });
          }
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            // PhotoView.customChild(
            panEnabled: true,
            scaleEnabled: true,
            minScale: widget.minScale,
            maxScale: widget.maxScale,
            child: SingleChildScrollView(
              controller: _controller,
              padding: EdgeInsets.zero,
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // 1
                  Padding(
                    key: _firstPageKey,
                    padding: EdgeInsets.only(top: 0),
                    child: widget.firstPageBuilder(context),
                  ),

                  // 2
                  for (var imageIndex = 0; imageIndex < widget.imageCount; imageIndex++)
                    GestureDetector(
                      key: _imagePageKeys[imageIndex],
                      behavior: HitTestBehavior.opaque,
                      onTapDown: widget.onImageTapDown /* <<< */,
                      onTapUp: widget.onImageTapUp /* <<< */,
                      onLongPress: widget.onImageLongPressed == null ? null : () => widget.onImageLongPressed!(imageIndex) /* <<< */,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: imageIndex == 0
                              ? math.max(widget.viewportPageSpace, 10) // for first page (page space must be larger than 10)
                              : widget.viewportPageSpace, // for remaining pages (use viewport page space as top padding)
                        ),
                        child: _imageViewWidgets[imageIndex], // TODO 竖直滚动的 GalleryView 的缩放效果问题待修复
                      ),
                    ),

                  // 3
                  Padding(
                    key: _lastPageKey,
                    padding: EdgeInsets.only(
                      top: math.max(widget.viewportPageSpace, 10), // for last page (page space must be larger than 10)
                    ),
                    child: widget.lastPageBuilder(context),
                  ),
                ],
              ),
            ),
          ),
        ),

        // <<<
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: _kMaskAnimDuration,
            child: !_masking
                ? const SizedBox.shrink()
                : Container(
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: 50,
                      width: 50,
                      child: Padding(
                        padding: EdgeInsets.all(4.5 / 2),
                        child: CircularProgressIndicator(
                          strokeWidth: 4.5,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
