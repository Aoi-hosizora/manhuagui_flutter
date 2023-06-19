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
import 'package:manhuagui_flutter/page/dlg/manga_dialog.dart';
import 'package:manhuagui_flutter/page/dlg/setting_view_dialog.dart';
import 'package:manhuagui_flutter/page/download_choose.dart';
import 'package:manhuagui_flutter/page/download_manga.dart';
import 'package:manhuagui_flutter/page/image_viewer.dart';
import 'package:manhuagui_flutter/page/manga_overview.dart';
import 'package:manhuagui_flutter/page/page/view_extra.dart';
import 'package:manhuagui_flutter/page/page/view_toc.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
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
import 'package:manhuagui_flutter/service/native/android.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';
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
    required this.neededData,
    required this.onlineMode,
    required this.initialPage, // start from 1
    this.onMangaGot, // for download manga page
    this.replacing = false,
  }) : super(key: key);

  final int mangaId;
  final int chapterId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final MangaChapterNeededData? neededData;
  final bool onlineMode;
  final int initialPage;
  final void Function(Manga)? onMangaGot;
  final bool replacing;

  @override
  _MangaViewerPageState createState() => _MangaViewerPageState();
}

class MangaChapterNeededData {
  const MangaChapterNeededData({
    required this.chapterGroups,
    required this.mangaAuthors,
    required this.newestChapterTitle,
    required this.newestDateAndFinished,
  });

  final List<MangaChapterGroup> chapterGroups;
  final List<TinyAuthor> mangaAuthors;
  final String newestChapterTitle;
  final Tuple2<String, bool> newestDateAndFinished;

  static MangaChapterNeededData fromMangaData(Manga manga) {
    return MangaChapterNeededData(
      chapterGroups: manga.chapterGroups,
      mangaAuthors: manga.authors,
      newestChapterTitle: manga.newestChapter,
      newestDateAndFinished: Tuple2(manga.formattedNewestDate, manga.finished),
    );
  }

  static MangaChapterNeededData? fromNullableMangaData(Manga? manga) {
    if (manga == null) {
      return null;
    }
    return fromMangaData(manga);
  }
}

