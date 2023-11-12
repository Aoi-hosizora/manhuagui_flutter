import 'dart:async' show Timer;
import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:ui';

import 'package:battery_info/battery_info_plugin.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/common.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/chapter_detail.dart';
import 'package:manhuagui_flutter/page/comments.dart';
import 'package:manhuagui_flutter/page/dlg/chapter_dialog.dart';
import 'package:manhuagui_flutter/page/dlg/manga_dialog.dart';
import 'package:manhuagui_flutter/page/dlg/setting_view_dialog.dart';
import 'package:manhuagui_flutter/page/download_choose.dart';
import 'package:manhuagui_flutter/page/download_manga.dart';
import 'package:manhuagui_flutter/page/image_viewer.dart';
import 'package:manhuagui_flutter/page/manga_overview.dart';
import 'package:manhuagui_flutter/page/manga_toc.dart';
import 'package:manhuagui_flutter/page/page/view_extra.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/manga_gallery.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/db/later_manga.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/image/imagelib.dart';
import 'package:manhuagui_flutter/service/native/android.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/service/native/system_ui.dart';
import 'package:manhuagui_flutter/service/storage/download.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:wakelock/wakelock.dart';

/// 漫画章节阅读页
class MangaViewerPage extends StatefulWidget {
  const MangaViewerPage({
    Key? key,
    required this.mangaId,
    required this.chapterId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required MangaExtraDataForViewer? extraData,
    required this.onlineMode,
    required this.initialPage, // start from 1
    this.onMangaGot, // for download manga page
    this.replacing = false,
  })  : neededData = extraData,
        // 在Viewer页，保留旧变量名 neededData
        super(key: key);

  final int mangaId;
  final int chapterId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final MangaExtraDataForViewer? neededData;
  final bool onlineMode;
  final int initialPage;
  final void Function(Manga)? onMangaGot;
  final bool replacing;

  @override
  _MangaViewerPageState createState() => _MangaViewerPageState();
}

/// 页面数据，基本覆盖 [TinyMangaChapter]，并展开 [MangaExtraDataForViewer] 的所有字段，在 [MangaViewerPage] / [ViewExtraSubPage] 使用
class MangaViewerPageData {
  const MangaViewerPageData({
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.chapterId,
    required this.chapterTitle,
    required this.chapterUrl,
    required this.pageCount,
    required this.pages,
    required this.chapterNeighbor,
    required this.chapterGroups,
    required this.mangaAuthors,
    required this.newestChapter,
    required this.newestDate,
    required this.isMangaFinished,
    required this.getMangaFailed,
    required this.metadataUpdatedAt,
  });

  // chapter data
  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final int chapterId;
  final String chapterTitle;
  final String chapterUrl;
  final int pageCount;
  final List<String> pages;

  // manga data
  final MangaChapterNeighbor? chapterNeighbor;
  final List<MangaChapterGroup>? chapterGroups;
  final List<TinyAuthor>? mangaAuthors;
  final String? newestChapter;
  final String? newestDate;
  final bool? isMangaFinished;

  // manga data (only used when offline)
  final bool? getMangaFailed;
  final DateTime? metadataUpdatedAt;

  String get chapterCover => pages.isNotEmpty ? pages.first : '';

  MangaExtraDataForViewer? get neededData => chapterGroups == null || mangaAuthors == null || newestChapter == null || newestDate == null || isMangaFinished == null
      ? null
      : MangaExtraDataForViewer(
          chapterGroups: chapterGroups!,
          mangaAuthors: mangaAuthors!,
          newestChapter: newestChapter!,
          newestDate: newestDate!,
          isMangaFinished: isMangaFinished!,
        );

  String chapterPageHtmlUrl(int imageIndex /* start from 0 */) => '$chapterUrl#p=${imageIndex + 1}';

  String get formattedMetadataUpdatedAt => // for view extra subpage offline download metadata banner
      metadataUpdatedAt?.let((dt) => formatDatetimeAndDuration(dt, FormatPattern.datetimeNoSecDuration)) ?? '未知时间';

  MangaViewerPageData updateNeededData({required MangaExtraDataForViewer? neededData, required bool? getMangaFailed}) {
    return MangaViewerPageData(
      mangaId: mangaId,
      mangaTitle: mangaTitle,
      mangaCover: mangaCover,
      mangaUrl: mangaUrl,
      chapterId: chapterId,
      chapterTitle: chapterTitle,
      chapterUrl: chapterUrl,
      pageCount: pageCount,
      pages: pages,
      chapterNeighbor: neededData?.chapterGroups.findChapterNeighbor(chapterId, prev: true, next: true) ?? chapterNeighbor,
      chapterGroups: neededData?.chapterGroups ?? chapterGroups,
      mangaAuthors: neededData?.mangaAuthors ?? mangaAuthors,
      newestChapter: neededData?.newestChapter ?? newestChapter,
      newestDate: neededData?.newestDate ?? newestDate,
      isMangaFinished: neededData?.isMangaFinished ?? isMangaFinished,
      getMangaFailed: getMangaFailed,
      metadataUpdatedAt: metadataUpdatedAt,
    );
  }
}

const _kSlideWidthRatio = 0.18; // 点击跳转页面的区域比例
const _kSlideHeightRatio = 0.18; // 点击跳转页面的区域比例
const _kViewportFraction = 1.08; // 页面间隔
const _kViewportPageSpace = 25.0; // 页面间隔
const _kAnimationDuration = Duration(milliseconds: 150); // 动画时长
const _kOverlayAnimationDuration = Duration(milliseconds: 100); // SystemUI 动画时长

class _MangaViewerPageState extends State<MangaViewerPage> with AutomaticKeepAliveClientMixin {
  final _mangaGalleryViewKey = GlobalKey<MangaGalleryViewState>();
  final _firstExtraPageKey = GlobalKey<ViewExtraSubPageState>();
  final _lastExtraPageKey = GlobalKey<ViewExtraSubPageState>();
  final _cancelHandlers = <VoidCallback>[];

  ViewSetting get _setting => AppSetting.instance.view;

  bool get _isLeftToRight => _setting.viewDirection == ViewDirection.leftToRight; // 从左往右

  bool get _isRightToLeft => _setting.viewDirection == ViewDirection.rightToLeft; // 从右往左

  bool get _isTopToBottom => _setting.viewDirection == ViewDirection.topToBottom; // 从上往下

  bool get _isTopToBottomRtl => _setting.viewDirection == ViewDirection.topToBottomRtl; // 从上往下 (右到左)

  bool get _isHorizontalScroll => _isLeftToRight || _isRightToLeft; // 水平滚动阅读

  bool get _isVerticalScroll => _isTopToBottom || _isTopToBottomRtl; // 竖直滚动阅读

  bool get _isRtlOperation => _isRightToLeft || _isTopToBottomRtl; // 从右到左操作

