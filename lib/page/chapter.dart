import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/image.dart';
import 'package:flutter_ahlib/util.dart';
import 'package:flutter_ahlib/widget.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/gallery_page_view.dart';
import 'package:manhuagui_flutter/page/view/image_load_view.dart';
import 'package:manhuagui_flutter/service/database/history.dart';
import 'package:manhuagui_flutter/service/natives/browser.dart';
import 'package:manhuagui_flutter/service/prefs/chapter.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';
import 'package:manhuagui_flutter/service/state/auth.dart';
import 'package:photo_view/photo_view.dart';

/// 章节
/// Page for [TinyMangaChapter].
class ChapterPage extends StatefulWidget {
  const ChapterPage({
    Key? key,
    this.action,
    required this.mid,
    required this.cid,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    this.initialPage = 1,
    this.showAppBar = false,
  })  : assert(mid != null),
        assert(cid != null),
        assert(mangaTitle != null),
        assert(mangaCover != null),
        assert(mangaUrl != null),
        assert(initialPage != null),
        assert(showAppBar != null),
        super(key: key);

  final ActionController action;
  final int mid;
  final int cid;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final int initialPage;
  final bool showAppBar;

  @override
  _ChapterPageState createState() => _ChapterPageState();
}

final _kSlideWidthRatio = 0.2; // 点击跳转页面的区域比例
final _kChapterSwipeWidth = 75; // 滑动跳转章节的比例
final _kViewportFraction = 1.08; // 页面间隔

class _ChapterPageState extends State<ChapterPage> with AutomaticKeepAliveClientMixin {
  PageController _controller;
  var _loading = true;
  MangaChapter _data;
  var _error = '';
  var _currentPage = 1;
  var _progressValue = 1;

  Timer _timer;
  var _currentTime = '00:00';
  var _fileProvider = () async => null;
  var _imageProviders = <Future<String> Function()>[];

  var _showRegion = false; // 显示区域提示
  var _showAppBar = false; // 显示工具栏
  var _setting = ChapterPageSetting.defaultSetting();
  var _pointerDownXPosition = 0.0; // 按住的横坐标
  var _swipeOffsetX = 0.0; // 滑动的水平偏移量
  var _swipeFirstOver = false; // 是否划出第一页
  var _swipeLastOver = false; // 是否划出最后一页

