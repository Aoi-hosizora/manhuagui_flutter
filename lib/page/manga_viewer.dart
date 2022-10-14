import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/page/view_setting.dart';
import 'package:manhuagui_flutter/page/view/image_load_view.dart';
import 'package:manhuagui_flutter/page/view/manga_gallery.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/natives/browser.dart';
import 'package:manhuagui_flutter/service/prefs/view_setting.dart';
import 'package:photo_view/photo_view.dart';

// TODO

/// 漫画章节浏览页
class MangaViewerPage extends StatefulWidget {
  const MangaViewerPage({
    Key? key,
    required this.mid,
    required this.cid,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    this.initialPage = 1,
    this.showAppBar = false,
  }) : super(key: key);

  final int mid;
  final int cid;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final int initialPage;
  final bool showAppBar;

  @override
  _MangaViewerPageState createState() => _MangaViewerPageState();
}

const _kSlideWidthRatio = 0.2; // 点击跳转页面的区域比例
const _kChapterSwipeWidth = 75; // 滑动跳转章节的比例
const _kViewportFraction = 1.08; // 页面间隔

class _MangaViewerPageState extends State<MangaViewerPage> with AutomaticKeepAliveClientMixin {
  PageController? _controller;
  Timer? _timer;
  var _currentTime = '00:00';
  var _currentPage = 1;
  var _progressValue = 1;

