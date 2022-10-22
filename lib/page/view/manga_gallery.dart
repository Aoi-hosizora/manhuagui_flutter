import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/view/extended_gallery.dart';
import 'package:manhuagui_flutter/page/view/image_load.dart';
import 'package:photo_view/photo_view.dart';

/// 漫画画廊展示，在 [MangaViewerPage] 使用
class MangaGalleryView extends StatefulWidget {
  const MangaGalleryView({
    Key? key,
    required this.imageCount,
    required this.imageUrls,
    required this.preloadPagesCount,
    required this.verticalScroll,
    required this.horizontalReverseScroll,
    required this.horizontalViewportFraction,
    required this.verticalViewportPageSpace,
    required this.slideWidthRatio,
    required this.slideHeightRatio,
    required this.onPageChanged, // exclude extra pages, starts from 1
    this.initialImageIndex = 1, // exclude extra pages, starts from 1
    this.onCenterAreaTapped,
    required this.firstPageBuilder, // always the first
    required this.lastPageBuilder, // always the last
    required this.onSaveImage, // exclude extra pages, starts from 1
    required this.onShareImage, // exclude extra pages, starts from 1
  }) : super(key: key);

  final int imageCount;
  final List<String> imageUrls;
  final int preloadPagesCount;
  final bool verticalScroll;
  final bool horizontalReverseScroll;
  final double horizontalViewportFraction;
  final double verticalViewportPageSpace;
  final double slideWidthRatio;
  final double slideHeightRatio;
  final void Function(int imageIndex, bool inFirstExtraPage, bool inLastExtraPage) onPageChanged;
  final int initialImageIndex;
  final void Function()? onCenterAreaTapped;
  final Widget Function(BuildContext) firstPageBuilder;
  final Widget Function(BuildContext) lastPageBuilder;
  final void Function(int imageIndex) onSaveImage;
  final void Function(int imageIndex) onShareImage;

  @override
  State<MangaGalleryView> createState() => MangaGalleryViewState();
}

class MangaGalleryViewState extends State<MangaGalleryView> {
  final CacheManager _cache = DefaultCacheManager();
  final _horizontalGalleryKey = GlobalKey<HorizontalGalleryViewState>();
  final _verticalGalleryKey = GlobalKey<VerticalGalleryViewState>();

  // current page index, include extra pages, starts from 0.
  late var _currentPageIndex = widget.initialImageIndex - 1 + 1;

  // current image index, exclude extra pages, starts from 0.
  int get _currentImageIndex => (_currentPageIndex - 1).clamp(0, widget.imageCount - 1);

  Offset? _pointerDownPosition;

  void _onPointerDown(Offset pos) {
    _pointerDownPosition = pos;
  }

  void _onPointerUp(Offset pos) {
    if (_pointerDownPosition != null && _pointerDownPosition == pos) {
      if (!widget.verticalScroll) {
        var width = MediaQuery.of(context).size.width;
        if (pos.dx < width * widget.slideWidthRatio) {
          _jumpToPage(!widget.horizontalReverseScroll ? _currentPageIndex - 1 : _currentPageIndex + 1); // 上一页 / 下一页(反)
        } else if (pos.dx > width * (1 - widget.slideWidthRatio)) {
          _jumpToPage(!widget.horizontalReverseScroll ? _currentPageIndex + 1 : _currentPageIndex - 1); // 下一页 / 上一页(反)
        } else {
          widget.onCenterAreaTapped?.call();
        }
      } else {
        var height = MediaQuery.of(context).size.height;
        if (pos.dy < height * widget.slideHeightRatio) {
          _jumpToPage(_currentPageIndex - 1); // 上一页
        } else if (pos.dy > height * (1 - widget.slideHeightRatio)) {
          _jumpToPage(_currentPageIndex + 1); // 下一页
        } else {
          widget.onCenterAreaTapped?.call();
        }
      }
    }
    _pointerDownPosition = null;
  }

