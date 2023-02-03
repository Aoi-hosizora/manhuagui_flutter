import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/author.dart';
import 'package:manhuagui_flutter/page/comment.dart';
import 'package:manhuagui_flutter/page/download_choose.dart';
import 'package:manhuagui_flutter/page/download_manga.dart';
import 'package:manhuagui_flutter/page/genre.dart';
import 'package:manhuagui_flutter/page/comments.dart';
import 'package:manhuagui_flutter/page/image_viewer.dart';
import 'package:manhuagui_flutter/page/manga_detail.dart';
import 'package:manhuagui_flutter/page/manga_toc.dart';
import 'package:manhuagui_flutter/page/manga_viewer.dart';
import 'package:manhuagui_flutter/page/page/manga_dialog.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/manga_rating.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/page/view/comment_line.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/db/shelf_cache.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';
import 'package:manhuagui_flutter/service/native/share.dart';
import 'package:manhuagui_flutter/service/storage/download_task.dart';
import 'package:manhuagui_flutter/service/storage/queue_manager.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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

class _MangaPageState extends State<MangaPage> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandlers.add(AuthManager.instance.listenOnlyWhen(Tuple1(AuthManager.instance.authData), (_) async {
        _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.id);
        _subscribeCount = null;
        _favoriteManga = await FavoriteDao.getFavorite(username: AuthManager.instance.username, mid: widget.id);
        _inShelf = false;
        _inFavorite = _favoriteManga != null;
        if (mounted) setState(() {});
      }));
      await AuthManager.instance.check();
    });

    _cancelHandlers.add(EventBusManager.instance.listen<AppSettingChangedEvent>((_) => mountedSetState(() {})));
    _cancelHandlers.add(EventBusManager.instance.listen<HistoryUpdatedEvent>((ev) async {
      if (!ev.fromMangaPage && ev.mangaId == widget.id) {
        _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.id);
        if (mounted) setState(() {});
      }
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadUpdatedEvent>((ev) async {
      if (!ev.fromMangaPage && ev.mangaId == widget.id) {
        _downloadEntity = await DownloadDao.getManga(mid: widget.id);
        if (mounted) setState(() {});
      }
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<ShelfUpdatedEvent>((ev) async {
      if (!ev.fromMangaPage && ev.mangaId == widget.id) {
        _inShelf = ev.added;
        if (mounted) setState(() {});
      }
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<FavoriteUpdatedEvent>((ev) async {
      if (!ev.fromMangaPage && ev.mangaId == widget.id) {
        _favoriteManga = await FavoriteDao.getFavorite(username: AuthManager.instance.username, mid: ev.mangaId);
        _inFavorite = _favoriteManga != null;
        if (mounted) setState(() {});
      }
    }));
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
  DownloadedManga? _downloadEntity;

  int? _subscribeCount;
  FavoriteManga? _favoriteManga;
  var _subscribing = false; // 执行订阅操作中
  var _inShelf = false; // 书架
  var _inFavorite = false; // 收藏
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
          Fluttertoast.showToast(msg: we.text);
        }
        if (_data != null && _subscribeCount != null) {
          // 在获取到书架情况时，如果漫画数据已获得，则随即更新书架缓存
          await _updateDatabaseAfterGot(updateHistory: false, updateDownload: false, updateShelfCache: true, updateFavorite: false);
        }
      });
    }

    // 3. 获取数据库的各种信息
    _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.id); // 阅读历史
    _downloadEntity = await DownloadDao.getManga(mid: widget.id); // 下载记录
    _favoriteManga = await FavoriteDao.getFavorite(username: AuthManager.instance.username, mid: widget.id); // 本地收藏
    _inFavorite = _favoriteManga != null;

    try {
      // 4. 获取漫画信息
      var result = await client.getManga(mid: widget.id);
      if (result.data.title == '') {
        throw SpecialException('未知错误'); // <<< 获取的漫画数据有问题
      }
      _data = null;
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(kFlashListDuration);
      _data = result.data;
      _firstChapter = _data!.chapterGroups.getFirstNotEmptyGroup()?.chapters.lastOrNull; // get last chapter

      // 5. 更新数据库的各种信息
      await _updateDatabaseAfterGot(/* update all */);
    } catch (e, s) {
      _data = null;
      _error = wrapError(e, s).text;
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _updateDatabaseAfterGot({
    bool updateHistory = true,
    bool updateDownload = true,
    bool updateShelfCache = true,
    bool updateFavorite = true,
  }) async {
    // => 获取到所有漫画数据后更新数据库
    if (_data == null) {
      return;
    }

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
        );
      } else {
        newHistory = MangaHistory(
          mangaId: _data!.mid,
          mangaTitle: _data!.title,
          mangaCover: _data!.cover,
          mangaUrl: _data!.url,
          chapterId: 0 /* 未开始阅读 */,
          chapterTitle: '',
          chapterPage: 1,
          lastTime: DateTime.now(), // 新历史
        );
      }
      if (_history == null || !newHistory.equals(_history!)) {
        var toAdd = _history == null;
        _history = newHistory;
        await HistoryDao.addOrUpdateHistory(username: AuthManager.instance.username, history: newHistory);
        EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: _data!.mid, reason: toAdd ? UpdateReason.added : UpdateReason.updated, fromMangaPage: true));
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
        _downloadEntity = newDownload;
        await DownloadDao.addOrUpdateManga(manga: newDownload);
        EventBusManager.instance.fire(DownloadUpdatedEvent(mangaId: _data!.mid, fromMangaPage: true));
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
        _favoriteManga = newFavorite;
        await FavoriteDao.addOrUpdateFavorite(username: AuthManager.instance.username, favorite: newFavorite);
        EventBusManager.instance.fire(FavoriteUpdatedEvent(mangaId: _data!.mid, group: newFavorite.groupName, reason: UpdateReason.updated, fromMangaPage: true));
        if (mounted) setState(() {});
      }
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
      _comments.addAll(result.data.data);
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
      fromMangaPage: true,
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

  void _read({required int? chapterId}) async {
    if (chapterId != null) {
      // 选择章节阅读
      Navigator.of(context).push(
        CustomPageRoute(
          context: context,
          builder: (c) => MangaViewerPage(
            parentContext: context,
            mangaId: _data!.mid,
            chapterId: chapterId,
            mangaCover: _data!.cover,
            chapterGroups: _data!.chapterGroups,
            initialPage: _history?.chapterId == chapterId
                ? _history?.chapterPage ?? 1 // have read
                : 1 /* have not read */,
            onlineMode: true,
          ),
        ),
      );
      return;
    }

    // 开始阅读 / 继续阅读
    int cid;
    int page;
    if (_history?.read != true) {
      // 未访问 or 未开始阅读 => 开始阅读
      var group = _data!.chapterGroups.getFirstNotEmptyGroup(); // 首要选【单话】分组，否则选首个拥有非空章节的分组
      if (group == null) {
        Fluttertoast.showToast(msg: '该漫画还没有章节，无法开始阅读');
        return;
      }
      cid = group.chapters.last.cid; // get last chapter
      page = 1;
    } else {
      // 继续阅读
      cid = _history!.chapterId;
      page = _history!.chapterPage;
    }

    Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => MangaViewerPage(
          parentContext: context,
          mangaId: _data!.mid,
          chapterId: cid,
          mangaCover: _data!.cover,
          chapterGroups: _data!.chapterGroups,
          initialPage: page,
          onlineMode: true,
        ),
      ),
    );
  }

  void _showDownloadActionDialog() {
    var noChapter = _downloadEntity == null || _downloadEntity!.triedChapterIds.isEmpty;
    var success = !noChapter && _downloadEntity!.allChaptersSucceeded;
    var paused = QueueManager.instance.getDownloadMangaQueueTask(_data!.mid) == null;

    String text;
    if (noChapter) {
      text = '尚未下载任何章节。';
    } else if (success) {
      text = '${_downloadEntity!.totalChapterIds.length} 个章节已全部下载完成。';
    } else {
      var suc = _downloadEntity!.successChapterIds.length;
      var tot = _downloadEntity!.totalChapterIds.length;
      text = (paused ? '下载已暂停' : '正在下载中') + '，已成功下载 $suc 个章节，共有 $tot 个章节在下载任务中。';
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
          if (!noChapter && !success && !paused)
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

  void _showHistoryPopupMenu() {
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('漫画阅读历史'),
        children: [
          if (_history != null && _history!.read)
            IconTextDialogOption(
              icon: Icon(MdiIcons.fileClock),
              text: Text('仅保留浏览历史'),
              onPressed: () async {
                Navigator.of(c).pop();
                var newHistory = _history!.copyWith(chapterId: 0 /* 未开始阅读 */, chapterTitle: '', chapterPage: 1, lastTime: DateTime.now());
                await HistoryDao.addOrUpdateHistory(username: AuthManager.instance.username, history: newHistory);
                _history = newHistory;
                EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: _data!.mid, reason: UpdateReason.updated, fromMangaPage: true));
                if (mounted) setState(() {});
              },
            ),
          if (_history != null)
            IconTextDialogOption(
              icon: Icon(MdiIcons.deleteClock),
              text: Text(!_history!.read ? '删除浏览历史' : '删除阅读历史'),
              onPressed: () async {
                Navigator.of(c).pop();
                _history = null;
                await HistoryDao.deleteHistory(username: AuthManager.instance.username, mid: _data!.mid);
                EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: _data!.mid, reason: UpdateReason.deleted, fromMangaPage: true));
                if (mounted) setState(() {});
              },
            ),
          if (_history == null)
            IconTextDialogOption(
              icon: Icon(MdiIcons.fileClock),
              text: Text('保留浏览历史'),
              onPressed: () async {
                Navigator.of(c).pop();
                _history = MangaHistory(
                  mangaId: _data!.mid,
                  mangaTitle: _data!.title,
                  mangaCover: _data!.cover,
                  mangaUrl: _data!.url,
                  chapterId: 0 /* 未开始阅读 */,
                  chapterTitle: '',
                  chapterPage: 1,
                  lastTime: DateTime.now(),
                );
                await HistoryDao.addOrUpdateHistory(username: AuthManager.instance.username, history: _history!);
                EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: _data!.mid, reason: UpdateReason.added, fromMangaPage: true));
                if (mounted) setState(() {});
              },
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
            onPressed: () {
              Navigator.of(c).pop();
              copyText(_data!.briefIntroduction, showToast: false);
              Fluttertoast.showToast(msg: '漫画简要介绍已经复制到剪贴板');
            },
          ),
          IconTextDialogOption(
            icon: Icon(Icons.copy),
            text: Text('复制详细介绍'),
            onPressed: () {
              Navigator.of(c).pop();
              copyText(_data!.introduction, showToast: false);
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
      chapterGroups: _data!.chapterGroups,
      onHistoryUpdated: forMangaPage //
          ? (h) => mountedSetState(() => _history = h)
          : null /* MangaTocPage 内的界面更新由 evb 处理 */,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_data?.title ?? widget.title),
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
              controller: _controller,
              padding: EdgeInsets.zero,
              physics: AlwaysScrollableScrollPhysics(),
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
                                          builder: (c) => GenrePage(
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
                              text: Text('排名 ${_data!.mangaRank} / 订阅 ${_subscribeCount ?? '未知'}'),
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
                // 几个按钮
                // ****************************************************************
                Container(
                  color: Colors.white,
                  child: ActionRowView.five(
                    action1: ActionItem(
                      text: !_inShelf && !_inFavorite
                          ? '订阅漫画'
                          : _inShelf && _inFavorite
                              ? '取消订阅'
                              : (_inShelf && !_inFavorite ? '已放书架' : '已加收藏'),
                      icon: !_inShelf && !_inFavorite ? Icons.sell : Icons.loyalty,
                      action: _subscribing ? null : () => _subscribe(),
                      longPress: _subscribing ? null : () => _subscribe(),
                      enable: !_subscribing,
                    ),
                    action2: ActionItem(
                      text: '查看作者',
                      icon: Icons.person,
                      action: _data!.authors.length == 1
                          ? () => Navigator.of(context).push(
                                CustomPageRoute(
                                  context: context,
                                  builder: (c) => AuthorPage(id: _data!.authors.first.aid, name: _data!.authors.first.name, url: _data!.authors.first.url),
                                ),
                              )
                          : () => showDialog(
                                context: context,
                                builder: (c) => SimpleDialog(
                                  title: Text('查看作者'),
                                  children: [
                                    for (var author in _data!.authors)
                                      TextDialogOption(
                                        text: Text(author.name),
                                        onPressed: () {
                                          Navigator.of(c).pop();
                                          Navigator.of(context).push(
                                            CustomPageRoute(
                                              context: context,
                                              builder: (c) => AuthorPage(id: author.aid, name: author.name, url: author.url),
                                            ),
                                          );
                                        },
                                      )
                                  ],
                                ),
                              ),
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
                      longPress: _showDownloadActionDialog,
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
                      action: () => shareText(
                        title: '漫画柜分享',
                        text: '【${_data!.title}】${_data!.url}',
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
                // 阅读历史
                // ****************************************************************
                Material(
                  color: Colors.white,
                  child: InkWell(
                    onTap: () => _read(chapterId: null),
                    onLongPress: _showHistoryPopupMenu,
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
                                height: 10.5,
                                width: 10.5,
                                decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: _history != null ? null : Icon(Icons.remove, size: 10.5, color: Colors.white),
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
                                  : '继续阅读该漫画 (${_history!.chapterTitle} 第${_history!.chapterPage}页)',
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
                // 排名评价
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
                        title: Text('评分投票'),
                        scrollable: true,
                        content: MangaRatingDetailView(
                          averageScore: _data!.averageScore,
                          scoreCount: _data!.scoreCount,
                          perScores: _data!.perScores,
                        ),
                        actions: [
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
                    firstGroupRowsIfNotFull: AppSetting.instance.other.regularGroupRows,
                    otherGroupsRowsIfNotFull: AppSetting.instance.other.otherGroupRows,
                    gridPadding: EdgeInsets.symmetric(horizontal: 12),
                    highlightedChapters: [_history?.chapterId ?? 0],
                    customBadgeBuilder: (cid) => DownloadBadge.fromEntity(
                      entity: _downloadEntity?.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull,
                    ),
                    onChapterPressed: (cid) => _read(chapterId: cid),
                    onChapterLongPressed: (cid) => _showChapterPopupMenu(chapterId: cid, forMangaPage: true),
                    onMoreChaptersPressed: () => Navigator.of(context).push(
                      CustomPageRoute(
                        context: context,
                        builder: (c) => MangaTocPage(
                          mangaId: _data!.mid,
                          mangaTitle: _data!.title,
                          groups: _data!.chapterGroups,
                          onChapterPressed: (cid) => _read(chapterId: cid),
                          onChapterLongPressed: (cid) => _showChapterPopupMenu(chapterId: cid, forMangaPage: false),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(height: 12),
                // ****************************************************************
                // 评论
                // ****************************************************************
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.fromLTRB(12, 6, 4, 6),
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
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: Text(
                              '发表评论',
                              style: Theme.of(context).textTheme.bodyText1?.copyWith(color: Theme.of(context).primaryColor),
                            ),
                          ),
                          onTap: () => showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: Text('发送评论'),
                              content: Text('是否用浏览器打开漫画页面来发表评论？'),
                              actions: [
                                TextButton(
                                  child: Text('确定'),
                                  onPressed: () {
                                    Navigator.of(c).pop();
                                    launchInBrowser(context: context, url: '${_data!.url}#Comment');
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
                      progressPadding: EdgeInsets.all(25),
                      iconPadding: EdgeInsets.fromLTRB(5, 15, 5, 5),
                      buttonPadding: EdgeInsets.fromLTRB(5, 5, 5, 10),
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
                                  comment: _comments[i],
                                ),
                              ),
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
            ),
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
