import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/view/extended_gallery.dart';
import 'package:manhuagui_flutter/page/view/image_load_view.dart';
import 'package:photo_view/photo_view.dart';

/// 漫画画廊展示，在 [MangaViewerPage] 使用
class MangaGalleryView extends StatefulWidget {
  const MangaGalleryView({
    Key? key,
    required this.imageCount,
    required this.imageUrls,
    required this.preloadPagesCount,
    required this.reverseScroll,
    required this.viewportFraction,
    required this.slideWidthRatio,
    required this.onPageChanged, // without extra pages, starts from 1
    this.initialImageIndex = 1, // without extra pages, starts from 1
    this.onCenterAreaTapped,
    required this.firstPageBuilder,
    required this.lastPageBuilder,
  }) : super(key: key);

  final int imageCount;
  final List<String> imageUrls;
  final int preloadPagesCount;
  final bool reverseScroll;
  final double viewportFraction;
  final double slideWidthRatio;
  final void Function(int imageIndex, bool inFirstExtraPage, bool inLastExtraPage) onPageChanged;
  final int initialImageIndex;
  final void Function()? onCenterAreaTapped;
  final Widget Function(BuildContext) firstPageBuilder;
  final Widget Function(BuildContext) lastPageBuilder;

  @override
  State<MangaGalleryView> createState() => MangaGalleryViewState();
}

class MangaGalleryViewState extends State<MangaGalleryView> {
  late var _controller = PageController(
    initialPage: widget.initialImageIndex - 1 + 1, // without extra pages
    viewportFraction: widget.viewportFraction,
  );

  // current page index, with extra pages, starts from 0.
  var _currentPageIndex = 0;

  // current image index, without extra pages, starts from 0.
  int get _currentImageIndex => (_currentPageIndex - 1).clamp(0, widget.imageCount - 1);

  @override
  void didUpdateWidget(covariant MangaGalleryView oldWidget) {
    if (oldWidget.viewportFraction != widget.viewportFraction) {
      var oldController = _controller;
      _controller = PageController(
        initialPage: _currentPageIndex, // initial to current page
        viewportFraction: widget.viewportFraction,
      );
      WidgetsBinding.instance?.addPostFrameCallback((_) => oldController.dispose());
    }
    super.didUpdateWidget(oldWidget);
  }

  var _pointerDownXPosition = 0.0;

  void _onPointerDown(Offset pos) {
    _pointerDownXPosition = pos.dx;
  }

  void _onPointerUp(Offset pos) {
    var width = MediaQuery.of(context).size.width;
    var x = pos.dx;
    if (x == _pointerDownXPosition && x < width * widget.slideWidthRatio) {
      _jumpToPage(!widget.reverseScroll ? _currentPageIndex - 1 : _currentPageIndex + 1); // 上一页 / 下一页(反)
    } else if (x == _pointerDownXPosition && x > width * (1 - widget.slideWidthRatio)) {
      _jumpToPage(!widget.reverseScroll ? _currentPageIndex + 1 : _currentPageIndex - 1); // 下一页 / 上一页(反)
    } else {
      widget.onCenterAreaTapped?.call();
    }
  }

  void _jumpToPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex <= widget.imageCount + 1) {
      _controller.jumpToPage(pageIndex);
    }
  }

  // jump to image page, without extra pages, starts from 1.
  void jumpToImage(int imageIndex) {
    if (imageIndex >= 1 && imageIndex <= widget.imageCount) {
      _controller.jumpToPage(imageIndex + 1 - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedPhotoViewGallery(
      pageController: _controller,
      imageCount: widget.imageCount,
      preloadPagesCount: widget.preloadPagesCount,
      reverse: widget.reverseScroll,
      backgroundDecoration: BoxDecoration(color: Colors.black),
      scrollPhysics: BouncingScrollPhysics(),
      keepViewportWidth: true,
      onPageChanged: (idx) {
        _currentPageIndex = idx;
        widget.onPageChanged.call(_currentImageIndex + 1, idx == 0, idx == widget.imageCount + 1);
      },
      // ****************************************************************
      // 漫画页
      // ****************************************************************
      imagePageBuilder: (c, idx) => ReloadablePhotoViewGalleryPageOptions(
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained / 2,
        maxScale: PhotoViewComputedScale.covered * 2,
        filterQuality: FilterQuality.high,
        onTapDown: (c, d, v) => _onPointerDown(d.globalPosition),
        onTapUp: (c, d, v) => _onPointerUp(d.globalPosition),
        imageProviderBuilder: (key) => LocalOrCachedNetworkImageProvider.fromNetwork(
          url: widget.imageUrls[idx],
          headers: {
            'User-Agent': USER_AGENT,
            'Referer': REFERER,
          },
        ),
        loadingBuilder: (_, ev) => Listener(
          onPointerUp: (e) => _onPointerUp(e.position),
          onPointerDown: (e) => _onPointerDown(e.position),
          child: ImageLoadingView(
            title: (_currentImageIndex + 1).toString(),
            event: ev,
          ),
        ),
        errorBuilder: (_, __, ___) => Listener(
          onPointerUp: (e) => _onPointerUp(e.position),
          onPointerDown: (e) => _onPointerDown(e.position),
          child: ImageLoadFailedView(
            title: (_currentImageIndex + 1).toString(),
          ),
        ),
      ),
      // ****************************************************************
      // 首页和尾页
      // ****************************************************************
      firstPageBuilder: (c) => Container(
        color: Colors.white,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
          maxWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal,
        ),
        child: widget.firstPageBuilder.call(c),
      ),
      lastPageBuilder: (c) => Container(
        color: Colors.white,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
          maxWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal,
        ),
        child: widget.lastPageBuilder.call(c),
      ),
    );
  }
}
