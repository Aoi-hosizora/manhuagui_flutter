import 'dart:async' show Timer;
import 'dart:io' show File;
import 'dart:math' as math;

import 'package:battery_info/battery_info_plugin.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/comments.dart';
import 'package:manhuagui_flutter/page/download_choose.dart';
import 'package:manhuagui_flutter/page/download_manga.dart';
import 'package:manhuagui_flutter/page/image_viewer.dart';
import 'package:manhuagui_flutter/page/page/manga_dialog.dart';
import 'package:manhuagui_flutter/page/page/view_extra.dart';
import 'package:manhuagui_flutter/page/page/view_setting.dart';
import 'package:manhuagui_flutter/page/page/view_toc.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/manga_gallery.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
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
import 'package:wakelock/wakelock.dart';

/// 漫画章节阅读页
class MangaViewerPage extends StatefulWidget {
  const MangaViewerPage({
    Key? key,
    required this.parentContext,
    required this.mangaId,
    required this.chapterId,
    required this.mangaCover,
    required this.chapterGroups,
    required this.onlineMode,
    required this.initialPage, // starts from 1
    this.onMangaGot, // for download manga page
  }) : super(key: key);

  final BuildContext parentContext;
  final int mangaId;
  final int chapterId;
  final String mangaCover;
  final List<MangaChapterGroup>? chapterGroups;
  final bool onlineMode;
  final int initialPage;
  final void Function(Manga)? onMangaGot;

  @override
  _MangaViewerPageState createState() => _MangaViewerPageState();
}

/// 页面数据，基本覆盖 [TinyMangaChapter]，在 [MangaViewerPage] / [ViewExtraSubPage] 使用
class MangaViewerPageData {
  const MangaViewerPageData({
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.chapterTitle,
    required this.pageCount,
    required this.pages,
    required this.nextChapterId,
    required this.prevChapterId,
    required this.chapterGroups,
  });

  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final String chapterTitle;
  final int pageCount;
  final List<String> pages;
  final int? nextChapterId;
  final int? prevChapterId;
  final List<MangaChapterGroup>? chapterGroups;

  String get chapterCover => pages.isNotEmpty ? pages.first : '';

  String? get nextChapterTitle => nextChapterId == null ? null : (chapterGroups?.findChapter(nextChapterId!)?.title ?? '未知章节');

  String? get prevChapterTitle => prevChapterId == null ? null : (chapterGroups?.findChapter(prevChapterId!)?.title ?? '未知章节');

  MangaViewerPageData updateChapterGroups(List<MangaChapterGroup> chapterGroups) {
    return MangaViewerPageData(
      mangaTitle: mangaTitle,
      mangaCover: mangaCover,
      mangaUrl: mangaUrl,
      chapterTitle: chapterTitle,
      pageCount: pageCount,
      pages: pages,
      nextChapterId: nextChapterId,
      prevChapterId: prevChapterId,
      chapterGroups: chapterGroups,
    );
  }
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

  ViewSetting get _setting => AppSetting.instance.view;

  bool get _isLeftToRight => _setting.viewDirection == ViewDirection.leftToRight;

  bool get _isRightToLeft => _setting.viewDirection == ViewDirection.rightToLeft;

  bool get _isTopToBottom => _setting.viewDirection == ViewDirection.topToBottom;

  Timer? _timer;
  var _currentTime = '00:00';
  var _networkInfo = 'WIFI';
  var _batteryInfo = '0%';

