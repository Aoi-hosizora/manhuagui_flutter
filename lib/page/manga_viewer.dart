import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/page/view_setting.dart';
import 'package:manhuagui_flutter/page/page/view_toc.dart';
import 'package:manhuagui_flutter/page/view/manga_gallery.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/natives/browser.dart';
import 'package:manhuagui_flutter/service/natives/share.dart';
import 'package:manhuagui_flutter/service/prefs/view_setting.dart';
import 'package:wakelock/wakelock.dart';

/// 漫画章节浏览页
class MangaViewerPage extends StatefulWidget {
  const MangaViewerPage({
    Key? key,
    required this.mid,
    required this.cid,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.chapterGroups,
    this.initialPage = 1, // starts from 1
    this.showAppBar = false,
  }) : super(key: key);

  final int mid;
  final int cid;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final List<MangaChapterGroup> chapterGroups;
  final int initialPage;
  final bool showAppBar;

  @override
  _MangaViewerPageState createState() => _MangaViewerPageState();
}

const _kSlideWidthRatio = 0.2; // 点击跳转页面的区域比例
const _kViewportFraction = 1.08; // 页面间隔
const _animationDuration = Duration(milliseconds: 150); // 动画时长

class _MangaViewerPageState extends State<MangaViewerPage> with AutomaticKeepAliveClientMixin {
  final _mangaGalleryViewKey = GlobalKey<MangaGalleryViewState>();
  Timer? _timer;
  var _currentTime = '00:00';

  var _setting = ViewSetting.defaultSetting();
  var _showRegion = false; // 显示区域提示
  late var __showAppBar = widget.showAppBar; // 显示工具栏
  var _showAppBarDone = true; // 显示工具栏动画完毕
  bool get _showAppBar => __showAppBar;

