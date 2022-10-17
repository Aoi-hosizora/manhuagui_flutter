import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/view/extended_gallery.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:photo_view/photo_view.dart';

/// 漫画画廊展示，在 [MangaViewerPage] 使用
class MangaGalleryView extends StatefulWidget {
  const MangaGalleryView({
    Key? key,
    required this.imageCount,
    required this.imageUrls,
    required this.preloadPagesCount,
    required this.verticalScroll,
    required this.reverseScroll,
    required this.viewportFraction,
    required this.slideWidthRatio,
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
  final bool reverseScroll;
  final double viewportFraction;
  final double slideWidthRatio;
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
  final _galleryKey = GlobalKey<ExtendedPhotoGalleryState>();
  final CacheManager _cache = DefaultCacheManager();
  late var _controller = PageController(
    initialPage: widget.initialImageIndex - 1 + 1, // exclude extra pages, starts from 0
    viewportFraction: widget.viewportFraction,
  );

  // current page index, include extra pages, starts from 0.
  late var _currentPageIndex = widget.initialImageIndex - 1 + 1;

  // current image index, exclude extra pages, starts from 0.
  int get _currentImageIndex => (_currentPageIndex - 1).clamp(0, widget.imageCount - 1);

  @override
  void didUpdateWidget(covariant MangaGalleryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewportFraction != widget.viewportFraction) {
      var oldController = _controller;
      _controller = PageController(
        initialPage: _currentPageIndex, // initial to current page
        viewportFraction: widget.viewportFraction,
      );
      WidgetsBinding.instance?.addPostFrameCallback((_) => oldController.dispose());
    }
  }

  Offset? _pointerDownPosition;

  void _onPointerDown(Offset pos) {
    _pointerDownPosition = pos;
  }

  void _onPointerUp(Offset pos) {
    if (_pointerDownPosition != null && _pointerDownPosition == pos) {
      var width = MediaQuery.of(context).size.width;
      if (pos.dx < width * widget.slideWidthRatio) {
        _jumpToPage(!widget.reverseScroll ? _currentPageIndex - 1 : _currentPageIndex + 1); // 上一页 / 下一页(反)
      } else if (pos.dx > width * (1 - widget.slideWidthRatio)) {
        _jumpToPage(!widget.reverseScroll ? _currentPageIndex + 1 : _currentPageIndex - 1); // 下一页 / 上一页(反)
      } else {
        widget.onCenterAreaTapped?.call();
      }
    }
    _pointerDownPosition = null;
  }

  Future<void> _onLongPressed() async {
    await showPopupListMenu(
      context: context,
      title: Text('第${_currentImageIndex + 1}页'),
      barrierDismissible: true,
      items: [
        IconTextMenuItem(
          iconText: IconText.simple(Icons.refresh, '重新加载'),
          action: () async {
            await _cache.removeFile(widget.imageUrls[_currentImageIndex]);
            _galleryKey.currentState?.reload(_currentImageIndex); // exclude extra pages, starts from 0
          },
        ),
        IconTextMenuItem(
          iconText: IconText.simple(Icons.download, '保存该页'),
          action: () => widget.onSaveImage.call(_currentImageIndex + 1),
        ),
        IconTextMenuItem(
          iconText: IconText.simple(Icons.share, '分享该页'),
          action: () => widget.onShareImage.call(_currentImageIndex + 1),
        ),
      ],
    );
  }

  void _jumpToPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex <= widget.imageCount + 1) {
      _controller.jumpToPage(pageIndex);
    }
  }

  // jump to image page, exclude extra pages, starts from 1.
  void jumpToImage(int imageIndex, [bool animated = false]) {
    if (imageIndex >= 1 && imageIndex <= widget.imageCount) {
      var pageIndex = imageIndex + 1 - 1; // include extra pages, starts from 0
      if (!animated) {
        _controller.jumpToPage(pageIndex);
      } else {
        _controller.defaultAnimateToPage(pageIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.verticalScroll) {
      return HorizontalGalleryView(
        key: _galleryKey,
        pageController: _controller,
        imageCount: widget.imageCount,
        preloadPagesCount: widget.preloadPagesCount,
        reverse: widget.reverseScroll,
        backgroundDecoration: BoxDecoration(color: Colors.black),
        scrollPhysics: AlwaysScrollableScrollPhysics(),
        keepViewportMainAxisSize: true,
        changePageWhenFinished: true,
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
            onLongPress: () => _onLongPressed(),
            child: ImageLoadingView(
              title: (idx + 1).toString(),
              event: ev,
            ),
          ),
          errorBuilder: (_, err, ___) => GestureDetector(
            onTapDown: (d) => _onPointerDown(d.globalPosition),
            onTapUp: (d) => _onPointerUp(d.globalPosition),
            onLongPress: () => _onLongPressed(),
            child: ImageLoadFailedView(
              title: (idx + 1).toString(),
              error: err,
            ),
          ),
        ),
        onImageLongPressed: () => _onLongPressed(),
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
      key: _galleryKey,
      pageController: _controller /* TODO */,
      imageCount: widget.imageCount,
      preloadPagesCount: widget.preloadPagesCount /* TODO */,
      reverse: widget.reverseScroll /* TODO */,
      backgroundDecoration: BoxDecoration(color: Colors.black),
      scrollPhysics: AlwaysScrollableScrollPhysics() /* TODO */,
      keepViewportMainAxisSize: true /* TODO */,
      changePageWhenFinished: true /* TODO */,
      betweenPageSpace: widget.viewportFraction == 1.0 ? 0 : 25,
      onPageChanged: (idx) {
        _currentPageIndex = idx;
        widget.onPageChanged.call(_currentImageIndex + 1, idx == 0, idx == widget.imageCount + 1);
      } /* TODO */,
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
          onLongPress: () => _onLongPressed(),
          child: ImageLoadingView(
            title: (idx + 1).toString(),
            event: ev,
          ),
        ),
        errorBuilder: (_, err, ___) => GestureDetector(
          onTapDown: (d) => _onPointerDown(d.globalPosition),
          onTapUp: (d) => _onPointerUp(d.globalPosition),
          onLongPress: () => _onLongPressed(),
          child: ImageLoadFailedView(
            title: (idx + 1).toString(),
            error: err,
          ),
        ),
      ),
      onImageLongPressed: () => _onLongPressed() /* TODO */,
      // ****************************************************************
      // 额外页
      // ****************************************************************
      firstPageBuilder: (c) => Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.only(bottom: 25),
        constraints: BoxConstraints(
          // maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical, // TODO test
          maxWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal,
        ),
        child: widget.firstPageBuilder.call(c), // 额外页-开头
      ),
      lastPageBuilder: (c) => Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.only(bottom: 25),
        constraints: BoxConstraints(
          // maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical, // TODO test
          maxWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal,
        ),
        child: widget.lastPageBuilder.call(c), // 额外页-末尾
      ),
    );
  }
}

