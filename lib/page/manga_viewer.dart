import 'dart:async' show Timer;
import 'dart:io' show File;
import 'dart:math' as math;

import 'package:battery_info/battery_info_plugin.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/comments.dart';
import 'package:manhuagui_flutter/page/download_select.dart';
import 'package:manhuagui_flutter/page/download_toc.dart';
import 'package:manhuagui_flutter/page/page/app_setting.dart';
import 'package:manhuagui_flutter/page/page/view_extra.dart';
import 'package:manhuagui_flutter/page/page/view_setting.dart';
import 'package:manhuagui_flutter/page/page/view_toc.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/manga_gallery.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/android.dart';
import 'package:manhuagui_flutter/service/native/share.dart';
import 'package:manhuagui_flutter/service/native/system_ui.dart';
import 'package:manhuagui_flutter/service/storage/download.dart';
import 'package:manhuagui_flutter/service/prefs/view_setting.dart';
import 'package:wakelock/wakelock.dart';

/// 漫画章节阅读页
class MangaViewerPage extends StatefulWidget {
  const MangaViewerPage({
    Key? key,
    required this.parentContext,
    required this.mangaId,
    required this.chapterId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.chapterGroups,
    this.initialPage = 1, // starts from 1
  }) : super(key: key);

  final BuildContext parentContext;
  final int mangaId;
  final int chapterId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final List<MangaChapterGroup>? chapterGroups;
  final int initialPage;

  @override
  _MangaViewerPageState createState() => _MangaViewerPageState();
}

const _kSlideWidthRatio = 0.2; // 点击跳转页面的区域比例
const _kSlideHeightRatio = 0.2; // 点击跳转页面的区域比例
const _kViewportFraction = 1.08; // 页面间隔
const _kViewportPageSpace = 25.0; // 页面间隔
const _kAnimationDuration = Duration(milliseconds: 150); // 动画时长
const _kOverlayAnimationDuration = Duration(milliseconds: 100); // SystemUI 动画时长

class _MangaViewerPageState extends State<MangaViewerPage> with AutomaticKeepAliveClientMixin {
  final _mangaGalleryViewKey = GlobalKey<MangaGalleryViewState>();
  final _cancelHandlers = <VoidCallback>[];

  var _setting = ViewSetting.defaultSetting();
  Timer? _timer;
  var _currentTime = '00:00';
  var _networkInfo = 'WIFI';
  var _batteryInfo = '0%';