  @override
  void initState() {
    super.initState();

    // data related
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandlers.add(AuthManager.instance.listenOnlyWhen(Tuple1(AuthManager.instance.authData), (ev) => _updateByEvent(authEvent: ev)));
      await AuthManager.instance.check();
    });
    // _cancelHandlers.add(EventBusManager.instance.listen<AppSettingChangedEvent>((_) => mountedSetState(() {}))); // => unnecessary in viewer page
    _cancelHandlers.add(EventBusManager.instance.listen<HistoryUpdatedEvent>((ev) => _updateByEvent(historyEvent: ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadUpdatedEvent>((ev) => _updateByEvent(downloadEvent: ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<ShelfUpdatedEvent>((ev) => _updateByEvent(shelfEvent: ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<FavoriteUpdatedEvent>((ev) => _updateByEvent(favoriteEvent: ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<LaterUpdatedEvent>((ev) => _updateByEvent(laterEvent: ev)));

    // setting and screen related
    _ScreenHelper.initialize(
      context: context,
      setState: () => mountedSetState(() {}),
      showAppBar: !widget.replacing
          ? !_setting.hideAppBarWhenEnter // show/hide appBar when enter
          : _setting.appBarSwitchBehavior == AppBarSwitchBehavior.keep
              ? null // keep appBar when switch
              : _setting.appBarSwitchBehavior == AppBarSwitchBehavior.show, // show/hide appBar when switch
    );
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      // apply settings to screen
      await _ScreenHelper.toggleWakelock(enable: _setting.keepScreenOn);
      await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
    });

    // timer related
    WidgetsBinding.instance?.addPostFrameCallback((_) => _prepareTimer());
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
  var _offlineError = false;

  // these fields are only used for MangaGalleryView
  int? _initialPage; // start from 1
  List<String?>? _pageUrls; // also used to share link/image, and construct overview page
  List<Future<String?>>? _urlFutures;
  List<Future<File?>>? _fileFutures;

  MangaHistory? _history; // ignore: unused_field
  int? _subscribeCount;
  FavoriteManga? _favoriteManga;
  var _subscribing = false; // 执行订阅操作中
  var _inShelf = false; // 书架
  var _inFavorite = false; // 收藏
  LaterManga? _laterManga; // 稍后阅读
  DownloadedManga? _downloadEntity;
  DownloadedChapter? _downloadChapter;

  Future<void> _loadData() async {
    _loading = true;
    _data = null;
    _error = '';
    _offlineError = false;
    if (mounted) setState(() {});

    // 1. 先获取各种数据库信息 (收藏、下载)
    _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId); // 阅读历史
    _favoriteManga = await FavoriteDao.getFavorite(username: AuthManager.instance.username, mid: widget.mangaId); // 本地收藏
    _inFavorite = _favoriteManga != null;
    _laterManga = await LaterMangaDao.getLaterManga(username: AuthManager.instance.username, mid: widget.mangaId); // 稍后阅读
    _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId); // 下载记录
    _downloadChapter = _downloadEntity?.downloadedChapters.where((el) => el.chapterId == widget.chapterId).firstOrNull;

    // 2. 在网络请求前，先判断当前是否处于离线模式，以及章节是否下载
    if (!widget.onlineMode && (_downloadEntity == null || _downloadChapter == null)) {
      await Future.delayed(Duration(milliseconds: 300)); // fake loading
      _error = '当前处于离线模式，但该章节尚未下载\n请切换至在线模式、或另选章节阅读';
      _offlineError = true;
      _loading = false;
      if (mounted) setState(() {});
      return;
    }

    final client = RestClient(DioManager.instance.dio);
    if (AuthManager.instance.logined) {
      // 3. 异步更新章节阅读记录
      Future.microtask(() async {
        try {
          await client.recordManga(token: AuthManager.instance.token, mid: widget.mangaId, cid: widget.chapterId);
        } catch (e, s) {
          var we = wrapError(e, s);
          globalLogger.e('MangaViewerPage._loadData recordManga: ${we.text}', e, s);
        }
      });

      // 4. 异步获取漫画书架信息
      Future.microtask(() async {
        try {
          var r = await client.checkShelfManga(token: AuthManager.instance.token, mid: widget.mangaId);
          _inShelf = r.data.isIn;
          _subscribeCount = r.data.count;
          if (mounted) setState(() {});
        } catch (e, s) {
          var we = wrapError(e, s);
          globalLogger.e('MangaViewerPage._loadData checkShelfManga: ${we.text}', e, s);
          if (AppSetting.instance.ui.allowErrorToast) {
            Fluttertoast.showToast(msg: '无法获取书架订阅情况：${we.text}');
          }
        }
      });
    }

    try {
      if (widget.onlineMode) {
        // => (I) 在线模式，通过网络获取漫画数据 (同步获取漫画数据)
        // I.5. 异步请求漫画数据
        Future<TaskResult<MangaExtraDataForViewer, Object>> neededDataFuture;
        if (widget.neededData != null) {
          neededDataFuture = Future.value(Ok(widget.neededData!));
        } else {
          neededDataFuture = Future.microtask(() async {
            try {
              var result = await client.getManga(mid: widget.mangaId);
              if (result.data.title == '') {
                if (!result.data.copyright) {
                  throw SpecialException('该漫画暂无版权');
                }
                throw SpecialException('未知错误'); // <<< 获取的漫画数据有问题
              }
              widget.onMangaGot?.call(result.data); // 将漫画数据保存至 DownloadMangaPage
              return Ok(MangaExtraDataForViewer.fromMangaData(result.data));
            } catch (e) {
              return Err(e); // ignore stack trace
            }
          });
        }

        // I.6. 获取章节和漫画数据并整合至 page data
        var result = await client.getMangaChapter(mid: widget.mangaId, cid: widget.chapterId);
        var data = result.data;
        var neededData = (await neededDataFuture).unwrap(); // 等待成功获取漫画数据
        _error = '';
        _data = MangaViewerPageData(
          mangaId: widget.mangaId,
          mangaTitle: data.mangaTitle,
          mangaCover: data.mangaCover,
          mangaUrl: data.mangaUrl,
          chapterId: widget.chapterId,
          chapterTitle: data.title,
          chapterUrl: data.url,
          pageCount: data.pages.length,
          pages: data.pages,
          chapterNeighbor: neededData.chapterGroups.findChapterNeighbor(widget.chapterId, prev: true, next: true) /* => no use response data as chapter neighbor */,
          chapterGroups: neededData.chapterGroups,
          mangaAuthors: neededData.mangaAuthors,
          newestChapter: neededData.newestChapter,
          newestDate: neededData.newestDate,
          isMangaFinished: neededData.isMangaFinished,
          getMangaFailed: false,
          metadataUpdatedAt: null /* never used when online */,
        );
        _preparePageValues(); // 初始化页码和页面列表
        await _updateDatabaseAndMetadataAfterGot(); // 更新数据库和下载文件的各种信息 (仅在线模式)
      } else {
        // => (II) 离线模式，使用已下载的漫画章节数据 (异步获取漫画数据)
        var manga = _downloadEntity, chapter = _downloadChapter;
        if (manga == null || chapter == null) {
          _error = '当前处于离线模式，但该章节尚未下载\n请先切换成在线模式再阅读'; // 再次判断
        } else {
          // II.5. 将下载漫画时记录的数据整合至 page data
          var metadata = await readMetadataFile(mangaId: widget.mangaId, chapterId: widget.chapterId, pageCount: chapter.totalPageCount);
          _error = '';
          _data = MangaViewerPageData(
            mangaId: widget.mangaId,
            mangaTitle: manga.mangaTitle,
            mangaCover: manga.mangaCover,
            mangaUrl: manga.mangaUrl,
            chapterId: widget.chapterId,
            chapterTitle: chapter.chapterTitle,
            chapterUrl: chapter.chapterUrl,
            pageCount: chapter.totalPageCount,
            pages: metadata.pages,
            chapterNeighbor: widget.neededData?.chapterGroups.findChapterNeighbor(widget.chapterId, prev: true, next: true) ??
                MangaChapterNeighbor(
                  // => use download metadata as chapter neighbor
                  notLoaded: metadata.prevCid == null || metadata.nextCid == null /* null => 未找到数据, notLoaded == true */,
                  prevChapter: (metadata.prevCid ?? 0) <= 0 ? null : TinierMangaChapter(cid: metadata.prevCid!, title: '未知章节', group: '未知分组') /* null => 没有上一章节 */,
                  nextChapter: (metadata.nextCid ?? 0) <= 0 ? null : TinierMangaChapter(cid: metadata.nextCid!, title: '未知章节', group: '未知分组') /* null => 没有下一章节 */,
                ),
            chapterGroups: widget.neededData?.chapterGroups /* maybe null */,
            mangaAuthors: widget.neededData?.mangaAuthors /* maybe null */,
            newestChapter: widget.neededData?.newestChapter /* maybe null */,
            newestDate: widget.neededData?.newestDate /* maybe null */,
            isMangaFinished: widget.neededData?.isMangaFinished /* maybe null */,
            getMangaFailed: null /* getting manga */,
            metadataUpdatedAt: metadata.updatedAt /* maybe null */,
          );
          _preparePageValues(); // 初始化页码和页面列表

          // II.6. 异步请求漫画数据
          if (widget.neededData == null) {
            Future.microtask(() async {
              try {
                var result = await client.getManga(mid: widget.mangaId);
                if (result.data.title == '') {
                  if (!result.data.copyright) {
                    throw SpecialException('该漫画暂无版权');
                  }
                  throw SpecialException('未知错误'); // <<< 获取的漫画数据有问题
                }
                widget.onMangaGot?.call(result.data); // 将漫画数据保存至 DownloadMangaPage
                _data = _data?.updateNeededData(neededData: MangaExtraDataForViewer.fromMangaData(result.data), getMangaFailed: false);
                if (mounted) setState(() {});
              } catch (e, s) {
                var we = wrapError(e, s);
                globalLogger.e('MangaViewerPage._loadData getManga (offline): ${we.text}', e, s);
                _data = _data?.updateNeededData(neededData: null, getMangaFailed: true); // failed to get manga
                if (AppSetting.instance.ui.allowErrorToast) {
                  Fluttertoast.showToast(msg: '无法获取漫画章节列表：${we.text}');
                }
              }
            });
          }
        }
      }

      // 7. 异步更新阅读历史
      _updateHistory();

      // 8. 显示网络使用提醒
      if (widget.onlineMode && AppSetting.instance.view.showNotWifiHint) {
        var conn = await Connectivity().checkConnectivity();
        if (conn != ConnectivityResult.wifi) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('当前正在使用非WIFI网络，阅读漫画时请注意流量消耗！'),
              duration: Duration(seconds: 6),
              action: SnackBarAction(
                label: '确定',
                onPressed: () => ScaffoldMessenger.of(context).clearSnackBars(),
              ),
            ),
          );
        }
      }
    } catch (e, s) {
      _data = null;
      _error = wrapError(e, s).text;
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  void _preparePageValues() {
    if (_data == null) {
      return; // unreachable
    }

    // 指定起始页，初始化进度条
    _initialPage = widget.initialPage.clamp(1, _data!.pageCount); // exclude extra pages, start from 1
    _currentPage = _initialPage!;
    _progressValue = _initialPage!;

    // url future 列表
    _pageUrls = [
      for (int idx = 0; idx < _data!.pageCount; idx++)
        !isValidPageUrlForMetadata(_data!.pages[idx]) // 离线模式下页面链接可能无效，只出现在 metadata 丢失的情况下
            ? null // 如果 metadata 内不包含有效链接 (仅针对漫画下载和离线模式) 则显示提示信息【该页尚未下载，且未获取到该页的链接】
            : _data!.pages[idx] //
                .let((url) => url.startsWith('//') ? 'https:$url' : url)
                .let((url) => AppSetting.instance.other.useHttpForImage ? url.replaceAll('https://', 'http://') : url),
    ];
    _urlFutures = _pageUrls!.map((url) => Future.value(url)).toList();

    // file future 列表
    _fileFutures = [
      for (int idx = 0; idx < _data!.pageCount; idx++)
        isValidPageUrlForMetadata(_data!.pages[idx]) && !AppSetting.instance.dl.usingDownloadedPage // 仅当链接有效时才可禁用载入页面文件
            ? Future<File?>.value(null) // 阅读时不载入已下载的页面
            : getDownloadedChapterPageFile(
                mangaId: widget.mangaId,
                chapterId: widget.chapterId,
                pageIndex: idx,
                url: _data!.pages[idx], // url is only used to get extension (webp) and construct file path
              ),
    ];
  }

  Future<void> _updateDatabaseAndMetadataAfterGot() async {
    // => 获取到章节数据后更新数据库 (仅在线模式)
    if (!widget.onlineMode || _data == null) {
      return;
    }

    // 1. 更新章节下载信息
    if (_downloadChapter != null) {
      var newDownload = _downloadChapter!.copyWith(
        mangaId: widget.mangaId,
        chapterId: widget.chapterId,
        chapterTitle: _data!.chapterTitle,
        chapterGroup: _data!.chapterGroups?.findChapter(widget.chapterId)?.group /* almost non-null */,
        totalPageCount: _data!.pageCount,
        needUpdate: false,
      );
      if (!newDownload.equals(_downloadChapter!)) {
        _downloadChapter = newDownload;
        _downloadEntity!.downloadedChapters.replaceWhere((el) => el.chapterId == widget.chapterId, (_) => newDownload);
        await DownloadDao.addOrUpdateChapter(chapter: newDownload);
        EventBusManager.instance.fire(DownloadUpdatedEvent(mangaId: widget.mangaId, fromMangaViewerPage: true));
        if (mounted) setState(() {});
      }
    }

    // 2. 更新章节下载 metadata 信息
    if (_downloadEntity?.downloadedChapters.any((el) => el.chapterId == widget.chapterId) == true) {
      var data = await readMetadataFile(mangaId: widget.mangaId, chapterId: widget.chapterId, pageCount: _data!.pageCount);
      var newData = data.copyWith(
        pages: _data!.pages, // also update page urls
        nextCid: _data!.chapterNeighbor?.nextChapter?.cid ?? 0 /* 0 => 没有上一章节 (仅在线模式才会更新数据) */,
        prevCid: _data!.chapterNeighbor?.prevChapter?.cid ?? 0 /* 0 => 没有下一章节 (仅在线模式才会更新数据) */,
        updatedAt: DateTime.now(),
      );
      var needToUpdate = !newData.equals(data, ignoreUpdatedAt: true, ignorePages: false) || data.updatedAt == null;
      var needToToast = !newData.equals(data, ignoreUpdatedAt: true, ignorePages: true) || data.updatedAt == null; // <<< 貌似 pages 偶尔会变化，这种情况下不弹出提醒
      if (needToUpdate) {
        // no need to update _data, because this method will only be invoked in online mode, which _data is always newest
        await writeMetadataFile(mangaId: widget.mangaId, chapterId: widget.chapterId, metadata: newData);
        if (needToToast) {
          Fluttertoast.showToast(msg: '漫画章节 (${_data!.chapterTitle}) 下载数据已更新');
        }
      }
    }
  }

  Future<void> _updateByEvent({
    AuthChangedEvent? authEvent,
    HistoryUpdatedEvent? historyEvent,
    DownloadUpdatedEvent? downloadEvent,
    ShelfUpdatedEvent? shelfEvent,
    FavoriteUpdatedEvent? favoriteEvent,
    LaterUpdatedEvent? laterEvent,
  }) async {
    if (authEvent != null) {
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId); // 阅读历史
      _subscribeCount = null;
      _favoriteManga = await FavoriteDao.getFavorite(username: AuthManager.instance.username, mid: widget.mangaId);
      _inShelf = false;
      _inFavorite = _favoriteManga != null;
      _laterManga = await LaterMangaDao.getLaterManga(username: AuthManager.instance.username, mid: widget.mangaId); // 稍后阅读
      if (mounted) setState(() {});
    }

    if (historyEvent != null && !historyEvent.fromMangaViewerPage && historyEvent.mangaId == widget.mangaId) {
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);
      if (mounted) setState(() {});
    }

    if (downloadEvent != null && !downloadEvent.fromMangaViewerPage && downloadEvent.mangaId == widget.mangaId) {
      _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId);
      _downloadChapter = _downloadEntity?.downloadedChapters.where((el) => el.chapterId == widget.chapterId).firstOrNull;
      if (mounted) setState(() {});
    }

    if (shelfEvent != null && shelfEvent.mangaId == widget.mangaId) {
      _inShelf = shelfEvent.added;
      if (mounted) setState(() {});
    }

    if (favoriteEvent != null && favoriteEvent.mangaId == widget.mangaId) {
      _favoriteManga = await FavoriteDao.getFavorite(username: AuthManager.instance.username, mid: favoriteEvent.mangaId);
      _inFavorite = _favoriteManga != null;
      if (mounted) setState(() {});
    }

    if (laterEvent != null && laterEvent.mangaId == widget.mangaId) {
      _laterManga = await LaterMangaDao.getLaterManga(username: AuthManager.instance.username, mid: widget.mangaId);
      if (mounted) setState(() {});
    }
  }

  // 载入时调用 / 离开页面时调用 / 跳转章节时调用
  Future<void> _updateHistory() async {
    final nowDateTime = DateTime.now();
    if (_data != null) {
      var oldHistory = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);
      MangaHistory newHistory;
      if (oldHistory == null || oldHistory.chapterId == widget.chapterId) {
        // 老历史为空 (基本不可能)、或当前章节等于老历史的curr字段 => curr<-当前章节，last<-老历史的last字段
        newHistory = MangaHistory(
          mangaId: widget.mangaId,
          mangaTitle: _data!.mangaTitle,
          mangaCover: _data!.mangaCover,
          mangaUrl: _data!.mangaUrl,
          chapterId: widget.chapterId /* => set to current chapter history */,
          chapterTitle: _data!.chapterTitle,
          chapterPage: _currentPage /* start from 1 */,
          lastChapterId: oldHistory?.lastChapterId ?? 0 /* => use last last chapter history */,
          lastChapterTitle: oldHistory?.lastChapterTitle ?? '',
          lastChapterPage: oldHistory?.lastChapterPage ?? 0,
          lastTime: nowDateTime /* 历史已更新 */,
        ); // 更新历史
        if (newHistory.chapterId == newHistory.lastChapterId) {
          // 额外检查，判断当前章节是否与last字段相等，如果相等则需要清空last字段
          newHistory = newHistory.copyWithNoLastChapterOnly(lastTime: DateTime.now()); // 更新漫画历史
        }
      } else {
        // 老历史不为空且当前章节不等于老历史的curr字段 => curr<-当前章节，last<-老历史的curr字段
        newHistory = MangaHistory(
          mangaId: widget.mangaId,
          mangaTitle: _data!.mangaTitle,
          mangaCover: _data!.mangaCover,
          mangaUrl: _data!.mangaUrl,
          chapterId: widget.chapterId /* => set to current chapter history */,
          chapterTitle: _data!.chapterTitle,
          chapterPage: _currentPage /* start from 1 */,
          lastChapterId: oldHistory.chapterId /* => use last chapter history */,
          lastChapterTitle: oldHistory.chapterTitle,
          lastChapterPage: oldHistory.chapterPage,
          lastTime: nowDateTime /* 历史已更新 */,
        ); // 更新漫画历史
      }
      _history = newHistory;
      await HistoryDao.addOrUpdateHistory(username: AuthManager.instance.username, history: newHistory);
      var newFootprint = ChapterFootprint(
        mangaId: widget.mangaId,
        chapterId: widget.chapterId,
        createdAt: nowDateTime /* 历史已更新 */,
      ); // 更新章节历史
      var toUpdateFp = await HistoryDao.checkFootprintExistence(username: AuthManager.instance.username, mid: widget.mangaId, cid: widget.chapterId) ?? false;
      await HistoryDao.addOrUpdateFootprint(username: AuthManager.instance.username, footprint: newFootprint);
      if (mounted) setState(() {});
      EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: widget.mangaId, reason: UpdateReason.updated, fromMangaViewerPage: true));
      EventBusManager.instance.fire(FootprintUpdatedEvent(mangaId: widget.mangaId, chapterIds: [widget.chapterId], reason: !toUpdateFp ? UpdateReason.added : UpdateReason.updated));
    }
  }

  var _currentPage = 1; // start from 1 (image page only)
  var _progressValue = 1; // start from 1, only used to display slider (must be seperated from currentPage)
  var _inExtraPage = false; // just true or false (including the first extra page and the last extra page)
  var _inLastExtraPage = false; // specific flag for the last extra
  var _hideAssistantOnce = false; // for chapter assistant

  void _onPageChanged(int imageIndex /* start from 0 */, bool inFirstExtraPage, bool inLastExtraPage) {
    _currentPage = imageIndex + 1; // start from 1
    _progressValue = imageIndex + 1; // start from 1
    var inExtraPage = inFirstExtraPage || inLastExtraPage;
    if (inExtraPage != _inExtraPage) {
      if (inExtraPage) {
        _ScreenHelper.toggleAppBarVisibility(show: false, fullscreen: _setting.fullscreen);
      }
      _inExtraPage = inExtraPage;
    }
    _hideAssistantOnce = false;
    _inLastExtraPage = inLastExtraPage;
    if (mounted) setState(() {});
  }

  void _onSliderChanged(int sliderValue /* start from 1 */) {
    _progressValue = sliderValue; // start from 1
    if (_currentPage == _progressValue) {
      return; // same page, ignore jump
    }
    _mangaGalleryViewKey.currentState?.jumpToImage(sliderValue - 1, animated: false); // start from 0
    if (mounted) setState(() {});
  }

  Future<void> _toOnlineMode({required bool alsoCheck}) async {
    bool? ok;
    if (!alsoCheck) {
      ok = true;
    } else {
      ok = await showYesNoAlertDialog(
        context: context,
        title: Text('离线模式'),
        content: Text('当前正以离线模式阅读漫画章节，是否切换为在线模式？'),
        yesText: Text('切换'),
        noText: Text('取消'),
      );
    }
    if (ok == true) {
      Navigator.of(context).pushReplacement(
        CustomPageRoute.fromTheme(
          themeData: CustomPageRouteTheme.of(context),
          builder: (c) => MangaViewerPage(
            mangaId: widget.mangaId,
            chapterId: widget.chapterId,
            mangaTitle: _data?.mangaTitle ?? widget.mangaTitle,
            mangaCover: _data?.mangaCover ?? widget.mangaCover,
            mangaUrl: _data?.mangaUrl ?? widget.mangaUrl,
            extraData: _data?.neededData ?? widget.neededData,
            initialPage: _currentPage /* initial page index starts from 1 */,
            onlineMode: true,
            replacing: true,
          ),
        ),
      );
    }
  }

  void _gotoNeighborChapter({required bool gotoPrevious}) async {
    if (_data?.chapterNeighbor?.notLoaded == null || _data?.chapterNeighbor?.notLoaded == true) {
      Fluttertoast.showToast(msg: '当前处于离线模式，但未在下载列表获取到章节跳转信息');
      return;
    }
    if ((gotoPrevious && _data?.chapterNeighbor?.hasPrevChapter != true) || (!gotoPrevious && _data?.chapterNeighbor?.hasNextChapter != true)) {
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

    // 寻找上/下一章节阅读
    var neighbor = _data!.chapterNeighbor!;
    int chapterId;
    if (gotoPrevious) {
      if (neighbor.prevSameGroupChapter != null && neighbor.prevDiffGroupChapter != null) {
        var result = await showDialog<int>(
          context: context,
          builder: (c) => SimpleDialog(
            title: Text('选择上一章节阅读'),
            children: [
              for (var ch in [neighbor.prevSameGroupChapter!, neighbor.prevDiffGroupChapter!]) //
                TextDialogOption(
                  text: Text('【${ch.group}】${ch.title}', maxLines: 2, overflow: TextOverflow.ellipsis),
                  onPressed: () => Navigator.of(c).pop(ch.cid),
                ),
            ],
          ),
        );
        if (result == null) return;
        chapterId = result;
      } else {
        chapterId = neighbor.prevChapter!.cid;
      }
    } else {
      if (neighbor.nextSameGroupChapter != null && neighbor.nextDiffGroupChapter != null) {
        var result = await showDialog<int>(
          context: context,
          builder: (c) => SimpleDialog(
            title: Text('选择下一章节阅读'),
            children: [
              for (var ch in [neighbor.nextSameGroupChapter!, neighbor.nextDiffGroupChapter!]) //
                TextDialogOption(
                  text: Text('【${ch.group}】${ch.title}', maxLines: 2, overflow: TextOverflow.ellipsis),
                  onPressed: () => Navigator.of(c).pop(ch.cid),
                ),
            ],
          ),
        );
        if (result == null) return;
        chapterId = result;
      } else {
        chapterId = neighbor.nextChapter!.cid;
      }
    }

    _updateHistory();
    Navigator.of(context).pushReplacement(
      CustomPageRoute.fromTheme(
        themeData: CustomPageRouteTheme.of(context),
        builder: (c) => MangaViewerPage(
          mangaId: widget.mangaId,
          chapterId: chapterId,
          mangaTitle: _data!.mangaTitle,
          mangaCover: _data!.mangaCover,
          mangaUrl: _data!.mangaUrl,
          extraData: _data!.neededData,
          initialPage: 1 /* always turn to the first page */,
          onlineMode: widget.onlineMode,
          replacing: true,
        ),
      ),
    );
  }

  void _showNeighborChapterTip({required bool previous}) {
    var neighbor = _data!.chapterNeighbor;
    if (neighbor == null || neighbor.notLoaded) {
      Fluttertoast.showToast(msg: '当前处于离线模式，但未在下载列表获取到章节跳转信息');
    } else {
      var titles = neighbor.getAvailableNeighbors(previous: previous).map((t) => '【${t.group}】${t.title}').join('\n');
      Fluttertoast.showToast(msg: (previous ? '上一章节\n' : '下一章节\n') + titles);
    }
  }

  Timer? _timer; // 定时器 更新界面
  var _currentTime = '00:00';
  var _networkInfo = 'WIFI';
  var _batteryInfo = '0%';

  void _prepareTimer() {
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
  }

  var _showHelpRegion = false; // 显示区域提示

  Future<void> _showSettingDialog() async {
    var ok = await showViewSettingDialog(
      context: context,
      extraButtonsBuilder: (c) => [
        Tuple3(
          '查看页面操作区域',
          '查看',
          () {
            Navigator.of(c).pop();
            _showHelpRegion = true;
            if (mounted) setState(() {});
            _ScreenHelper.toggleAppBarVisibility(show: false, fullscreen: _setting.fullscreen);
          },
        ),
      ],
      navigateWrapper: (navigate) async {
        await _ScreenHelper.restoreSystemUI();
        var ok = await navigate();
        await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
        return ok;
      },
    );

    // apply settings to screen
    if (ok) {
      if (mounted) setState(() {});
      await _ScreenHelper.toggleWakelock(enable: _setting.keepScreenOn);
      await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
    }
  }

  void _toSubscribe() {
    showPopupMenuForSubscribing(
      context: context,
      mangaId: widget.mangaId,
      mangaTitle: _data!.mangaTitle,
      mangaCover: _data!.mangaCover,
      mangaUrl: _data!.mangaUrl,
      extraData: MangaExtraDataForDialog.fromMangaViewer(_data!),
      fromMangaPage: false,
      nowInShelf: _inShelf,
      nowInFavorite: _inFavorite,
      nowInLater: _laterManga != null,
      subscribeCount: _subscribeCount,
      favoriteManga: _favoriteManga,
      laterManga: _laterManga,
      subscribing: (s) => mountedSetState(() => _subscribing = s),
      inShelfSetter: (s) => mountedSetState(() => _inShelf = s),
      inFavoriteSetter: (f) {
        _inFavorite = f != null;
        _favoriteManga = f;
        if (mounted) setState(() {});
      },
      inLaterSetter: (l) {
        _laterManga = l;
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _toDownloadManga() async {
    if (_data!.chapterGroups == null) {
      if (_data!.getMangaFailed != true) {
        Fluttertoast.showToast(msg: '当前处于离线模式，正在获取漫画章节列表');
      } else {
        Fluttertoast.showToast(msg: '当前处于离线模式，但漫画章节列表获取失败');
      }
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
    // 由于 _showToc 有可能在 _offlineError 时被调用，所以方法内不使用 _data 来获取这些数据
    String mangaTitle, mangaCover, mangaUrl;
    MangaExtraDataForViewer neededData;
    if (!_offlineError) {
      mangaTitle = _data!.mangaTitle;
      mangaCover = _data!.mangaCover;
      mangaUrl = _data!.mangaUrl;
      if (_data!.neededData != null) {
        neededData = _data!.neededData!;
      } else {
        if (_data!.getMangaFailed != true) {
          Fluttertoast.showToast(msg: '当前处于离线模式，正在获取漫画章节列表');
        } else {
          Fluttertoast.showToast(msg: '当前处于离线模式，但漫画章节列表获取失败');
        }
        return;
      }
    } else {
      mangaTitle = widget.mangaTitle;
      mangaCover = widget.mangaCover;
      mangaUrl = widget.mangaUrl;
      if (widget.neededData != null) {
        neededData = widget.neededData!;
      } else {
        Fluttertoast.showToast(msg: '当前处于离线模式，但未获取到漫画章节列表'); // <<< for _offlineError
        return;
      }
    }

    void switchChapter(BuildContext c, int chapterId) {
      if (chapterId == widget.chapterId) {
        // (1) 所选章节是当前正在阅读的章节 => 显示提示
        Fluttertoast.showToast(msg: '当前正在阅读 ${neededData.chapterGroups.findChapter(chapterId)?.title ?? '该章节'}');
        return;
      }
      checkAndShowSwitchChapterDialogForViewer(
        context: context,
        mangaId: widget.mangaId,
        chapterId: chapterId,
        currentChapterId: widget.chapterId,
        chapterGroups: neededData.chapterGroups,
        toReadChapter: ({required int cid, required int page}) {
          _updateHistory(); // update history before push route
          Navigator.of(c).pop(); // close bottom sheet
          Navigator.of(context).pushReplacement(
            CustomPageRoute.fromTheme(
              themeData: CustomPageRouteTheme.of(context),
              builder: (c) => MangaViewerPage(
                mangaId: widget.mangaId,
                chapterId: cid /* <<< */,
                mangaTitle: mangaTitle,
                mangaCover: mangaCover,
                mangaUrl: mangaUrl,
                extraData: neededData,
                initialPage: page /* <<< */,
                onlineMode: widget.onlineMode,
                replacing: true,
              ),
            ),
          );
        },
      );
    }

    // >>>
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (c, _setState) => MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          child: Container(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical - Theme.of(context).appBarTheme.toolbarHeight!,
            margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            child: MangaTocPage(
              mangaId: widget.mangaId,
              mangaTitle: mangaTitle,
              mangaCover: mangaCover,
              mangaUrl: mangaUrl,
              extraData: neededData,
              showAppDrawer: false,
              onManageHistoryPressed: null,
              onChapterPressed: (cid) => switchChapter(c, cid),
              canOperateHistory: (cid) => widget.chapterId != cid /* => 不允许删除当前章节的历史 */,
              toSwitchChapter: (cid) => switchChapter(c, cid) /* => 仅显示 "切换为该章节" */,
              navigateWrapper: (navigate) async {
                await _ScreenHelper.restoreSystemUI();
                await navigate();
                await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
              },
            ),
          ),
        ),
      ),
    );
    await Future.delayed(kBottomSheetExitDuration + Duration(milliseconds: 10));
    await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
  }

  Future<void> _showDetails() async {
    var tocLoaded = _data!.chapterGroups != null; // 是否成功获取漫画数据

    // null 的原因 => **漫画数据未加载完成** (tocLoaded == false)、未从章节列表中找到章节 (almost impossible)
    var tocChapter = _data!.chapterGroups?.findChapter(widget.chapterId);
    var chapterGroup = _data!.chapterGroups?.where((el) => el.title == tocChapter?.group).firstOrNull;
    var chapter = tocChapter ??
        TinyMangaChapter(
          cid: widget.chapterId,
          title: _data!.chapterTitle,
          mid: widget.mangaId,
          url: _data!.chapterUrl,
          pageCount: _data!.pageCount,
          isNew: false /* 未知 */,
          group: '' /* 未知 */,
          number: 0 /* 未知 */,
        );

    await _ScreenHelper.restoreSystemUI();
    await Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => ChapterDetailPage(
          data: chapter,
          chapterCover: _data!.pages.firstOrNull,
          groupLength: chapterGroup?.chapters.length,
          mangaTitle: _data!.mangaTitle,
          mangaCover: _data!.mangaCover,
          mangaUrl: _data!.mangaUrl,
          mangaAuthors: _data!.mangaAuthors?.map((a) => a.name).toList() ?? [],
          isTocLoaded: tocLoaded,
        ),
      ),
    );
    await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
  }

  Future<void> _showComments() async {
    await _ScreenHelper.restoreSystemUI();
    await Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => CommentsPage(
          mangaId: widget.mangaId,
          mangaTitle: _data!.mangaTitle,
          pushNavigateWrapper: (navigate) async {
            await _ScreenHelper.restoreSystemUI();
            await navigate(); // pushReplaced => true
            await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
          },
        ),
      ),
    );
    await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
  }

  Future<void> _showLaterMangaDialog() async {
    showPopupMenuForLaterManga(
      context: context,
      mangaId: _data!.mangaId,
      mangaTitle: _data!.mangaTitle,
      mangaCover: _data!.mangaCover,
      mangaUrl: _data!.mangaUrl,
      extraData: MangaExtraDataForDialog.fromMangaViewer(_data!),
      fromMangaPage: false,
      laterManga: _laterManga!,
      onLaterUpdated: (l) {
        // (更新数据库)、更新界面[↴]、(弹出提示)、(发送通知)
        _laterManga = l;
        if (mounted) setState(() {});
      },
      onLcCleared: null /* 该页暂不显示稍后阅读章节 */,
      navigateWrapper: (navigate) async {
        await _ScreenHelper.restoreSystemUI();
        await navigate();
        await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
      },
    );
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

  Future<void> _showOverview() async {
    if (_pageUrls!.any((el) => el == null)) {
      // some page urls maybe invalid when offline => null
      Fluttertoast.showToast(msg: '当前处于离线模式，但未能获取到部分页面的链接');
      return;
    }

    await _ScreenHelper.restoreSystemUI();
    var pushReplaced = await Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => MangaOverviewPage(
          mangaId: widget.mangaId,
          mangaTitle: _data!.mangaTitle,
          chapterId: widget.chapterId,
          chapterTitle: _data!.chapterTitle,
          chapterUrl: _data!.chapterUrl,
          imageUrls: _pageUrls!.map((u) => u!).toList(),
          currentIndex: _currentPage - 1 /* start from 0 */,
          loadAllImages: AppSetting.instance.ui.overviewLoadAll,
          onJumpRequested: (pageContext, imageIndex) {
            Navigator.of(pageContext).pop();
            _progressValue = imageIndex + 1; // start from 1
            if (mounted) setState(() {});
            _mangaGalleryViewKey.currentState?.jumpToImage(imageIndex, animated: false); // start from 0
          },
          replaceNavigateWrapper: (navigate) async {
            await _ScreenHelper.restoreSystemUI();
            await navigate(routeResult: true); // push
            await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
          },
        ),
      ),
    );
    if (pushReplaced != true) {
      await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
    }
  }

  void _toShareChapter({bool short = false}) {
    if (short) {
      shareText(text: _data!.chapterUrl);
    } else {
      shareText(text: '【${_data!.mangaTitle} ${_data!.chapterTitle}】${_data!.chapterUrl}');
    }
  }

  Future<Tuple2<String, File?>?> _getPageUrlAndPrecheckFile(int imageIndex) async {
    var url = _pageUrls![imageIndex]; // maybe invalid when offline => null
    if (url == null) {
      Fluttertoast.showToast(msg: '当前处于离线模式，但未在下载列表中获取到第${imageIndex + 1}页链接'); // also show toast
      return null;
    }
    var precheckFile = await getCachedOrDownloadedChapterPageFile(mangaId: widget.mangaId, chapterId: widget.chapterId, pageIndex: imageIndex, url: url);
    return Tuple2(url, precheckFile);
  }

  void _showPopupMenu(int imageIndex /* start from 0 */) {
    HapticFeedback.vibrate();

    Future<void> _download(int imageIndex, {bool alsoShare = false}) async {
      var tuple = await _getPageUrlAndPrecheckFile(imageIndex);
      if (tuple != null) {
        var url = tuple.item1, file = tuple.item2;
        var f = await downloadImageToGallery(url, precheck: file, convertFromWebp: AppSetting.instance.ui.convertWebpWhenSave);
        Fluttertoast.showToast(msg: f != null ? '第${imageIndex + 1}页已保存至 ${f.path}' : '无法保存第${imageIndex + 1}页');
        if (f != null && alsoShare) {
          await shareFile(filepath: f.path, type: 'image/*'); // 保存后分享
        }
      }
    }

    void _sharePage(int imageIndex, {bool short = false}) {
      var url = _data!.chapterPageHtmlUrl(imageIndex /* start from 0 */);
      if (short) {
        shareText(text: url);
      } else {
        shareText(text: '【${_data!.mangaTitle} ${_data!.chapterTitle}】第${imageIndex + 1}页 $url');
      }
    }

    Future<void> _shareImage(int imageIndex, {bool short = false}) async {
      var url = _pageUrls![imageIndex]; // maybe invalid when offline => null
      var filepath = (await getCachedOrDownloadedChapterPageFile(mangaId: widget.mangaId, chapterId: widget.chapterId, pageIndex: imageIndex, url: url))?.path;
      if (filepath == null) {
        Fluttertoast.showToast(msg: '图片未加载完成，无法分享图片');
      } else {
        if (short) {
          await shareFile(filepath: filepath, type: 'image/*');
        } else {
          await shareFile(filepath: filepath, type: 'image/*', text: '【${_data!.mangaTitle} ${_data!.chapterTitle}】第${imageIndex + 1}页 $url');
        }
      }
    }

    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('第${imageIndex + 1}页'),
        children: [
          IconTextDialogOption(
            icon: Icon(Icons.refresh),
            text: Text('重新加载'),
            popWhenPress: c,
            onPressed: () => _mangaGalleryViewKey.currentState?.reloadImage(imageIndex),
          ),
          IconTextDialogOption(
            icon: Icon(Icons.download),
            text: Text('保存该页'),
            popWhenPress: c,
            onPressed: () => _download(imageIndex),
            onLongPressed: () => showYesNoAlertDialog(context: context, title: Text('保存并分享'), content: Text('是否保存第${imageIndex + 1}页并分享图片？'), yesText: Text('确定'), noText: Text('取消')) //
                .then((r) => r?.ifTrue(() => //
                    callAll([() => Navigator.of(c).pop(), () => _download(imageIndex, alsoShare: true)]))),
          ),
          if (_data!.pageCount > 1)
            IconTextDialogOption(
              icon: Icon(CustomIcons.image_multiple_plus),
              text: Text('合并图片保存'),
              popWhenPress: c,
              onPressed: () => _showConcatImagePopupMenu(imageIndex),
            ),
          IconTextDialogOption(
            icon: Icon(Icons.share),
            text: Text('分享该页链接'),
            popWhenPress: c,
            onPressed: () => _sharePage(imageIndex),
            popWhenLongPress: c,
            onLongPressed: () => _sharePage(imageIndex, short: true),
          ),
          IconTextDialogOption(
            icon: Icon(MdiIcons.imageMove),
            text: Text('分享该页图片'),
            popWhenPress: c,
            onPressed: () => _shareImage(imageIndex, short: true),
            popWhenLongPress: c,
            onLongPressed: () => _shareImage(imageIndex),
          ),
        ],
      ),
    );
  }

  void _showConcatImagePopupMenu(int imageIndex /* start from 0 */) {
    if (_data!.pageCount <= 1) {
      return;
    }

    Future<void> _concat(int imageIndex1, int imageIndex2, ConcatImageMode mode, {bool alsoShare = false}) async {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: CircularProgressDialogOption(
              progress: CircularProgressIndicator(),
              child: Text('正在合并第${imageIndex1 + 1}页与第${imageIndex2 + 1}页...'),
            ),
          ),
        ),
      );

      Tuple2<String, File?>? tuple1, tuple2;
      tuple1 = await _getPageUrlAndPrecheckFile(imageIndex1);
      if (tuple1 != null) {
        tuple2 = await _getPageUrlAndPrecheckFile(imageIndex2);
      }
      if (tuple1 == null || tuple2 == null) {
        return;
      }

      var url1 = tuple1.item1, file1 = tuple1.item2;
      var url2 = tuple2.item1, file2 = tuple2.item2;
      var f = await downloadAndConcatImagesToGallery(url1, url2, mode, precheck1: file1, precheck2: file2);
      Navigator.of(context).pop(); // dismiss progress dialog
      if (f == null) {
        Fluttertoast.showToast(msg: '无法下载第${imageIndex1 + 1}页与第${imageIndex2 + 1}页');
      } else {
        Fluttertoast.showToast(msg: '第${imageIndex1 + 1}页与第${imageIndex2 + 1}页的图片合并结果已保存至 ${f.path}');
        if (alsoShare) {
          await shareFile(filepath: f.path, type: 'image/*'); // 合并后分享
        }
      }
    }

    var concatMode = AppSetting.instance.ui.defaultConcatMode; // ConcatImageMode.horizontal
    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, _setState) => SimpleDialog(
          title: Text('合并保存图片'),
          children: [
            for (var mode in [ConcatImageMode.horizontal, ConcatImageMode.vertical, ConcatImageMode.horizontalReverse, ConcatImageMode.verticalReverse])
              IconTextDialogOption(
                icon: concatMode == mode //
                    ? Icon(Icons.radio_button_on, color: Theme.of(context).primaryColor)
                    : Icon(Icons.radio_button_off),
                text: Text(mode.toOptionTitle()),
                onPressed: () => _setState(() => concatMode = mode),
              ),
            Divider(height: 16, thickness: 1),
            if (imageIndex > 0)
              IconTextDialogOption(
                icon: Icon(CustomIcons.image_concat_left),
                text: Text('与第${imageIndex + 1 - 1}页合并保存'),
                popWhenPress: c,
                onPressed: () => _concat(imageIndex - 1, imageIndex, concatMode),
                onLongPressed: () => showYesNoAlertDialog(context: context, title: Text('保存并分享'), content: Text('是否合并保存后分享合并后的图片？'), yesText: Text('确定'), noText: Text('取消')) //
                    .then((r) => r?.ifTrue(() => //
                        callAll([() => Navigator.of(c).pop(), () => _concat(imageIndex - 1, imageIndex, concatMode, alsoShare: true)]))),
              ),
            IconTextDialogOption(
              icon: Icon(Icons.image),
              text: Text('当前选中第${imageIndex + 1}页'),
              onPressed: () {},
            ),
            if (imageIndex < _data!.pageCount - 1)
              IconTextDialogOption(
                icon: Icon(CustomIcons.image_concat_right),
                text: Text('与第${imageIndex + 1 + 1}页合并保存'),
                popWhenPress: c,
                onPressed: () => _concat(imageIndex, imageIndex + 1, concatMode),
                onLongPressed: () => showYesNoAlertDialog(context: context, title: Text('保存并分享'), content: Text('是否合并保存后分享合并后的图片？'), yesText: Text('确定'), noText: Text('取消')) //
                    .then((r) => r?.ifTrue(() => //
                        callAll([() => Navigator.of(c).pop(), () => _concat(imageIndex, imageIndex + 1, concatMode, alsoShare: true)]))),
              ),
          ],
        ),
      ),
    );
  }

  void _showPopupMenuForActions() {
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('《${widget.mangaTitle}》${_data!.chapterTitle}'),
        children: [
          IconTextDialogOption(icon: Icon(Icons.refresh), text: Text('重新加载本章节'), popWhenPress: c, onPressed: _loadData),
          IconTextDialogOption(icon: Icon(Icons.share), text: Text('分享章节'), popWhenPress: c, onPressed: _toShareChapter),
          IconTextDialogOption(icon: Icon(Icons.open_in_browser), text: Text('用浏览器打开'), popWhenPress: c, onPressed: () => launchInBrowser(context: context, url: _data?.chapterUrl ?? widget.mangaUrl)),
          Divider(height: 16, thickness: 1),
          IconTextDialogOption(icon: Icon(Icons.loyalty), text: Text('查看订阅情况'), popWhenPress: c, onPressed: _toSubscribe),
          IconTextDialogOption(icon: Icon(Icons.menu), text: Text('查看章节列表'), popWhenPress: c, onPressed: _showToc),
          IconTextDialogOption(icon: Icon(Icons.download), text: Text('下载漫画'), popWhenPress: c, onPressed: _toDownloadManga),
          IconTextDialogOption(icon: Icon(CustomIcons.opened_book_cog), text: Text('更改阅读设置'), popWhenPress: c, onPressed: _showSettingDialog),
          IconTextDialogOption(icon: Icon(Icons.subject), text: Text('查看章节详情'), popWhenPress: c, onPressed: _showDetails),
          IconTextDialogOption(icon: Icon(Icons.forum), text: Text('查看漫画评论'), popWhenPress: c, onPressed: _showComments),
          IconTextDialogOption(icon: Icon(CustomIcons.image_timeline), text: Text('打开页面一览'), popWhenPress: c, onPressed: _showOverview),
        ],
      ),
    );
  }

  double _getChapterAssistantBottomPosition() {
    // this function is only called, when the page view is at final page, or the scroll position is at bottom.
    var extraPageHeight = _mangaGalleryViewKey.currentState?.getPageHeight(
      _data!.pageCount + 1, // last extra page
      safeArea: !_isHorizontalScroll || _ScreenHelper.safeAreaTop, // no consideration of safe area (media query), when vertical scrolling or non-fullscreen
    );
    var extraPageTitleBoxHeight = _lastExtraPageKey.currentState?.getTitleBoxHeight();
    return (extraPageHeight ?? 0) - (extraPageTitleBoxHeight ?? 0);
  }

  Tuple3<String /* tooltip */, IconData /* button icon */, void Function() /* callback */ >? _decideAssistantAction({
    bool leftTop = false,
    bool rightTop = false,
    bool leftBottom = false,
    bool rightBottom = false,
  }) {
    return AppSetting.instance.view.assistantActionSetting.decideAction<Tuple3<String, IconData, void Function()>>(
      leftTop: leftTop,
      rightTop: rightTop,
      leftBottom: leftBottom,
      rightBottom: rightBottom,
      rtlOperation: _isRtlOperation,
      // ===========================
      toc: Tuple3('打开漫画章节列表', Icons.menu, _showToc),
      reverse: Tuple3('左右翻转阅读方向', Icons.swap_horiz, () async {
        await updateViewSettingViewDirection(_setting.viewDirection.reverse());
        if (mounted) setState(() {});
      }),
      config: Tuple3('更改阅读设置', Icons.settings, _showSettingDialog),
      hideOnce: Tuple3('暂时隐藏 "单手章节跳转助手"', Icons.visibility_off, () {
        _hideAssistantOnce = !_hideAssistantOnce;
        if (mounted) setState(() {});
      }),
      disable: Tuple3('禁用 "单手章节跳转助手"', Icons.cancel_outlined, () async {
        await updateViewSettingUseChapterAssistant(!_setting.useChapterAssistant);
        if (mounted) setState(() {});
      }),
      pop: Tuple3('结束阅读', Icons.arrow_back, () => Navigator.of(context).maybePop()),
    );
  }

  void _toggleAppBarVisibility(int imageIndex /* start from 0 */) {
    _ScreenHelper.toggleAppBarVisibility(
      show: !_ScreenHelper.showAppBar,
      fullscreen: _setting.fullscreen,
    );
    if (mounted) setState(() {});
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
                      title: (_data?.chapterTitle ?? widget.neededData?.chapterGroups.findChapter(widget.chapterId)?.title ?? '未知章节').let(
                        (title) => GestureDetector(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.white),
                          ),
                          onTap: () => showPopupMenuForChapterTitle(
                            context: context,
                            mangaTitle: widget.mangaTitle,
                            chapterTitle: title,
                            onDetailsPressed: _showDetails,
                            vibrate: false,
                          ),
                          onLongPress: () => showPopupMenuForChapterTitle(
                            context: context,
                            mangaTitle: widget.mangaTitle,
                            chapterTitle: title,
                            onDetailsPressed: _showDetails,
                            vibrate: true,
                          ),
                        ),
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
                            onPressed: () => _toOnlineMode(alsoCheck: true),
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
                                    child: Text('关闭'),
                                    onPressed: () => Navigator.of(c).pop(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        PopupMenuButton(
                          child: Builder(
                            builder: (c) => AppBarActionButton(
                              icon: Icon(Icons.more_vert),
                              tooltip: '更多选项',
                              onPressed: () => c.findAncestorStateOfType<PopupMenuButtonState>()?.showButtonMenu(),
                            ),
                          ),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              child: IconTextMenuItem(Icons.refresh, '重新加载本章节'),
                              onTap: () => _loadData(),
                            ),
                            LongPressablePopupMenuItem(
                              child: IconTextMenuItem(Icons.share, '分享本章节'),
                              onTap: () => _toShareChapter(),
                              onLongPressed: () async {
                                HapticFeedback.vibrate();
                                _toShareChapter(short: true);
                              },
                            ),
                            PopupMenuItem(
                              child: IconTextMenuItem(Icons.open_in_browser, '用浏览器打开'),
                              onTap: () => launchInBrowser(context: context, url: _data?.chapterUrl ?? widget.mangaUrl),
                            ),
                            PopupMenuItem(
                              child: IconTextMenuItem(Icons.more_vert, '查看更多选项'),
                              onTap: () => WidgetsBinding.instance?.addPostFrameCallback((_) => _showPopupMenuForActions()),
                            ),
                          ],
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
              useAnimatedSwitcher: false,
              showLoadingText: false,
              iconColor: Colors.grey[400]!,
              textStyle: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.grey[400]!),
              buttonTextStyle: TextStyle(color: Colors.grey[400]!),
              buttonStyle: ButtonStyle(
                side: MaterialStateProperty.all(BorderSide(color: Colors.grey[400]!)),
              ),
              customErrorRetryBuilder: (c, setting, callback) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    child: Text(setting.errorRetryText!, style: setting.buttonTextStyle!),
                    style: setting.buttonStyle,
                    onPressed: callback,
                  ),
                  if (_offlineError)
                    Padding(
                      padding: EdgeInsets.only(left: 15),
                      child: OutlinedButton(
                        child: Text('另选章节', style: setting.buttonTextStyle!),
                        style: setting.buttonStyle,
                        onPressed: () => _showToc() /* _data maybe null here */,
                      ),
                    ),
                ],
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
                    imageUrlFutures: _urlFutures!,
                    imageFileFutures: _fileFutures!,
                    networkTimeout: AppSetting.instance.other.imgTimeoutBehavior.determineValue(
                      normal: Duration(milliseconds: GALLERY_IMAGE_TIMEOUT),
                      long: Duration(milliseconds: GALLERY_IMAGE_LTIMEOUT),
                      longLong: Duration(milliseconds: GALLERY_IMAGE_LLTIMEOUT),
                    ),
                    preloadPagesCount: _setting.preloadCount,
                    verticalScroll: _isVerticalScroll,
                    horizontalReverseScroll: _isRightToLeft,
                    horizontalViewportFraction: _setting.enablePageSpace ? _kViewportFraction : 1,
                    verticalViewportPageSpace: _setting.enablePageSpace ? _kViewportPageSpace : 0,
                    verticalPageNoPosition: AppSetting.instance.view.pageNoPosition,
                    slideWidthRatio: _kSlideWidthRatio,
                    slideHeightRatio: _kSlideHeightRatio,
                    initialImageIndex: (_initialPage ?? 1) - 1 /* start from 0 */,
                    fileAndUrlNotFoundMessage: '该页尚未下载，且未获取到该页的链接\n请重新下载该章节、或切换成在线模式再阅读',
                    onPageChanged: _onPageChanged,
                    onLongPressed: _showPopupMenu,
                    onCenterAreaTapped: _toggleAppBarVisibility,
                    mediaQueryPadding: MediaQuery.of(context).padding,
                    firstPageBuilder: (c, extraCallbacks) => ViewExtraSubPage(
                      key: _firstExtraPageKey,
                      isHeader: true,
                      isRtlOperation: _isRtlOperation,
                      data: _data!,
                      onlineMode: widget.onlineMode,
                      subscribing: _subscribing,
                      inShelf: _inShelf,
                      inFavorite: _inFavorite,
                      laterManga: _laterManga,
                      onHeightChanged: ({bool byOpt = false, bool byLater = false}) {
                        _mangaGalleryViewKey.currentState?.updatePageHeight(0); // update page height
                      },
                      callbacks: extraCallbacks as ViewExtraSubPageCallbacks,
                    ),
                    lastPageBuilder: (c, extraCallbacks) => ViewExtraSubPage(
                      key: _lastExtraPageKey,
                      isHeader: false,
                      isRtlOperation: _isRtlOperation,
                      data: _data!,
                      onlineMode: widget.onlineMode,
                      subscribing: _subscribing,
                      inShelf: _inShelf,
                      inFavorite: _inFavorite,
                      laterManga: _laterManga,
                      onHeightChanged: ({bool byOpt = false, bool byLater = false}) {
                        _mangaGalleryViewKey.currentState?.updatePageHeight(_data!.pageCount + 1); // update page height
                        if (byOpt) {
                          _mangaGalleryViewKey.currentState?.jumpToPage(_data!.pageCount + 1, animated: true);
                        }
                        if (mounted) setState(() {}); // also set state to update assistant height
                      },
                      callbacks: extraCallbacks as ViewExtraSubPageCallbacks,
                    ),
                    pageBuilderData: ViewExtraSubPageCallbacks(
                      toJumpToImage: (idx, anim) => _mangaGalleryViewKey.currentState?.jumpToImage(idx, animated: anim) /* start from 0 */,
                      toGotoNeighbor: (prev) => _gotoNeighborChapter(gotoPrevious: prev),
                      toShowNeighborTip: (prev) => _showNeighborChapterTip(previous: prev),
                      toPop: () => Navigator.of(context).maybePop(),
                      toSubscribe: _toSubscribe,
                      toDownload: _toDownloadManga,
                      toShowToc: _showToc,
                      toShowSettings: _showSettingDialog,
                      toShowDetails: _showDetails,
                      toShowComments: _showComments,
                      toShowOverview: _showOverview,
                      toShare: (short) => _toShareChapter(short: short),
                      toShowLaters: _showLaterMangaDialog,
                      toShowImage: _showImage,
                      toOnlineMode: () => _toOnlineMode(alsoCheck: false),
                    ),
                  ),
                ),
                // ****************************************************************
                // 单手章节跳转助手
                // ****************************************************************
                ...(({
                  required bool leftSide,
                  required bool toPrevious,
                  required String text,
                  String? disableText,
                  required void Function() action,
                  void Function()? longPress,
                  required bool disable,
                }) =>
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0, 0.5, 1],
                          colors: [
                            if (toPrevious) ...[
                              Colors.blue[!disable ? 400 : 200]!.withOpacity(!disable ? 0.7 : 0.5),
                              Colors.blue[!disable ? 700 : 400]!.withOpacity(!disable ? 0.8 : 0.5),
                              Colors.blue[!disable ? 400 : 200]!.withOpacity(!disable ? 0.7 : 0.5),
                            ],
                            if (!toPrevious) ...[
                              Colors.orange[!disable ? 600 : 400]!.withOpacity(!disable ? 0.7 : 0.5),
                              Colors.orange[!disable ? 900 : 600]!.withOpacity(!disable ? 0.8 : 0.5),
                              Colors.orange[!disable ? 600 : 400]!.withOpacity(!disable ? 0.7 : 0.5),
                            ],
                          ],
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: disable ? null : action,
                          onLongPress: disable ? null : longPress,
                          highlightColor: Colors.black.withOpacity(0.18),
                          splashColor: Colors.black.withOpacity(0.18),
                          child: Column(
                            children: [
                              // top button
                              _decideAssistantAction(leftTop: leftSide, rightTop: !leftSide)?.let(
                                    (tup) => Tooltip(
                                      message: tup.item1,
                                      child: InkWell(
                                        child: Padding(
                                          padding: EdgeInsets.all((10 * 2 + 28 - 22) / 2),
                                          child: Icon(tup.item2, size: 22, color: Colors.white),
                                        ),
                                        onTap: tup.item3,
                                      ),
                                    ),
                                  ) ??
                                  SizedBox(height: (10 * 2 + 28 - 22) + 22),

                              // main navigation
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (!disable)
                                        Transform.rotate(
                                          angle: leftSide ? math.pi : 0,
                                          child: Icon(Icons.arrow_right_alt, size: 28, color: Colors.white),
                                        ),
                                      if (disable)
                                        Padding(
                                          padding: EdgeInsets.all((28 - 22) / 2),
                                          child: Icon(Icons.do_not_disturb, size: 22, color: Colors.white.withOpacity(0.45)),
                                        ),
                                      SizedBox(height: 2),
                                      Text(
                                        (!disable ? text : (disableText ?? text)).split('').join('\n').trim(),
                                        style: Theme.of(context).textTheme.subtitle1?.copyWith(
                                              fontSize: 18,
                                              color: !disable ? Colors.white : Colors.white.withOpacity(0.45),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // bottom button
                              _decideAssistantAction(leftBottom: leftSide, rightBottom: !leftSide)?.let(
                                    (tup) => Tooltip(
                                      message: tup.item1,
                                      child: InkWell(
                                        child: Padding(
                                          padding: EdgeInsets.all((10 * 2 + 28 - 22) / 2),
                                          child: Icon(tup.item2, size: 22, color: Colors.white),
                                        ),
                                        onTap: tup.item3,
                                      ),
                                    ),
                                  ) ??
                                  SizedBox(height: (10 * 2 + 28 - 22) + 22),
                            ],
                          ),
                        ),
                      ),
                    )).let(
                  (buildHandler) => [
                    Positioned(
                      top: 0,
                      bottom: _getChapterAssistantBottomPosition(),
                      left: 0, // left
                      child: AnimatedSwitcher(
                        duration: _kAnimationDuration,
                        child: !(_data != null && _inLastExtraPage && !_hideAssistantOnce && _setting.useChapterAssistant)
                            ? const SizedBox.shrink() //
                            : buildHandler(
                                leftSide: true,
                                toPrevious: !_isRtlOperation,
                                text: !_isRtlOperation ? '阅读上一章节' : '阅读下一章节',
                                disable: !_isRtlOperation ? _data!.chapterNeighbor?.hasPrevChapter != true : _data!.chapterNeighbor?.hasNextChapter != true,
                                disableText: !_isRtlOperation ? '暂无上一章节' : '暂无下一章节',
                                action: () => _gotoNeighborChapter(gotoPrevious: !_isRtlOperation),
                                longPress: () => _showNeighborChapterTip(previous: !_isRtlOperation),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: _getChapterAssistantBottomPosition(),
                      right: 0, // right
                      child: AnimatedSwitcher(
                        duration: _kAnimationDuration,
                        child: !(_data != null && _inLastExtraPage && !_hideAssistantOnce && _setting.useChapterAssistant)
                            ? const SizedBox.shrink() //
                            : buildHandler(
                                leftSide: false,
                                toPrevious: _isRtlOperation,
                                text: !_isRtlOperation ? '阅读下一章节' : '阅读上一章节',
                                disable: !_isRtlOperation ? _data!.chapterNeighbor?.hasNextChapter != true : _data!.chapterNeighbor?.hasPrevChapter != true,
                                disableText: !_isRtlOperation ? '暂无下一章节' : '暂无上一章节',
                                action: () => _gotoNeighborChapter(gotoPrevious: _isRtlOperation),
                                longPress: () => _showNeighborChapterTip(previous: _isRtlOperation),
                              ),
                      ),
                    ),
                  ],
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
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
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
                                        textDirection: !_isRtlOperation ? TextDirection.ltr : TextDirection.rtl,
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
                                              _progressValue = p.toInt(); // update _progressValue directly
                                              if (mounted) setState(() {});
                                            },
                                            onChangeEnd: (p) => _onSliderChanged(p.toInt()),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(right: 5),
                                      child: Tooltip(
                                        message: '查看章节页面一览',
                                        preferBelow: false,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            child: Padding(
                                              padding: EdgeInsets.only(left: 10, right: 10, top: 4.5, bottom: 4.5),
                                              child: Text(
                                                '$_progressValue/${_data!.pageCount}页',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFeatures: const [FontFeature.tabularFigures()],
                                                ),
                                              ),
                                            ),
                                            onTap: _showOverview,
                                          ),
                                        ),
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
                                    text: !_isRtlOperation ? '上一章节' : '下一章节',
                                    icon: Icons.arrow_right_alt,
                                    rotateAngle: math.pi,
                                    action: () => _gotoNeighborChapter(gotoPrevious: !_isRtlOperation),
                                    longPress: () => _showNeighborChapterTip(previous: !_isRtlOperation),
                                    enable: !_isRtlOperation ? _data!.chapterNeighbor?.hasPrevChapter == true : _data!.chapterNeighbor?.hasNextChapter == true,
                                  ),
                                  action2: ActionItem(
                                    text: !_isRtlOperation ? '下一章节' : '上一章节',
                                    icon: Icons.arrow_right_alt,
                                    action: () => _gotoNeighborChapter(gotoPrevious: _isRtlOperation),
                                    longPress: () => _showNeighborChapterTip(previous: _isRtlOperation),
                                    enable: !_isRtlOperation ? _data!.chapterNeighbor?.hasNextChapter == true : _data!.chapterNeighbor?.hasPrevChapter == true,
                                  ),
                                  action3: ActionItem(
                                    text: '阅读设置',
                                    icon: Icons.settings,
                                    action: () => _showSettingDialog(),
                                    longPress: () => _showPopupMenuForActions(),
                                  ),
                                  action4: ActionItem(
                                    text: '章节列表',
                                    icon: Icons.menu,
                                    action: () => _showToc(),
                                    longPress: () => _showDetails(),
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
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: _kAnimationDuration,
                    child: !_showHelpRegion
                        ? const SizedBox.shrink()
                        : GestureDetector(
                            onTap: () {
                              _showHelpRegion = false;
                              if (mounted) setState(() {});
                            },
                            child: DefaultTextStyle(
                              style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.white),
                              child: _isHorizontalScroll
                                  ? Row(
                                      children: [
                                        Container(
                                          width: MediaQuery.of(context).size.width * _kSlideWidthRatio,
                                          color: Colors.orange[300]!.withOpacity(0.75),
                                          alignment: Alignment.center,
                                          child: Text(!_isRtlOperation ? '上\n一\n页' : '下\n一\n页'),
                                        ),
                                        Container(
                                          width: MediaQuery.of(context).size.width * (1 - 2 * _kSlideWidthRatio),
                                          color: Colors.blue[300]!.withOpacity(0.75),
                                          alignment: Alignment.center,
                                          child: Text('显示菜单'),
                                        ),
                                        Container(
                                          width: MediaQuery.of(context).size.width * _kSlideWidthRatio,
                                          color: Colors.pink[300]!.withOpacity(0.75),
                                          alignment: Alignment.center,
                                          child: Text(!_isRtlOperation ? '下\n一\n页' : '上\n一\n页'),
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
                                          child: Text('显示菜单'),
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

  static void initialize({required BuildContext context, required void Function() setState, bool? showAppBar}) {
    // initialize global context and setState field for current MangaViewerPage
    _context = context;
    _setState = setState;

    // initialize global show app bar field, and do not call `setState` here
    if (showAppBar != null) {
      _showAppBar = showAppBar;
    }

    // do not initialize global system ui fields here, just to call `setSystemUIWhenEnter`
  }

  // ========
  // wakelock
  // ========

  static Future<void> toggleWakelock({required bool enable}) {
    return Wakelock.toggle(enable: enable);
  }

  static Future<void> restoreWakelock() {
    return Wakelock.toggle(enable: false);
  }

  // =======
  // app bar
  // =======

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

  // =========
  // system ui
  // =========

  static bool _safeAreaTop = true; // defaults to non-fullscreen

  static bool get safeAreaTop => _safeAreaTop; // true => non-fullscreen, false => fullscreen

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

  static Future<void> setSystemUIWhenAppbarChanged({required bool fullscreen, required bool /* explicit */ isAppbarShown}) async {
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