  @override
  void initState() {
    super.initState();
    _showAppBar = widget.showAppBar;
    _setting.existed().then((ok) async {
      if (!ok) {
        _setting = ChapterPageSetting.defaultSetting();
        await _setting.save();
      } else {
        await _setting.load();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    });
    var now = DateTime.now();
    _currentTime = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    if (_data != null) {
      addHistory(
        username: AuthState.instance.username,
        history: MangaHistory(
          mangaId: widget.mid,
          mangaTitle: widget.mangaTitle ?? '?',
          mangaCover: widget.mangaCover ?? '?',
          mangaUrl: widget.mangaUrl ?? '',
          chapterId: widget.cid,
          chapterTitle: _data.title,
          chapterPage: _currentPage,
        ),
      ).then((_) {
        widget.action?.invoke('history');
        widget.action?.invoke('history_toc');
      }).catchError((_) {});
    }
    super.dispose();
  }

  Future<void> _loadData() {
    _loading = true;
    if (mounted) setState(() {});

    var dio = DioManager.instance.dio;
    var client = RestClient(dio);
    if (AuthState.instance.logined) {
      client.recordManga(token: AuthState.instance.token, mid: widget.mid, cid: widget.cid).catchError((_) {});
    }

    return client.getMangaChapter(mid: widget.mid, cid: widget.cid).then((r) async {
      _error = '';
      _data = null;
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 500));
      _data = r.data;
      _imageProviders = [for (var url in _data.pages) () async => url];

      // !!!
      var initialPage = widget.initialPage <= 0 ? _data.pageCount : widget.initialPage; // 指定初始页
      _controller = PageController(
        initialPage: initialPage - 1,
        viewportFraction: _setting.enablePageSpace ? _kViewportFraction : 1,
      );
      _currentPage = initialPage;
      _progressValue = initialPage;

      addHistory(
        username: AuthState.instance.username,
        history: MangaHistory(
          mangaId: widget.mid,
          mangaTitle: widget.mangaTitle ?? '?',
          mangaCover: widget.mangaCover ?? '?',
          mangaUrl: widget.mangaUrl ?? '',
          chapterId: _data.cid,
          chapterTitle: _data.title,
          chapterPage: _currentPage,
        ),
      ).then((_) {
        widget.action?.invoke('history');
        widget.action?.invoke('history_toc');
      }).catchError((_) {});

      if (mounted && (_timer == null || !_timer.isActive)) {
        _timer = Timer.periodic(Duration(seconds: 1), (t) {
          if (t.isActive) {
            var now = DateTime.now();
            _currentTime = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
            if (mounted) setState(() {});
          }
        });
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
      if (x == _pointerDownXPosition && x < width * _kSlideWidthRatio) {
        _gotoPage(!_setting.reverseScroll ? _currentPage - 1 : _currentPage + 1); // 上一页 / 下一页(反)
      } else if (x == _pointerDownXPosition && x > width * (1 - _kSlideWidthRatio)) {
        _gotoPage(!_setting.reverseScroll ? _currentPage + 1 : _currentPage - 1); // 下一页 / 上一页(反)
      } else {
        _showAppBar = !_showAppBar;
        if (mounted) setState(() {});
      }
    }
  }

  void _onPageChanged(int page) {
    _currentPage = page + 1;
    _progressValue = page + 1;
    if (mounted) setState(() {});
  }

  void _onSliderChanged(double p) {
    _progressValue = p.toInt();
    _gotoPage(_progressValue);
    if (mounted) setState(() {});
  }

  /// goto page
  void _gotoPage(int page) {
    if (page <= 0) {
      if (_setting.useClickForChapter) {
        _gotoChapter(last: true);
      }
    } else if (page > _data.pages.length) {
      if (_setting.useClickForChapter) {
        _gotoChapter(last: false);
      }
    } else {
      _controller.animateToPage(
        page - 1,
        duration: Duration(milliseconds: 1),
        curve: Curves.ease,
      );
    }
  }

  /// goto chapter
  void _gotoChapter({bool last, bool isAppBar = false}) {
    if ((last && _data.prevCid == 0) || (!last && _data.nextCid == 0)) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(last ? '上一章节' : '下一章节'),
          content: Text(last ? '没有上一章节了。' : '没有下一章节了。'),
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
    var _go = () {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (c) => ChapterPage(
            action: widget.action,
            mid: widget.mid,
            cid: last ? _data.prevCid : _data.nextCid,
            mangaTitle: widget.mangaTitle,
            mangaCover: widget.mangaCover,
            mangaUrl: widget.mangaUrl,
            showAppBar: _showAppBar,
            initialPage: (!last || isAppBar) ? 1 : -1, // 下一章节 || 工具栏点击的上一章节 => 第一页，否则 => 最后一页
          ),
        ),
      );
    };
    if (_setting.needCheckForChapter) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(last ? '上一章节' : '下一章节'),
          content: Text(last ? '即将跳转至上一章节？' : '即将跳转至下一章节？'),
          actions: [
            FlatButton(
              child: Text('取消'),
              onPressed: () => Navigator.of(c).pop(),
            ),
            FlatButton(
              child: Text('跳转'),
              onPressed: () {
                Navigator.of(c).pop();
                _go();
              },
            ),
          ],
        ),
      );
    } else {
      _go();
    }
  }

  void _onSettingPressed() {
    _showAppBar = false;
    if (mounted) setState(() {});

    Widget _buildCombo<T>({String title, double width = 120, T value, List<T> values, Widget Function(T) builder, void Function(T) onChanged}) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Container(
            height: 38,
            width: width,
            child: DropdownButton<T>(
              value: value,
              items: values.map((s) => DropdownMenuItem<T>(child: builder(s), value: s)).toList(),
              underline: Container(color: Colors.white),
              isExpanded: true,
              onChanged: onChanged,
            ),
          ),
        ],
      );
    }

    Widget _buildSlider({String title, bool value, void Function(bool) onChanged}) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Container(
            height: 38,
            child: Switch(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      );
    }

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('设置'),
        content: StatefulBuilder(
          builder: (_, _setState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCombo<bool>(
                title: '阅读方向',
                value: _setting.reverseScroll,
                values: [false, true],
                builder: (s) => Text(
                  s == false ? '从左往右' : '从右往左',
                  style: Theme.of(context).textTheme.bodyText1,
                ),
                onChanged: (s) async {
                  _setting.reverseScroll = s;
                  await _setting.save();
                  _setState(() {});
                  if (mounted) setState(() {});
                },
              ),
              _buildSlider(
                title: '显示页码',
                value: _setting.showPageHint,
                onChanged: (b) async {
                  _setting.showPageHint = b;
                  await _setting.save();
                  _setState(() {});
                  if (mounted) setState(() {});
                },
              ),
              _buildSlider(
                title: '滑动跳转至章节',
                value: _setting.useSwipeForChapter,
                onChanged: (b) async {
                  _setting.useSwipeForChapter = b;
                  await _setting.save();
                  _setState(() {});
                  if (mounted) setState(() {});
                },
              ),
              _buildSlider(
                title: '点击跳转至章节',
                value: _setting.useClickForChapter,
                onChanged: (b) async {
                  _setting.useClickForChapter = b;
                  await _setting.save();
                  _setState(() {});
                  if (mounted) setState(() {});
                },
              ),
              _buildSlider(
                title: '跳转章节时弹出提示',
                value: _setting.needCheckForChapter,
                onChanged: (b) async {
                  _setting.needCheckForChapter = b;
                  await _setting.save();
                  _setState(() {});
                  if (mounted) setState(() {});
                },
              ),
              _buildSlider(
                title: '显示页面间隔',
                value: _setting.enablePageSpace,
                onChanged: (b) async {
                  _setting.enablePageSpace = b;
                  await _setting.save();
                  _setState(() {});
                  _controller = PageController(
                    initialPage: _controller.initialPage,
                    viewportFraction: b ? _kViewportFraction : 1,
                  );
                  if (mounted) setState(() {});
                },
              ),
              _buildCombo<int>(
                title: '预加载页数',
                width: 80,
                value: _setting.preloadCount.clamp(0, 5),
                values: [0, 1, 2, 3, 4, 5],
                builder: (s) => Text(
                  '$s页',
                  style: Theme.of(context).textTheme.bodyText1,
                ),
                onChanged: (c) async {
                  _setting.preloadCount = c.clamp(0, 5);
                  await _setting.save();
                  _setState(() {});
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
        ),
        actions: [
          FlatButton(
            child: Text('操作'),
            onPressed: () {
              Navigator.of(c).pop();
              _showRegion = true;
              _showAppBar = false;
              if (mounted) setState(() {});
            },
          ),
          FlatButton(
            child: Text('返回'),
            onPressed: () => Navigator.of(c).pop(),
          ),
        ],
      ),
    );
  }

  bool _onScrollNotification(Notification n) {
    if (!_setting.useSwipeForChapter) {
      return true; // 不开启滑动跳转章节
    }

    if (n is ScrollUpdateNotification) {
      var dx = n.dragDetails?.delta?.dx;
      if (dx == null) {
        _swipeOffsetX = 0;
        if (_swipeFirstOver) {
          _gotoChapter(last: !_setting.reverseScroll); // 上一章 / 下一章(反)
        } else if (_swipeLastOver) {
          _gotoChapter(last: _setting.reverseScroll); // 下一章 / 上一章(反)
        }
      } else {
        _swipeOffsetX += dx;
      }

      var willSwipeFirst = ((!_setting.reverseScroll && _currentPage == 1) || (_setting.reverseScroll && _currentPage == _data.pageCount)); // 第一页 / 最后一页(反)
      var willSwipeLast = ((!_setting.reverseScroll && _currentPage == _data.pageCount) || (_setting.reverseScroll && _currentPage == 1)); // 最后一页 / 第一页(反)
      var nowSwipeFirstOver = _swipeOffsetX >= _kChapterSwipeWidth; // 当前划出第一页
      var nowSwipeLastOver = _swipeOffsetX <= -_kChapterSwipeWidth; // 当前划出最后一页
      if (willSwipeFirst && _swipeOffsetX >= 0 && _swipeOffsetX < _kChapterSwipeWidth * 2) {
        if (!_swipeFirstOver && nowSwipeFirstOver) {
          _swipeFirstOver = true;
          if (mounted) setState(() {});
        } else if (_swipeFirstOver && !nowSwipeFirstOver) {
          _swipeFirstOver = false;
          if (mounted) setState(() {});
        }
      } else if (willSwipeLast && _swipeOffsetX <= 0 && _swipeOffsetX > -_kChapterSwipeWidth * 2) {
        if (!_swipeLastOver && nowSwipeLastOver) {
          _swipeLastOver = true;
          if (mounted) setState(() {});
        } else if (_swipeLastOver && !nowSwipeLastOver) {
          _swipeLastOver = false;
          if (mounted) setState(() {});
        }
      }
    }

    return true;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - (_showAppBar ? 45 : 0);
    return SafeArea(
      top: !_showAppBar,
      child: Scaffold(
        appBar: _loading || _data == null || !_showAppBar
            ? null
            : AppBar(
                centerTitle: false,
                toolbarHeight: 45,
                title: Text(_data.title),
                actions: [
                  IconButton(
                    icon: Icon(Icons.settings),
                    tooltip: '设置',
                    onPressed: _onSettingPressed,
                  ),
                  IconButton(
                    icon: Transform.rotate(
                      angle: pi,
                      child: Icon(Icons.arrow_right_alt),
                    ),
                    tooltip: !_setting.reverseScroll ? '上一章节' : '下一章节', // 上一章节 / 下一章节(反)
                    onPressed: () => _gotoChapter(last: !_setting.reverseScroll, isAppBar: true),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_right_alt),
                    tooltip: !_setting.reverseScroll ? '下一章节' : '上一章节', // 下一章节 / 上一章节(反)
                    onPressed: () => _gotoChapter(last: _setting.reverseScroll, isAppBar: true),
                  ),
                  IconButton(
                    icon: Icon(Icons.open_in_browser),
                    tooltip: '用浏览器打开',
                    onPressed: () => launchInBrowser(context: context, url: _data.url),
                  ),
                ],
              ),
        body: Container(
          color: Colors.black,
          child: PlaceholderText(
            onRefresh: () => _loadData(),
            state: _loading
                ? PlaceholderState.loading
                : _data == null
                    ? PlaceholderState.error
                    : PlaceholderState.normal,
            setting: PlaceholderSetting(
              iconColor: Colors.grey,
              showLoadingText: false,
              textStyle: TextStyle(
                fontSize: Theme.of(context).textTheme.headline6.fontSize,
                color: Colors.grey,
              ),
              buttonTextStyle: TextStyle(color: Colors.grey),
              buttonBorderSide: BorderSide(color: Colors.grey),
            ).toChinese(),
            errorText: _error,
            childBuilder: (c) => Stack(
              children: [
                // ****************************************************************
                // 漫画显示
                // ****************************************************************
                Positioned.fill(
                  child: NotificationListener<ScrollUpdateNotification>(
                    onNotification: _onScrollNotification,
                    child: GalleryPageView(
                      scrollPhysics: BouncingScrollPhysics(),
                      reverse: _setting.reverseScroll,
                      backgroundDecoration: BoxDecoration(color: Colors.black),
                      pageController: _controller,
                      onPageChanged: _onPageChanged,
                      itemCount: _data.pages.length,
                      preloadPagesCount: _setting.preloadCount,
                      // 2
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
                      builder: (c, idx) => GalleryPageViewPageOptions(
                        initialScale: PhotoViewComputedScale.contained,
                        minScale: PhotoViewComputedScale.contained / 2,
                        maxScale: PhotoViewComputedScale.covered * 2,
                        filterQuality: FilterQuality.high,
                        onTapDown: (c, d, v) => _onPointerDown(d.globalPosition),
                        onTapUp: (c, d, v) => _onPointerUp(d.globalPosition),
                        imageProvider: FileOrNetworkImageProvider(
                          url: _imageProviders[idx],
                          file: _fileProvider,
                          headers: {
                            'User-Agent': USER_AGENT,
                            'Referer': REFERER,
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                // ****************************************************************
                // 左边导航: 上一章节 / 下一章节(反)
                // ****************************************************************
                if (_setting.useSwipeForChapter)
                  AnimatedPositioned(
                    left: _swipeFirstOver ? 0 : -30,
                    duration: Duration(milliseconds: 200),
                    child: AnimatedOpacity(
                      opacity: _swipeFirstOver ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 200),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        width: 34,
                        height: height,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Transform.rotate(
                              angle: pi,
                              child: Icon(Icons.arrow_right_alt, size: 24, color: Colors.white),
                            ),
                            Text(
                              !_setting.reverseScroll ? '前\n往\n上\n一\n章\n节' : '前\n往\n下\n一\n章\n节',
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
                // 右边导航: 下一章节 / 上一章节(反)
                // ****************************************************************
                if (_setting.useSwipeForChapter)
                  AnimatedPositioned(
                    right: _swipeLastOver ? 0 : -30,
                    duration: Duration(milliseconds: 200),
                    child: AnimatedOpacity(
                      opacity: _swipeLastOver ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 200),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        width: 34,
                        height: height,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_right_alt, size: 24, color: Colors.white),
                            Text(
                              !_setting.reverseScroll ? '前\n往\n下\n一\n章\n节' : '前\n往\n上\n一\n章\n节',
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
                // 右下角的提示文字
                // ****************************************************************
                if (_setting.showPageHint && !_showAppBar && _data != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black.withOpacity(0.7),
                      padding: EdgeInsets.only(left: 8, right: 8, top: 1.5, bottom: 1.5),
                      child: Text(
                        '${_data.title} $_currentPage/${_data.pageCount}页 $_currentTime',
                        style: TextStyle(color: Colors.white),
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
                            child: Directionality(
                              textDirection: !_setting.reverseScroll ? TextDirection.ltr : TextDirection.rtl,
                              child: Slider(
                                value: _progressValue.toDouble(),
                                min: 1,
                                max: _data.pageCount.toDouble(),
                                onChanged: (p) {
                                  _progressValue = p.toInt();
                                  if (mounted) setState(() {});
                                },
                                onChangeEnd: _onSliderChanged,
                              ),
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
                // 帮助区域显示
                // ****************************************************************
                if (_showRegion)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        _showRegion = false;
                        if (mounted) setState(() {});
                      },
                      child: Row(
                        children: [
                          Container(
                            height: height,
                            width: width * _kSlideWidthRatio,
                            color: Colors.yellow[800].withAlpha(200),
                            child: Center(
                              child: Text(
                                !_setting.reverseScroll ? '上\n一\n页' : '下\n一\n页', // 上一页 / 下一页(反)
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
                                !_setting.reverseScroll ? '下\n一\n页' : '上\n一\n页', // 下一页 / 上一页(反)
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Theme.of(context).textTheme.headline6.fontSize,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // ****************************************************************
                // ================================================================
                // ****************************************************************
              ],
            ),
          ),
        ),
      ),
    );
  }
}
