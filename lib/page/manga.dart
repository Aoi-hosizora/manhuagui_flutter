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
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
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
  final _actionScrollKey = GlobalKey<State<StatefulWidget>>();
  final _controller = ScrollController();

  final _fabController = AnimatedFabController();
  final _physicsController = CustomScrollPhysicsController();
  final _cancelHandlers = <VoidCallback>[];
  AuthData? _oldAuthData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _refreshIndicatorKey.currentState?.show());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandlers.add(AuthManager.instance.listen(() => _oldAuthData, (_) async {
        _oldAuthData = AuthManager.instance.authData;
        _history = null;
        _refreshIndicatorKey.currentState?.show();
      }));
      await AuthManager.instance.check();
    });
    _cancelHandlers.add(EventBusManager.instance.listen<AppSettingChangedEvent>((_) => mountedSetState(() {})));
    _cancelHandlers.add(EventBusManager.instance.listen<HistoryUpdatedEvent>((_) => _loadHistory()));
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadedMangaEntityChangedEvent>((_) => _loadDownload()));
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadMangaProgressChangedEvent>((_) => _loadDownload()));
    _cancelHandlers.add(EventBusManager.instance.listen<SubscribeUpdatedEvent>((e) {
      if (e.mangaId == widget.id) {
        _inShelf = e.inShelf ?? _inShelf;
        _inFavorite = e.inFavorite ?? _inFavorite;
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

  var _loading = true;
  Manga? _data;
  var _error = '';
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

    final client = RestClient(DioManager.instance.dio);

    // 1. 异步加载漫画评论首页
    _getComments();

    // 2. 异步获取漫画订阅信息
    if (AuthManager.instance.logined) {
      Future.microtask(() async {
        try {
          var r = await client.checkShelfManga(token: AuthManager.instance.token, mid: widget.id);
          _inShelf = r.data.isIn;
          _subscribeCount = r.data.count;

          // 更新订阅缓存信息
          if (_data != null) {
            if (_inShelf) {
              var cache = ShelfCache(mangaId: widget.id, mangaTitle: _data!.title, mangaCover: _data!.cover, mangaUrl: _data!.url, cachedAt: DateTime.now());
              await ShelfCacheDao.addOrUpdateShelfCache(username: AuthManager.instance.username, cache: cache);
              EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: widget.id, inShelf: true));
            } else {
              await ShelfCacheDao.deleteShelfCache(username: AuthManager.instance.username, mangaId: widget.id);
              EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: widget.id, inShelf: false));
            }
          }
          if (mounted) setState(() {});
        } catch (e, s) {
          var we = wrapError(e, s);
          globalLogger.e('MangaPage._loadData checkShelfManga', e, s);
          Fluttertoast.showToast(msg: we.text);
        }
      });
    }
    Future.microtask(() async {
      _favoriteManga = await FavoriteDao.getFavorite(username: AuthManager.instance.username, mid: widget.id);
      _inFavorite = _favoriteManga != null;
      if (mounted) setState(() {});
    });

    // 3. 异步获取下载信息
    _loadDownload();

    try {
      // 4. 获取漫画信息
      var result = await client.getManga(mid: widget.id);
      _data = null;
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(kFlashListDuration);
      _data = result.data; // TODO 数据可能有异常，会导致历史数据更新有误

      // 5. 更新漫画阅读历史和订阅缓存信息
      await _loadHistory();
      var newHistory = _history?.copyWith(
            mangaId: _data!.mid,
            mangaTitle: _data!.title,
            mangaCover: _data!.cover,
            mangaUrl: _data!.url,
            lastTime: _history?.read == true ? _history!.lastTime : DateTime.now(), // 只有未阅读过才修改时间
          ) ??
          MangaHistory(
            mangaId: _data!.mid,
            mangaTitle: _data!.title,
            mangaCover: _data!.cover,
            mangaUrl: _data!.url,
            chapterId: 0 /* 未开始阅读 */,
            chapterTitle: '',
            chapterPage: 1,
            lastTime: DateTime.now(),
          );
      if (_history == null || !newHistory.equals(_history!)) {
        _history = newHistory;
        await HistoryDao.addOrUpdateHistory(username: AuthManager.instance.username, history: _history!);
        EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: _data!.mid));
      }
      if (_subscribeCount != null) {
        if (_inShelf) {
          var cache = ShelfCache(mangaId: widget.id, mangaTitle: _data!.title, mangaCover: _data!.cover, mangaUrl: _data!.url, cachedAt: DateTime.now());
          await ShelfCacheDao.addOrUpdateShelfCache(username: AuthManager.instance.username, cache: cache);
          EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: widget.id, inShelf: true));
        } else {
          await ShelfCacheDao.deleteShelfCache(username: AuthManager.instance.username, mangaId: widget.id);
          EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: widget.id, inShelf: false));
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

  Future<void> _loadHistory() async {
    _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.id);
    if (mounted) setState(() {});
  }

  Future<void> _loadDownload() async {
    _downloadEntity = await DownloadDao.getManga(mid: widget.id);
    if (mounted) setState(() {});
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
      nowInShelf: _inShelf,
      nowInFavorite: _inFavorite,
      subscribeCount: _subscribeCount,
      favoriteManga: _favoriteManga,
      subscribing: (s) => mountedSetState(() => _subscribing = s),
      inShelfSetter: (s) => mountedSetState(() => _inShelf = s),
      inFavoriteSetter: (f) => mountedSetState(() => _inFavorite = f),
      favoriteSetter: (f) => mountedSetState(() => _favoriteManga = f),
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
      cid = group.chapters.last.cid;
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

  void _longPressDownloadAction() {
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
          TextButton(child: Text('确定'), onPressed: () => Navigator.of(c).pop()),
        ],
      ),
    );
  }

  void _longPressHistoryAction() {
    String text;
    if (_history == null) {
      text = '尚未开始阅读该漫画，且当前浏览记录不会被保留。';
    } else if (!_history!.read) {
      text = '尚未开始阅读该漫画。';
    } else {
      text = '最近阅读至 ${_history!.chapterTitle} 第${_history!.chapterPage}页 (${_history!.fullFormattedLastTime})。';
    }

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('漫画阅读历史'),
        content: Text(text),
        actions: [
          if (_history == null)
            TextButton(
              child: Text('保留该历史'),
              onPressed: () async {
                Navigator.of(context).pop();
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
                if (mounted) setState(() {});
                EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: _data!.mid));
              },
            ),
          if (_history != null)
            TextButton(
              child: Text('删除该历史'),
              onPressed: () async {
                Navigator.of(context).pop();
                await HistoryDao.deleteHistory(username: AuthManager.instance.username, mid: _data!.mid);
                _history = null;
                if (mounted) setState(() {});
                EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: _data!.mid));
              },
            ),
          TextButton(child: Text('确定'), onPressed: () => Navigator.of(c).pop()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DrawerScaffold(
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
      drawerEdgeDragWidth: null,
      physicsController: _physicsController,
      implicitlyOverscrollableScaffold: true,
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
                              iconPadding: EdgeInsets.symmetric(vertical: 3.2),
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
                              iconPadding: EdgeInsets.symmetric(vertical: 3.2),
                            ),
                            IconText(
                              icon: Icon(Icons.date_range, size: 20, color: Colors.orange),
                              text: Text('发布于 ${_data!.publishYear} ${_data!.mangaZone.replaceAll('漫画', '')}'),
                              space: 8,
                              iconPadding: EdgeInsets.symmetric(vertical: 3.2),
                            ),
                            IconText(
                              icon: Icon(Icons.stars, size: 20, color: Colors.orange),
                              text: Text('排名 ${_data!.mangaRank} / 订阅 ${_subscribeCount ?? '未知'}'),
                              space: 8,
                              iconPadding: EdgeInsets.symmetric(vertical: 3.2),
                            ),
                            IconText(
                              icon: Icon(Icons.subject, size: 20, color: Colors.orange),
                              text: Flexible(
                                child: Text(
                                  '最新章节：${_data!.newestChapter}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              space: 8,
                              iconPadding: EdgeInsets.symmetric(vertical: 3.2),
                            ),
                            IconText(
                              icon: Icon(Icons.update, size: 20, color: Colors.orange),
                              text: Text(_data!.newestDate + (_data!.finished ? ' 已完结' : ' 连载中')),
                              space: 8,
                              iconPadding: EdgeInsets.symmetric(vertical: 3.2),
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
                  child: ActionRowView.scroll(
                    key: _actionScrollKey,
                    physics: CustomScrollPhysics(controller: _physicsController),
                    actions: [
                      ActionItem(
                        text: !_inShelf && !_inFavorite
                            ? '订阅漫画'
                            : _inShelf && !_inFavorite
                                ? '已放书架'
                                : !_inShelf && _inFavorite
                                    ? '已加收藏'
                                    : '取消订阅',
                        icon: !_inShelf && !_inFavorite ? Icons.sell : Icons.loyalty,
                        action: _subscribing ? null : () => _subscribe(),
                        enable: !_subscribing,
                      ),
                      ActionItem(
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
                        longPress: _longPressDownloadAction,
                      ),
                      ActionItem(
                        text: _history == null || !_history!.read ? '开始阅读' : '继续阅读',
                        icon: _history == null ? CustomIcons.opened_empty_star_book : (!_history!.read ? CustomIcons.opened_empty_book : Icons.import_contacts),
                        action: () => _read(chapterId: null),
                        longPress: _longPressHistoryAction,
                      ),
                      ActionItem(
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
                      ActionItem(
                        text: '漫画详情',
                        icon: Icons.subject,
                        action: () => Navigator.of(context).push(
                          CustomPageRoute(
                            context: context,
                            builder: (c) => MangaDetailPage(data: _data!),
                          ),
                        ),
                      ),
                      ActionItem(
                        text: '分享漫画',
                        icon: Icons.share,
                        action: () => shareText(
                          title: '漫画柜分享',
                          text: '【${_data!.title}】${_data!.url}',
                        ),
                      ),
                      ActionItem(
                        text: '外部浏览',
                        icon: Icons.open_in_browser,
                        action: () => launchInBrowser(
                          context: context,
                          url: _data!.url,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 12),
                // ****************************************************************
                // 介绍
                // ****************************************************************
                Container(
                  color: Colors.white,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _showBriefIntroduction = !_showBriefIntroduction;
                        if (mounted) setState(() {});
                      },
                      onLongPress: () {
                        copyText(_showBriefIntroduction ? _data!.briefIntroduction : _data!.introduction, showToast: false);
                        Fluttertoast.showToast(msg: (_showBriefIntroduction ? '漫画简要介绍' : '漫画详细介绍') + '已经复制到剪贴板');
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: TextGroup.normal(
                          style: TextStyle(color: Colors.black),
                          texts: [
                            if (_showBriefIntroduction) ...[
                              PlainTextItem(text: _data!.briefIntroduction), // TODO fontSize, lineHeight
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
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    // TODO 长按弹出菜单，阅读 / 下载 / 删除历史, 添加 prefix icon
                    full: false,
                    firstGroupRowsIfNotFull: AppSetting.instance.other.regularGroupRows,
                    otherGroupsRowsIfNotFull: AppSetting.instance.other.otherGroupRows,
                    gridPadding: EdgeInsets.symmetric(horizontal: 12),
                    highlightedChapters: [_history?.chapterId ?? 0],
                    customBadgeBuilder: (cid) => DownloadBadge.fromEntity(
                      entity: _downloadEntity?.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull,
                    ),
                    onChapterPressed: (cid) => _read(chapterId: cid),
                    onMoreChaptersPressed: () => Navigator.of(context).push(
                      CustomPageRoute(
                        context: context,
                        builder: (c) => MangaTocPage(
                          mangaId: _data!.mid,
                          mangaTitle: _data!.title,
                          groups: _data!.chapterGroups,
                          onChapterPressed: (cid) => _read(chapterId: cid),
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
                        '评论区 (共 $_commentTotal 条)', // TODO 添加 prefix icon
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
