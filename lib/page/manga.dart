import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/author.dart';
import 'package:manhuagui_flutter/page/genre.dart';
import 'package:manhuagui_flutter/page/comments.dart';
import 'package:manhuagui_flutter/page/manga_detail.dart';
import 'package:manhuagui_flutter/page/manga_viewer.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/page/view/comment_line.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/natives/browser.dart';

// TODO

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
  VoidCallback? _cancelHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _refreshIndicatorKey.currentState?.show());
    _cancelHandler = EventBusManager.instance.listen<HistoryUpdatedEvent>((_) async {
      try {
        // TODO history
        _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.id);
        if (mounted) setState(() {});
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _cancelHandler?.call();
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  var _loading = true;
  Manga? _data;
  var _error = '';
  MangaHistory? _history;
  var _commentLoading = true;
  final _comments = <Comment>[];
  var _commentError = '';
  var _commentTotal = 0;

  Future<void> _loadData() async {
    _loading = true;
    _commentLoading = true;
    _data = null;
    _comments.clear();
    if (mounted) setState(() {});

    final client = RestClient(DioManager.instance.dio);
    if (AuthManager.instance.logined) {
      client.checkShelfMangas(token: AuthManager.instance.token, mid: widget.id).then((r) {
        _subscribed = r.data.isIn;
        if (mounted) setState(() {});
      }).catchError((_) {});
    }

    client.getMangaComments(mid: widget.id, page: 1).then((r) async {
      _comments.addAll(r.data.data);
      _commentError = '';
      _commentTotal = r.data.total;
    }).catchError((e, s) {
      _comments.clear();
      _commentError = wrapError(e, s).text;
      _commentTotal = 0;
    }).whenComplete(() {
      _commentLoading = false;
      if (mounted) setState(() {});
    });

    try {
      var result = await client.getManga(mid: widget.id);
      _data = null;
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _data = result.data;

      // <<<
      // TODO history
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.id).catchError((_) {}); // 可能已经开始阅读，也可能还没访问
      if (mounted) setState(() {});
      if (_history?.read != true) {
        await HistoryDao.addHistory(
          username: AuthManager.instance.username,
          history: MangaHistory(
            mangaId: _data!.mid,
            mangaTitle: _data!.title,
            mangaCover: _data!.cover,
            mangaUrl: _data!.url,
            chapterId: 0 /* 还没开始阅读 */,
            chapterTitle: '',
            chapterPage: 0,
            lastTime: DateTime.now(),
          ),
        ).catchError((_) {});
      } else {
        await HistoryDao.updateHistory(
          username: AuthManager.instance.username,
          mid: _data!.mid,
          title: _data!.title,
          cover: _data!.cover,
          url: _data!.url,
        );
      }
    } catch (e, s) {
      _data = null;
      _error = wrapError(e, s).text;
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  var _subscribing = false;
  var _subscribed = false;
  var _showBriefIntroduction = true;

  void _subscribe() async {
    if (!AuthManager.instance.logined) {
      Fluttertoast.showToast(msg: '用户未登录');
      return;
    }

    final client = RestClient(DioManager.instance.dio);
    _subscribing = true;
    if (mounted) setState(() {});
    var toSubscribe = _subscribed != true; // 去订阅
    try {
      await (toSubscribe ? client.addToShelf : client.removeFromShelf)(token: AuthManager.instance.token, mid: widget.id);
      _subscribed = toSubscribe;
      Fluttertoast.showToast(msg: toSubscribe ? '订阅成功' : '取消订阅成功');
      if (mounted) setState(() {});
    } catch (e, s) {
      var err = wrapError(e, s).text;
      Fluttertoast.showToast(msg: toSubscribe ? '订阅失败，$err' : '取消订阅失败，$err');
    } finally {
      _subscribing = false;
      if (mounted) setState(() {});
    }
  }

  void _read() async {
    // TODO history
    int cid;
    int page;
    if (_history == null || !_history!.read) {
      // 开始阅读
      if (_data!.chapterGroups.isEmpty) {
        Fluttertoast.showToast(msg: '该漫画还没有章节，无法开始阅读');
        return;
      }
      var sGroup = _data!.chapterGroups.first;
      var specificGroups = _data!.chapterGroups.where((g) => g.title == '单话');
      if (specificGroups.isNotEmpty) {
        sGroup = specificGroups.first;
      }
      if (sGroup.chapters.isEmpty) {
        var specificGroups = _data!.chapterGroups.where((g) => g.chapters.isNotEmpty);
        if (specificGroups.isEmpty) {
          Fluttertoast.showToast(msg: '该漫画还没有章节，无法开始阅读');
          return;
        }
        sGroup = specificGroups.first;
      }
      cid = sGroup.chapters.last.cid;
      page = 1;
    } else {
      // 继续阅读
      cid = _history!.chapterId;
      page = _history!.chapterPage;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (c) => MangaViewerPage(
          mid: _data!.mid,
          mangaTitle: _data!.title,
          mangaCover: _data!.cover,
          mangaUrl: _data!.url,
          cid: cid,
          initialPage: page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_data?.title ?? widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_browser),
            tooltip: '用浏览器打开',
            onPressed: () => launchInBrowser(
              context: context,
              url: _data?.url ?? widget.url,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () => _loadData(),
        child: PlaceholderText.from(
          isLoading: _loading,
          errorText: _error,
          isEmpty: _data == null,
          setting: PlaceholderSetting().copyWithChinese(),
          onRefresh: () => _loadData(),
          childBuilder: (c) => ScrollbarWithMore(
            controller: _controller,
            interactive: true,
            crossAxisMargin: 2,
            child: ListView(
              controller: _controller,
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
                        child: NetworkImageView(
                          url: _data!.cover,
                          height: 160,
                          width: 120,
                        ),
                      ),
                      // ****************************************************************
                      // 信息
                      // ****************************************************************
                      Container(
                        width: MediaQuery.of(context).size.width - 14 * 3 - 120, // | ▢ ▢▢ |
                        padding: EdgeInsets.only(top: 10, bottom: 10, right: 14),
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconText(
                              icon: Icon(Icons.date_range, size: 20, color: Colors.orange),
                              text: Text('${_data!.publishYear} ${_data!.mangaZone}'),
                              space: 8,
                            ),
                            IconText(
                              icon: Icon(Icons.bookmark, size: 20, color: Colors.orange),
                              text: TextGroup.normal(
                                texts: [
                                  for (var i = 0; i < _data!.genres.length; i++) ...[
                                    LinkTextItem(
                                      text: _data!.genres[i].title,
                                      pressedColor: Theme.of(context).primaryColor,
                                      showUnderline: true,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
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
                            ),
                            IconText(
                              icon: Icon(Icons.person, size: 20, color: Colors.orange),
                              text: TextGroup.normal(
                                texts: [
                                  for (var i = 0; i < _data!.authors.length; i++) ...[
                                    LinkTextItem(
                                      text: _data!.authors[i].name,
                                      pressedColor: Theme.of(context).primaryColor,
                                      showUnderline: true,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
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
                            ),
                            IconText(
                              icon: Icon(Icons.trending_up, size: 20, color: Colors.orange),
                              text: Text('排名 ${_data!.mangaRank}'),
                              space: 8,
                            ),
                            IconText(
                              icon: Icon(Icons.subject, size: 20, color: Colors.orange),
                              text: Flexible(
                                child: Text(
                                  (_data!.finished ? '共 ' : '更新至 ') + _data!.newestChapter,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              space: 8,
                            ),
                            IconText(
                              icon: Icon(Icons.access_time, size: 20, color: Colors.orange),
                              text: Text(_data!.newestDate + (_data!.finished ? ' 已完结' : ' 连载中')),
                              space: 8,
                            ),
                            SizedBox(height: 4),
                            // ****************************************************************
                            // 两个按钮
                            // ****************************************************************
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 28,
                                  width: 84,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                                    child: Text(
                                      _subscribed == true ? '取消订阅' : '订阅漫画',
                                      style: TextStyle(color: _subscribing ? Colors.grey : Colors.black),
                                    ),
                                    onPressed: _subscribing == true ? null : () => _subscribe(),
                                  ),
                                ),
                                SizedBox(width: 6),
                                Container(
                                  height: 28,
                                  width: 84,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                                    child: Text(
                                      _history?.read == true ? '继续阅读' : '开始阅读', // TODO history
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    onPressed: () => _read(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                // 排名
                // ****************************************************************
                Container(
                  color: Colors.white,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (c) => MangaDetailPage(data: _data!),
                        ),
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  RatingBar.builder(
                                    direction: Axis.horizontal,
                                    allowHalfRating: true,
                                    itemCount: 5,
                                    itemPadding: EdgeInsets.symmetric(horizontal: 4),
                                    itemBuilder: (c, i) => Icon(Icons.star, color: Colors.amber),
                                    initialRating: _data!.averageScore / 2.0,
                                    minRating: 0,
                                    itemSize: 32,
                                    ignoreGestures: true,
                                    onRatingUpdate: (_) {},
                                  ),
                                  SizedBox(height: 4),
                                  Text('平均分数: ${_data!.averageScore} / 10.0，共 ${_data!.scoreCount} 人评价'),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Text(
                                '查看漫画详情',
                                style: TextStyle(color: Theme.of(context).primaryColor),
                              ),
                            ),
                          ],
                        ),
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
                    highlightedChapter: _history?.chapterId ?? 0,
                    mangaId: _data!.mid,
                    mangaTitle: _data!.title,
                    mangaCover: _data!.cover,
                    mangaUrl: _data!.url,
                  ), // TODO history
                ),
                Container(height: 12),
                // ****************************************************************
                // 评论
                // ****************************************************************
                PlaceholderText(
                  state: _commentLoading
                      ? PlaceholderState.loading
                      : _commentError.isNotEmpty
                          ? PlaceholderState.error
                          : _comments.isEmpty
                              ? PlaceholderState.nothing
                              : PlaceholderState.normal,
                  errorText: _commentError,
                  setting: PlaceholderSetting(
                    loadingText: '评论加载中...',
                    nothingText: '暂无评论',
                  ),
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
                            MaterialPageRoute(
                              builder: (c) => CommentsPage(
                                mid: widget.id,
                                title: _data!.title,
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
                      )
                    ],
                  ),
                ),
                Container(height: 12),
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