  void _jumpToPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex <= widget.imageCount + 1) {
      if (!widget.verticalScroll) {
        _horizontalGalleryKey.currentState?.jumpToPage(pageIndex, animated: false);
      } else {
        _verticalGalleryKey.currentState?.jumpToPage(pageIndex, masked: false);
      }
    }
  }

  // jump to image page, exclude extra pages, starts from 1.
  void jumpToImage(int imageIndex, {bool animated = false}) {
    if (imageIndex >= 1 && imageIndex <= widget.imageCount) {
      var pageIndex = imageIndex + 1 - 1; // include extra pages, starts from 0
      if (!widget.verticalScroll) {
        _horizontalGalleryKey.currentState?.jumpToPage(pageIndex, animated: animated);
      } else {
        _verticalGalleryKey.currentState?.jumpToPage(pageIndex, masked: !animated);
      }
    }
  }

  Future<void> _onLongPressed(int index) async {
    await showPopupListMenu(
      context: context,
      title: Text('第${index + 1}页'),
      barrierDismissible: true,
      items: [
        IconTextMenuItem(
          iconText: IconText.simple(Icons.refresh, '重新加载'),
          action: () async {
            await _cache.removeFile(widget.imageUrls[index]);
            if (!widget.verticalScroll) {
              _horizontalGalleryKey.currentState?.reload(index); // exclude extra pages, starts from 0
            } else {
              _verticalGalleryKey.currentState?.reload(index); // exclude extra pages, starts from 0
            }
          },
        ),
        IconTextMenuItem(
          iconText: IconText.simple(Icons.download, '保存该页'),
          action: () => widget.onSaveImage.call(index + 1),
        ),
        IconTextMenuItem(
          iconText: IconText.simple(Icons.share, '分享该页'),
          action: () => widget.onShareImage.call(index + 1),
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
        initialPage: widget.initialImageIndex - 1 + 1,
        viewportFraction: widget.horizontalViewportFraction,
        reverse: widget.horizontalReverseScroll,
        backgroundDecoration: BoxDecoration(color: Colors.black),
        scrollPhysics: AlwaysScrollableScrollPhysics(),
        onPageChanged: (idx) {
          _currentPageIndex = idx;
          widget.onPageChanged.call(_currentImageIndex + 1, idx == 0, idx == widget.imageCount + 1);
        },
        // ****************************************************************
        // 漫画页
        // ****************************************************************
        imagePageBuilder: (c, idx) => ExtendedPhotoGalleryPageOptions(
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained / 2,
          maxScale: PhotoViewComputedScale.covered * 2,
          filterQuality: FilterQuality.high,
          onTapDown: (c, d, v) => _onPointerDown(d.globalPosition),
          onTapUp: (c, d, v) => _onPointerUp(d.globalPosition),
          imageProviderBuilder: (key) => LocalOrCachedNetworkImageProvider.fromNetwork(
            key: key,
            url: widget.imageUrls[idx],
            cacheManager: _cache,
            headers: {
              'User-Agent': USER_AGENT,
              'Referer': REFERER,
            },
          ),
          loadingBuilder: (_, ev) => GestureDetector(
            onTapDown: (d) => _onPointerDown(d.globalPosition),
            onTapUp: (d) => _onPointerUp(d.globalPosition),
            onLongPress: () => _onLongPressed(idx),
            child: ImageLoadingView(
              title: (idx + 1).toString(),
              event: ev,
            ),
          ),
          errorBuilder: (_, err, __) => GestureDetector(
            onTapDown: (d) => _onPointerDown(d.globalPosition),
            onTapUp: (d) => _onPointerUp(d.globalPosition),
            onLongPress: () => _onLongPressed(idx),
            child: ImageLoadFailedView(
              title: (idx + 1).toString(),
              error: err,
            ),
          ),
        ),
        onImageLongPressed: (idx) => _onLongPressed(idx),
        // ****************************************************************
        // 额外页
        // ****************************************************************
        firstPageBuilder: (c) => Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
            maxWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal,
          ),
          child: widget.firstPageBuilder.call(c), // 额外页-开头
        ),
        lastPageBuilder: (c) => Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
            maxWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal,
          ),
          child: widget.lastPageBuilder.call(c), // 额外页-末尾
        ),
      );
    }

    return VerticalGalleryView(
      key: _verticalGalleryKey,
      imageCount: widget.imageCount,
      preloadPagesCount: widget.preloadPagesCount,
      initialPage: widget.initialImageIndex - 1 + 1,
      viewportPageSpace: widget.verticalViewportPageSpace,
      backgroundDecoration: BoxDecoration(color: Colors.black),
      scrollPhysics: AlwaysScrollableScrollPhysics(),
      onPageChanged: (idx) {
        _currentPageIndex = idx;
        widget.onPageChanged.call(_currentImageIndex + 1, idx == 0, idx == widget.imageCount + 1);
      },
      // ****************************************************************
      // 漫画页
      // ****************************************************************
      imagePageBuilder: (c, idx) => ExtendedPhotoGalleryPageOptions(
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained / 2,
        maxScale: PhotoViewComputedScale.covered * 2,
        filterQuality: FilterQuality.high,
        onTapDown: null,
        onTapUp: null,
        imageProviderBuilder: (key) => LocalOrCachedNetworkImageProvider.fromNetwork(
          key: key,
          url: widget.imageUrls[idx],
          cacheManager: _cache,
          headers: {
            'User-Agent': USER_AGENT,
            'Referer': REFERER,
          },
        ),
        loadingBuilder: (_, ev) => GestureDetector(
          onTapDown: (d) => _onPointerDown(d.globalPosition),
          onTapUp: (d) => _onPointerUp(d.globalPosition),
          onLongPress: () => _onLongPressed(idx),
          child: ImageLoadingView(
            title: (idx + 1).toString(),
            event: ev,
          ),
        ),
        errorBuilder: (_, err, ___) => GestureDetector(
          onTapDown: (d) => _onPointerDown(d.globalPosition),
          onTapUp: (d) => _onPointerUp(d.globalPosition),
          onLongPress: () => _onLongPressed(idx),
          child: ImageLoadFailedView(
            title: (idx + 1).toString(),
            error: err,
          ),
        ),
      ),
      onImageTapDown: (d) => _onPointerDown(d.globalPosition),
      onImageTapUp: (d) => _onPointerUp(d.globalPosition),
      onImageLongPressed: (idx) => _onLongPressed(idx),
      // ****************************************************************
      // 额外页
      // ****************************************************************
      firstPageBuilder: (c) => Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal,
        ),
        child: widget.firstPageBuilder.call(c), // 额外页-开头
      ),
      lastPageBuilder: (c) => Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal,
        ),
        child: widget.lastPageBuilder.call(c), // 额外页-末尾
      ),
    );
  }
}
