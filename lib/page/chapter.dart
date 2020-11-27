import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/page/view/image_loading.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// 章节
/// Page for [TinyMangaChapter].
class ChapterPage extends StatefulWidget {
  const ChapterPage({
    Key key,
    @required this.mid,
    @required this.cid,
    this.initialPage = 1,
    this.showAppBar = false,
  })  : assert(mid != null),
        assert(cid != null),
        assert(initialPage != null),
        assert(showAppBar != null),
        super(key: key);

  final int mid;
  final int cid;
  final int initialPage;
  final bool showAppBar;

  @override
  _ChapterPageState createState() => _ChapterPageState();
}

class _ChapterPageState extends State<ChapterPage> with AutomaticKeepAliveClientMixin {
  PageController _controller;
  var _loading = true;
  MangaChapter _data;
  var _error = '';
  var _currentPage = 1;
  var _progressValue = 1;
  var _showRegion = false;
  var _showAppBar = false;
  var _pointerDownXPosition = 0.0;
  final _kSlideWidthRatio = 0.3;
  final _kChapterSwipeWidth = 100;
  var _swipeOffsetX = 0.0;
  var _swipeFirstOver = false;
  var _swipeLastOver = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPage > 0) {
      _controller = PageController(initialPage: widget.initialPage - 1);
      _currentPage = widget.initialPage;
      _progressValue = widget.initialPage;
    }
    _showAppBar = widget.showAppBar;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() {
    _loading = true;
    if (mounted) setState(() {});

    var dio = DioManager.getInstance().dio;
    var client = RestClient(dio);
    return client.getMangaChapter(mid: widget.mid, cid: widget.cid).then((r) async {
      _error = '';
      _data = null;
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _data = r.data;
      if (widget.initialPage <= 0) {
        // <<<
        _controller = PageController(initialPage: _data.pageCount - 1);
        _currentPage = _data.pageCount;
        _progressValue = _data.pageCount;
      }
    }).catchError((e) {
      _data = null;
      _error = wrapError(e).text;
    }).whenComplete(() {
      _loading = false;
      if (mounted) setState(() {});
    });
  }

  void _onPointerDown(Offset pos) {
    _pointerDownXPosition = pos?.dx ?? 0;
  }

  void _onPointerUp(Offset pos) {
    var width = MediaQuery.of(context).size.width;
    if (pos != null) {
      var x = pos.dx;
      // print('x: $x, width: $width');
      if (x == _pointerDownXPosition && x < width * _kSlideWidthRatio) {
        _onMoveToPage(_currentPage - 1);
      } else if (x == _pointerDownXPosition && x > width * (1 - _kSlideWidthRatio)) {
        _onMoveToPage(_currentPage + 1);
      } else {
        _showAppBar = !_showAppBar;
        if (mounted) setState(() {});
      }
    }
  }

  void _onSliderChanged(double p) {
    _progressValue = p.toInt();
    if (mounted) setState(() {});
  }

  void _onSliderChangeEnd(double p) {
    _progressValue = p.toInt();
    _onMoveToPage(_progressValue);
    if (mounted) setState(() {});
  }

  void _onPageChanged(int page) {
    // print('page: $page');
    _progressValue = page + 1;
    _currentPage = page + 1;
    if (mounted) setState(() {});
  }

  bool _onScrollNotification(Notification n) {
    if (n is ScrollUpdateNotification) {
      var dx = n.dragDetails?.delta?.dx;
      if (dx != null) {
        _swipeOffsetX += dx;
      } else {
        _swipeOffsetX = 0;
        if (_swipeFirstOver) {
          _gotoLastChapter(gotoLastPage: true); // <<<
        } else if (_swipeLastOver) {
          _gotoNextChapter(); // <<<
        }
      }
      if (_currentPage == 1 && _swipeOffsetX >= 0 && _swipeOffsetX < _kChapterSwipeWidth * 2) {
        if (_swipeOffsetX > _kChapterSwipeWidth && !_swipeFirstOver) {
          _swipeFirstOver = true;
          if (mounted) setState(() {});
        } else if (_swipeOffsetX <= _kChapterSwipeWidth && _swipeFirstOver) {
          _swipeFirstOver = false;
          if (mounted) setState(() {});
        }
      } else if (_currentPage == _data.pageCount && _swipeOffsetX <= 0 && _swipeOffsetX > -_kChapterSwipeWidth * 2) {
        if (_swipeOffsetX < -_kChapterSwipeWidth && !_swipeLastOver) {
          _swipeLastOver = true;
          if (mounted) setState(() {});
        } else if (_swipeOffsetX >= -_kChapterSwipeWidth && _swipeLastOver) {
          _swipeLastOver = false;
          if (mounted) setState(() {});
        }
      }
    }
    return true;
  }

  void _onMoveToPage(int page) {
    if (page <= 0) {
      _gotoLastChapter(gotoLastPage: true);
    } else if (page > _data.pages.length) {
      _gotoNextChapter();
    } else {
      _controller.animateToPage(
        page - 1,
        duration: Duration(milliseconds: 1),
        curve: Curves.ease,
      );
    }
  }

  void _gotoLastChapter({bool gotoLastPage = false}) {
    if (_data.prevCid == 0) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('上一章节'),
          content: Text('没有上一章节了。'),
          actions: [
            FlatButton(
              child: Text('确定'),
              onPressed: () => Navigator.of(c).pop(),
            ),
          ],
        ),
      );
      return;
    }
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (c) => ChapterPage(
          mid: widget.mid,
          cid: _data.prevCid,
          showAppBar: _showAppBar,
          initialPage: gotoLastPage ? -1 : 1,
        ),
      ),
    );
  }

  void _gotoNextChapter() {
    if (_data.nextCid == 0) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('下一章节'),
          content: Text('没有下一章节了。'),
          actions: [
            FlatButton(
              child: Text('确定'),
              onPressed: () => Navigator.of(c).pop(),
            ),
          ],
        ),
      );
      return;
    }
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (c) => ChapterPage(
          mid: widget.mid,
          cid: _data.nextCid,
          showAppBar: _showAppBar,
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    } else if (_data == null) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(5),
                  child: Icon(
                    Icons.error,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Text(
                    _error?.isNotEmpty == true ? _error : '未知错误',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.headline6.fontSize,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(5),
                  child: OutlineButton(
                    borderSide: BorderSide(color: Colors.grey),
                    child: Text(
                      '重试',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onPressed: () => _loadData(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - (_showAppBar ? 45 : 0);
    return SafeArea(
      top: !_showAppBar,
      child: Scaffold(
        appBar: !_showAppBar
            ? null
            : AppBar(
                centerTitle: true,
                toolbarHeight: 45,
                title: Text(_data.title),
                actions: [
                  IconButton(
                    icon: Icon(Icons.help),
                    tooltip: '操作',
                    onPressed: () {
                      _showRegion = true;
                      _showAppBar = false;
                      if (mounted) setState(() {});
                    },
                  ),
                  IconButton(
                    icon: Transform.rotate(
                      angle: pi,
                      child: Icon(Icons.arrow_right_alt),
                    ),
                    tooltip: '上一章节',
                    onPressed: _gotoLastChapter,
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_right_alt),
                    tooltip: '下一章节',
                    onPressed: _gotoNextChapter,
                  ),
                ],
              ),
        body: Stack(
          children: [
            // ****************************************************************
            // 漫画显示
            // ****************************************************************
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: NotificationListener<ScrollUpdateNotification>(
                  onNotification: _onScrollNotification,
                  child: PhotoViewGallery.builder(
                    scrollPhysics: BouncingScrollPhysics(),
                    backgroundDecoration: BoxDecoration(color: Colors.black),
                    pageController: _controller,
                    onPageChanged: _onPageChanged,
                    itemCount: _data.pages.length,
                    loadingBuilder: (c, ImageChunkEvent e) => Listener(
                      onPointerUp: (e) => _onPointerUp(e.position),
                      onPointerDown: (e) => _onPointerDown(e.position),
                      child: ImageLoadingView(
                        title: _currentPage.toString(),
                        event: e,
                        height: height,
                        width: width,
                      ),
                    ),
                    loadFailedChild: Listener(
                      onPointerUp: (e) => _onPointerUp(e.position),
                      onPointerDown: (e) => _onPointerDown(e.position),
                      child: ImageLoadFailedView(
                        title: _currentPage.toString(),
                        height: height,
                        width: width,
                      ),
                    ),
                    // ****************************************************************
                    // 漫画显示选项
                    // ****************************************************************
                    builder: (c, idx) => PhotoViewGalleryPageOptions(
                      initialScale: PhotoViewComputedScale.contained,
                      minScale: PhotoViewComputedScale.contained / 2,
                      maxScale: PhotoViewComputedScale.covered * 2,
                      filterQuality: FilterQuality.high,
                      onTapDown: (c, d, v) => _onPointerDown(d.globalPosition),
                      onTapUp: (c, d, v) => _onPointerUp(d.globalPosition),
                      imageProvider: LocalOrNetworkImageProvider(
                        url: () async => _data.pages[idx],
                        file: () async => null,
                        headers: {
                          'User-Agent': USER_AGENT,
                          'Referer': REFERER,
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // ****************************************************************
            // 上一章节
            // ****************************************************************
            AnimatedPositioned(
              left: _swipeFirstOver ? 8 : -30,
              duration: Duration(milliseconds: 300),
              child: AnimatedOpacity(
                opacity: _swipeFirstOver ? 1.0 : 0.0,
                duration: Duration(milliseconds: 500),
                child: Container(
                  color: Colors.black,
                  width: 30,
                  height: height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.rotate(
                        angle: pi,
                        child: Icon(
                          Icons.arrow_right_alt,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '前\n往\n上\n一\n章\n节',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Theme.of(context).textTheme.headline6.fontSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ****************************************************************
            // 下一章节
            // ****************************************************************
            AnimatedPositioned(
              right: _swipeLastOver ? 8 : -30,
              duration: Duration(milliseconds: 300),
              child: AnimatedOpacity(
                opacity: _swipeLastOver ? 1.0 : 0.0,
                duration: Duration(milliseconds: 500),
                child: Container(
                  color: Colors.black,
                  width: 30,
                  height: height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_right_alt,
                        size: 24,
                        color: Colors.white,
                      ),
                      Text(
                        '前\n往\n下\n一\n章\n节',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Theme.of(context).textTheme.headline6.fontSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ****************************************************************
            // 最下面的滚动条
            // ****************************************************************
            if (_showAppBar && _data != null)
              Positioned(
                bottom: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.75),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _progressValue.toDouble(),
                          min: 1,
                          max: _data.pageCount.toDouble(),
                          onChanged: _onSliderChanged,
                          onChangeEnd: _onSliderChangeEnd,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 4, right: 18),
                        child: Text(
                          '$_progressValue/${_data.pageCount}页',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // ****************************************************************
            // 右下角的提示文字
            // ****************************************************************
            if (!_showAppBar && _data != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  color: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${_data.title} $_currentPage/${_data.pageCount}',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            // ****************************************************************
            // 帮助区域显示
            // ****************************************************************
            if (_showRegion)
              Positioned.fill(
                child: GestureDetector(
                  child: Row(
                    children: [
                      Container(
                        height: height,
                        width: width * _kSlideWidthRatio,
                        color: Colors.yellow[800].withAlpha(200),
                        child: Center(
                          child: Text(
                            '上\n一\n页',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Theme.of(context).textTheme.headline6.fontSize,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: height,
                        width: width * (1 - 2 * _kSlideWidthRatio),
                        color: Colors.blue[300].withAlpha(200),
                        child: Center(
                          child: Text(
                            '菜单',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Theme.of(context).textTheme.headline6.fontSize,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: height,
                        width: width * _kSlideWidthRatio,
                        color: Colors.red[200].withAlpha(200),
                        child: Center(
                          child: Text(
                            '下\n一\n页',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Theme.of(context).textTheme.headline6.fontSize,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    _showRegion = false;
                    if (mounted) setState(() {});
                  },
                ),
              ),
            // ****************************************************************
            // ================================================================
            // ****************************************************************
          ],
        ),
      ),
    );
  }
}