  var _setting = ViewSetting.defaultSetting();
  late var _showAppBar = widget.showAppBar; // 显示工具栏
  var _showRegion = false; // 显示区域提示
  var _pointerDownXPosition = 0.0; // 按住的横坐标
  var _swipeOffsetX = 0.0; // 滑动的水平偏移量
  var _swipeFirstOver = false; // 是否划出第一页
  var _swipeLastOver = false; // 是否划出最后一页

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _setting = await ViewSettingPrefs.getSetting();
      if (mounted) setState(() {});
      if (mounted && (_timer == null || !_timer!.isActive)) {
        _timer = Timer.periodic(Duration(seconds: 1), (t) {
          if (t.isActive) {
            var now = DateTime.now();
            _currentTime = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
            if (mounted) setState(() {});
          }
        });
      }
    });
  }

  @override
  void dispose() {
    if (_data != null) {
      Future.microtask(() async {
        await HistoryDao.addOrUpdateHistory(
          username: AuthManager.instance.username,
          history: MangaHistory(
            mangaId: widget.mid,
            mangaTitle: widget.mangaTitle,
            mangaCover: widget.mangaCover,
            mangaUrl: widget.mangaUrl,
            chapterId: _data!.cid,
            chapterTitle: _data!.title,
            chapterPage: _currentPage,
            lastTime: DateTime.now(),
          ),
        );
        EventBusManager.instance.fire(HistoryUpdatedEvent());
      });
    }
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _updatePageController({int? initialPage, double? viewportFraction}) {
    var oldController = _controller;
    _controller = PageController(
      initialPage: initialPage ?? _controller!.initialPage,
      viewportFraction: viewportFraction ?? _controller!.viewportFraction,
    );
    if (mounted) setState(() {});
    WidgetsBinding.instance?.addPostFrameCallback((_) => oldController?.dispose());
  }

  var _loading = true;
  MangaChapter? _data;
  var _error = '';

  Future<void> _loadData() async {
    _loading = true;
    if (mounted) setState(() {});

    final client = RestClient(DioManager.instance.dio);

    // 1. 异步更新章节阅读记录
    if (AuthManager.instance.logined) {
      Future.microtask(() async {
        try {
          await client.recordManga(token: AuthManager.instance.token, mid: widget.mid, cid: widget.cid);
        } catch (_) {}
      });
    }

    try {
      // 2. 获取章节数据
      var result = await client.getMangaChapter(mid: widget.mid, cid: widget.cid);
      _data = null;
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 200));
      _data = result.data;

      // 3. 指定起始页并更新 PageController
      var initialPage = widget.initialPage > 0 && widget.initialPage <= _data!.pageCount ? widget.initialPage : 1;
      _updatePageController(
        initialPage: initialPage - 1,
        viewportFraction: _setting.enablePageSpace ? _kViewportFraction : 1,
      );
      _currentPage = initialPage;
      _progressValue = initialPage;

      // 4. 更新浏览历史
      Future.microtask(() async {
        await HistoryDao.addOrUpdateHistory(
          username: AuthManager.instance.username,
          history: MangaHistory(
            mangaId: widget.mid,
            mangaTitle: widget.mangaTitle,
            mangaCover: widget.mangaCover,
            mangaUrl: widget.mangaUrl,
            chapterId: _data!.cid,
            chapterTitle: _data!.title,
            chapterPage: _currentPage,
            lastTime: DateTime.now(),
          ),
        );
        EventBusManager.instance.fire(HistoryUpdatedEvent());
      });
    } catch (e, s) {
      _data = null;
      _error = wrapError(e, s).text;
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  // TODO >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  void _onPageChanged(int page) {
    _currentPage = page + 1;
    _progressValue = page + 1;
    if (mounted) setState(() {});
  }

  void _onPointerDown(Offset pos) {
    _pointerDownXPosition = pos.dx;
  }

  void _onPointerUp(Offset pos) {
    var width = MediaQuery.of(context).size.width;
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

  void _onSliderChanged(double p) {
    _progressValue = p.toInt();
    _gotoPage(_progressValue);
    if (mounted) setState(() {});
  }

  void _gotoPage(int page) {
    if (page <= 0) {
      if (_setting.useClickForChapter) {
        _gotoChapter(last: true);
      }
    } else if (page > _data!.pages.length) {
      if (_setting.useClickForChapter) {
        _gotoChapter(last: false);
      }
    } else {
      _controller?.animateToPage(
        page - 1,
        duration: Duration(milliseconds: 1),
        curve: Curves.ease,
      );
    }
  }

  void _gotoChapter({required bool last, bool isAppBar = false}) {
    if ((last && _data!.prevCid == 0) || (!last && _data!.nextCid == 0)) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(last ? '上一章节' : '下一章节'),
          content: Text(last ? '没有上一章节了。' : '没有下一章节了。'),
          actions: [
            TextButton(
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
          builder: (c) => MangaViewerPage(
            mid: widget.mid,
            cid: last ? _data!.prevCid : _data!.nextCid,
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
            TextButton(
              child: Text('取消'),
              onPressed: () => Navigator.of(c).pop(),
            ),
            TextButton(
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

  // TODO >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  void _onSettingPressed() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('设置'),
        content: ViewSettingSubPage(
          setting: _setting,
          onSettingChanged: (s) async {
            var oldSetting = _setting;
            _setting = s;
            if (oldSetting.enablePageSpace != s.enablePageSpace) {
              _updatePageController(viewportFraction: _setting.enablePageSpace ? _kViewportFraction : 1);
            }
            if (mounted) setState(() {});
            await ViewSettingPrefs.setSetting(_setting);
          },
        ),
        actions: [
          TextButton(
            child: Text('操作'),
            onPressed: () {
              Navigator.of(c).pop();
              _showRegion = true;
              _showAppBar = false;
              if (mounted) setState(() {});
            },
          ),
          TextButton(
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
      var dx = n.dragDetails?.delta.dx;
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

      var willSwipeFirst = ((!_setting.reverseScroll && _currentPage == 1) || (_setting.reverseScroll && _currentPage == _data!.pageCount)); // 第一页 / 最后一页(反)
      var willSwipeLast = ((!_setting.reverseScroll && _currentPage == _data!.pageCount) || (_setting.reverseScroll && _currentPage == 1)); // 最后一页 / 第一页(反)
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
                title: Text(_data!.title),
                actions: [
                  IconButton(
                    icon: Icon(Icons.open_in_browser),
                    tooltip: '用浏览器打开',
                    onPressed: () => launchInBrowser(context: context, url: _data!.url),
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
            errorText: _error,
            setting: PlaceholderSetting(
              iconColor: Colors.grey,
              showLoadingText: false,
              textStyle: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.grey),
              buttonTextStyle: TextStyle(color: Colors.grey),
              buttonStyle: ButtonStyle(
                side: MaterialStateProperty.all(BorderSide(color: Colors.grey)),
              ),
            ).copyWithChinese(),
            childBuilder: (c) => Stack(
              children: [
                // ****************************************************************
                // 漫画显示
                // ****************************************************************
                Positioned.fill(
                  child: NotificationListener<ScrollUpdateNotification>(
                    onNotification: _onScrollNotification,
                    // TODO add reload and long pressed popup menu
                    child: MangaGalleryView(
                      scrollPhysics: BouncingScrollPhysics(),
                      reverse: _setting.reverseScroll,
                      backgroundDecoration: BoxDecoration(color: Colors.black),
                      pageController: _controller,
                      onPageChanged: _onPageChanged,
                      itemCount: _data!.pages.length,
                      preloadPagesCount: _setting.preloadCount,
                      // ****************************************************************
                      // 漫画显示选项
                      // ****************************************************************
                      builder: (c, idx) => ReloadablePhotoViewGalleryPageOptions(
                        initialScale: PhotoViewComputedScale.contained,
                        minScale: PhotoViewComputedScale.contained / 2,
                        maxScale: PhotoViewComputedScale.covered * 2,
                        filterQuality: FilterQuality.high,
                        onTapDown: (c, d, v) => _onPointerDown(d.globalPosition),
                        onTapUp: (c, d, v) => _onPointerUp(d.globalPosition),
                        imageProviderBuilder: (key) => LocalOrCachedNetworkImageProvider.fromNetwork(
                          url: _data!.pages[idx],
                          headers: {
                            'User-Agent': USER_AGENT,
                            'Referer': REFERER,
                          },
                        ),
                        loadingBuilder: (_, ev) => Listener(
                          onPointerUp: (e) => _onPointerUp(e.position),
                          onPointerDown: (e) => _onPointerDown(e.position),
                          child: ImageLoadingView(
                            title: _currentPage.toString(),
                            event: ev,
                            height: height,
                            width: width,
                          ),
                        ),
                        errorBuilder: (_, __, ___) => Listener(
                          onPointerUp: (e) => _onPointerUp(e.position),
                          onPointerDown: (e) => _onPointerDown(e.position),
                          child: ImageLoadFailedView(
                            title: _currentPage.toString(),
                            height: height,
                            width: width,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // ****************************************************************
                // 左边导航: 上一章节 / 下一章节(反)
                // ****************************************************************
                if (_setting.useSwipeForChapter) // TODO 如何优化？？？
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
                              style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.white),
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
                              style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.white),
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
                      color: Colors.black.withOpacity(0.65),
                      padding: EdgeInsets.only(left: 8, right: 8, top: 1.5, bottom: 1.5),
                      child: Text(
                        '${_data!.title} $_currentPage/${_data!.pageCount}页 $_currentTime',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                // ****************************************************************
                // 最下面的滚动条和按钮
                // ****************************************************************
                if (_showAppBar && _data != null) // TODO use Animation
                  Positioned(
                    bottom: 0,
                    child: Container(
                      color: Colors.black.withOpacity(0.75),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Directionality(
                                  textDirection: !_setting.reverseScroll ? TextDirection.ltr : TextDirection.rtl,
                                  child: Slider(
                                    value: _progressValue.toDouble(),
                                    min: 1,
                                    max: _data!.pageCount.toDouble(),
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
                                  '$_progressValue/${_data!.pageCount}页',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          Material(
                            color: Colors.transparent,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                InkWell(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    child: IconText(
                                      icon: Transform.rotate(
                                        angle: pi,
                                        child: Icon(Icons.arrow_right_alt, color: Colors.white),
                                      ),
                                      text: Text(
                                        !_setting.reverseScroll ? '上一章节' : '下一章节',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      alignment: IconTextAlignment.t2b,
                                      space: 2,
                                    ),
                                  ),
                                  onTap: () => _gotoChapter(last: !_setting.reverseScroll, isAppBar: true),
                                ),
                                InkWell(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    child: IconText(
                                      icon: Icon(Icons.settings, color: Colors.white),
                                      text: Text(
                                        '设置',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      alignment: IconTextAlignment.t2b,
                                      space: 2,
                                    ),
                                  ),
                                  onTap: _onSettingPressed,
                                ),
                                InkWell(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    child: IconText(
                                      icon: Icon(Icons.arrow_right_alt, color: Colors.white),
                                      text: Text(
                                        !_setting.reverseScroll ? '下一章节' : '上一章节',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      alignment: IconTextAlignment.t2b,
                                      space: 2,
                                    ),
                                  ),
                                  onTap: () => _gotoChapter(last: _setting.reverseScroll, isAppBar: true),
                                ),
                              ],
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
                            color: Colors.yellow[800]!.withAlpha(200),
                            child: Center(
                              child: Text(
                                !_setting.reverseScroll ? '上\n一\n页' : '下\n一\n页', // 上一页 / 下一页(反)
                                style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                          Container(
                            height: height,
                            width: width * (1 - 2 * _kSlideWidthRatio),
                            color: Colors.blue[300]!.withAlpha(200),
                            child: Center(
                              child: Text(
                                '菜单',
                                style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                          Container(
                            height: height,
                            width: width * _kSlideWidthRatio,
                            color: Colors.red[200]!.withAlpha(200),
                            child: Center(
                              child: Text(
                                !_setting.reverseScroll ? '下\n一\n页' : '上\n一\n页', // 下一页 / 上一页(反)
                                style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // ****************************************************************
                // Stack children 结束
                // ****************************************************************
              ],
            ),
          ),
        ),
      ),
    );
  }
}
