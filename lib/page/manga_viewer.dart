import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga_toc.dart';
import 'package:manhuagui_flutter/page/page/view_setting.dart';
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

class _MangaViewerPageState extends State<MangaViewerPage> with AutomaticKeepAliveClientMixin {
  final _mangaGalleryViewKey = GlobalKey<MangaGalleryViewState>();
  Timer? _timer;
  var _currentTime = '00:00';

  var _setting = ViewSetting.defaultSetting();
  late var _showAppBar = widget.showAppBar; // 显示工具栏
  var _showRegion = false; // 显示区域提示

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
      _initialPage = widget.initialPage > 0 && widget.initialPage <= _data!.pageCount ? widget.initialPage : 1; // TODO given -1
      _currentPage = _initialPage!;
      _progressValue = _initialPage!;

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

  void _gotoChapter({required bool last}) {
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


    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (c) => MangaViewerPage(
          mid: widget.mid,
          cid: last ? _data!.prevCid : _data!.nextCid,
          mangaTitle: widget.mangaTitle,
          mangaCover: widget.mangaCover,
          mangaUrl: widget.mangaUrl,
          chapterGroups:  widget. chapterGroups,
          initialPage: (!last /* || isAppBar */) ? 1 : -1, // 下一章节 || 工具栏点击的上一章节 => 第一页，否则 => 最后一页 // TODO
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
                  // TODO add reload and long pressed popup menu
                  child: MangaGalleryView(
                    key: _mangaGalleryViewKey,
                    imageCount: _data!.pages.length,
                    imageUrls: _data!.pages,
                    preloadPagesCount: _setting.preloadCount,
                    reverseScroll: _setting.reverseScroll,
                    viewportFraction: _setting.enablePageSpace ? _kViewportFraction : 1,
                    slideWidthRatio: _kSlideWidthRatio,
                    onPageChanged: _onPageChanged,
                    initialImageIndex: _initialPage ?? 1,
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
                    duration: Duration(milliseconds: 200),
                    child: !(_data != null && (!_showAppBar || _inExtraPage) && _setting.showPageHint)
                        ? SizedBox(height: 0)
                        : Container(
                            color: Colors.black.withOpacity(0.65),
                            padding: EdgeInsets.only(left: 8, right: 8, top: 1.5, bottom: 1.5),
                            child: Text(
                              !_inExtraPage
                                  ? '${_data!.title} $_currentPage/${_data!.pageCount}页 $_currentTime' //
                                  : '${_data!.title} $_currentTime',
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
                    duration: Duration(milliseconds: 200),
                    child: !(_data != null && _showAppBar && !_inExtraPage)
                        ? SizedBox(height: 0)
                        : Container(
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
                                        action: () => _gotoChapter(last: !_setting.reverseScroll),
                                      ),
                                      _buildAction(
                                        text: !_setting.reverseScroll ? '下一章节' : '上一章节',
                                        icon: Icons.arrow_right_alt,
                                        action: () => _gotoChapter(last: _setting.reverseScroll),
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
                                            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - Theme.of(context).appBarTheme.toolbarHeight!,
                                            child: MangaTocPage(
                                              mid: widget.mid,
                                              mangaTitle: widget.mangaTitle,
                                              mangaCover: widget.mangaCover,
                                              mangaUrl: widget.mangaUrl,
                                              groups: widget. chapterGroups,
                                            ),
                                          ),
                                        ), // TODO
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
