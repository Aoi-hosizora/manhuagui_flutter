import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/author.dart';
import 'package:manhuagui_flutter/page/chapter.dart';
import 'package:manhuagui_flutter/page/genre.dart';
import 'package:manhuagui_flutter/page/manga_comment.dart';
import 'package:manhuagui_flutter/page/manga_detail.dart';
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

/// 漫画页
/// Page for [Manga].
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
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.id).catchError((_) {});
      if (mounted) setState(() {});
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
  var _subscribing = false;
  var _subscribed = false;
  MangaHistory? _history;
  var _showBriefIntroduction = true;
  var _commentLoading = true;
  var _comments = <Comment>[];
  var _commentError = '';
  var _commentTotal = 0;

  Future<void> _loadData() async {
    _loading = true;
    _commentLoading = true;
    _data = null;
    _comments = [];
    if (mounted) setState(() {});

    final client = RestClient(DioManager.instance.dio);
    if (AuthManager.instance.logined) {
      client.checkShelfMangas(token: AuthManager.instance.token, mid: widget.id).then((r) {
        _subscribed = r.data.isIn;
        if (mounted) setState(() {});
      }).catchError((_) {});
    }

    client.getMangaComments(mid: widget.id, page: 1).then((r) async {
      _comments = r.data.data;
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
        builder: (c) => ChapterPage(
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
            tooltip: '打开浏览器',
            onPressed: () => launchInBrowser(
              context: context,
              url: _data?.url ?? widget.url,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadData,
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
                  height: 180,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          fit: BoxFit.cover,
                        ),
                      ),
                      // ****************************************************************
                      // 信息
                      // ****************************************************************
                      Container(
                        width: MediaQuery.of(context).size.width - 14 * 3 - 120, // | ▢ ▢ |
                        height: 180,
                        padding: EdgeInsets.only(top: 14, bottom: 14, right: 14),
                        child: Column(
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
                                textScaleFactor: MediaQuery.of(context).textScaleFactor,
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
                                textScaleFactor: MediaQuery.of(context).textScaleFactor,
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
                              text: Text((_data!.finished ? '共 ' : '更新至 ') + _data!.newestChapter),
                              space: 8,
                            ),
                            IconText(
                              icon: Icon(Icons.access_time, size: 20, color: Colors.orange),
                              text: Text(_data!.newestDate + (_data!.finished ? ' 已完结' : ' 连载中')),
                              space: 8,
                            ),
                            // SizedBox(height: 4),
                            Spacer(),
                            // ****************************************************************
                            // 两个按钮
                            // ****************************************************************
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 28,
                                  width: 75,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.all(2),
                                    ),
                                    child: Text(
                                      _subscribed == true ? '取消订阅' : '订阅漫画',
                                      style: TextStyle(color: _subscribing ? Colors.grey : Theme.of(context).textTheme.button?.color),
                                    ),
                                    onPressed: _subscribing == true ? null : () => _subscribe(),
                                  ),
                                ),
                                SizedBox(width: 14),
                                Container(
                                  height: 28,
                                  width: 75,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.all(2),
                                    ),
                                    child: Text(_history?.read == true ? '继续阅读' : '开始阅读'),
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
                      onTap: () => mountedSetState(() => _showBriefIntroduction = !_showBriefIntroduction),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: RichText(
                          textScaleFactor: MediaQuery.of(context).textScaleFactor,
                          text: TextSpan(
                            text: '',
                            style: TextStyle(color: Colors.black),
                            children: [
                              if (_showBriefIntroduction) ...[
                                TextSpan(text: _data!.briefIntroduction),
                                TextSpan(
                                  text: ' 展开详情',
                                  style: TextStyle(color: Theme.of(context).primaryColor),
                                ),
                              ],
                              if (!_showBriefIntroduction) ...[
                                TextSpan(text: _data!.introduction),
                                TextSpan(
                                  text: ' 收起介绍',
                                  style: TextStyle(color: Theme.of(context).primaryColor),
                                ),
                              ],
                              TextSpan(text: ' '),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white,
                  child: Divider(height: 1, thickness: 1),
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
                                '查看详情',
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
                  ),
                ),
                Container(height: 12),
                // ****************************************************************
                // 评论
                // ****************************************************************
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: PlaceholderText(
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
                          child: Divider(height: 1, thickness: 1),
                        ),
                        for (var comment in _comments.sublist(0, _comments.length - 1)) ...[
                          CommentLineView(comment: comment),
                          Container(
                            margin: EdgeInsets.only(left: 2.0 * 12 + 32),
                            width: MediaQuery.of(context).size.width - 3 * 12 - 32,
                            color: Colors.white,
                            child: Divider(height: 1, thickness: 1),
                          ),
                        ],
                        CommentLineView(comment: _comments.last),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          color: Colors.white,
                          child: Divider(height: 1, thickness: 1),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (c) => MangaCommentPage(mid: widget.id),
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
