import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/author.dart';
import 'package:manhuagui_flutter/page/comment.dart';
import 'package:manhuagui_flutter/page/dlg/comment_dialog.dart';
import 'package:manhuagui_flutter/page/dlg/manga_dialog.dart';
import 'package:manhuagui_flutter/page/dlg/setting_ui_dialog.dart';
import 'package:manhuagui_flutter/page/download_choose.dart';
import 'package:manhuagui_flutter/page/download_manga.dart';
import 'package:manhuagui_flutter/page/favorite_author.dart';
import 'package:manhuagui_flutter/page/comments.dart';
import 'package:manhuagui_flutter/page/image_viewer.dart';
import 'package:manhuagui_flutter/page/manga_detail.dart';
import 'package:manhuagui_flutter/page/manga_history.dart';
import 'package:manhuagui_flutter/page/manga_toc.dart';
import 'package:manhuagui_flutter/page/manga_viewer.dart';
import 'package:manhuagui_flutter/page/sep_category.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/fit_system_screenshot.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/later_manga_banner.dart';
import 'package:manhuagui_flutter/page/view/manga_rating.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/page/view/comment_line.dart';
import 'package:manhuagui_flutter/page/view/manga_toc_badge.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/db/later_manga.dart';
import 'package:manhuagui_flutter/service/db/shelf_cache.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/android.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';
import 'package:manhuagui_flutter/service/storage/download_task.dart';
import 'package:manhuagui_flutter/service/storage/queue_manager.dart';

/// 漫画页，网络请求并展示 [Manga] 和 [Comment] 信息
class MangaPage extends StatefulWidget {
  const MangaPage({
    Key? key,
    required this.id,
    required this.title,
    required this.url,
  }) : super(key: key);

  final int id;
  final String title;
  final String url;

  @override
  _MangaPageState createState() => _MangaPageState();
}

