import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/view/extended_gallery.dart';
import 'package:manhuagui_flutter/page/view/image_load.dart';
import 'package:photo_view/photo_view.dart';

/// 使用 [HorizontalGalleryView] 和 [VerticalGalleryView] 构建的漫画画廊，在 [MangaViewerPage] 使用
/// (仅负责部分交互逻辑的实现，业务逻辑不在此处实现)
class MangaGalleryView extends StatefulWidget {
  const MangaGalleryView({
    Key? key,
    required this.imageCount,
    required this.imageUrlFutures,
    required this.imageFileFutures,
    required this.networkTimeout,
    required this.preloadPagesCount,
    required this.verticalScroll,
    required this.horizontalReverseScroll,
    required this.horizontalViewportFraction,
    required this.verticalViewportPageSpace,
    required this.verticalPageNoPosition,
    required this.slideWidthRatio,
    required this.slideHeightRatio,
    required this.onPageChanged, // exclude extra pages, start from 0
    this.initialImageIndex = 0, // exclude extra pages, start from 0
    required this.fileAndUrlNotFoundMessage,
    required this.onLongPressed, // exclude extra pages, start from 0
    required this.onCenterAreaTapped, // exclude extra pages, start from 0
    required this.mediaQueryPadding,
    this.pageBuilderData,
    required this.firstPageBuilder,
    required this.lastPageBuilder,
  }) : super(key: key);

  final int imageCount;
  final List<Future<String?>> imageUrlFutures;
  final List<Future<File?>> imageFileFutures;
  final Duration? networkTimeout;
  final int preloadPagesCount;
  final bool verticalScroll;
  final bool horizontalReverseScroll;
  final double horizontalViewportFraction;
  final double verticalViewportPageSpace;
  final PageNoPosition verticalPageNoPosition;
  final double slideWidthRatio;
  final double slideHeightRatio;
  final void Function(int imageIndex, bool inFirstExtraPage, bool inLastExtraPage) onPageChanged;
  final int initialImageIndex;
  final String fileAndUrlNotFoundMessage;
  final void Function(int imageIndex) onLongPressed;
  final void Function(int imageIndex) onCenterAreaTapped;
  final EdgeInsets mediaQueryPadding;
  final dynamic pageBuilderData;
  final Widget Function(BuildContext, dynamic) firstPageBuilder;
  final Widget Function(BuildContext, dynamic) lastPageBuilder;

  @override
  State<MangaGalleryView> createState() => MangaGalleryViewState();
}

class MangaGalleryViewState extends State<MangaGalleryView> {
  final _cache = DefaultCacheManager();
  final _horizontalGalleryKey = GlobalKey<HorizontalGalleryViewState>();
  final _verticalGalleryKey = GlobalKey<VerticalGalleryViewState>();

  // current page index, include extra pages, start from 0.
  late var _currentPageIndex = widget.initialImageIndex + 1;

  // current image index, exclude extra pages, start from 0.
  int get _currentImageIndex => (_currentPageIndex - 1).clamp(0, widget.imageCount - 1);

  void _onPageChanged(int pageIndex) {
    _currentPageIndex = pageIndex; // include extra pages, start from 0
    widget.onPageChanged.call(
      _currentImageIndex, // exclude extra pages, start from 0
      pageIndex == 0,
      pageIndex == widget.imageCount + 1,
    );
  }

