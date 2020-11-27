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
    this.showAppBar = false,
  })  : assert(mid != null),
        assert(cid != null),
        assert(showAppBar != null),
        super(key: key);

  final int mid;
  final int cid;
  final bool showAppBar;

  @override
  _ChapterPageState createState() => _ChapterPageState();
}

class _ChapterPageState extends State<ChapterPage> {
  PageController _controller;
  var _loading = true;
  MangaChapter _data;
  var _error = '';
  var _currentPage = 1;
  var _progressValue = 1;
  var _showRegion = false;
  var _showAppBar = false;
  double _pointerDownXPosition = 0;
  final _kSlideWidth = 0.3;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
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

  void _onImagePointerUp(Offset pos) {
    var width = MediaQuery.of(context).size.width;
    if (pos != null) {
      var x = pos.dx;
      // print('x: $x, y: $y, width: $width, height: $height');
      if (x == _pointerDownXPosition && x < width * _kSlideWidth) {
        _onMoveToPage(_currentPage - 1);
      } else if (x == _pointerDownXPosition && x > width * (1 - _kSlideWidth)) {
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
    _progressValue = page + 1;
    _currentPage = page + 1;
    if (mounted) setState(() {});
  }

  void _onMoveToPage(int page) {
    if (page <= 0) {
      _gotoLastChapter();
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

  void _gotoLastChapter() {
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
  Widget build(BuildContext context) {
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
    var height = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top;
    return SafeArea(
      top: !_showAppBar,
      child: Scaffold(
        appBar: !_showAppBar && _data != null
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
                      angle: 180 * pi / 180,
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
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(color: Colors.black),
                constraints: BoxConstraints.expand(
                  height: MediaQuery.of(context).size.height,
                ),
                child: PhotoViewGallery.builder(
                  pageController: _controller,
                  scrollPhysics: BouncingScrollPhysics(),
                  backgroundDecoration: BoxDecoration(color: Colors.black),
                  loadingBuilder: (c, ImageChunkEvent e) => ImageLoadingView(title: _currentPage.toString(), event: e),
                  loadFailedChild: ImageLoadFailedView(title: _currentPage.toString()),
                  onPageChanged: _onPageChanged,
                  itemCount: _data.pages.length,
                  builder: (c, idx) => PhotoViewGalleryPageOptions(
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained / 2,
                    maxScale: PhotoViewComputedScale.covered * 2,
                    filterQuality: FilterQuality.high,
                    onTapDown: (c, d, v) => _onPointerDown(d.globalPosition),
                    onTapUp: (c, d, v) => _onImagePointerUp(d.globalPosition),
                    imageProvider: LocalOrNetworkImageProvider(
                      url: () async => _data.pages[idx],
                      file: () async => null,
                      headers: {
                        'User-Agent': USER_AGENT,
                        'REFERER': REFERER,
                      },
                    ),
                  ),
                ),
              ),
            ),
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
            if (_showRegion)
              Positioned.fill(
                child: GestureDetector(
                  child: Row(
                    children: [
                      Container(
                        height: height,
                        width: width * _kSlideWidth,
                        color: Colors.amber.withAlpha(200),
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
                        width: width * (1 - 2 * _kSlideWidth),
                        color: Colors.blue.withAlpha(200),
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
                        width: width * _kSlideWidth,
                        color: Colors.deepOrange.withAlpha(200),
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
          ],
        ),
      ),
    );
  }
}