class _MangaPageState extends State<MangaPage> with FitSystemScreenshotMixin {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _listViewKey = GlobalKey();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandlers.add(AuthManager.instance.listenOnlyWhen(Tuple1(AuthManager.instance.authData), (ev) => _updateByEvent(authEvent: ev)));
      await AuthManager.instance.check();
    });

    _cancelHandlers.add(EventBusManager.instance.listen<AppSettingChangedEvent>((_) => mountedSetState(() {})));
    _cancelHandlers.add(EventBusManager.instance.listen<HistoryUpdatedEvent>((ev) => _updateByEvent(historyEvent: ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadUpdatedEvent>((ev) => _updateByEvent(downloadEvent: ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<ShelfUpdatedEvent>((ev) => _updateByEvent(shelfEvent: ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<FavoriteUpdatedEvent>((ev) => _updateByEvent(favoriteEvent: ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<LaterUpdatedEvent>((ev) => _updateByEvent(laterEvent: ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<FootprintUpdatedEvent>((ev) => _updateByEvent(footprintEvent: ev)));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  var _loading = true; // initialize to true
  Manga? _data;
  var _error = '';
  TinyMangaChapter? _firstChapter;
  MangaHistory? _history;
  Map<int, ChapterFootprint>? _footprints;
  DownloadedManga? _downloadEntity;

  int? _subscribeCount;
  FavoriteManga? _favoriteManga;
  var _subscribing = false; // 执行订阅操作中
  var _inShelf = false; // 书架
  var _inFavorite = false; // 收藏
  LaterManga? _laterManga; // 稍后阅读
  var _showBriefIntroduction = true;

  Future<void> _loadData() async {
    _loading = true;
    _data = null;
    if (mounted) setState(() {});

    // 1. 异步加载漫画评论首页
    _getComments();

    // 2. 异步获取漫画书架情况
    final client = RestClient(DioManager.instance.dio);
    if (AuthManager.instance.logined) {
      Future.microtask(() async {
        try {
          var r = await client.checkShelfManga(token: AuthManager.instance.token, mid: widget.id); // 我的书架
          _inShelf = r.data.isIn;
          _subscribeCount = r.data.count;
          if (mounted) setState(() {});
        } catch (e, s) {
          var we = wrapError(e, s);
          globalLogger.e('MangaPage._loadData checkShelfManga', e, s);
          if (AppSetting.instance.ui.allowErrorToast) {
            Fluttertoast.showToast(msg: '无法获取书架订阅情况：${we.text}');
          }
        }
        if (_data != null && _subscribeCount != null) {
          // 在获取到书架情况时，如果漫画数据已获得，则随即更新书架缓存
          await _updateDatabaseAfterGot(updateAll: false, updateShelfCache: true);
        }
      });
    }

    // 3. 获取数据库的各种信息
    _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.id); // 阅读历史
    _footprints = await HistoryDao.getMangaFootprintsSet(username: AuthManager.instance.username, mid: widget.id) ?? {}; // 章节历史
    _downloadEntity = await DownloadDao.getManga(mid: widget.id); // 下载记录
    _favoriteManga = await FavoriteDao.getFavorite(username: AuthManager.instance.username, mid: widget.id); // 本地收藏
    _inFavorite = _favoriteManga != null;
    _laterManga = await LaterMangaDao.getLaterManga(username: AuthManager.instance.username, mid: widget.id); // 稍后阅读

    try {
      // 4. 获取漫画信息
      var result = await client.getManga(mid: widget.id);
      if (result.data.title == '') {
        if (!result.data.copyright) {
          throw SpecialException('该漫画暂无版权');
        }
        throw SpecialException('未知错误'); // <<< 获取的漫画数据有问题
      }
      _data = null;
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(kFlashListDuration);
      _data = result.data;
      _firstChapter = _data!.chapterGroups.getFirstNotEmptyGroup()?.chapters.lastOrNull; // get first chapter

      // 5. 更新数据库的各种信息
      await _updateDatabaseAfterGot(updateAll: true);
    } catch (e, s) {
      _data = null;
      _error = wrapError(e, s).text;
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _updateDatabaseAfterGot({
    required bool updateAll,
    bool updateHistory = false,
    bool updateDownload = false,
    bool updateShelfCache = false,
    bool updateFavorite = false,
    bool updateLater = false,
  }) async {
    // => 获取到漫画数据后再更新数据库
    if (_data == null) {
      return;
    }

    // 更新全部 or 单独更新
    updateHistory = updateAll || updateHistory;
    updateDownload = updateAll || updateDownload;
    updateShelfCache = updateAll || updateShelfCache;
    updateFavorite = updateAll || updateFavorite;
    updateLater = updateAll || updateLater;

    // 1. 更新漫画阅读历史
    if (updateHistory) {
      MangaHistory newHistory;
      if (_history != null) {
        newHistory = _history!.copyWith(
          mangaId: _data!.mid,
          mangaTitle: _data!.title,
          mangaCover: _data!.cover,
          mangaUrl: _data!.url,
          lastTime: _history!.read ? _history!.lastTime : DateTime.now(), // 只有未阅读过才修改时间
        ); // 更新历史
      } else {
        newHistory = MangaHistory(
          mangaId: _data!.mid,
          mangaTitle: _data!.title,
          mangaCover: _data!.cover,
          mangaUrl: _data!.url,
          chapterId: 0 /* 未开始阅读 */,
          chapterTitle: '',
          chapterPage: 1,
          lastChapterId: 0 /* 未开始阅读 */,
          lastChapterTitle: '',
          lastChapterPage: 1,
          lastTime: DateTime.now(), // 新历史
        ); // 创建历史
      }
      if (_history == null || !newHistory.equals(_history!)) {
        var toAdd = _history == null;
        var changedExcludeCover = _history == null || !newHistory.equals(_history!, includeCover: false);
        _history = newHistory;
        await HistoryDao.addOrUpdateHistory(username: AuthManager.instance.username, history: newHistory);
        if (changedExcludeCover) {
          EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: _data!.mid, reason: toAdd ? UpdateReason.added : UpdateReason.updated, fromMangaPage: true));
        }
        if (mounted) setState(() {});
      }
    }

    // 2. 更新漫画下载信息
    if (updateDownload && _downloadEntity != null) {
      var newDownload = _downloadEntity!.copyWith(
        mangaId: _data!.mid,
        mangaTitle: _data!.title,
        mangaCover: _data!.cover,
        mangaUrl: _data!.url,
        needUpdate: false,
      );
      if (!newDownload.equals(_downloadEntity!)) {
        var changedExcludeCover = !newDownload.equals(_downloadEntity!, includeCover: false);
        _downloadEntity = newDownload;
        await DownloadDao.addOrUpdateManga(manga: newDownload);
        if (changedExcludeCover) {
          EventBusManager.instance.fire(DownloadUpdatedEvent(mangaId: _data!.mid, fromMangaPage: true));
        }
        if (mounted) setState(() {});
      }
    }

    // 3. 更新书架缓存信息
    if (updateShelfCache && _subscribeCount != null) {
      if (_inShelf) {
        var cache = ShelfCache(mangaId: widget.id, mangaTitle: _data!.title, mangaCover: _data!.cover, mangaUrl: _data!.url, cachedAt: DateTime.now());
        await ShelfCacheDao.addOrUpdateShelfCache(username: AuthManager.instance.username, cache: cache);
      } else {
        await ShelfCacheDao.deleteShelfCache(username: AuthManager.instance.username, mangaId: widget.id);
      }
      EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: widget.id, added: _inShelf));
    }

    // 4. 更新漫画收藏信息
    if (updateFavorite && _favoriteManga != null) {
      var newFavorite = _favoriteManga!.copyWith(
        mangaId: _data!.mid,
        mangaTitle: _data!.title,
        mangaCover: _data!.cover,
        mangaUrl: _data!.url,
      );
      if (!newFavorite.equals(_favoriteManga!)) {
        var changedExcludeCover = !newFavorite.equals(_favoriteManga!, includeCover: false);
        _favoriteManga = newFavorite;
        await FavoriteDao.addOrUpdateFavorite(username: AuthManager.instance.username, favorite: newFavorite);
        if (changedExcludeCover) {
          EventBusManager.instance.fire(FavoriteUpdatedEvent(mangaId: _data!.mid, group: newFavorite.groupName, reason: UpdateReason.updated, fromMangaPage: true));
        }
        if (mounted) setState(() {});
      }
    }

    // 5. 更新稍后阅读信息
    if (updateLater && _laterManga != null) {
      var newLater = _laterManga!.copyWith(
        mangaId: _data!.mid,
        mangaTitle: _data!.title,
        mangaCover: _data!.cover,
        mangaUrl: _data!.url,
      );
      if (!newLater.equals(_laterManga!)) {
        var changedExcludeCover = !newLater.equals(_laterManga!, includeCover: false);
        _laterManga = newLater;
        await LaterMangaDao.addOrUpdateLaterManga(username: AuthManager.instance.username, manga: newLater);
        if (changedExcludeCover) {
          EventBusManager.instance.fire(LaterUpdatedEvent(mangaId: _data!.mid, added: false, fromMangaPage: true));
        }
        if (mounted) setState(() {});
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
    FootprintUpdatedEvent? footprintEvent,
  }) async {
    if (authEvent != null) {
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.id); // 阅读历史
      _footprints = await HistoryDao.getMangaFootprintsSet(username: AuthManager.instance.username, mid: widget.id) ?? {}; // 章节历史
      _subscribeCount = null;
      _favoriteManga = await FavoriteDao.getFavorite(username: AuthManager.instance.username, mid: widget.id);
      _inShelf = false;
      _inFavorite = _favoriteManga != null;
      _laterManga = await LaterMangaDao.getLaterManga(username: AuthManager.instance.username, mid: widget.id); // 稍后阅读
      if (mounted) setState(() {});
    }

    if (historyEvent != null && !historyEvent.fromMangaPage && historyEvent.mangaId == widget.id) {
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.id);
      if (mounted) setState(() {});
    }

    if (downloadEvent != null && !downloadEvent.fromMangaPage && downloadEvent.mangaId == widget.id) {
      _downloadEntity = await DownloadDao.getManga(mid: widget.id);
      if (mounted) setState(() {});
    }

    if (shelfEvent != null && !shelfEvent.fromMangaPage && shelfEvent.mangaId == widget.id) {
      _inShelf = shelfEvent.added;
      if (mounted) setState(() {});
    }

    if (favoriteEvent != null && !favoriteEvent.fromMangaPage && favoriteEvent.mangaId == widget.id) {
      _favoriteManga = await FavoriteDao.getFavorite(username: AuthManager.instance.username, mid: favoriteEvent.mangaId);
      _inFavorite = _favoriteManga != null;
      if (mounted) setState(() {});
    }

    if (laterEvent != null && !laterEvent.fromMangaPage && laterEvent.mangaId == widget.id) {
      _laterManga = await LaterMangaDao.getLaterManga(username: AuthManager.instance.username, mid: widget.id);
      if (mounted) setState(() {});
    }

    if (footprintEvent != null && !footprintEvent.fromMangaPage && footprintEvent.mangaId == widget.id) {
      _footprints = await HistoryDao.getMangaFootprintsSet(username: AuthManager.instance.username, mid: widget.id) ?? {};
      if (mounted) setState(() {});
    }
  }

  var _commentLoading = true;
  final _comments = <Comment>[];
  var _commentError = '';
  var _commentTotal = 0;

  Future<void> _getComments() async {
    _commentLoading = true;
    _comments.clear();
    _commentTotal = 0;
    if (mounted) setState(() {});

    final client = RestClient(DioManager.instance.dio);
    try {
      var result = await client.getMangaComments(mid: widget.id, page: 1);
      _comments.addAll(result.data.data.sublist(0, 20.clamp(0, result.data.data.length))); // # = 30 -> 20
      _commentError = '';
      _commentTotal = result.data.total;
    } catch (e, s) {
      _comments.clear();
      _commentError = wrapError(e, s).text;
    } finally {
      _commentLoading = false;
      if (mounted) setState(() {});
    }
  }

  void _subscribe() {
    showPopupMenuForSubscribing(
      context: context,
      mangaId: _data!.mid,
      mangaTitle: _data!.title,
      mangaCover: _data!.cover,
      mangaUrl: _data!.url,
      extraData: MangaExtraDataForDialog.fromManga(_data!),
      fromMangaPage: true,
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

  void __gotoViewerPage({required int cid, required int page}) {
    Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => MangaViewerPage(
          mangaId: _data!.mid,
          chapterId: cid /* <<< */,
          mangaTitle: _data!.title,
          mangaCover: _data!.cover,
          mangaUrl: _data!.url,
          neededData: MangaChapterNeededData.fromMangaData(_data!),
          initialPage: page /* <<< */,
          onlineMode: true,
        ),
      ),
    );
  }

  void _readChapter({required int chapterId}) {
    if (_history == null || (_history!.chapterId != chapterId && _history!.lastChapterId != chapterId)) {
      // (1) 所选章节不是上次/上上次阅读的章节 => 直接从第一页阅读
      __gotoViewerPage(cid: chapterId, page: 1);
      return;
    }

    // (2) 所选章节在上次/上上次被阅读 => 弹出选项判断是否需要阅读
    var historyTitle = _history!.chapterId == chapterId ? _history!.chapterTitle : _history!.lastChapterTitle;
    var historyPage = _history!.chapterId == chapterId ? _history!.chapterPage : _history!.lastChapterPage;
    var chapter = _data!.chapterGroups.findChapter(chapterId);
    if (chapter == null) {
      showYesNoAlertDialog(context: context, title: Text('章节阅读'), content: Text('未找到所选章节，无法阅读。'), yesText: Text('确定'), noText: null);
      return; // actually unreachable
    }
    var checkNotfin = AppSetting.instance.ui.readGroupBehavior.needCheckNotfin(currentPage: historyPage, totalPage: chapter.pageCount); // 是否检查"未阅读完"
    var checkFinish = AppSetting.instance.ui.readGroupBehavior.needCheckFinish(currentPage: historyPage, totalPage: chapter.pageCount); // 是否检查"已阅读完"
    if (!checkNotfin && !checkFinish) {
      // (2.1) 所选章节无需弹出提示 => 继续阅读
      __gotoViewerPage(cid: chapterId, page: historyPage);
    } else if (checkNotfin) {
      // (2.2) 所选章节需要弹出提示 (未阅读完) => 根据所选选项来确定阅读行为
      showDialog(
        context: context,
        builder: (c) => SimpleDialog(
          title: Text('章节阅读'),
          children: [
            SubtitleDialogOption(
              text: Text('该章节 ($historyTitle) 已阅读至第$historyPage页 (共${chapter.pageCount}页)，是否继续阅读该页？'),
            ),
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_book_arrow_right),
              text: Text('继续阅读该章节 ($historyTitle 第$historyPage页)'), // TODO handle overflow
              popWhenPress: c,
              onPressed: () => __gotoViewerPage(cid: chapterId, page: historyPage),
            ),
            if (historyPage > 1)
              IconTextDialogOption(
                icon: Icon(CustomIcons.opened_book_replay),
                text: Text('从头阅读该章节 ($historyTitle 第1页)'),
                popWhenPress: c,
                onPressed: () => __gotoViewerPage(cid: chapterId, page: 1),
              ),
          ],
        ),
      );
    } else {
      // (2.3) 所选章节需要弹出提示 (已阅读完) => 寻找下一章节，再根据所选选项来确定阅读行为
      var neighbor = _data!.chapterGroups.findNextChapter(chapterId); // 从全部分组的章节中选取上下章节
      showDialog(
        context: context,
        builder: (c) => SimpleDialog(
          title: Text('章节阅读'),
          children: [
            SubtitleDialogOption(
              text: Text(
                neighbor != null && neighbor.hasNextChapter
                    ? '该章节 ($historyTitle) 已阅读至最后一页 (第$historyPage页)，是否继续下一章节该页？' // 已找到下一个章节 (可能会找到两个)
                    : '该章节 ($historyTitle) 已阅读至最后一页 (第$historyPage页)，且暂无下一章节，是否继续阅读该章节？', // 未找到下一个章节
              ),
            ),
            if (neighbor?.nextSameGroupChapter != null)
              IconTextDialogOption(
                icon: Icon(CustomIcons.opened_left_star_book),
                text: Text('开始阅读新章节 (${neighbor!.nextSameGroupChapter!.title} 第1页)'),
                popWhenPress: c,
                onPressed: () => __gotoViewerPage(cid: neighbor.nextSameGroupChapter!.cid, page: 1),
              ),
            if (neighbor?.nextDiffGroupChapter != null)
              IconTextDialogOption(
                icon: Icon(CustomIcons.opened_left_star_book),
                text: Text('开始阅读新章节 (${neighbor!.nextDiffGroupChapter!.title} 第1页)'),
                popWhenPress: c,
                onPressed: () => __gotoViewerPage(cid: neighbor.nextDiffGroupChapter!.cid, page: 1),
              ),
            if (historyPage > 1)
              IconTextDialogOption(
                icon: Icon(CustomIcons.opened_book_replay),
                text: Text('从头阅读该章节 ($historyTitle 第1页)'),
                popWhenPress: c,
                onPressed: () => __gotoViewerPage(cid: chapterId, page: 1),
              ),
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_book_arrow_right),
              text: Text('继续阅读该章节 ($historyTitle 第$historyPage页)'),
              popWhenPress: c,
              onPressed: () => __gotoViewerPage(cid: chapterId, page: historyPage),
            ),
          ],
        ),
      );
    }
  }

  void _startOrContinueToRead() {
    if (_history == null || !_history!.read) {
      // (1) 未访问 or 未开始阅读 => 开始阅读
      _firstChapter = _data!.chapterGroups.getFirstNotEmptyGroup()?.chapters.lastOrNull; // 首要选【单话】分组，否则选首个拥有非空章节的分组
      if (mounted) setState(() {});
      if (_firstChapter != null) {
        __gotoViewerPage(cid: _firstChapter!.cid, page: 1);
      }
      return;
    }

    // (2) 存在阅读历史 => 进一步判断阅读状态
    var historyCid = _history!.chapterId;
    var historyTitle = _history!.chapterTitle;
    var historyPage = _history!.chapterPage;
    var chapter = _data!.chapterGroups.findChapter(historyCid);
    if (chapter == null) {
      showYesNoAlertDialog(context: context, title: Text('章节阅读'), content: Text('未找到所选章节，无法阅读。'), yesText: Text('确定'), noText: null);
      return; // actually unreachable
    }
    var checkNotfin = AppSetting.instance.ui.readGroupBehavior.needCheckNotfin(currentPage: historyPage, totalPage: chapter.pageCount); // 是否检查"未阅读完"
    if (chapter.pageCount != historyPage && !checkNotfin) {
      // (2.1) 章节未阅读完，且无需弹出提示 => 继续阅读
      __gotoViewerPage(cid: historyCid, page: historyPage); // 继续阅读
    } else if (chapter.pageCount != historyPage && checkNotfin) {
      // (2.2) 章节未阅读完，且需要弹出提示 => 根据所选选项来确定阅读行为
      showDialog(
        context: context,
        builder: (c) => SimpleDialog(
          title: Text('继续阅读'),
          children: [
            SubtitleDialogOption(
              text: Text('该章节 ($historyTitle) 已阅读至第$historyPage页 (共${chapter.pageCount}页)，是否继续阅读该页？'),
            ),
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_book_arrow_right),
              text: Text('继续阅读该章节 ($historyTitle 第$historyPage页)'),
              popWhenPress: c,
              onPressed: () => __gotoViewerPage(cid: historyCid, page: historyPage),
            ),
            if (historyPage > 1)
              IconTextDialogOption(
                icon: Icon(CustomIcons.opened_book_replay),
                text: Text('从头阅读该章节 ($historyTitle 第1页)'),
                popWhenPress: c,
                onPressed: () => __gotoViewerPage(cid: historyCid, page: 1),
              ),
          ],
        ),
      );
    } else {
      // (2.3) 该章节已阅读完 => 寻找下一章节，再根据所选选项来确定阅读行为
      var neighbor = _data!.chapterGroups.findNextChapter(historyCid); // 从全部分组的章节中选取上下章节
      showDialog(
        context: context,
        builder: (c) => SimpleDialog(
          title: Text('继续阅读'),
          children: [
            SubtitleDialogOption(
              text: Text(
                neighbor != null && neighbor.hasNextChapter
                    ? '该章节 ($historyTitle) 已阅读至最后一页 (第$historyPage页)，是否继续下一章节该页？' // 已找到下一个章节 (可能会找到两个)
                    : '该章节 ($historyTitle) 已阅读至最后一页 (第$historyPage页)，且暂无下一章节，是否继续阅读该章节？', // 未找到下一个章节
              ),
            ),
            if (neighbor?.nextSameGroupChapter != null)
              IconTextDialogOption(
                icon: Icon(CustomIcons.opened_left_star_book),
                text: Text('开始阅读新章节 (${neighbor!.nextSameGroupChapter!.title} 第1页)'),
                popWhenPress: c,
                onPressed: () => __gotoViewerPage(cid: neighbor.nextSameGroupChapter!.cid, page: 1),
              ),
            if (neighbor?.nextDiffGroupChapter != null)
              IconTextDialogOption(
                icon: Icon(CustomIcons.opened_left_star_book),
                text: Text('开始阅读新章节 (${neighbor!.nextDiffGroupChapter!.title} 第1页)'),
                popWhenPress: c,
                onPressed: () => __gotoViewerPage(cid: neighbor.nextDiffGroupChapter!.cid, page: 1),
              ),
            if (historyPage > 1)
              IconTextDialogOption(
                icon: Icon(CustomIcons.opened_book_replay),
                text: Text('从头阅读该章节 ($historyTitle 第1页)'),
                popWhenPress: c,
                onPressed: () => __gotoViewerPage(cid: historyCid, page: 1),
              ),
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_book_arrow_right),
              text: Text('继续阅读该章节 ($historyTitle 第$historyPage页)'),
              popWhenPress: c,
              onPressed: () => __gotoViewerPage(cid: historyCid, page: historyPage),
            ),
          ],
        ),
      );
    }
  }

  void _showHistoryPopupMenu() {
    _firstChapter = _data!.chapterGroups.getFirstNotEmptyGroup()?.chapters.lastOrNull; // 首要选【单话】分组，否则选首个拥有非空章节的分组
    if (mounted) setState(() {});

    Future<bool> showCheckDialog({required String msg}) async {
      var ok = await showYesNoAlertDialog(context: context, title: Text('删除历史确认'), content: Text(msg), yesText: Text('删除'), noText: Text('取消'));
      return ok ?? false;
    }

    bool checkIsChapterFinished({required int chapterId, required int chapterPage}) {
      return _data!.chapterGroups.findChapter(chapterId)?.pageCount == chapterPage;
    }

    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('漫画阅读历史'),
        children: [
          /// 历史展示 (无阅读历史)
          if (_history == null || !_history!.read) ...[
            IconTextDialogOption(
              icon: Icon(Icons.history),
              text: Text('无阅读历史${_history == null ? '，且不保留浏览历史' : ''}'),
              onPressed: () {},
            ),
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_left_star_book),
              text: Flexible(
                child: Text('开始阅读该漫画 (${_firstChapter?.title ?? '未知话'})', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              popWhenPress: c,
              onPressed: () => _startOrContinueToRead() /* 开始阅读 */,
            ),
          ],

          /// 历史展示 (有阅读历史)
          if (_history != null && _history!.read) ...[
            IconTextDialogOption(
              icon: Icon(Icons.history),
              text: Flexible(
                child: Text('最近阅读于 ${_history!.formattedLastTime}', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              onPressed: () => copyText(_history!.formattedLastTime, showToast: true),
            ),
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_book_clock),
              text: Flexible(
                child: Text(
                  checkIsChapterFinished(chapterId: _history!.chapterId, chapterPage: _history!.chapterPage).let(
                    (fin) => '上次阅读到 ${_history!.chapterTitle} 第${_history!.chapterPage}页${fin ? ' 完' : ''}',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              popWhenPress: c,
              onPressed: () => _readChapter(chapterId: _history!.chapterId) /* 选择章节阅读 */,
            ),
            if (_history!.lastChapterId != 0)
              IconTextDialogOption(
                icon: Icon(CustomIcons.opened_book_clock),
                text: Flexible(
                  child: Text(
                    checkIsChapterFinished(chapterId: _history!.lastChapterId, chapterPage: _history!.lastChapterPage).let(
                      (fin) => '上上次阅读到 ${_history!.lastChapterTitle} 第${_history!.lastChapterPage}页${fin ? ' 完' : ''}',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                popWhenPress: c,
                onPressed: () => _readChapter(chapterId: _history!.lastChapterId) /* 选择章节阅读 */,
              ),
          ],

          /// 章节阅读历史
          if (_history != null)
            IconTextDialogOption(
              icon: Icon(CustomIcons.history_menu),
              text: Text('已阅读 ${_footprints?.length ?? 0} 个章节，管理章节阅读历史'),
              popWhenPress: c,
              onPressed: () => _gotoHistoryPage(),
            ),
          Divider(height: 16, thickness: 1),

          /// 删除操作
          // 显示对话框、更新数据库、更新界面[↴]、发送通知
          // 本页引起的更新 => 更新历史相关的界面
          if (_history != null && _history!.read)
            IconTextDialogOption(
              icon: Icon(CustomIcons.history_delete),
              text: Text('删除所有章节阅读历史，保留漫画浏览历史'),
              predicateForPress: () => showCheckDialog(msg: '确定删除漫画阅读历史 (包括章节阅读历史)，且保留漫画浏览历史？'),
              popWhenPress: c,
              onPressed: () async {
                _history = _history!.copyWithNoCurrChapterAndLastChapter(lastTime: DateTime.now()); // 删除章节阅读历史，仅保留漫画浏览历史
                await HistoryDao.addOrUpdateHistory(username: AuthManager.instance.username, history: _history!);
                _footprints?.clear();
                await HistoryDao.clearMangaFootprints(username: AuthManager.instance.username, mid: widget.id);
                if (mounted) setState(() {});
                EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: _data!.mid, reason: UpdateReason.updated, fromMangaPage: true));
                EventBusManager.instance.fire(FootprintUpdatedEvent(mangaId: _data!.mid, chapterIds: null, reason: UpdateReason.deleted, fromMangaPage: true));
              },
            ),
          if (_history != null)
            IconTextDialogOption(
              icon: Icon(CustomIcons.history_delete),
              text: Text(!_history!.read ? '删除浏览历史' : '删除所有章节阅读历史、以及漫画浏览历史'),
              predicateForPress: () => showCheckDialog(msg: '确定删除' + (!_history!.read ? '漫画浏览历史？' : '漫画阅读历史 (包括章节阅读历史)、以及漫画浏览历史？')),
              popWhenPress: c,
              onPressed: () async {
                _history = null; // 删除历史
                await HistoryDao.deleteHistory(username: AuthManager.instance.username, mid: _data!.mid);
                _footprints?.clear();
                await HistoryDao.clearMangaFootprints(username: AuthManager.instance.username, mid: widget.id);
                if (mounted) setState(() {});
                EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: _data!.mid, reason: UpdateReason.deleted, fromMangaPage: true));
                EventBusManager.instance.fire(FootprintUpdatedEvent(mangaId: _data!.mid, chapterIds: null, reason: UpdateReason.deleted, fromMangaPage: true));
              },
            ),
          if (_history == null)
            IconTextDialogOption(
              icon: Icon(CustomIcons.history_plus),
              text: Text('保留漫画浏览历史'),
              popWhenPress: c,
              onPressed: () async {
                _history = MangaHistory(
                  mangaId: _data!.mid,
                  mangaTitle: _data!.title,
                  mangaCover: _data!.cover,
                  mangaUrl: _data!.url,
                  chapterId: 0 /* 未开始阅读 */,
                  chapterTitle: '',
                  chapterPage: 1,
                  lastChapterId: 0 /* 未开始阅读 */,
                  lastChapterTitle: '',
                  lastChapterPage: 1,
                  lastTime: DateTime.now(),
                ); // 还原历史
                await HistoryDao.addOrUpdateHistory(username: AuthManager.instance.username, history: _history!);
                if (mounted) setState(() {});
                EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: _data!.mid, reason: UpdateReason.added, fromMangaPage: true));
              },
            ),
        ],
      ),
    );
  }

  Future<void> _showLaterMangaDialog() async {
    showPopupMenuForLaterManga(
      context: context,
      mangaId: _data!.mid,
      mangaTitle: _data!.title,
      mangaCover: _data!.cover,
      mangaUrl: _data!.url,
      extraData: MangaExtraDataForDialog.fromManga(_data!),
      fromMangaPage: true,
      laterManga: _laterManga!,
      inLaterSetter: (l) {
        // (更新数据库)、更新界面[↴]、(弹出提示)、(发送通知)
        _laterManga = l;
        if (mounted) setState(() {});
      },
    );
  }

  void _showAuthorDialog() {
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('查看作者'),
        children: [
          for (var author in _data!.authors)
            IconTextDialogOption(
              icon: Icon(Icons.person),
              text: Text(author.name),
              popWhenPress: c,
              onPressed: () => Navigator.of(context).push(
                CustomPageRoute(
                  context: context,
                  builder: (c) => AuthorPage(
                    id: author.aid,
                    name: author.name,
                    url: author.url,
                  ),
                ),
              ),
            ),
          IconTextDialogOption(
            icon: Icon(Icons.people),
            text: Text('查看已收藏的作者'),
            popWhenPress: c,
            onPressed: () => Navigator.of(context).push(
              CustomPageRoute(
                context: context,
                builder: (c) => FavoriteAuthorPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDownloadDetailDialog() {
    var noChapter = _downloadEntity == null || _downloadEntity!.triedChaptersCount == 0;
    var success = !noChapter && _downloadEntity!.allChaptersSucceeded;
    var paused = QueueManager.instance.getDownloadMangaQueueTask(_data!.mid) == null;
    var downloading = QueueManager.instance.getDownloadMangaQueueTask(_data!.mid)?.cancelRequested == false;

    String text;
    if (noChapter) {
      text = '尚未下载任何章节。';
    } else if (success) {
      text = '${_downloadEntity!.totalChaptersCount} 个章节已全部下载完成。';
    } else {
      var started = _downloadEntity!.triedChaptersCount;
      var success = _downloadEntity!.successChaptersCount;
      var tot = _downloadEntity!.totalChaptersCount;
      text = (paused ? '下载已暂停' : '漫画正在下载') + '，已开始下载 $started/$tot 个章节，其中共 $success/$tot 个章节已下载完成。';
    }

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('漫画下载情况'),
        content: Text(text),
        actions: [
          if (noChapter)
            TextButton(
              child: Text('去下载'),
              onPressed: () {
                Navigator.of(c).pop();
                Navigator.of(context).push(
                  CustomPageRoute(
                    context: context,
                    builder: (c) => DownloadChoosePage(
                      mangaId: _data!.mid,
                      mangaTitle: _data!.title,
                      mangaCover: _data!.cover,
                      mangaUrl: _data!.url,
                      groups: _data!.chapterGroups,
                    ),
                  ),
                );
              },
            ),
          if (!noChapter)
            TextButton(
              child: Text('查看下载'),
              onPressed: () {
                Navigator.of(c).pop();
                Navigator.of(context).push(
                  CustomPageRoute(
                    context: context,
                    builder: (c) => DownloadMangaPage(
                      mangaId: _data!.mid,
                      gotoDownloading: !success,
                    ),
                    settings: DownloadMangaPage.buildRouteSetting(
                      mangaId: _data!.mid,
                    ),
                  ),
                );
              },
            ),
          if (!noChapter && !success && downloading)
            TextButton(
              child: Text('暂停下载'),
              onPressed: () {
                Navigator.of(c).pop();
                QueueManager.instance.getDownloadMangaQueueTask(_data!.mid)?.cancel();
              },
            ),
          TextButton(
            child: Text('确定'),
            onPressed: () => Navigator.of(c).pop(),
          ),
        ],
      ),
    );
  }

  void _showDescriptionPopupMenu() {
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('漫画介绍'),
        children: [
          if (_data!.aliases.isNotEmpty)
            IconTextDialogOption(
              icon: Icon(Icons.copy),
              text: Text('复制漫画别名'),
              onPressed: () {
                Navigator.of(c).pop();
                copyText(_data!.aliases.map((a) => '《$a》').join(), showToast: true);
              },
            ),
          IconTextDialogOption(
            icon: Icon(Icons.subject),
            text: Text(_showBriefIntroduction ? '展开详细介绍' : '收起详细介绍'),
            onPressed: () {
              Navigator.of(c).pop();
              _showBriefIntroduction = !_showBriefIntroduction;
              if (mounted) setState(() {});
            },
          ),
          IconTextDialogOption(
            icon: Icon(Icons.copy),
            text: Text('复制简要介绍'),
            onPressed: () async {
              Navigator.of(c).pop();
              copyText(_data!.briefIntroduction, showToast: false);
              await Fluttertoast.cancel();
              Fluttertoast.showToast(msg: '漫画简要介绍已经复制到剪贴板');
            },
          ),
          IconTextDialogOption(
            icon: Icon(Icons.copy),
            text: Text('复制详细介绍'),
            onPressed: () async {
              Navigator.of(c).pop();
              copyText(_data!.introduction, showToast: false);
              await Fluttertoast.cancel();
              Fluttertoast.showToast(msg: '漫画详细介绍已经复制到剪贴板');
            },
          ),
        ],
      ),
    );
  }

  void _showChapterPopupMenu({required int chapterId, required bool forMangaPage}) {
    var chapter = _data!.chapterGroups.findChapter(chapterId);
    if (chapter == null) {
      Fluttertoast.showToast(msg: '未从漫画章节列表中找到章节'); // almost unreachable
      return;
    }

    // (更新数据库)、更新界面[↴]、(弹出提示)、(发送通知)
    // 本页引起的更新 => 更新历史相关的界面
    showPopupMenuForMangaToc(
      context: context,
      mangaId: _data!.mid,
      mangaTitle: _data!.title,
      mangaCover: _data!.cover,
      mangaUrl: _data!.url,
      fromMangaPage: forMangaPage,
      chapter: chapter,
      chapterNeededData: MangaChapterNeededData.fromMangaData(_data!),
      onHistoryUpdated: forMangaPage //
          ? (h) => mountedSetState(() => _history = h)
          : null /* MangaTocPage 内的界面更新由 evb 处理 */,
      onFootprintAdded: forMangaPage //
          ? (fp) => mountedSetState(() => _footprints?[fp.chapterId] = fp)
          : null /* MangaTocPage 内的界面更新由 evb 处理 */,
      onFootprintsAdded: forMangaPage //
          ? (fps) => mountedSetState(() => fps.forEach((fp) => _footprints?[fp.chapterId] = fp))
          : null /* MangaTocPage 内的界面更新由 evb 处理 */,
      onFootprintsRemoved: forMangaPage //
          ? (cids) => mountedSetState(() => _footprints?.removeWhere((key, _) => cids.contains(key)))
          : null /* MangaTocPage 内的界面更新由 evb 处理 */,
    );
  }

  void _gotoTocPage() {
    // 直接打开 MangaTocPage (阅读历史和下载情况等数据由该页自行通过 EventBus 处理)
    Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => MangaTocPage(
          mangaId: _data!.mid,
          mangaTitle: _data!.title,
          groups: _data!.chapterGroups,
          onChapterPressed: (cid) => _readChapter(chapterId: cid),
          onChapterLongPressed: (cid) => _showChapterPopupMenu(chapterId: cid, forMangaPage: false),
          onManageHistoryPressed: () => _gotoHistoryPage(),
        ),
      ),
    );
  }

  void _gotoHistoryPage() {
    Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => MangaHistoryPage(
          mangaId: widget.id,
          mangaTitle: _data!.title,
          mangaCover: _data!.cover,
          mangaUrl: _data!.url,
          chapterGroups: _data!.chapterGroups,
          chapterNeededData: MangaChapterNeededData.fromMangaData(_data!),
        ),
      ),
    );
  }

  void _showMoreChaptersPopupMenu() {
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(_data!.title),
        children: [
          IconTextDialogOption(
            icon: Icon(Icons.notes),
            text: Text('查看全部漫画章节'),
            popWhenPress: c,
            onPressed: () => _gotoTocPage(),
          ),
          IconTextDialogOption(
            icon: Icon(CustomIcons.history_menu),
            text: Text('管理章节阅读历史'),
            popWhenPress: c,
            onPressed: () => _gotoHistoryPage(),
          ),
          IconTextDialogOption(
            icon: Icon(Icons.settings),
            text: Text('漫画章节列表显示设置'),
            popWhenPress: c,
            onPressed: () => showUiSettingDialog(context: context),
          ),
        ],
      ),
    );
  }

  @override
  FitSystemScreenshotData get fitSystemScreenshotData => FitSystemScreenshotData(
        scrollViewKey: _listViewKey,
        scrollController: _controller,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          child: Text(_data?.title ?? widget.title),
          onTap: () => showPopupMenuForMangaTitle(
            context: context,
            manga: _data,
            fallbackTitle: widget.title,
            vibrate: false,
          ),
          onLongPress: () => showPopupMenuForMangaTitle(
            context: context,
            manga: _data,
            fallbackTitle: widget.title,
            vibrate: true,
          ),
        ),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: false),
        actions: [
          AppBarActionButton(
            icon: Icon(Icons.open_in_browser),
            tooltip: '用浏览器打开',
            onPressed: () => launchInBrowser(
              context: context,
              url: _data?.url ?? widget.url,
            ),
          ),
        ],
      ),
      drawer: AppDrawer(
        currentSelection: DrawerSelection.none,
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadData,
        child: PlaceholderText.from(
          isLoading: _loading,
          errorText: _error,
          isEmpty: _data == null,
          setting: PlaceholderSetting().copyWithChinese(),
          onRefresh: () => _loadData(),
          childBuilder: (c) => ExtendedScrollbar(
            controller: _controller,
            interactive: true,
            mainAxisMargin: 2,
            crossAxisMargin: 2,
            child: ListView(
              key: _listViewKey,
              controller: _controller,
              padding: EdgeInsets.zero,
              physics: AlwaysScrollableScrollPhysics(),
              cacheExtent: 999999 /* <<< keep states in ListView */,
              children: [
                // ****************************************************************
                // 头部框
                // ****************************************************************
                Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0, 0.5, 1],
                      colors: [
                        Colors.blue[100]!,
                        Colors.orange[100]!,
                        Colors.purple[100]!,
                      ],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ****************************************************************
                      // 封面
                      // ****************************************************************
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: FullRippleWidget(
                          child: NetworkImageView(
                            url: _data!.cover,
                            height: 160,
                            width: 120,
                            quality: FilterQuality.high,
                          ),
                          onTap: () => Navigator.of(context).push(
                            CustomPageRoute(
                              context: context,
                              builder: (c) => ImageViewerPage(
                                url: _data!.cover,
                                title: '漫画封面',
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ****************************************************************
                      // 信息
                      // ****************************************************************
                      Container(
                        width: MediaQuery.of(context).size.width - 14 * 3 - 120, // | ▢ ▢▢ |
                        padding: EdgeInsets.only(top: 10, bottom: 10, right: 0),
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconText(
                              icon: Icon(Icons.person, size: 20, color: Colors.orange),
                              text: TextGroup.normal(
                                texts: [
                                  PlainTextItem(text: '作者：'),
                                  for (var i = 0; i < _data!.authors.length; i++) ...[
                                    LinkTextItem(
                                      text: _data!.authors[i].name,
                                      pressedColor: Theme.of(context).primaryColor,
                                      showUnderline: true,
                                      onTap: () => Navigator.of(context).push(
                                        CustomPageRoute(
                                          context: context,
                                          builder: (c) => AuthorPage(
                                            id: _data!.authors[i].aid,
                                            name: _data!.authors[i].name,
                                            url: _data!.authors[i].url,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (i != _data!.authors.length - 1) PlainTextItem(text: ' / '),
                                  ],
                                ],
                              ),
                              space: 8,
                              iconPadding: EdgeInsets.symmetric(vertical: 3.3),
                            ),
                            IconText(
                              icon: Icon(Icons.category, size: 20, color: Colors.orange),
                              text: TextGroup.normal(
                                texts: [
                                  PlainTextItem(text: '类别：'),
                                  for (var i = 0; i < _data!.genres.length; i++) ...[
                                    LinkTextItem(
                                      text: _data!.genres[i].title,
                                      pressedColor: Theme.of(context).primaryColor,
                                      showUnderline: true,
                                      onTap: () => Navigator.of(context).push(
                                        CustomPageRoute(
                                          context: context,
                                          builder: (c) => SepCategoryPage(
                                            genre: _data!.genres[i].toTiny(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (i != _data!.genres.length - 1) PlainTextItem(text: ' / '),
                                  ],
                                ],
                              ),
                              space: 8,
                              iconPadding: EdgeInsets.symmetric(vertical: 3.3),
                            ),
                            IconText(
                              icon: Icon(Icons.event, size: 20, color: Colors.orange),
                              text: Text('发布于 ${_data!.publishYear} ${_data!.mangaZone.replaceAll('漫画', '')}'),
                              space: 8,
                              iconPadding: EdgeInsets.symmetric(vertical: 3.3),
                            ),
                            IconText(
                              icon: Icon(Icons.stars, size: 20, color: Colors.orange),
                              text: Text('排名 ${_data!.mangaRank} / 订阅 ${_subscribeCount?.let((c) => '$c人') ?? '未知'}'),
                              space: 8,
                              iconPadding: EdgeInsets.symmetric(vertical: 3.3),
                            ),
                            IconText(
                              icon: Icon(Icons.notes, size: 20, color: Colors.orange),
                              text: Flexible(
                                child: Text(
                                  '最新章节：${_data!.newestChapter}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              space: 8,
                              iconPadding: EdgeInsets.symmetric(vertical: 3.3),
                            ),
                            IconText(
                              icon: Icon(Icons.update, size: 20, color: Colors.orange),
                              text: Text('更新于 ${_data!.formattedNewestDate}・${_data!.finished ? '已完结' : '连载中'}'),
                              space: 8,
                              iconPadding: EdgeInsets.symmetric(vertical: 3.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ****************************************************************
                // 稍后阅读
                // ****************************************************************
                if (_laterManga != null)
                  LaterMangaBannerView(
                    manga: _laterManga!,
                    currentNewestChapter: _data!.newestChapter,
                    currentNewestDate: _data!.formattedNewestDate,
                    action: () => _showLaterMangaDialog(),
                  ),
                // ****************************************************************
                // 几个按钮
                // ****************************************************************
                Container(
                  color: Colors.white,
                  child: ActionRowView.five(
                    action1: ActionItem(
                      text: !_inShelf && !_inFavorite
                          ? '订阅漫画'
                          : _inShelf && _inFavorite
                              ? '查看订阅'
                              : (_inShelf && !_inFavorite ? '已放书架' : '已加收藏'),
                      icon: !_inShelf && !_inFavorite ? Icons.sell : Icons.loyalty,
                      action: _subscribing ? null : () => _subscribe(),
                      longPress: _subscribing ? null : () => _subscribe(),
                      enable: !_subscribing,
                    ),
                    action2: ActionItem(
                      text: '查看作者',
                      icon: Icons.person,
                      action: () => _showAuthorDialog(),
                      longPress: () => _showAuthorDialog(),
                    ),
                    action3: ActionItem(
                      text: '下载漫画',
                      icon: Icons.download,
                      action: () => Navigator.of(context).push(
                        CustomPageRoute(
                          context: context,
                          builder: (c) => DownloadChoosePage(
                            mangaId: _data!.mid,
                            mangaTitle: _data!.title,
                            mangaCover: _data!.cover,
                            mangaUrl: _data!.url,
                            groups: _data!.chapterGroups,
                          ),
                        ),
                      ),
                      longPress: _showDownloadDetailDialog,
                    ),
                    action4: ActionItem(
                      text: '漫画详情',
                      icon: Icons.subject,
                      action: () => Navigator.of(context).push(
                        CustomPageRoute(
                          context: context,
                          builder: (c) => MangaDetailPage(data: _data!),
                        ),
                      ),
                    ),
                    action5: ActionItem(
                      text: '分享漫画',
                      icon: Icons.share,
                      action: () => shareText(text: '【${_data!.title}】${_data!.url}'),
                      longPress: () => shareText(text: _data!.url),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white,
                  child: Divider(height: 0, thickness: 1),
                ),
                // ****************************************************************
                // 阅读历史
                // ****************************************************************
                Material(
                  color: Colors.white,
                  child: InkWell(
                    onTap: () => _startOrContinueToRead(),
                    onLongPress: () => _showHistoryPopupMenu(),
                    child: IconText(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 9), // | ▢° ▢▢ |
                      space: 14 /* 14 + 2 <= 16 (narrow than horizontal_padding_18) */,
                      icon: Stack(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 2),
                            child: Icon(Icons.import_contacts, size: 26, color: Colors.black54),
                          ),
                          if (_history == null || !_history!.read)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                height: 11,
                                width: 11,
                                decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: _history != null ? null : Icon(Icons.close, size: 9.0, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      text: Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _history == null || !_history!.read //
                                  ? '开始阅读该漫画 (${_firstChapter?.title ?? '未知话'})'
                                  : (_data!.chapterGroups.findChapter(_history!.chapterId)?.pageCount == _history!.chapterPage).let(
                                      (fin) => '继续阅读该漫画 (${_history!.chapterTitle} 第${_history!.chapterPage}页${fin ? ' 完' : ''})',
                                    ),
                              style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 1),
                            Text(
                              _history == null || !_history!.read //
                                  ? '无阅读历史${_history == null ? '，且不保留浏览历史' : ''}'
                                  : '最近阅读于 ${_history!.formattedLastTimeAndFullDuration}',
                              style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(height: 12),
                // ****************************************************************
                // 介绍
                // ****************************************************************
                Material(
                  color: Colors.white,
                  child: InkWell(
                    onTap: () {
                      _showBriefIntroduction = !_showBriefIntroduction;
                      if (mounted) setState(() {});
                    },
                    onLongPress: () => _showDescriptionPopupMenu(),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      child: TextGroup.normal(
                        style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 15, height: 1.5),
                        texts: [
                          if (_data!.aliases.isNotEmpty) //
                            PlainTextItem(text: '漫画别名${_data!.aliases.map((a) => '《$a》').join()}\n'),
                          if (_showBriefIntroduction) ...[
                            PlainTextItem(text: _data!.briefIntroduction),
                            PlainTextItem(
                              text: '　展开详情',
                              style: TextStyle(color: Theme.of(context).primaryColor),
                            ),
                          ],
                          if (!_showBriefIntroduction) ...[
                            PlainTextItem(text: _data!.introduction),
                            PlainTextItem(
                              text: '　收起介绍',
                              style: TextStyle(color: Theme.of(context).primaryColor),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white,
                  child: Divider(height: 0, thickness: 1),
                ),
                // ****************************************************************
                // 评分投票
                // ****************************************************************
                Material(
                  color: Colors.white,
                  child: InkWell(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      child: MangaRatingView(
                        averageScore: _data!.averageScore,
                        scoreCount: _data!.scoreCount,
                      ),
                    ),
                    onTap: () => showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text('投票评分详情'),
                        scrollable: true,
                        content: MangaRatingDetailView(
                          averageScore: _data!.averageScore,
                          scoreCount: _data!.scoreCount,
                          perScores: _data!.perScores,
                        ),
                        actions: [
                          TextButton(
                            child: Text('投票'),
                            onPressed: () async {
                              var score = await showDialog<int>(
                                context: context,
                                builder: (c) => SimpleDialog(
                                  title: Text('投票评分'),
                                  children: [
                                    for (var i in [5, 4, 3, 2, 1]) //
                                      TextDialogOption(text: StarsTextView(score: i), onPressed: () => Navigator.of(c).pop(i)),
                                  ],
                                ),
                              );
                              if (score != null) {
                                if (!AuthManager.instance.logined) {
                                  Fluttertoast.showToast(msg: '用户未登录');
                                  return;
                                }
                                final client = RestClient(DioManager.instance.dio);
                                try {
                                  await client.voteManga(token: AuthManager.instance.token, mid: widget.id, score: score);
                                  Fluttertoast.showToast(msg: '投票成功，刷新后可查看最新的投票结果');
                                } catch (e, s) {
                                  var _ = wrapError(e, s); // ignore message
                                  Fluttertoast.showToast(msg: '投票失败，可能已对该漫画投票');
                                }
                              }
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
                ),
                Container(height: 12),
                // ****************************************************************
                // 章节列表
                // ****************************************************************
                Container(
                  color: Colors.white,
                  child: MangaTocView(
                    groups: _data!.chapterGroups,
                    full: false,
                    firstGroupRowsIfNotFull: AppSetting.instance.ui.regularGroupRows,
                    otherGroupsRowsIfNotFull: AppSetting.instance.ui.otherGroupRows,
                    gridPadding: EdgeInsets.symmetric(horizontal: 12),
                    highlightedChapters: [_history?.chapterId ?? 0],
                    highlighted2Chapters: [_history?.lastChapterId ?? 0],
                    showHighlight2: AppSetting.instance.ui.showLastHistory,
                    faintedChapters: _footprints?.keys.toList() ?? [],
                    customBadgeBuilder: (cid) => DownloadBadge.fromEntity(
                      entity: _downloadEntity?.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull,
                    ),
                    onChapterPressed: (cid) => _readChapter(chapterId: cid),
                    onChapterLongPressed: (cid) => _showChapterPopupMenu(chapterId: cid, forMangaPage: true),
                    onMoreChaptersPressed: () => _gotoTocPage(),
                    onMoreChaptersLongPressed: () => _showMoreChaptersPopupMenu(),
                  ),
                ),
                Container(height: 12),
                // ****************************************************************
                // 评论
                // ****************************************************************
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.fromLTRB(12, 6, 6, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '评论区 (共 $_commentTotal 条)',
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              '发表评论',
                              style: Theme.of(context).textTheme.bodyText1?.copyWith(color: Theme.of(context).primaryColor),
                            ),
                          ),
                          onTap: () async {
                            var added = await showCommentDialogForAddingComment(context: context, mangaId: widget.id);
                            if (added != null) {
                              var ok = await showYesNoAlertDialog(
                                context: context,
                                title: Text('发表评论'),
                                content: Text('评论发表成功，是否刷新评论列表？'),
                                yesText: Text('刷新'),
                                noText: Text('取消'),
                              );
                              if (ok == true) {
                                _getComments();
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white,
                  child: Divider(height: 0, thickness: 1),
                ),
                Container(
                  color: Colors.white,
                  child: PlaceholderText.from(
                    isEmpty: _comments.isEmpty,
                    isLoading: _commentLoading,
                    errorText: _commentError.isEmpty ? '' : '加载漫画评论失败\n$_commentError',
                    displayRule: PlaceholderDisplayRule.errorFirst,
                    setting: PlaceholderSetting(
                      useAnimatedSwitcher: false,
                      wholePaddingUnlessNormal: EdgeInsets.symmetric(vertical: 15),
                    ).copyWithChinese(
                      loadingText: '评论加载中...',
                      nothingText: '暂无评论',
                    ),
                    onRefresh: () => _getComments(),
                    childBuilder: (_) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < _comments.length; i++) ...[
                          CommentLineView.normalWithReplies(
                            comment: _comments[i],
                            onPressed: () => Navigator.of(context).push(
                              CustomPageRoute(
                                context: context,
                                builder: (c) => CommentPage(
                                  mangaId: widget.id,
                                  comment: _comments[i],
                                ),
                              ),
                            ),
                            onLongPressed: () => showCommentPopupMenuForListAndPage(
                              context: context,
                              mangaId: widget.id,
                              forCommentList: true,
                              comment: _comments[i],
                            ),
                          ),
                          if (i != _comments.length - 1)
                            Container(
                              color: Colors.white,
                              child: Divider(height: 0, thickness: 1, indent: 2.0 * 12 + 32),
                            ),
                        ],
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          color: Colors.white,
                          child: Divider(height: 0, thickness: 1),
                        ),
                        Material(
                          color: Colors.white,
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                              CustomPageRoute(
                                context: context,
                                builder: (c) => CommentsPage(
                                  mangaId: _data!.mid,
                                  mangaTitle: _data!.title,
                                ),
                              ),
                            ),
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              height: 42,
                              child: Center(
                                child: Text(
                                  '查看更多评论...',
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ).fitSystemScreenshot(this),
          ),
        ),
      ),
      floatingActionButton: ScrollAnimatedFab(
        controller: _fabController,
        scrollController: _controller,
        condition: ScrollAnimatedCondition.direction,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: null,
          onPressed: () => _controller.scrollToTop(),
        ),
      ),
    );
  }
}