  set _showAppBar(bool b) {
    __showAppBar = b;
    if (mounted) setState(() {});
    _showAppBarDone = false;
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await Future.delayed(_animationDuration - Duration(milliseconds: 15), () {
        _showAppBarDone = true;
        if (mounted) setState(() {});
      });
    });
    _setFullscreen(full: _setting.fullscreen && !_showAppBar);
  }

  void _setFullscreen({required bool full}) {
    // TODO without test
    if (full) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      // setting
      _setting = await ViewSettingPrefs.getSetting();
      if (mounted) setState(() {});
      if (_setting.keepScreenOn) {
        Wakelock.enable();
      }
      if (_setting.fullscreen && !_showAppBar) {
        _setFullscreen(full: true);
      }

      // timer
      var now = DateTime.now();
      _currentTime = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
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
    _timer?.cancel();
    super.dispose();
  }

  var _loading = true;
  MangaChapter? _data;
  int? _initialPage;
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

      // 3. 指定起始页
      _initialPage = widget.initialPage.clamp(1, _data!.pageCount);
      _currentPage = _initialPage!;
      _progressValue = _initialPage!;

      // 4. 异步更新浏览历史
      _updateHistory();
    } catch (e, s) {
      _data = null;
      _error = wrapError(e, s).text;
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _updateHistory() async {
    if (_data != null) {
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
    }
  }

  var _currentPage = 1; // image page only, starts from 1
  var _progressValue = 1; // image page only, starts from 1
  var _inExtraPage = false;

  void _onPageChanged(int imageIndex, bool inFirstExtraPage, bool inLastExtraPage) {
    _currentPage = imageIndex;
    _progressValue = imageIndex;
    _inExtraPage = inFirstExtraPage || inLastExtraPage;
    if (mounted) setState(() {});
  }

  void _onSliderChanged(double p) {
    _progressValue = p.toInt();
    _mangaGalleryViewKey.currentState?.jumpToImage(_progressValue);
    if (mounted) setState(() {});
  }

  void _gotoChapter({required bool gotoPrevious}) {
    if ((gotoPrevious && _data!.prevCid == 0) || (!gotoPrevious && _data!.nextCid == 0)) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(gotoPrevious ? '上一章节' : '下一章节'),
          content: Text(gotoPrevious ? '没有上一章节了。' : '没有下一章节了。'),
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

    Navigator.of(context).pop(); // pop this page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (c) => MangaViewerPage(
          mid: widget.mid,
          mangaTitle: widget.mangaTitle,
          mangaCover: widget.mangaCover,
          mangaUrl: widget.mangaUrl,
          chapterGroups: widget.chapterGroups,
          cid: gotoPrevious ? _data!.prevCid : _data!.nextCid,
          initialPage: 1,
          showAppBar: _showAppBar,
        ),
      ),
    );
  }

  void _onSettingPressed() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('设置'),
        content: ViewSettingSubPage(
          setting: _setting,
          onSettingChanged: (s) async {
            _setting = s;
            if (mounted) setState(() {});
            await ViewSettingPrefs.setSetting(_setting);

            // apply settings
            Wakelock.toggle(enable: _setting.keepScreenOn);
            _setFullscreen(full: _setting.fullscreen && !_showAppBar);
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

  Widget _buildAction({required String text, required IconData icon, required void Function() action, double? rotateAngle}) {
    return InkWell(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: IconText(
          icon: rotateAngle == null
              ? Icon(icon, color: Colors.white)
              : Transform.rotate(
                  angle: rotateAngle,
                  child: Icon(icon, color: Colors.white),
                ),
          text: Text(
            text,
            style: TextStyle(color: Colors.white),
          ),
          alignment: IconTextAlignment.t2b,
          space: 2,
        ),
      ),
      onTap: action,
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    var viewWidth = MediaQuery.of(context).size.width;
    var viewHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - (_showAppBar ? Theme.of(context).appBarTheme.toolbarHeight! : 0);
    return WillPopScope(
      onWillPop: () async {
        _updateHistory(); // 异步执行
        Wakelock.disable();
        _setFullscreen(full: false);
        return true;
      },
      child: SafeArea(
        top: !_showAppBar && _showAppBarDone, // TODO
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(Theme.of(context).appBarTheme.toolbarHeight!),
            child: AnimatedSwitcher(
              duration: _animationDuration,
              child: _loading || _data == null || !_showAppBar
                  ? SizedBox(height: 0)
                  : AppBar(
                      title: Text(_data!.title), // TODO don't use AppBar ???
                      actions: [
                        IconButton(
                          icon: Icon(Icons.open_in_browser),
                          tooltip: '用浏览器打开',
                          onPressed: () => launchInBrowser(context: context, url: _data!.url),
                        ),
                      ],
                    ),
            ),
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
                    child: MangaGalleryView(
                      key: _mangaGalleryViewKey,
                      imageCount: _data!.pages.length,
                      imageUrls: _data!.pages,
                      preloadPagesCount: _setting.preloadCount,
                      reverseScroll: _setting.reverseScroll,
                      viewportFraction: _setting.enablePageSpace ? _kViewportFraction : 1,
                      slideWidthRatio: _kSlideWidthRatio,
                      initialImageIndex: _initialPage ?? 1,
                      onPageChanged: _onPageChanged,
                      onSaveImage: (imageIndex) => Fluttertoast.showToast(msg: '第$imageIndex页') /* TODO save image */,
                      onShareImage: (imageIndex) => shareText(
                        title: '【漫画柜】《${_data!.title}》 第$imageIndex页', // TODO without test
                        link: _data!.pages[imageIndex - 1],
                      ),
                      onCenterAreaTapped: () {
                        _showAppBar = !_showAppBar;
                        if (mounted) setState(() {});
                      },
                      firstPageBuilder: (c) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('first page'),
                            OutlinedButton(
                              child: Text('下一页'),
                              onPressed: () => _mangaGalleryViewKey.currentState?.jumpToImage(1),
                            ),
                            OutlinedButton(
                              child: Text('下一章节'),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                      lastPageBuilder: (c) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('last page'),
                            OutlinedButton(
                              child: Text('上一页'),
                              onPressed: () => _mangaGalleryViewKey.currentState?.jumpToImage(_data!.pages.length),
                            ),
                            OutlinedButton(
                              child: Text('回到首页'),
                              onPressed: () => _mangaGalleryViewKey.currentState?.jumpToImage(1),
                            ),
                            OutlinedButton(
                              child: Text('上一章节'),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // ****************************************************************
                  // 右下角的提示文字
                  // ****************************************************************
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: AnimatedSwitcher(
                      duration: _animationDuration,
                      child: !(_data != null && !_showAppBar && !_inExtraPage && _setting.showPageHint)
                          ? SizedBox(height: 0)
                          : Container(
                              color: Colors.black.withOpacity(0.65),
                              padding: EdgeInsets.only(left: 8, right: 8, top: 1.5, bottom: 1.5),
                              child: Text(
                                '${_data!.title} $_currentPage/${_data!.pageCount}页 $_currentTime',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                    ),
                  ),
                  // ****************************************************************
                  // 最下面的滚动条和按钮
                  // ****************************************************************
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedSwitcher(
                      duration: _animationDuration,
                      child: !(_data != null && _showAppBar && !_inExtraPage)
                          ? SizedBox(height: 0)
                          : Container(
                              color: Colors.black.withOpacity(0.75),
                              padding: EdgeInsets.only(left: 12, right: 12, top: 0, bottom: 4),
                              width: MediaQuery.of(context).size.width,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Directionality(
                                          textDirection: !_setting.reverseScroll ? TextDirection.ltr : TextDirection.rtl,
                                          child: SliderTheme(
                                            data: Theme.of(context).sliderTheme.copyWith(
                                                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.0),
                                                  overlayShape: RoundSliderOverlayShape(overlayRadius: 20.0),
                                                ),
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
                                        _buildAction(
                                          text: !_setting.reverseScroll ? '上一章节' : '下一章节',
                                          icon: Icons.arrow_right_alt,
                                          rotateAngle: pi,
                                          action: () => _gotoChapter(gotoPrevious: !_setting.reverseScroll),
                                        ),
                                        _buildAction(
                                          text: !_setting.reverseScroll ? '下一章节' : '上一章节',
                                          icon: Icons.arrow_right_alt,
                                          action: () => _gotoChapter(gotoPrevious: _setting.reverseScroll),
                                        ),
                                        _buildAction(
                                          text: '浏览设置',
                                          icon: Icons.settings,
                                          action: () => _onSettingPressed(),
                                        ),
                                        _buildAction(
                                          text: '漫画目录',
                                          icon: Icons.menu,
                                          action: () => showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            builder: (c) => Container(
                                              height: viewHeight,
                                              child: ViewTocSubPage(
                                                mid: widget.mid,
                                                mangaTitle: widget.mangaTitle,
                                                mangaCover: widget.mangaCover,
                                                mangaUrl: widget.mangaUrl,
                                                groups: widget.chapterGroups,
                                                highlightedChapter: widget.cid,
                                                predicate: (cid) {
                                                  if (cid == _data!.cid) {
                                                    Fluttertoast.showToast(msg: '正在阅读 ${_data!.title}');
                                                    return false;
                                                  }
                                                  Navigator.of(c).pop(); // bottom sheet
                                                  Navigator.of(context).pop(); // this page
                                                  return true;
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
                              height: viewHeight,
                              width: viewWidth * _kSlideWidthRatio,
                              color: Colors.yellow[800]!.withAlpha(200),
                              child: Center(
                                child: Text(
                                  !_setting.reverseScroll ? '上\n一\n页' : '下\n一\n页', // 上一页 / 下一页(反)
                                  style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                            Container(
                              height: viewHeight,
                              width: viewWidth * (1 - 2 * _kSlideWidthRatio),
                              color: Colors.blue[300]!.withAlpha(200),
                              child: Center(
                                child: Text(
                                  '菜单',
                                  style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                            Container(
                              height: viewHeight,
                              width: viewWidth * _kSlideWidthRatio,
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
      ),
    );
  }
}