  @override
  void initState() {
    super.initState();

    // data related
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
    _cancelHandlers.add(EventBusManager.instance.listen<ShelfUpdatedEvent>((ev) async {
      if (ev.mangaId == widget.mangaId) {
        _inShelf = ev.added;
        if (mounted) setState(() {});
      }
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<FavoriteUpdatedEvent>((ev) async {
      if (ev.mangaId == widget.mangaId) {
        _inFavorite = ev.reason != UpdateReason.deleted;
        if (mounted) setState(() {});
      }
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadUpdatedEvent>((ev) async {
      if (ev.mangaId == widget.mangaId) {
        _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId);
        _downloadChapter = _downloadEntity?.downloadedChapters.where((el) => el.chapterId == widget.chapterId).firstOrNull;
        if (mounted) setState(() {});
      }
    }));

    // setting and screen related
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      // initialize in async manner
      _ScreenHelper.initialize(context: context, setState: () => mountedSetState(() {}));
      // apply settings to screen
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

  var _loading = true; // initialize to true
  MangaViewerPageData? _data;
  var _error = '';

  int? _initialPage;
  List<Future<String?>>? _urlFutures;
  List<Future<File?>>? _fileFutures;

  int? _subscribeCount;
  FavoriteManga? _favoriteManga;
  var _subscribing = false; // 执行订阅操作中
  var _inShelf = false; // 书架
  var _inFavorite = false; // 收藏
  DownloadedManga? _downloadEntity;
  DownloadedChapter? _downloadChapter;

  Future<void> _loadData() async {
    _loading = true;
    if (mounted) setState(() {});

    final client = RestClient(DioManager.instance.dio);
    if (AuthManager.instance.logined) {
      // 1. 异步更新章节阅读记录
      Future.microtask(() async {
        try {
          await client.recordManga(token: AuthManager.instance.token, mid: widget.mangaId, cid: widget.chapterId);
        } catch (e, s) {
          var we = wrapError(e, s);
          globalLogger.e('MangaViewerPage._loadData recordManga: ${we.text}', e, s);
        }
      });

      // 2. 异步获取漫画书架信息
      Future.microtask(() async {
        try {
          var r = await client.checkShelfManga(token: AuthManager.instance.token, mid: widget.mangaId);
          _inShelf = r.data.isIn;
          _subscribeCount = r.data.count;
          if (mounted) setState(() {});
        } catch (e, s) {
          var we = wrapError(e, s);
          globalLogger.e('MangaViewerPage._loadData checkShelfManga: ${we.text}', e, s);
          Fluttertoast.showToast(msg: we.text);
        }
      });
    }

    // 3. 获取各种数据库信息 (收藏、下载)
    _favoriteManga = await FavoriteDao.getFavorite(username: AuthManager.instance.username, mid: widget.mangaId);
    _inFavorite = _favoriteManga != null;
    _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId);
    _downloadChapter = _downloadEntity?.downloadedChapters.where((el) => el.chapterId == widget.chapterId).firstOrNull;

    try {
      if (widget.onlineMode) {
        // => (I) 在线模式，通过网络获取章节数据
        // I.4. 异步请求章节目录
        Future<TaskResult<List<MangaChapterGroup>, Object>> groupsFuture;
        if (widget.chapterGroups != null) {
          groupsFuture = Future.value(Ok(widget.chapterGroups!));
        } else {
          groupsFuture = Future.microtask(() async {
            try {
              var result = await client.getManga(mid: widget.mangaId);
              if (result.data.title == '') {
                throw SpecialException('未知错误'); // <<< 获取的漫画数据有问题
              }
              widget.onMangaGot?.call(result.data); // 将漫画数据保存至 DownloadMangaPage
              return Ok(result.data.chapterGroups);
            } catch (e) {
              return Err(e); // ignore stack trace
            }
          });
        }

        // I.5. 获取章节数据并整合至 page data
        var result = await client.getMangaChapter(mid: widget.mangaId, cid: widget.chapterId);
        var data = result.data;
        var groups = (await groupsFuture).unwrap(); // 等待成功获取章节目录
        _error = '';
        _data = MangaViewerPageData(
          mangaTitle: data.mangaTitle,
          mangaCover: widget.mangaCover,
          mangaUrl: data.mangaUrl,
          chapterTitle: data.title,
          pageCount: data.pages.length,
          pages: data.pages,
          nextChapterId: data.nextCid,
          prevChapterId: data.prevCid,
          chapterGroups: groups,
        );
        _preparePageAndFutures(); // 初始化页码和页面列表
      } else {
        // => (II) 离线模式，使用已下载的漫画章节数据
        var manga = _downloadEntity, chapter = _downloadChapter;
        if (manga == null || chapter == null) {
          _error = '当前处于离线模式，但该章节尚未下载\n请先切换成在线模式再阅读';
        } else {
          // II.4. 将下载漫画时记录的数据整合至 page data
          var metadata = await readMetadataFile(mangaId: widget.mangaId, chapterId: widget.chapterId, pageCount: chapter.totalPageCount);
          _error = '';
          _data = MangaViewerPageData(
            mangaTitle: manga.mangaTitle,
            mangaCover: manga.mangaCover,
            mangaUrl: manga.mangaUrl,
            chapterTitle: chapter.chapterTitle,
            pageCount: chapter.totalPageCount,
            pages: metadata.item1,
            nextChapterId: metadata.item2,
            prevChapterId: metadata.item3,
            chapterGroups: widget.chapterGroups /* maybe null */,
          );
          _preparePageAndFutures(); // 初始化页码和页面列表

          // II.5. 异步请求章节目录
          if (widget.chapterGroups == null) {
            Future.microtask(() async {
              try {
                var result = await client.getManga(mid: widget.mangaId);
                if (result.data.title == '') {
                  throw SpecialException('未知错误'); // <<< 获取的漫画数据有问题
                }
                widget.onMangaGot?.call(result.data); // 将漫画数据保存至 DownloadMangaPage
                _data = _data?.updateChapterGroups(result.data.chapterGroups); // no need to setState
              } catch (e, s) {
                var we = wrapError(e, s);
                globalLogger.e('MangaViewerPage._loadData getManga (offline): ${we.text}', e, s);
                Fluttertoast.showToast(msg: we.text);
              }
            });
          }
        }
      }

      // 6. 异步更新阅读历史
      _updateHistory();
    } catch (e, s) {
      _data = null;
      _error = wrapError(e, s).text;
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  void _preparePageAndFutures() {
    if (_data == null) {
      return; // unreachable
    }

    // 指定起始页，初始化进度条
    _initialPage = widget.initialPage.clamp(1, _data!.pageCount);
    _currentPage = _initialPage!;
    _progressValue = _initialPage!;

    // url future 列表
    _urlFutures = [
      for (int idx = 0; idx < _data!.pageCount; idx++)
        Future<String?>.value(
          _data!.pages[idx].let(
            (url) => !isPageUrlValidInMetadata(url)
                ? null // 离线模式下如果 metadata 内不包含有效链接则不访问网络
                : (url.startsWith('//') ? 'https:$url' : url),
          ),
        ),
    ];

    // file future 列表
    _fileFutures = [
      for (int idx = 0; idx < _data!.pageCount; idx++)
        isPageUrlValidInMetadata(_data!.pages[idx]) && !AppSetting.instance.other.usingDownloadedPage // 仅当链接有效时才可禁用载入页面文件
            ? Future<File?>.value(null) // 阅读时不载入已下载的页面
            : getDownloadedChapterPageFile(
                mangaId: widget.mangaId,
                chapterId: widget.chapterId,
                pageIndex: idx,
                url: _data!.pages[idx], // only for getting extension
              ),
    ];
  }

  // 载入时调用 / 离开页面时调用 / 跳转章节时调用
  Future<void> _updateHistory() async {
    if (_data != null) {
      var history = MangaHistory(
        mangaId: widget.mangaId,
        mangaTitle: _data!.mangaTitle,
        mangaCover: _data!.mangaCover,
        mangaUrl: _data!.mangaUrl,
        chapterId: widget.chapterId,
        chapterTitle: _data!.chapterTitle,
        chapterPage: _currentPage,
        lastTime: DateTime.now(),
      );
      await HistoryDao.addOrUpdateHistory(username: AuthManager.instance.username, history: history);
      EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: widget.mangaId, reason: UpdateReason.updated));
    }
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
    if ((gotoPrevious && _data!.prevChapterId == null) || (!gotoPrevious && _data!.nextChapterId == null)) {
      Fluttertoast.showToast(msg: '当前处于离线模式，但未在下载列表获取到章节跳转信息');
      return;
    }
    if ((gotoPrevious && _data!.prevChapterId == 0) || (!gotoPrevious && _data!.nextChapterId == 0)) {
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

    _updateHistory();
    Navigator.of(context).pushReplacement(
      CustomPageRoute(
        context: widget.parentContext,
        builder: (c) => MangaViewerPage(
          parentContext: widget.parentContext,
          mangaId: widget.mangaId,
          chapterId: gotoPrevious ? _data!.prevChapterId! : _data!.nextChapterId!,
          mangaCover: _data!.mangaCover,
          chapterGroups: _data!.chapterGroups,
          initialPage: 1,
          // always turn to the first page
          onlineMode: widget.onlineMode,
        ),
      ),
    );
  }

  var _showHelpRegion = false; // 显示区域提示

  Future<void> _onSettingPressed() async {
    var ok = await showViewSettingDialog(
      context: context,
      anotherButtonBuilder: (c) => TextButton(
        child: Text('操作'),
        onPressed: () {
          Navigator.of(c).pop();
          _showHelpRegion = true;
          if (mounted) setState(() {});
          _ScreenHelper.toggleAppBarVisibility(show: false, fullscreen: _setting.fullscreen);
        },
      ),
    );

    // apply settings to screen
    if (ok) {
      if (mounted) setState(() {});
      await _ScreenHelper.toggleWakelock(enable: _setting.keepScreenOn);
      await _ScreenHelper.setSystemUIWhenSettingChanged(fullscreen: _setting.fullscreen);
    }
  }

  Future<void> _download(int imageIndex, String url) async {
    if (!isPageUrlValidInMetadata(url)) {
      Fluttertoast.showToast(msg: '当前处于离线模式，但未在下载列表中获取到第$imageIndex页链接');
    } else {
      var f = await downloadImageToGallery(url);
      if (f != null) {
        Fluttertoast.showToast(msg: '第$imageIndex页已保存至 ${f.path}');
      } else {
        Fluttertoast.showToast(msg: '无法保存第$imageIndex页');
      }
    }
  }

  void _subscribe() {
    showPopupMenuForSubscribing(
      context: context,
      mangaId: widget.mangaId,
      mangaTitle: _data!.mangaTitle,
      mangaCover: _data!.mangaCover,
      mangaUrl: _data!.mangaUrl,
      fromMangaPage: false,
      nowInShelf: _inShelf,
      nowInFavorite: _inFavorite,
      subscribeCount: _subscribeCount,
      favoriteManga: _favoriteManga,
      subscribing: (s) => mountedSetState(() => _subscribing = s),
      inShelfSetter: (s) => mountedSetState(() => _inShelf = s),
      inFavoriteSetter: (f) {
        _inFavorite = f != null;
        _favoriteManga = f;
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _downloadManga() async {
    if (_data!.chapterGroups == null) {
      Fluttertoast.showToast(msg: '当前处于离线模式，正在获取漫画章节列表');
      return;
    }
    await _ScreenHelper.restoreSystemUI();
    await Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => DownloadChoosePage(
          mangaId: widget.mangaId,
          mangaTitle: _data!.mangaTitle,
          mangaCover: _data!.mangaCover,
          mangaUrl: _data!.mangaUrl,
          groups: _data!.chapterGroups!,
        ),
      ),
    );
    await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
  }

  Future<void> _showDownloadedManga({required bool gotoDownloading}) async {
    await _ScreenHelper.restoreSystemUI();
    await Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => DownloadMangaPage(
          mangaId: widget.mangaId,
          gotoDownloading: gotoDownloading,
        ),
        settings: DownloadMangaPage.buildRouteSetting(
          mangaId: widget.mangaId,
        ),
      ),
    );
    await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
  }

  Future<void> _showToc() async {
    if (_data!.chapterGroups == null) {
      Fluttertoast.showToast(msg: '当前处于离线模式，正在获取漫画章节列表');
      return;
    }
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
            mangaTitle: _data!.mangaTitle,
            groups: _data!.chapterGroups!,
            highlightedChapter: widget.chapterId,
            onChapterPressed: (cid) {
              if (cid == widget.chapterId) {
                Fluttertoast.showToast(msg: '当前正在阅读 ${_data!.chapterTitle}');
              } else {
                Navigator.of(c).pop(); // close bottom sheet
                _updateHistory();
                Navigator.of(context).pushReplacement(
                  CustomPageRoute(
                    context: widget.parentContext,
                    builder: (c) => MangaViewerPage(
                      parentContext: widget.parentContext,
                      mangaId: widget.mangaId,
                      chapterId: cid,
                      mangaCover: _data!.mangaCover,
                      chapterGroups: _data!.chapterGroups,
                      initialPage: 1,
                      // always turn to the first page
                      onlineMode: widget.onlineMode,
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
            mangaId: widget.mangaId,
            mangaTitle: _data!.mangaTitle,
          ),
        ),
      ),
    );
    await Future.delayed(kBottomSheetExitDuration + Duration(milliseconds: 10));
    await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
  }

  Future<void> _showImage(String url, String title) async {
    await _ScreenHelper.restoreSystemUI(notificationBar: false, fullscreen: true);
    await Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => ImageViewerPage(
          url: url,
          title: title,
          ignoreSystemUI: true,
        ),
      ),
    );
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
              child: !_loading && _data != null && !_ScreenHelper.showAppBar
                  ? const SizedBox.shrink()
                  : AppBar(
                      backgroundColor: Colors.black.withOpacity(0.7),
                      elevation: 0,
                      title: Text(
                        _data?.chapterTitle ?? widget.chapterGroups?.findChapter(widget.chapterId)?.title ?? '',
                        style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.white),
                      ),
                      leading: AppBarActionButton(
                        icon: Icon(Icons.arrow_back),
                        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        highlightColor: Colors.transparent,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      actions: [
                        if (!widget.onlineMode)
                          AppBarActionButton(
                            icon: Icon(Icons.public_off),
                            tooltip: '离线模式',
                            onPressed: () => showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: Text('离线模式'),
                                content: Text('当前正以离线模式阅读漫画章节，是否切换为在线模式？'),
                                actions: [
                                  TextButton(
                                    child: Text('切换'),
                                    onPressed: () {
                                      Navigator.of(c).pop(); // close dialog first
                                      Navigator.of(context).pushReplacement(
                                        CustomPageRoute(
                                          context: widget.parentContext,
                                          builder: (c) => MangaViewerPage(
                                            parentContext: widget.parentContext,
                                            mangaId: widget.mangaId,
                                            chapterId: widget.chapterId,
                                            mangaCover: widget.mangaCover,
                                            chapterGroups: widget.chapterGroups,
                                            initialPage: _currentPage,
                                            onlineMode: true,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  TextButton(
                                    child: Text('取消'),
                                    onPressed: () => Navigator.of(c).pop(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_downloadChapter != null)
                          AppBarActionButton(
                            icon: Icon(_downloadChapter!.succeeded && !_downloadChapter!.needUpdate ? Icons.file_download_done : Icons.downloading),
                            tooltip: '下载情况',
                            highlightColor: Colors.transparent,
                            onPressed: () => showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: Text('下载情况'),
                                content: Text(
                                  !_downloadChapter!.tried
                                      ? '该章节正在等待下载。'
                                      : !_downloadChapter!.succeeded
                                          ? '该章节仅部分页下载完成。'
                                          : _downloadChapter!.needUpdate
                                              ? '该章节需要下载更新数据。'
                                              : '该章节已下载完成。',
                                ),
                                actions: [
                                  TextButton(
                                    child: Text('查看'),
                                    onPressed: () {
                                      Navigator.of(c).pop();
                                      _showDownloadedManga(gotoDownloading: !_downloadChapter!.tried || !_downloadChapter!.succeeded || _downloadChapter!.needUpdate);
                                    },
                                  ),
                                  TextButton(
                                    child: Text('确定'),
                                    onPressed: () => Navigator.of(c).pop(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          body: PlaceholderText(
            state: _loading ? PlaceholderState.loading : (_data == null ? PlaceholderState.error : PlaceholderState.normal),
            errorText: _error,
            onRefresh: () => _loadData(),
            setting: PlaceholderSetting(
              showLoadingText: false,
              iconColor: Colors.grey[400]!,
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
                    imageCount: _data!.pageCount,
                    imageUrls: _data!.pages,
                    imageUrlFutures: _urlFutures!,
                    imageFileFutures: _fileFutures!,
                    networkTimeout: AppSetting.instance.other.timeoutBehavior.determineValue(
                      normal: Duration(milliseconds: DOWNLOAD_IMAGE_TIMEOUT),
                      long: Duration(milliseconds: DOWNLOAD_IMAGE_LTIMEOUT),
                    ),
                    preloadPagesCount: _setting.preloadCount,
                    verticalScroll: _isTopToBottom,
                    horizontalReverseScroll: _isRightToLeft,
                    horizontalViewportFraction: _setting.enablePageSpace ? _kViewportFraction : 1,
                    verticalViewportPageSpace: _setting.enablePageSpace ? _kViewportPageSpace : 0,
                    slideWidthRatio: _kSlideWidthRatio,
                    slideHeightRatio: _kSlideHeightRatio,
                    initialImageIndex: _initialPage ?? 1,
                    onPageChanged: _onPageChanged,
                    onSaveImage: (imageIndex) => _download(imageIndex, _data!.pages[imageIndex - 1] /* maybe invalid when offline */),
                    onShareImage: (imageIndex) => shareText(
                      title: '漫画柜分享',
                      text: '【${_data!.mangaTitle} ${_data!.chapterTitle}】第$imageIndex页' + //
                          _data!.pages[imageIndex - 1].let((url) => isPageUrlValidInMetadata(url) ? ' $url' : ' ${_data!.mangaUrl}'),
                    ),
                    onCenterAreaTapped: () {
                      _ScreenHelper.toggleAppBarVisibility(show: !_ScreenHelper.showAppBar, fullscreen: _setting.fullscreen);
                      if (mounted) setState(() {});
                    },
                    firstPageBuilder: (c) => ViewExtraSubPage(
                      isHeader: true,
                      reverseScroll: _isRightToLeft,
                      data: _data!,
                      subscribing: _subscribing,
                      inShelf: _inShelf,
                      inFavorite: _inFavorite,
                      toJumpToImage: (idx, anim) => _mangaGalleryViewKey.currentState?.jumpToImage(idx, animated: anim),
                      toGotoChapter: (prev) => _gotoChapter(gotoPrevious: prev),
                      toSubscribe: _subscribe,
                      toDownload: _downloadManga,
                      toShowToc: _showToc,
                      toShowComments: _showComments,
                      toShowImage: _showImage,
                      toPop: () => Navigator.of(context).maybePop(),
                    ),
                    lastPageBuilder: (c) => ViewExtraSubPage(
                      isHeader: false,
                      reverseScroll: _isRightToLeft,
                      data: _data!,
                      subscribing: _subscribing,
                      inShelf: _inShelf,
                      inFavorite: _inFavorite,
                      toJumpToImage: (idx, anim) => _mangaGalleryViewKey.currentState?.jumpToImage(idx, animated: anim),
                      toGotoChapter: (prev) => _gotoChapter(gotoPrevious: prev),
                      toSubscribe: _subscribe,
                      toDownload: _downloadManga,
                      toShowToc: _showToc,
                      toShowComments: _showComments,
                      toShowImage: _showImage,
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
                                _data!.chapterTitle,
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
                                        textDirection: !_isRightToLeft ? TextDirection.ltr : TextDirection.rtl,
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
                                  disabledTextColor: Colors.grey[600],
                                  disabledIconColor: Colors.grey[600],
                                  action1: ActionItem(
                                    text: !_isRightToLeft ? '上一章节' : '下一章节',
                                    icon: Icons.arrow_right_alt,
                                    rotateAngle: math.pi,
                                    action: () => _gotoChapter(gotoPrevious: !_isRightToLeft),
                                    longPress: () => (!_isRightToLeft ? _data!.prevChapterTitle : _data!.nextChapterTitle)?.let((title) => Fluttertoast.showToast(msg: title)),
                                    enable: !_isRightToLeft ? (_data!.prevChapterId ?? 0) > 0 : (_data!.nextChapterId ?? 0) > 0,
                                  ),
                                  action2: ActionItem(
                                    text: !_isRightToLeft ? '下一章节' : '上一章节',
                                    icon: Icons.arrow_right_alt,
                                    action: () => _gotoChapter(gotoPrevious: _isRightToLeft),
                                    longPress: () => (!_isRightToLeft ? _data!.nextChapterTitle : _data!.prevChapterTitle)?.let((title) => Fluttertoast.showToast(msg: title)),
                                    enable: !_isRightToLeft ? (_data!.nextChapterId ?? 0) > 0 : (_data!.prevChapterId ?? 0) > 0,
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
                        child: !_isTopToBottom
                            ? Row(
                                children: [
                                  Container(
                                    width: MediaQuery.of(context).size.width * _kSlideWidthRatio,
                                    color: Colors.orange[300]!.withOpacity(0.75),
                                    alignment: Alignment.center,
                                    child: Text(_isLeftToRight ? '上\n一\n页' : '下\n一\n页'),
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
                                    child: Text(_isLeftToRight ? '下\n一\n页' : '上\n一\n页'),
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

  static Future<void> restoreSystemUI({bool notificationBar = true, bool fullscreen = true}) async {
    if (notificationBar) {
      setDefaultSystemUIOverlayStyle();
    }
    if (fullscreen) {
      await setManualSystemUIMode(SystemUiOverlay.values);
    }
  }
}