  @override
  void didUpdateWidget(covariant MangaGalleryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.verticalScroll != oldWidget.verticalScroll) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        _onPageChanged(_currentPageIndex); // include extra pages, start from 0
      });
    }
    if (widget.verticalScroll && widget.verticalViewportPageSpace != oldWidget.verticalViewportPageSpace) {
      // done by VerticalGalleryView, ignore
    }
    if (widget.verticalScroll && widget.verticalPageNoPosition != oldWidget.verticalPageNoPosition) {
      // not be done by VerticalGalleryView, do updating here
      for (int imageIndex = 0; imageIndex < widget.imageCount; imageIndex++) {
        _verticalGalleryKey.currentState?.updateImagePageState(imageIndex); // <<< update photo view state manually
      }
    }
  }

  Offset? _pointerDownPosition;

  void _onPointerDown(Offset pos) {
    _pointerDownPosition = pos;
  }

  void _onPointerUp(Offset pos) {
    if (_pointerDownPosition != null && _pointerDownPosition == pos) {
      if (!widget.verticalScroll) {
        var width = MediaQuery.of(context).size.width;
        if (pos.dx < width * widget.slideWidthRatio) {
          jumpToPage(!widget.horizontalReverseScroll ? _currentPageIndex - 1 : _currentPageIndex + 1); // 上一页 / 下一页(反)
        } else if (pos.dx > width * (1 - widget.slideWidthRatio)) {
          jumpToPage(!widget.horizontalReverseScroll ? _currentPageIndex + 1 : _currentPageIndex - 1); // 下一页 / 上一页(反)
        } else {
          widget.onCenterAreaTapped.call(_currentImageIndex);
        }
      } else {
        var height = MediaQuery.of(context).size.height;
        if (pos.dy < height * widget.slideHeightRatio) {
          jumpToPage(_currentPageIndex - 1); // 上一页
        } else if (pos.dy > height * (1 - widget.slideHeightRatio)) {
          jumpToPage(_currentPageIndex + 1); // 下一页
        } else {
          widget.onCenterAreaTapped.call(_currentImageIndex);
        }
      }
    }
    _pointerDownPosition = null;
  }

  /// jumpToPage, include extra pages, start from 0.
  void jumpToPage(int pageIndex, {bool animated = false}) {
    if (pageIndex >= 0 && pageIndex < widget.imageCount + 2) {
      if (!widget.verticalScroll) {
        _horizontalGalleryKey.currentState?.jumpToPage(pageIndex, animated: animated);
      } else {
        _verticalGalleryKey.currentState?.jumpToPage(pageIndex, animated: animated, masked: false);
      }
    }
  }

  /// jumpToImage, exclude extra pages, start from 0.
  void jumpToImage(int imageIndex, {bool animated = false}) {
    if (imageIndex >= 0 && imageIndex < widget.imageCount) {
      var pageIndex = imageIndex + 1; // include extra pages, start from 0
      if (!widget.verticalScroll) {
        _horizontalGalleryKey.currentState?.jumpToPage(pageIndex, animated: animated);
      } else {
        _verticalGalleryKey.currentState?.jumpToPage(pageIndex, animated: animated, masked: false);
      }
    }
  }

  /// getPageHeight, include extra pages, start from 0.
  double getPageHeight(int pageIndex, {bool safeArea = true}) {
    if (!widget.verticalScroll) {
      return MediaQuery.of(context).size.height - (safeArea ? widget.mediaQueryPadding.vertical : 0 /* no need to minus if fullscreen */);
    }
    return (_verticalGalleryKey.currentState?.getPageHeight(pageIndex) ?? 0);
  }

  /// updatePageHeight, include extra pages, start from 0 (only for vertical scrolling).
  void updatePageHeight(int pageIndex) {
    if (widget.verticalScroll) {
      _verticalGalleryKey.currentState?.updatePageHeight(pageIndex);
    }
  }

  /// reloadImage, exclude extra pages, start from 0.
  void reloadImage(int imageIndex) async {
    if (imageIndex >= 0 && imageIndex < widget.imageCount) {
      await (await widget.imageUrlFutures[imageIndex])?.let((url) async {
        await _cache.removeFile(url);
      });
      if (!widget.verticalScroll) {
        _horizontalGalleryKey.currentState?.reload(imageIndex /* pass image index */, alsoEvict: true);
      } else {
        _verticalGalleryKey.currentState?.reload(imageIndex /* pass image index */, alsoEvict: true);
      }
    }
  }

  // for constructing ImageLoadFailedView.
  String? _imageErrorFormatter(dynamic error) {
    // Image file "/storage/emulated/0/Manhuagui/manhuagui_download/39793/620266/0005.webp" is not found while given url is null.
    if (error is LoadImageException && error.type == LoadImageExceptionType.notExistedFileNullUrl) {
      return widget.fileAndUrlNotFoundMessage; // 该页尚未下载，且未获取到该页的链接
    }
    return null;
  }

  // for customPageBuilder, only for VerticalGalleryView, need to update states manually.
  Widget _buildPageWithPageNumber(BuildContext context, Widget photoView, int imageIndex) {
    var pos = widget.verticalPageNoPosition;
    double? left, right, top, bottom;
    switch (pos) {
      case PageNoPosition.hide:
        return photoView;
      case PageNoPosition.topLeft:
        left = 0.0;
        top = 0.0;
        break;
      case PageNoPosition.topCenter:
        left = 0.0;
        right = 0.0;
        top = 0.0;
        break;
      case PageNoPosition.topRight:
        right = 0.0;
        top = 0.0;
        break;
      case PageNoPosition.bottomLeft:
        left = 0.0;
        bottom = 0.0;
        break;
      case PageNoPosition.bottomCenter:
        left = 0.0;
        right = 0.0;
        bottom = 0.0;
        break;
      case PageNoPosition.bottomRight:
        right = 0.0;
        bottom = 0.0;
        break;
    }
    return Stack(
      children: [
        Center(child: photoView),
        Positioned(
          left: left,
          right: right,
          top: top,
          bottom: bottom,
          child: Center(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              child: Text(
                '${imageIndex + 1}',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.verticalScroll) {
      return HorizontalGalleryView(
        key: _horizontalGalleryKey,
        imageCount: widget.imageCount,
        preloadPagesCount: widget.preloadPagesCount,
        initialPageIndex: _currentPageIndex /* include extra pages, start from 0 */,
        viewportFraction: widget.horizontalViewportFraction,
        reverse: widget.horizontalReverseScroll,
        onPageChanged: _onPageChanged /* include extra pages, start from 0 */,
        // ****************************************************************
        // 漫画页
        // ****************************************************************
        imagePageBuilder: (c, imageIndex) => ExtendedPhotoGalleryPageOptions(
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained / 2,
          maxScale: 1.5,
          backgroundDecoration: BoxDecoration(color: Colors.black),
          filterQuality: FilterQuality.high,
          onTapDown: (c, d, v) => _onPointerDown(d.globalPosition),
          onTapUp: (c, d, v) => _onPointerUp(d.globalPosition),
          imageProviderBuilder: (key) => LocalOrCachedNetworkImageProvider.fromFutures(
            key: key,
            urlFuture: widget.imageUrlFutures[imageIndex],
            headers: {'User-Agent': USER_AGENT, 'Referer': REFERER},
            cacheManager: _cache,
            networkTimeout: widget.networkTimeout,
            fileFuture: widget.imageFileFutures[imageIndex],
            fileMustExist: false, // <<<
          ),
          loadingBuilder: (_, ev) => GestureDetector(
            onTapDown: (d) => _onPointerDown(d.globalPosition),
            onTapUp: (d) => _onPointerUp(d.globalPosition),
            onLongPress: () => widget.onLongPressed.call(imageIndex),
            behavior: HitTestBehavior.opaque,
            child: ImageLoadingView(
              title: (imageIndex + 1).toString(),
              event: ev,
            ),
          ),
          errorBuilder: (_, err, __) => GestureDetector(
            onTapDown: (d) => _onPointerDown(d.globalPosition),
            onTapUp: (d) => _onPointerUp(d.globalPosition),
            onLongPress: () => widget.onLongPressed.call(imageIndex),
            behavior: HitTestBehavior.opaque,
            child: ImageLoadFailedView(
              title: (imageIndex + 1).toString(),
              error: err,
              errorFormatter: _imageErrorFormatter,
            ),
          ),
        ),
        onImageLongPressed: (imageIndex) => widget.onLongPressed.call(imageIndex),
        // ****************************************************************
        // 额外页
        // ****************************************************************
        firstPageBuilder: (c) => Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height - widget.mediaQueryPadding.vertical,
            maxWidth: MediaQuery.of(context).size.width - widget.mediaQueryPadding.horizontal,
          ),
          child: SingleChildScrollView(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onCenterAreaTapped.call(-1),
              child: widget.firstPageBuilder.call(c, widget.pageBuilderData), // 额外页-开头
            ),
          ),
        ),
        lastPageBuilder: (c) => Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height - widget.mediaQueryPadding.vertical,
            maxWidth: MediaQuery.of(context).size.width - widget.mediaQueryPadding.horizontal,
          ),
          child: SingleChildScrollView(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onCenterAreaTapped.call(widget.imageCount),
              child: widget.lastPageBuilder.call(c, widget.pageBuilderData), // 额外页-末尾
            ),
          ),
        ),
      );
    }

    return VerticalGalleryView(
      key: _verticalGalleryKey,
      imageCount: widget.imageCount,
      preloadPagesCount: widget.preloadPagesCount,
      initialPageIndex: _currentPageIndex /* include extra pages, start from 0 */,
      viewportPageSpace: widget.verticalViewportPageSpace,
      onPageChanged: _onPageChanged /* include extra pages, start from 0 */,
      // ****************************************************************
      // 漫画页
      // ****************************************************************
      minScale: 1.0,
      maxScale: 2.5,
      imagePageBuilder: (c, imageIndex) => ExtendedPhotoGalleryPageOptions(
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained / 2,
        maxScale: 1.5,
        backgroundDecoration: BoxDecoration(color: Colors.black),
        filterQuality: FilterQuality.high,
        onTapDown: null /* >>> */,
        onTapUp: null /* >>> */,
        imageProviderBuilder: (key) => LocalOrCachedNetworkImageProvider.fromFutures(
          key: key,
          urlFuture: widget.imageUrlFutures[imageIndex],
          headers: {'User-Agent': USER_AGENT, 'Referer': REFERER},
          cacheManager: _cache,
          networkTimeout: widget.networkTimeout,
          fileFuture: widget.imageFileFutures[imageIndex],
          fileMustExist: false,
        ),
        loadingBuilder: (_, ev) => GestureDetector(
          onTapDown: (d) => _onPointerDown(d.globalPosition),
          onTapUp: (d) => _onPointerUp(d.globalPosition),
          onLongPress: () => widget.onLongPressed.call(imageIndex),
          behavior: HitTestBehavior.opaque,
          child: ImageLoadingView(
            title: (imageIndex + 1).toString(),
            event: ev,
          ),
        ),
        errorBuilder: (_, err, ___) => GestureDetector(
          onTapDown: (d) => _onPointerDown(d.globalPosition),
          onTapUp: (d) => _onPointerUp(d.globalPosition),
          onLongPress: () => widget.onLongPressed.call(imageIndex),
          behavior: HitTestBehavior.opaque,
          child: ImageLoadFailedView(
            title: (imageIndex + 1).toString(),
            error: err,
            errorFormatter: _imageErrorFormatter,
          ),
        ),
      ),
      onImageTapDown: (d) => _onPointerDown(d.globalPosition) /* <<< */,
      onImageTapUp: (d) => _onPointerUp(d.globalPosition) /* <<< */,
      onImageLongPressed: (imageIndex) => widget.onLongPressed.call(imageIndex),
      customPageBuilder: _buildPageWithPageNumber,
      // ****************************************************************
      // 额外页
      // ****************************************************************
      firstPageBuilder: (c) => Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - widget.mediaQueryPadding.horizontal,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onCenterAreaTapped.call(-1),
          child: widget.firstPageBuilder.call(c, widget.pageBuilderData), // 额外页-开头
        ),
      ),
      lastPageBuilder: (c) => Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - widget.mediaQueryPadding.horizontal,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onCenterAreaTapped.call(widget.imageCount),
          child: widget.lastPageBuilder.call(c, widget.pageBuilderData), // 额外页-末尾
        ),
      ),
    );
  }
}
