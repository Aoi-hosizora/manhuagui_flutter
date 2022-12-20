import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/author.dart';
import 'package:manhuagui_flutter/page/download_choose.dart';
import 'package:manhuagui_flutter/page/genre.dart';
import 'package:manhuagui_flutter/page/comments.dart';
import 'package:manhuagui_flutter/page/image_viewer.dart';
import 'package:manhuagui_flutter/page/manga_detail.dart';
import 'package:manhuagui_flutter/page/manga_toc.dart';
import 'package:manhuagui_flutter/page/manga_viewer.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/manga_rating.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/page/view/comment_line.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/service/native/share.dart';

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
    _cancelHandlers.add(EventBusManager.instance.listen<HistoryUpdatedEvent>((_) => _loadHistory()));
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadedMangaEntityChangedEvent>((_) => _loadDownload()));
    _cancelHandlers.add(EventBusManager.instance.listen<SubscribeUpdatedEvent>((e) {
      if (e.mangaId == widget.id) {
        _subscribed = e.subscribe;
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
  var _subscribing = false;
  var _subscribed = false;
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
          _subscribed = r.data.isIn;
          _subscribeCount = r.data.count;
          if (mounted) setState(() {});
        } catch (e, s) {
          var we = wrapError(e, s);
          globalLogger.e('MangaPage._loadData checkShelfManga', e, s);
          Fluttertoast.showToast(msg: we.text);
        }
      });
    }

    // 3. 异步获取下载信息
    _loadDownload();

    try {
      // 4. 获取漫画信息
      var result = await client.getManga(mid: widget.id);
      _data = null;
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(kFlashListDuration);
      _data = result.data;

      // 5. 更新漫画阅读历史
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
        EventBusManager.instance.fire(HistoryUpdatedEvent());
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

  Future<void> _subscribe() async {
    if (!AuthManager.instance.logined) {
      Fluttertoast.showToast(msg: '用户未登录');
      return;
    }
    var toSubscribe = _subscribed != true; // 去订阅
    if (!toSubscribe) {
      var ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('取消订阅确认'),
          content: Text('是否取消订阅《${_data!.title}》？'),
          actions: [
            TextButton(child: Text('确定'), onPressed: () => Navigator.of(c).pop(true)),
            TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
          ],
        ),
      );
      if (ok != true) {
        return;
      }
    }

    final client = RestClient(DioManager.instance.dio);
    _subscribing = true;
    if (mounted) setState(() {});
    try {
      await (toSubscribe ? client.addToShelf : client.removeFromShelf)(token: AuthManager.instance.token, mid: _data!.mid);
      _subscribed = toSubscribe;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toSubscribe ? '订阅漫画成功' : '取消订阅漫画成功')));
      EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: _data!.mid, subscribe: _subscribed));
    } catch (e, s) {
      var err = wrapError(e, s).text;
      var already = err.contains('已经被'), notYet = err.contains('还没有被');
      if (already || notYet) {
        _subscribed = already;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err))); // 漫画已经被订阅 / 漫画还没有被订阅
        EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: _data!.mid, subscribe: _subscribed));
      } else {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toSubscribe ? '订阅漫画失败，$err' : '取消订阅漫画失败，$err')));
      }
    } finally {
      _subscribing = false;
      if (mounted) setState(() {});
    }
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
                              iconPadding: EdgeInsets.symmetric(vertical: 2.8),
                            ),
                            IconText(
                              icon: Icon(Icons.bookmark, size: 20, color: Colors.orange),
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
                              iconPadding: EdgeInsets.symmetric(vertical: 2.8),
                            ),
                            IconText(
                              icon: Icon(Icons.date_range, size: 20, color: Colors.orange),
                              text: Text('发布于 ${_data!.publishYear} / ${_data!.mangaZone.replaceAll('漫画', '')}'),
                              space: 8,
                              iconPadding: EdgeInsets.symmetric(vertical: 2.8),
                            ),
                            IconText(
                              icon: Icon(Icons.trending_up, size: 20, color: Colors.orange),
                              text: Text('排名 ${_data!.mangaRank} / 订阅数量 ${_subscribeCount ?? '未知'}'),
                              space: 8,
                              iconPadding: EdgeInsets.symmetric(vertical: 2.8),
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
                              iconPadding: EdgeInsets.symmetric(vertical: 2.8),
                            ),
                            IconText(
                              icon: Icon(Icons.access_time, size: 20, color: Colors.orange),
                              text: Text(_data!.newestDate + (_data!.finished ? ' 已完结' : ' 连载中')),
                              space: 8,
                              iconPadding: EdgeInsets.symmetric(vertical: 2.8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ****************************************************************
                // 五个按钮
                // ****************************************************************
                Container(
                  color: Colors.white,
                  child: ActionRowView.five(
                    action1: ActionItem(
                      text: _subscribed == true ? '取消订阅' : '订阅漫画',
                      icon: _subscribed == true ? Icons.star : Icons.star_border,
                      action: _subscribing ? null : () => _subscribe(),
                      enable: !_subscribing,
                    ),
                    action2: ActionItem(
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
                      longPress: () {
                        if (_downloadEntity == null || _downloadEntity!.triedChapterIds.isEmpty) {
                          Fluttertoast.showToast(msg: '未下载任何章节');
                        } else if (_downloadEntity!.successChapterIds.length == _downloadEntity!.totalChapterIds.length) {
                          Fluttertoast.showToast(msg: '已成功下载 ${_downloadEntity!.totalChapterIds.length} 章节');
                        } else {
                          Fluttertoast.showToast(msg: '未完成下载，已开始下载 ${_downloadEntity!.triedChapterIds.length}/${_downloadEntity!.totalChapterIds.length} 章节');
                        }
                      },
                    ),
                    action3: ActionItem(
                      text: _history?.read == true ? '继续阅读' : '开始阅读',
                      icon: Icons.import_contacts,
                      action: () => _read(chapterId: null),
                      longPress: () {
                        if (_history == null || !_history!.read) {
                          Fluttertoast.showToast(msg: '未开始阅读该漫画');
                        } else if (_history != null) {
                          Fluttertoast.showToast(msg: '上次阅读到 ${_history!.chapterTitle} 第${_history!.chapterPage}页');
                        }
                      },
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
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: TextGroup.normal(
                          style: TextStyle(color: Colors.black),
                          texts: [
                            if (_showBriefIntroduction) ...[
                              PlainTextItem(text: _data!.briefIntroduction),
                              PlainTextItem(
                                text: ' 展开详情',
                                style: TextStyle(color: Theme.of(context).primaryColor),
                              ),
                            ],
                            if (!_showBriefIntroduction) ...[
                              PlainTextItem(text: _data!.introduction),
                              PlainTextItem(
                                text: ' 收起介绍',
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
                    full: false,
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
                PlaceholderText.from(
                  isEmpty: _comments.isEmpty,
                  isLoading: _commentLoading,
                  errorText: _commentError.isEmpty ? '' : '加载漫画评论失败\n$_commentError',
                  displayRule: PlaceholderDisplayRule.errorFirst,
                  setting: PlaceholderSetting().copyWithChinese(
                    loadingText: '评论加载中...',
                    nothingText: '暂无评论',
                  ),
                  onRefresh: () => _getComments(),
                  childBuilder: (_) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '评论区',
                              style: Theme.of(context).textTheme.subtitle1,
                            ),
                            Text(
                              '共 $_commentTotal 条',
                              style: Theme.of(context).textTheme.subtitle1,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        color: Colors.white,
                        child: Divider(height: 0, thickness: 1),
                      ),
                      for (var comment in _comments.sublist(0, _comments.length - 1)) ...[
                        CommentLineView(
                          comment: comment,
                          style: CommentLineViewStyle.normal,
                        ),
                        Container(
                          color: Colors.white,
                          child: Divider(height: 0, thickness: 1, indent: 2.0 * 12 + 32),
                        ),
                      ],
                      CommentLineView(
                        comment: _comments.last,
                        style: CommentLineViewStyle.normal,
                      ),
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