class ImageLoadingView extends StatelessWidget {
  const ImageLoadingView({
    Key? key,
    required this.title,
    required this.event,
  }) : super(key: key);

  final String title;
  final ImageChunkEvent? event;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(vertical: 30),
      constraints: BoxConstraints(
        // maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical, // TODO use switcher ???
        maxWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 45, color: Colors.grey),
          ),
          Padding(
            padding: EdgeInsets.all(30),
            child: Container(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: (event == null || (event!.expectedTotalBytes ?? 0) == 0) ? null : event!.cumulativeBytesLoaded / event!.expectedTotalBytes!,
              ),
            ),
          ),
          Text(
            event == null
                ? ''
                : (event!.expectedTotalBytes ?? 0) == 0
                    ? filesize(event!.cumulativeBytesLoaded)
                    : '${filesize(event!.cumulativeBytesLoaded)} / ${filesize(event!.expectedTotalBytes!)}',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ImageLoadFailedView extends StatelessWidget {
  const ImageLoadFailedView({
    Key? key,
    required this.title,
    this.error,
  }) : super(key: key);

  final String title;
  final dynamic error;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(vertical: 30),
      constraints: BoxConstraints(
        // maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical, // TODO use switcher ???
        maxWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 45, color: Colors.grey),
          ),
          Padding(
            padding: EdgeInsets.all(30),
            child: Container(
              width: 50,
              height: 50,
              child: Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 50,
              ),
            ),
          ),
          Text(
            error == null ? '' : wrapError(error, StackTrace.empty).text,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