  @override
  void initState() {
    super.initState();

    // data related
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
    _cancelHandlers.add(EventBusManager.instance.listen<SubscribeUpdatedEvent>((e) {
      if (e.mangaId == widget.mangaId) {
        _subscribed = e.subscribe;
        if (mounted) setState(() {});
      }
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadedMangaEntityChangedEvent>((_) => _loadDownload()));

    // setting and screen related
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      // initialize in async manner
      _ScreenHelper.initialize(
        context: context,
        setState: () => mountedSetState(() {}),
      );

      // setting
      _setting = await ViewSettingPrefs.getSetting();
      if (mounted) setState(() {});

      // apply settings
      await _ScreenHelper.toggleWakelock(enable: _setting.keepScreenOn);
      await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
    });

    // timer related
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      Future<void> getInfo() async {
        var now = DateTime.now();
        _currentTime = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
        var conn = await Connectivity().checkConnectivity();
        _networkInfo = conn == ConnectivityResult.wifi ? 'WIFI' : (conn == ConnectivityResult.mobile ? '移动网络' : '无网络');
        var battery = await BatteryInfoPlugin().androidBatteryInfo;
        _batteryInfo = '电源${(battery?.batteryLevel ?? 0).clamp(0, 100)}%';
        if (mounted) setState(() {});
      }

      getInfo();
      var now = DateTime.now();
      var nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
      if (mounted && (_timer == null || !_timer!.isActive)) {
        Timer(nextMinute.difference(now), () {
          _timer = Timer.periodic(const Duration(minutes: 1), (_) async {
            if (_timer != null && _timer!.isActive) {
              await getInfo();
            }
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _timer?.cancel();
    super.dispose();
  }

  var _loading = true;
  MangaChapter? _data;
  DownloadedManga? _downloadEntity;
  List<MangaChapterGroup>? _chapterGroups;
  int? _initialPage;
  List<Future<String>>? _urlFutures;
  List<Future<File?>>? _fileFutures;
  var _error = '';

  var _subscribing = false;
  var _subscribed = false;

  Future<void> _loadData() async {
    _loading = true;
    if (mounted) setState(() {});

    final client = RestClient(DioManager.instance.dio);

    if (AuthManager.instance.logined) {
      // 1. 异步更新章节阅读记录
      Future.microtask(() async {
        try {
          await client.recordManga(token: AuthManager.instance.token, mid: widget.mangaId, cid: widget.chapterId);
        } catch (_) {}
      });

      // 2. 异步获取漫画订阅信息
      Future.microtask(() async {
        try {
          var r = await client.checkShelfManga(token: AuthManager.instance.token, mid: widget.mangaId);
          _subscribed = r.data.isIn;
          if (mounted) setState(() {});
        } catch (e, s) {
          if (_error.isEmpty) {
            Fluttertoast.showToast(msg: wrapError(e, s).text);
          }
        }
      });
    }

    // 3. 异步获取下载信息
    _loadDownload();

    try {
      // 4. 异步请求章节目录
      Future<TaskResult<List<MangaChapterGroup>, Object>> groupsFuture;
      if (widget.chapterGroups != null) {
        groupsFuture = Future.value(Ok(widget.chapterGroups!));
      } else {
        groupsFuture = Future.microtask(() async {
          try {
            var result = await client.getManga(mid: widget.mangaId);
            return Ok(result.data.chapterGroups);
          } catch (e) {
            return Err(e); // ignore stack trace
          }
        });
      }

      // 5. 获取章节数据
      var result = await client.getMangaChapter(mid: widget.mangaId, cid: widget.chapterId);
      _data = result.data;
      _error = '';
      _chapterGroups = (await groupsFuture).unwrap(); // 等待成功获取章节目录

      // 6. 指定起始页
      _initialPage = widget.initialPage.clamp(1, _data!.pageCount);
      _currentPage = _initialPage!;
      _progressValue = _initialPage!;

      // 7. 提前保存 future 列表
      _urlFutures = _data!.pages.map((url) {
        if (url.startsWith('//')) {
          url = 'https:$url';
        }
        return Future.value(url);
      }).toList();
      _fileFutures = [
        for (int idx = 0; idx < _data!.pageCount; idx++)
          !AppSetting.global.usingDownloadedPage
              ? Future<File?>.value(null) // 阅读时不载入已下载的页面
              : getDownloadedChapterPageFile(
                  mangaId: widget.mangaId,
                  chapterId: _data!.cid,
                  pageIndex: idx,
                  url: _data!.pages[idx],
                ), // Future<File?>
      ];

      // 8. 异步更新浏览历史
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
          mangaId: widget.mangaId,
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

  Future<void> _loadDownload() async {
    _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId);
    if (mounted) setState(() {});
  }

  var _currentPage = 1; // image page only, starts from 1
  var _progressValue = 1; // image page only, starts from 1
  var _inExtraPage = false;

  void _onPageChanged(int imageIndex, bool inFirstExtraPage, bool inLastExtraPage) {
    _currentPage = imageIndex;
    _progressValue = imageIndex;
    var inExtraPage = inFirstExtraPage || inLastExtraPage;
    if (inExtraPage != _inExtraPage) {
      if (inExtraPage) {
        _ScreenHelper.toggleAppBarVisibility(show: false, fullscreen: _setting.fullscreen);
      }
      _inExtraPage = inExtraPage;
    }
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

    Navigator.of(context).pop(); // pop this page, should not use maybePop
    Navigator.of(context).push(
      CustomPageRoute(
        context: widget.parentContext,
        builder: (c) => MangaViewerPage(
          parentContext: widget.parentContext,
          mangaId: widget.mangaId,
          mangaTitle: widget.mangaTitle,
          mangaCover: widget.mangaCover,
          mangaUrl: widget.mangaUrl,
          chapterGroups: _chapterGroups,
          chapterId: gotoPrevious ? _data!.prevCid : _data!.nextCid,
          initialPage: 1,
        ),
      ),
    );
  }

  var _showHelpRegion = false; // 显示区域提示

  Future<void> _onSettingPressed() async {
    _setting = await ViewSettingPrefs.getSetting();
    var setting = _setting.copyWith();
    return showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('阅读设置'),
        scrollable: true,
        content: ViewSettingSubPage(
          setting: setting,
          onSettingChanged: (s) => setting = s,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            child: Text('操作'),
            onPressed: () {
              Navigator.of(c).pop();
              _showHelpRegion = true;
              if (mounted) setState(() {});
              _ScreenHelper.toggleAppBarVisibility(show: false, fullscreen: _setting.fullscreen);
            },
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                child: Text('确定'),
                onPressed: () async {
                  Navigator.of(c).pop();
                  _setting = setting;
                  if (mounted) setState(() {});
                  await ViewSettingPrefs.setSetting(_setting);

                  // apply settings
                  await _ScreenHelper.toggleWakelock(enable: _setting.keepScreenOn);
                  await _ScreenHelper.setSystemUIWhenSettingChanged(fullscreen: _setting.fullscreen);
                },
              ),
              TextButton(
                child: Text('取消'),
                onPressed: () => Navigator.of(c).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _download(int imageIndex, String url) async {
    var f = await downloadImageToGallery(url);
    if (f != null) {
      Fluttertoast.showToast(msg: '第$imageIndex页已保存至 ${f.path}');
    } else {
      Fluttertoast.showToast(msg: '无法保存第$imageIndex页');
    }
  }

  Future<void> _subscribe() async {
    if (!AuthManager.instance.logined) {
      Fluttertoast.showToast(msg: '用户未登录');
      return;
    }

    final client = RestClient(DioManager.instance.dio);
    var toSubscribe = _subscribed != true; // 去订阅
    if (!toSubscribe) {
      var ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('取消订阅确认'),
          content: Text('是否取消订阅《${_data!.mangaTitle}》？'),
          actions: [
            TextButton(
              child: Text('确定'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            TextButton(
              child: Text('取消'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      );
      if (ok != true) {
        return;
      }
    }

    _subscribing = true;
    if (mounted) setState(() {});

    try {
      await (toSubscribe ? client.addToShelf : client.removeFromShelf)(token: AuthManager.instance.token, mid: widget.mangaId);
      _subscribed = toSubscribe;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(toSubscribe ? '订阅漫画成功' : '取消订漫画阅成功'),
        ),
      );
      EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: widget.mangaId, subscribe: _subscribed));
    } catch (e, s) {
      var err = wrapError(e, s).text;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(toSubscribe ? '订阅漫画失败，$err' : '取消订阅漫画失败，$err'),
        ),
      );
    } finally {
      _subscribing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _downloadManga() async {
    await _ScreenHelper.restoreSystemUI();
    await Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => DownloadSelectPage(
          mangaId: widget.mangaId,
          mangaTitle: widget.mangaTitle,
          mangaCover: widget.mangaCover,
          mangaUrl: widget.mangaUrl,
          groups: _chapterGroups!,
        ),
      ),
    );
    await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
  }

  Future<void> _showDownloadedManga() async {
    await _ScreenHelper.restoreSystemUI();
    await Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => DownloadTocPage(
          mangaId: widget.mangaId,
        ),
        settings: DownloadTocPage.buildRouteSetting(
          mangaId: widget.mangaId,
        ),
      ),
    );
    await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
  }

  Future<void> _showToc() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: Container(
          height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical - Theme.of(context).appBarTheme.toolbarHeight!,
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: ViewTocSubPage(
            mangaId: widget.mangaId,
            mangaTitle: widget.mangaTitle,
            groups: _chapterGroups!,
            highlightedChapter: _data!.cid,
            downloadedChapters: _downloadEntity?.downloadedChapters ?? [],
            onChapterPressed: (cid) {
              if (cid == _data!.cid) {
                Fluttertoast.showToast(msg: '当前正在阅读 ${_data!.title}');
              } else {
                Navigator.of(c).pop(); // bottom sheet
                Navigator.of(context).pop(); // this page, should not use maybePop
                Navigator.of(context).push(
                  CustomPageRoute(
                    context: widget.parentContext,
                    builder: (c) => MangaViewerPage(
                      parentContext: widget.parentContext,
                      mangaId: _data!.mid,
                      mangaTitle: _data!.mangaTitle,
                      mangaCover: widget.mangaCover,
                      mangaUrl: widget.mangaUrl,
                      chapterGroups: _chapterGroups,
                      chapterId: cid,
                      initialPage: 1, // always turn to the first page
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
    await Future.delayed(kBottomSheetExitDuration + Duration(milliseconds: 10));
    await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
  }

  Future<void> _showComments() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: Container(
          height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical - Theme.of(context).appBarTheme.toolbarHeight!,
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: CommentsPage(
            mangaId: _data!.mid,
            mangaTitle: _data!.mangaTitle,
          ),
        ),
      ),
    );
    await Future.delayed(kBottomSheetExitDuration + Duration(milliseconds: 10));
    await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: () async {
        // 全部都异步执行
        _updateHistory();
        _ScreenHelper.restoreWakelock();
        _ScreenHelper.restoreSystemUI();
        _ScreenHelper.restoreAppBarVisibility();
        return true;
      },
      child: SafeArea(
        top: _ScreenHelper.safeAreaTop,
        bottom: false,
        child: Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(Theme.of(context).appBarTheme.toolbarHeight!),
            child: AnimatedSwitcher(
              duration: _kAnimationDuration,
              child: !(!_loading && _data != null && _ScreenHelper.showAppBar)
                  ? const SizedBox.shrink()
                  : AppBar(
                      backgroundColor: Colors.black.withOpacity(0.7),
                      elevation: 0,
                      title: Text(
                        _data!.title,
                        style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.white),
                      ),
                      leading: AppBarActionButton(
                        icon: Icon(Icons.arrow_back),
                        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        highlightColor: Colors.transparent,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      actions: [
                        if (_downloadEntity?.downloadedChapters.any((el) => el.chapterId == widget.chapterId) == true)
                          AppBarActionButton(
                            icon: Icon(Icons.download_done),
                            tooltip: '下载情况',
                            highlightColor: Colors.transparent,
                            onPressed: () {
                              var chapter = _downloadEntity?.downloadedChapters.where((el) => el.chapterId == widget.chapterId).firstOrNull;
                              if (chapter == null) {
                                return;
                              }
                              showDialog(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: Text('下载情况'),
                                  content: Text(
                                    !chapter.tried
                                        ? '该章节正在等待下载。'
                                        : chapter.succeeded
                                            ? '该章节已下载完成。'
                                            : '该章节部分页已下载完成。',
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text('查看'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _showDownloadedManga();
                                      },
                                    ),
                                    TextButton(
                                      child: Text('确定'),
                                      onPressed: () => Navigator.of(c).pop(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
            ),
          ),
          body: PlaceholderText(
            state: _loading
                ? PlaceholderState.loading
                : _data == null
                    ? PlaceholderState.error
                    : PlaceholderState.normal,
            errorText: _error,
            onRefresh: () => _loadData(),
            setting: PlaceholderSetting(
              iconColor: Colors.grey[400]!,
              showLoadingText: false,
              textStyle: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.grey[400]!),
              buttonTextStyle: TextStyle(color: Colors.grey[400]!),
              buttonStyle: ButtonStyle(
                side: MaterialStateProperty.all(BorderSide(color: Colors.grey[400]!)),
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
                    imageUrlFutures: _urlFutures!,
                    imageFileFutures: _fileFutures!,
                    preloadPagesCount: _setting.preloadCount,
                    verticalScroll: _setting.viewDirection == ViewDirection.topToBottom,
                    horizontalReverseScroll: _setting.viewDirection == ViewDirection.rightToLeft,
                    horizontalViewportFraction: _setting.enablePageSpace ? _kViewportFraction : 1,
                    verticalViewportPageSpace: _setting.enablePageSpace ? _kViewportPageSpace : 0,
                    slideWidthRatio: _kSlideWidthRatio,
                    slideHeightRatio: _kSlideHeightRatio,
                    initialImageIndex: _initialPage ?? 1,
                    onPageChanged: _onPageChanged,
                    onSaveImage: (imageIndex) => _download(imageIndex, _data!.pages[imageIndex - 1]),
                    onShareImage: (imageIndex) => shareText(
                      title: '漫画柜分享',
                      text: '【${_data!.mangaTitle} ${_data!.title}】第$imageIndex页 ${_data!.pages[imageIndex - 1]}',
                    ),
                    onCenterAreaTapped: () {
                      _ScreenHelper.toggleAppBarVisibility(show: !_ScreenHelper.showAppBar, fullscreen: _setting.fullscreen);
                      if (mounted) setState(() {});
                    },
                    firstPageBuilder: (c) => ViewExtraSubPage(
                      isHeader: true,
                      reverseScroll: _setting.viewDirection == ViewDirection.rightToLeft,
                      chapter: _data!,
                      mangaCover: widget.mangaCover,
                      chapterTitleGetter: (cid) => _chapterGroups?.findChapter(cid)?.title,
                      subscribing: _subscribing,
                      subscribed: _subscribed,
                      toJumpToImage: (idx, anim) => _mangaGalleryViewKey.currentState?.jumpToImage(idx, animated: anim),
                      toGotoChapter: (prev) => _gotoChapter(gotoPrevious: prev),
                      toSubscribe: _subscribe,
                      toDownload: _downloadManga,
                      toShowToc: _showToc,
                      toShowComments: _showComments,
                      toPop: () => Navigator.of(context).maybePop(),
                    ),
                    lastPageBuilder: (c) => ViewExtraSubPage(
                      isHeader: false,
                      reverseScroll: _setting.viewDirection == ViewDirection.rightToLeft,
                      chapter: _data!,
                      mangaCover: widget.mangaCover,
                      chapterTitleGetter: (cid) => _chapterGroups?.findChapter(cid)?.title,
                      subscribing: _subscribing,
                      subscribed: _subscribed,
                      toJumpToImage: (idx, anim) => _mangaGalleryViewKey.currentState?.jumpToImage(idx, animated: anim),
                      toGotoChapter: (prev) => _gotoChapter(gotoPrevious: prev),
                      toSubscribe: _subscribe,
                      toDownload: _downloadManga,
                      toShowToc: _showToc,
                      toShowComments: _showComments,
                      toPop: () => Navigator.of(context).maybePop(),
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
                    duration: _kAnimationDuration,
                    child: !(_data != null && !_ScreenHelper.showAppBar && !_inExtraPage && _setting.showPageHint)
                        ? const SizedBox.shrink()
                        : Container(
                            color: Colors.black.withOpacity(0.7),
                            padding: EdgeInsets.only(left: 8, right: 8, top: 1.5, bottom: 1.5),
                            child: Text(
                              [
                                _data!.title,
                                '$_currentPage/${_data!.pageCount}页',
                                if (_setting.showNetwork) _networkInfo,
                                if (_setting.showBattery) _batteryInfo,
                                if (_setting.showClock) _currentTime,
                              ].join(' '),
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
                    duration: _kAnimationDuration,
                    child: !(_data != null && _ScreenHelper.showAppBar)
                        ? const SizedBox.shrink()
                        : Container(
                            color: Colors.black.withOpacity(0.7),
                            padding: EdgeInsets.only(left: 12, right: 12, top: 0, bottom: _ScreenHelper.bottomPanelDistance + 6),
                            width: MediaQuery.of(context).size.width,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Directionality(
                                        textDirection: _setting.viewDirection == ViewDirection.rightToLeft ? TextDirection.rtl : TextDirection.ltr,
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
                                ActionRowView.four(
                                  compact: true,
                                  textColor: Colors.white,
                                  iconColor: Colors.white,
                                  action1: ActionItem(
                                    text: _setting.viewDirection != ViewDirection.rightToLeft ? '上一章节' : '下一章节',
                                    icon: Icons.arrow_right_alt,
                                    rotateAngle: math.pi,
                                    action: () => _gotoChapter(gotoPrevious: _setting.viewDirection != ViewDirection.rightToLeft),
                                  ),
                                  action2: ActionItem(
                                    text: _setting.viewDirection != ViewDirection.rightToLeft ? '下一章节' : '上一章节',
                                    icon: Icons.arrow_right_alt,
                                    action: () => _gotoChapter(gotoPrevious: _setting.viewDirection == ViewDirection.rightToLeft),
                                  ),
                                  action3: ActionItem(
                                    text: '阅读设置',
                                    icon: Icons.settings,
                                    action: () => _onSettingPressed(),
                                  ),
                                  action4: ActionItem(
                                    text: '漫画目录',
                                    icon: Icons.menu,
                                    action: () => _showToc(),
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
                if (_showHelpRegion)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        _showHelpRegion = false;
                        if (mounted) setState(() {});
                      },
                      child: DefaultTextStyle(
                        style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.white),
                        child: _setting.viewDirection != ViewDirection.topToBottom
                            ? Row(
                                children: [
                                  Container(
                                    width: MediaQuery.of(context).size.width * _kSlideWidthRatio,
                                    color: Colors.orange[300]!.withOpacity(0.75),
                                    alignment: Alignment.center,
                                    child: Text(_setting.viewDirection == ViewDirection.leftToRight ? '上\n一\n页' : '下\n一\n页'),
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width * (1 - 2 * _kSlideWidthRatio),
                                    color: Colors.blue[300]!.withOpacity(0.75),
                                    alignment: Alignment.center,
                                    child: Text('菜单'),
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width * _kSlideWidthRatio,
                                    color: Colors.pink[300]!.withOpacity(0.75),
                                    alignment: Alignment.center,
                                    child: Text(_setting.viewDirection == ViewDirection.leftToRight ? '下\n一\n页' : '上\n一\n页'),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Container(
                                    height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical) * _kSlideHeightRatio,
                                    color: Colors.orange[300]!.withOpacity(0.75),
                                    alignment: Alignment.center,
                                    child: Text('上一页'),
                                  ),
                                  Container(
                                    height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical) * (1 - 2 * _kSlideHeightRatio),
                                    color: Colors.blue[300]!.withOpacity(0.75),
                                    alignment: Alignment.center,
                                    child: Text('菜单'),
                                  ),
                                  Container(
                                    height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical) * _kSlideHeightRatio,
                                    color: Colors.pink[300]!.withOpacity(0.75),
                                    alignment: Alignment.center,
                                    child: Text('下一页'),
                                  ),
                                ],
                              ),
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

class _ScreenHelper {
  static late BuildContext _context;
  static void Function() _setState = () {};

  static void initialize({required BuildContext context, required void Function() setState}) {
    _context = context;
    _setState = setState;
  }

  static Future<void> toggleWakelock({required bool enable}) {
    return Wakelock.toggle(enable: enable);
  }

  static Future<void> restoreWakelock() {
    return Wakelock.toggle(enable: false);
  }

  static bool _showAppBar = false; // default to hide

  static bool get showAppBar => _showAppBar;

  static Future<void> toggleAppBarVisibility({required bool show, required bool fullscreen}) async {
    if (_showAppBar == true && show == false) {
      _showAppBar = false;
      _setState();
      if (fullscreen) {
        await Future.delayed(_kAnimationDuration + Duration(milliseconds: 50));
        await _ScreenHelper.setSystemUIWhenAppbarChanged(fullscreen: fullscreen, isAppbarShown: false);
      }
    } else if (_showAppBar == false && show == true) {
      if (fullscreen) {
        await _ScreenHelper.setSystemUIWhenAppbarChanged(fullscreen: fullscreen, isAppbarShown: true);
        await Future.delayed(_kOverlayAnimationDuration + Duration(milliseconds: 50));
      }
      _showAppBar = true;
      _setState();
    }
    await WidgetsBinding.instance?.endOfFrame;
  }

  static Future<void> restoreAppBarVisibility() async {
    _showAppBar = false;
    _safeAreaTop = true;
    _bottomPanelDistance = 0;
    // no setState
  }

  static bool _safeAreaTop = true; // defaults to non-fullscreen

  static bool get safeAreaTop => _safeAreaTop;

  static double _bottomPanelDistance = 0; // defaults to non-fullscreen

  static double get bottomPanelDistance => _bottomPanelDistance;

  static Future<void> setSystemUIWhenEnter({required bool fullscreen}) async {
    var color = !fullscreen || await lowerThanAndroidQ() ? Colors.black : Colors.transparent;
    setSystemUIOverlayStyle(
      navigationBarIconBrightness: Brightness.light,
      navigationBarColor: color,
      navigationBarDividerColor: color,
    );
    await setSystemUIWhenAppbarChanged(fullscreen: fullscreen, isAppbarShown: _showAppBar);
  }

  static Future<void> setSystemUIWhenSettingChanged({required bool fullscreen}) async {
    await setSystemUIWhenEnter(fullscreen: fullscreen);
  }

  static Future<void> setSystemUIWhenAppbarChanged({required bool fullscreen, required bool isAppbarShown}) async {
    // https://hiyoko-programming.com/953/
    if (!fullscreen) {
      // 不全屏 => 全部显示，不透明 (manual)
      await setManualSystemUIMode(SystemUiOverlay.values);
      _safeAreaTop = true;
      _bottomPanelDistance = 0;
    } else if (!isAppbarShown) {
      // 全屏，且不显示 AppBar => 全部隐藏 (manual)
      await setManualSystemUIMode([]);
      _safeAreaTop = false;
      _bottomPanelDistance = 0;
    } else {
      // 全屏，且显示 AppBar => 全部显示，尽量透明 (edgeToEdge / manual)
      if (!(await lowerThanAndroidQ())) {
        await setEdgeToEdgeSystemUIMode();
        _safeAreaTop = false;
        await Future.delayed(_kOverlayAnimationDuration + Duration(milliseconds: 50));
        _bottomPanelDistance = MediaQuery.of(_context).padding.bottom;
      } else {
        await setManualSystemUIMode(SystemUiOverlay.values);
        _safeAreaTop = false;
        _bottomPanelDistance = 0;
      }
    }
    _setState();
    await WidgetsBinding.instance?.endOfFrame;
  }

  static Future<void> restoreSystemUI() async {
    setDefaultSystemUIOverlayStyle();
    await setManualSystemUIMode(SystemUiOverlay.values);
  }
}