/// 页面数据，基本覆盖 [TinyMangaChapter]，在 [MangaViewerPage] / [ViewExtraSubPage] 使用
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
    required this.newestChapterTitle,
    required this.newestDateAndFinished,
    required this.getMangaFailed,
    required this.metadataUpdatedAt,
  });

  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final int chapterId;
  final String chapterTitle;
  final String chapterUrl;
  final int pageCount;
  final List<String> pages;
  final MangaChapterNeighbor? chapterNeighbor;
  final List<MangaChapterGroup>? chapterGroups;
  final List<TinyAuthor>? mangaAuthors;
  final String? newestChapterTitle;
  final Tuple2<String, bool>? newestDateAndFinished;
  final bool? getMangaFailed; // only used when offline
  final DateTime? metadataUpdatedAt; // only used when offline

  String get chapterCover => pages.isNotEmpty ? pages.first : '';

  MangaChapterNeededData? get neededData => chapterGroups == null || mangaAuthors == null || newestChapterTitle == null || newestDateAndFinished == null
      ? null
      : MangaChapterNeededData(
          chapterGroups: chapterGroups!,
          mangaAuthors: mangaAuthors!,
          newestChapterTitle: newestChapterTitle!,
          newestDateAndFinished: newestDateAndFinished!,
        );

  String chapterPageHtmlUrl(int imageIndex /* start from 0 */) => '$chapterUrl#p=${imageIndex + 1}';

  String get formattedMetadataUpdatedAt => //
      metadataUpdatedAt?.let((dt) => formatDatetimeAndDuration(dt, FormatPattern.datetimeDuration)) ?? '未知时间';

  MangaViewerPageData updateNeededData({required MangaChapterNeededData? neededData, required bool? getMangaFailed}) {
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
      newestChapterTitle: neededData?.newestChapterTitle ?? newestChapterTitle,
      newestDateAndFinished: neededData?.newestDateAndFinished ?? newestDateAndFinished,
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
    _cancelHandlers.add(EventBusManager.instance.listen<LaterMangaUpdatedEvent>((ev) async {
      if (ev.mangaId == widget.mangaId) {
        _laterManga = await LaterMangaDao.getLaterManga(username: AuthManager.instance.username, mid: ev.mangaId);
        if (mounted) setState(() {});
      }
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadUpdatedEvent>((ev) async {
      if (ev.mangaId == widget.mangaId && !ev.fromMangaViewerPage) {
        _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId);
        _downloadChapter = _downloadEntity?.downloadedChapters.where((el) => el.chapterId == widget.chapterId).firstOrNull;
        if (mounted) setState(() {});
      }
    }));

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
  var _offlineError = false;

  // these fields are only used for MangaGalleryView
  int? _initialPage; // start from 1
  List<String?>? _pageUrls; // also used to share link, share image, and open grid view
  List<Future<String?>>? _urlFutures;
  List<Future<File?>>? _fileFutures;

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
    _favoriteManga = await FavoriteDao.getFavorite(username: AuthManager.instance.username, mid: widget.mangaId);
    _inFavorite = _favoriteManga != null;
    _laterManga = await LaterMangaDao.getLaterManga(username: AuthManager.instance.username, mid: widget.mangaId);
    _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId);
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
        Future<TaskResult<MangaChapterNeededData, Object>> neededDataFuture;
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
              return Ok(MangaChapterNeededData.fromMangaData(result.data));
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
          newestChapterTitle: neededData.newestChapterTitle,
          newestDateAndFinished: neededData.newestDateAndFinished,
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
                  prevChapter: (metadata.prevCid ?? 0) <= 0 ? null : NanoTinyMangaChapter(cid: metadata.prevCid!, title: '未知章节', group: '未知分组') /* null => 没有上一章节 */,
                  nextChapter: (metadata.nextCid ?? 0) <= 0 ? null : NanoTinyMangaChapter(cid: metadata.nextCid!, title: '未知章节', group: '未知分组') /* null => 没有下一章节 */,
                ),
            chapterGroups: widget.neededData?.chapterGroups /* maybe null */,
            mangaAuthors: widget.neededData?.mangaAuthors /* maybe null */,
            newestChapterTitle: widget.neededData?.newestChapterTitle /* maybe null */,
            newestDateAndFinished: widget.neededData?.newestDateAndFinished /* maybe null */,
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
                _data = _data?.updateNeededData(neededData: MangaChapterNeededData.fromMangaData(result.data), getMangaFailed: false);
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
    _initialPage = widget.initialPage.clamp(1, _data!.pageCount);
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
      if (!newData.equals(data) /* updatedAt is ignored */ || data.updatedAt == null /* need to record updatedAt */) {
        // no need to update _data, because this method will only be invoked in online mode, which _data is always newest
        await writeMetadataFile(mangaId: widget.mangaId, chapterId: widget.chapterId, metadata: newData);
        Fluttertoast.showToast(msg: '漫画章节 (${_data!.chapterTitle}) 下载数据已更新');
      }
    }
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
        chapterPage: _currentPage /* start from 1 */,
        lastTime: DateTime.now(),
      );
      await HistoryDao.addOrUpdateHistory(username: AuthManager.instance.username, history: history);
      EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: widget.mangaId, reason: UpdateReason.updated));
    }
  }

  var _currentPage = 1; // start from 1 (image page only)
  var _progressValue = 1; // start from 1, only used to display slider (must be seperated from currentPage)
  var _inExtraPage = false; // just true or false (including the first extra page and the last extra page)

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
    if (mounted) setState(() {});
  }

  void _onSliderChanged(int value /* start from 1 */) {
    _progressValue = value; // start from 1
    if (_currentPage == _progressValue) {
      return; // same page, ignore jump
    }
    _mangaGalleryViewKey.currentState?.jumpToImage(value - 1, animated: false); // start from 0
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
            neededData: _data?.neededData ?? widget.neededData,
            initialPage: _currentPage /* start from 1 */,
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
    // TODO improving neighbor accuracy
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
                TextDialogOption(text: Text('【${ch.group}】${ch.title}'), onPressed: () => Navigator.of(c).pop(ch.cid)),
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
                TextDialogOption(text: Text('【${ch.group}】${ch.title}'), onPressed: () => Navigator.of(c).pop(ch.cid)),
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
          neededData: _data!.neededData,
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
      var titles = neighbor.getAvailableChapters(previous: previous).map((t) => '【${t.group}】${t.title}').join('\n');
      Fluttertoast.showToast(msg: (previous ? '上一章节\n' : '下一章节\n') + titles);
    }
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
      await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
    }
  }

  void _subscribe() {
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

  Future<void> _downloadManga() async {
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
    MangaChapterNeededData? neededData;
    if (!_offlineError) {
      mangaTitle = _data!.mangaTitle;
      mangaCover = _data!.mangaCover;
      mangaUrl = _data!.mangaUrl;
      neededData = _data!.neededData;
      if (neededData == null) {
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
      neededData = widget.neededData;
      if (neededData == null) {
        Fluttertoast.showToast(msg: '当前处于离线模式，但未获取到漫画章节列表'); // <<< for _offlineError
        return;
      }
    }

    void switchChapter(BuildContext c, int cid) {
      if (cid == widget.chapterId) {
        Fluttertoast.showToast(msg: '当前正在阅读 ${neededData?.chapterGroups.findChapter(cid)?.title ?? '该章节'}');
      } else {
        Navigator.of(c).pop(); // close bottom sheet
        _updateHistory();
        Navigator.of(context).pushReplacement(
          CustomPageRoute.fromTheme(
            themeData: CustomPageRouteTheme.of(context),
            builder: (c) => MangaViewerPage(
              mangaId: widget.mangaId,
              chapterId: cid,
              mangaTitle: mangaTitle,
              mangaCover: mangaCover,
              mangaUrl: mangaUrl,
              neededData: neededData,
              initialPage: 1 /* always turn to the first page */,
              onlineMode: widget.onlineMode,
              replacing: true,
            ),
          ),
        );
      }
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
            mangaTitle: mangaTitle,
            groups: neededData!.chapterGroups,
            highlightedChapter: widget.chapterId,
            onChapterPressed: (cid) => switchChapter(c, cid),
            onChapterLongPressed: (cid) {
              var chapter = neededData!.chapterGroups.findChapter(cid);
              if (chapter == null) {
                Fluttertoast.showToast(msg: '未在漫画章节列表中找到章节'); // almost unreachable
                return;
              }

              // (更新数据库)、~~更新界面~~、(弹出提示)、(发送通知)
              showPopupMenuForMangaToc(
                context: context,
                mangaId: widget.mangaId,
                mangaTitle: mangaTitle,
                mangaCover: mangaCover,
                mangaUrl: mangaUrl,
                fromMangaPage: false,
                chapter: chapter,
                chapterNeededData: neededData,
                onHistoryUpdated: null,
                allowDeletingHistory: false /* => 不显示 "删除阅读历史" */,
                toSwitchChapter: () => switchChapter(c, cid) /* => 仅显示 "切换为该章节" */,
                navigateWrapper: (navigate) async {
                  await _ScreenHelper.restoreSystemUI();
                  await navigate();
                  await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
                },
              );
            },
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
            pushNavigateWrapper: (navigate) async {
              await _ScreenHelper.restoreSystemUI();
              await navigate(); // pushReplaced => true
              await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
            },
          ),
        ),
      ),
    );
    await Future.delayed(kBottomSheetExitDuration + Duration(milliseconds: 10));
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
      laterManga: _laterManga,
      inLaterSetter: (l) {
        // (更新数据库)、更新界面[↴]、(弹出提示)、(发送通知)
        _laterManga = l;
        if (mounted) setState(() {});
      },
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

  Future<void> _openOverviewPage() async {
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

  void _showPopupMenu(int imageIndex /* start from 0 */) {
    HapticFeedback.vibrate();
    var imageIndexP1 = imageIndex + 1; // start from 1
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('第$imageIndexP1页'),
        children: [
          IconTextDialogOption(
            icon: Icon(Icons.refresh),
            text: Text('重新加载'),
            onPressed: () async {
              Navigator.of(c).pop();
              _mangaGalleryViewKey.currentState?.reloadImage(imageIndex); // start from 0
            },
          ),
          IconTextDialogOption(
            icon: Icon(Icons.download),
            text: Text('保存该页'),
            onPressed: () async {
              Navigator.of(c).pop();
              var url = _pageUrls![imageIndex]; // maybe invalid when offline => null
              if (url == null) {
                Fluttertoast.showToast(msg: '当前处于离线模式，但未在下载列表中获取到第$imageIndexP1页链接');
              } else {
                var filepath = await getCachedOrDownloadedChapterPageFilePath(mangaId: widget.mangaId, chapterId: widget.chapterId, pageIndex: imageIndex, url: url);
                var f = await downloadImageToGallery(url, precheck: filepath == null ? null : File(filepath));
                if (f != null) {
                  Fluttertoast.showToast(msg: '第$imageIndexP1页已保存至 ${f.path}');
                } else {
                  Fluttertoast.showToast(msg: '无法保存第$imageIndexP1页');
                }
              }
            },
          ),
          IconTextDialogOption(
            icon: Icon(Icons.share),
            text: Text('分享该页链接'),
            onPressed: () {
              Navigator.of(c).pop();
              var url = _data!.chapterPageHtmlUrl(imageIndex /* start from 0 */);
              shareText(text: '【${_data!.mangaTitle} ${_data!.chapterTitle}】第$imageIndexP1页 $url');
            },
            onLongPressed: () {
              Navigator.of(c).pop();
              shareText(text: _data!.chapterPageHtmlUrl(imageIndex));
            },
          ),
          IconTextDialogOption(
            icon: Icon(MdiIcons.imageMove),
            text: Text('分享该页图片'),
            onPressed: () async {
              Navigator.of(c).pop();
              var url = _pageUrls![imageIndex]; // maybe invalid when offline => null
              var filepath = await getCachedOrDownloadedChapterPageFilePath(mangaId: widget.mangaId, chapterId: widget.chapterId, pageIndex: imageIndex, url: url);
              if (filepath == null) {
                Fluttertoast.showToast(msg: '图片未加载完成，无法分享图片');
              } else {
                await shareFile(filepath: filepath, type: 'image/*');
              }
            },
            onLongPressed: () async {
              Navigator.of(c).pop();
              var url = _pageUrls![imageIndex]; // maybe invalid when offline => null
              var filepath = await getCachedOrDownloadedChapterPageFilePath(mangaId: widget.mangaId, chapterId: widget.chapterId, pageIndex: imageIndex, url: url);
              if (filepath == null) {
                Fluttertoast.showToast(msg: '图片未加载完成，无法分享图片');
              } else {
                await shareFile(filepath: filepath, type: 'image/*', text: '【${_data!.mangaTitle} ${_data!.chapterTitle}】第$imageIndexP1页 $url'); // TODO test
              }
            },
          ),
        ],
      ),
    );
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
                          onLongPress: () {
                            HapticFeedback.vibrate();
                            showDialog(
                              context: context,
                              builder: (c) => SimpleDialog(
                                title: Text(title),
                                children: [
                                  IconTextDialogOption(
                                    icon: Icon(Icons.copy),
                                    text: Text('复制标题'),
                                    popWhenPress: c,
                                    onPressed: () => copyText(title, showToast: true),
                                  ),
                                  if (_data != null)
                                    IconTextDialogOption(
                                      icon: Icon(Icons.subject),
                                      text: Text('查看章节详情'),
                                      popWhenPress: c,
                                      onPressed: () => _showDetails(),
                                    ),
                                ],
                              ),
                            );
                          },
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
                            PopupMenuItem(
                              child: IconTextMenuItem(Icons.share, '分享本章节'),
                              onTap: () => shareText(text: '【${_data!.mangaTitle} ${_data!.chapterTitle}】${_data!.chapterUrl}'),
                            ),
                            PopupMenuItem(
                              child: IconTextMenuItem(Icons.open_in_browser, '用浏览器打开'),
                              onTap: () => launchInBrowser(context: context, url: _data?.chapterUrl ?? widget.mangaUrl),
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
                    verticalScroll: _isTopToBottom,
                    horizontalReverseScroll: _isRightToLeft,
                    horizontalViewportFraction: _setting.enablePageSpace ? _kViewportFraction : 1,
                    verticalViewportPageSpace: _setting.enablePageSpace ? _kViewportPageSpace : 0,
                    slideWidthRatio: _kSlideWidthRatio,
                    slideHeightRatio: _kSlideHeightRatio,
                    initialImageIndex: (_initialPage ?? 1) - 1 /* start from 0 */,
                    fileAndUrlNotFoundMessage: '该页尚未下载，且未获取到该页的链接\n请重新下载该章节、或切换成在线模式再阅读',
                    onPageChanged: _onPageChanged,
                    onLongPressed: _showPopupMenu,
                    onCenterAreaTapped: (_) {
                      _ScreenHelper.toggleAppBarVisibility(show: !_ScreenHelper.showAppBar, fullscreen: _setting.fullscreen);
                      if (mounted) setState(() {});
                    },
                    firstPageBuilder: (c) => ViewExtraSubPage(
                      isHeader: true,
                      reverseScroll: _isRightToLeft,
                      data: _data!,
                      onlineMode: widget.onlineMode,
                      subscribing: _subscribing,
                      inShelf: _inShelf,
                      inFavorite: _inFavorite,
                      laterManga: _laterManga,
                      toJumpToImage: (idx, anim) => _mangaGalleryViewKey.currentState?.jumpToImage(idx, animated: anim) /* start from 0 */,
                      toGotoNeighbor: (prev) => _gotoNeighborChapter(gotoPrevious: prev),
                      toShowNeighborTip: (prev) => _showNeighborChapterTip(previous: prev),
                      toPop: () => Navigator.of(context).maybePop(),
                      onActionsUpdated: (more) => _mangaGalleryViewKey.currentState?.updatePageHeight(0),
                      toSubscribe: _subscribe,
                      toDownload: _downloadManga,
                      toShowToc: _showToc,
                      toShowSettings: _onSettingPressed,
                      toShowDetails: _showDetails,
                      toShowComments: _showComments,
                      toShowOverview: _openOverviewPage,
                      toShare: () => shareText(text: '【${_data!.mangaTitle} ${_data!.chapterTitle}】${_data!.chapterUrl}'),
                      toShowLaters: _showLaterMangaDialog,
                      toShowImage: _showImage,
                      toOnlineMode: () => _toOnlineMode(alsoCheck: false),
                    ),
                    lastPageBuilder: (c) => ViewExtraSubPage(
                      isHeader: false,
                      reverseScroll: _isRightToLeft,
                      data: _data!,
                      onlineMode: widget.onlineMode,
                      subscribing: _subscribing,
                      inShelf: _inShelf,
                      inFavorite: _inFavorite,
                      laterManga: _laterManga,
                      toJumpToImage: (idx, anim) => _mangaGalleryViewKey.currentState?.jumpToImage(idx, animated: anim) /* start from 0 */,
                      toGotoNeighbor: (prev) => _gotoNeighborChapter(gotoPrevious: prev),
                      toShowNeighborTip: (prev) => _showNeighborChapterTip(previous: prev),
                      toPop: () => Navigator.of(context).maybePop(),
                      onActionsUpdated: (more) => _mangaGalleryViewKey.currentState?.jumpToPage(_data!.pageCount + 1, animated: true),
                      toSubscribe: _subscribe,
                      toDownload: _downloadManga,
                      toShowToc: _showToc,
                      toShowSettings: _onSettingPressed,
                      toShowDetails: _showDetails,
                      toShowComments: _showComments,
                      toShowOverview: _openOverviewPage,
                      toShare: () => shareText(text: '【${_data!.mangaTitle} ${_data!.chapterTitle}】${_data!.chapterUrl}'),
                      toShowLaters: _showLaterMangaDialog,
                      toShowImage: _showImage,
                      toOnlineMode: () => _toOnlineMode(alsoCheck: false),
                    ),
                  ),
                ),
                // ****************************************************************
                // TODO 单手跳转章节助手 (同时添加到 ViewSetting 中)
                // ****************************************************************
                if (_inExtraPage && _currentPage > 1)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: AnimatedSwitcher(
                      duration: _kAnimationDuration,
                      child: !(_data != null && !_ScreenHelper.showAppBar && !_inExtraPage && _setting.showPageHint)
                          ? const SizedBox.shrink() //
                          : null,
                      // : Container(
                      //     color: Colors.black.withOpacity(0.7),
                      //     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                      //     child: null,
                      //   ),
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
                                            onTap: _openOverviewPage,
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
                                    text: !_isRightToLeft ? '上一章节' : '下一章节',
                                    icon: Icons.arrow_right_alt,
                                    rotateAngle: math.pi,
                                    action: () => _gotoNeighborChapter(gotoPrevious: !_isRightToLeft),
                                    longPress: () => _showNeighborChapterTip(previous: !_isRightToLeft),
                                    enable: !_isRightToLeft ? _data!.chapterNeighbor?.hasPrevChapter == true : _data!.chapterNeighbor?.hasNextChapter == true,
                                  ),
                                  action2: ActionItem(
                                    text: !_isRightToLeft ? '下一章节' : '上一章节',
                                    icon: Icons.arrow_right_alt,
                                    action: () => _gotoNeighborChapter(gotoPrevious: _isRightToLeft),
                                    longPress: () => _showNeighborChapterTip(previous: _isRightToLeft),
                                    enable: !_isRightToLeft ? _data!.chapterNeighbor?.hasNextChapter == true : _data!.chapterNeighbor?.hasPrevChapter == true,
                                  ),
                                  action3: ActionItem(
                                    text: '阅读设置',
                                    icon: Icons.settings,
                                    action: () => _onSettingPressed(),
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
                                    child: Text('显示菜单'),
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

  static Future<void> setSystemUIWhenAppbarChanged({required bool fullscreen, required bool isAppbarShown /* explicit */
      }) async {
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
