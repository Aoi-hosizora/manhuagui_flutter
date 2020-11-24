import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga_toc.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/service/natives/browser.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';

/// 漫画页
/// Page for [Manga].
class MangaPage extends StatefulWidget {
  const MangaPage({
    Key key,
    @required this.id,
    @required this.title,
    @required this.url,
  })  : assert(id != null),
        assert(title != null),
        assert(url != null),
        super(key: key);

  final int id;
  final String title;
  final String url;

  @override
  _MangaPageState createState() => _MangaPageState();
}

class _MangaPageState extends State<MangaPage> {
  GlobalKey<RefreshIndicatorState> _indicatorKey;
  var _loading = true;
  Manga _data;
  var _error = '';
  var _showBriefIntroduction = true;
  var _invertedOrder = true;

  @override
  void initState() {
    super.initState();
    _indicatorKey = GlobalKey<RefreshIndicatorState>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _indicatorKey?.currentState?.show());
  }

  Future<void> _loadData() {
    _loading = true;
    if (mounted) setState(() {});

    var dio = DioManager.getInstance().dio;
    var client = RestClient(dio);
    return client.getManga(mid: widget.id).then((r) async {
      _error = '';
      _data = null;
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _data = r.data;
    }).catchError((e) {
      _data = null;
      _error = wrapError(e).text;
    }).whenComplete(() {
      _loading = false;
      if (mounted) setState(() {});
    });
  }

  Widget _buildChapterListView() {
    var chaptersHPadding = 12.0;
    var chaptersVPadding = 10.0;
    var chapterPadding = 4.0;
    var chapterWidth = (MediaQuery.of(context).size.width - 2 * chaptersHPadding - 6 * chapterPadding) / 4;

    void gotoToc() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (c) => MangaTocPage(
            title: _data.title,
            groups: _data.chapterGroups,
          ),
        ),
      );
    }

    var groupViews = <Widget>[];
    for (var idx = 0; idx < _data.chapterGroups.length; idx++) {
      var group = _data.chapterGroups[idx];
      var inGroupView = <Widget>[];
      if (idx == 0) {
        inGroupView = [
          Row(
            children: [
              Container(child: OutlineButton(child: Text('X话'), onPressed: () {}), height: 36, width: chapterWidth, margin: EdgeInsets.only(right: chapterPadding)),
              Container(child: OutlineButton(child: Text('X话'), onPressed: () {}), height: 36, width: chapterWidth, margin: EdgeInsets.symmetric(horizontal: chapterPadding)),
              Container(child: OutlineButton(child: Text('X话'), onPressed: () {}), height: 36, width: chapterWidth, margin: EdgeInsets.symmetric(horizontal: chapterPadding)),
              Container(child: OutlineButton(child: Text('X话'), onPressed: () {}), height: 36, width: chapterWidth, margin: EdgeInsets.only(left: chapterPadding)),
            ],
          ),
          SizedBox(height: chapterPadding * 2),
          Row(
            children: [
              Container(child: OutlineButton(child: Text('X话'), onPressed: () {}), height: 36, width: chapterWidth, margin: EdgeInsets.only(right: chapterPadding)),
              Container(child: OutlineButton(child: Text('X话'), onPressed: () {}), height: 36, width: chapterWidth, margin: EdgeInsets.symmetric(horizontal: chapterPadding)),
              Container(child: OutlineButton(child: Text('X话'), onPressed: () {}), height: 36, width: chapterWidth, margin: EdgeInsets.symmetric(horizontal: chapterPadding)),
              Container(child: OutlineButton(child: Text('X话'), onPressed: () {}), height: 36, width: chapterWidth, margin: EdgeInsets.only(left: chapterPadding)),
            ],
          ),
          SizedBox(height: chapterPadding * 2),
          Row(
            children: [
              Container(child: OutlineButton(child: Text('X话'), onPressed: () {}), height: 36, width: chapterWidth, margin: EdgeInsets.only(right: chapterPadding)),
              Container(child: OutlineButton(child: Text('X话'), onPressed: () {}), height: 36, width: chapterWidth, margin: EdgeInsets.symmetric(horizontal: chapterPadding)),
              Container(child: OutlineButton(child: Text('X话'), onPressed: () {}), height: 36, width: chapterWidth, margin: EdgeInsets.symmetric(horizontal: chapterPadding)),
              Container(child: OutlineButton(child: Text('...'), onPressed: gotoToc), height: 36, width: chapterWidth, margin: EdgeInsets.only(left: chapterPadding)),
            ],
          ),
        ];
      } else {
        inGroupView = [
          Row(
            children: [
              Container(child: OutlineButton(child: Text('X话'), onPressed: () {}), height: 36, width: chapterWidth, margin: EdgeInsets.only(right: chapterPadding)),
              Container(child: OutlineButton(child: Text('X话'), onPressed: () {}), height: 36, width: chapterWidth, margin: EdgeInsets.symmetric(horizontal: chapterPadding)),
              Container(child: OutlineButton(child: Text('X话'), onPressed: () {}), height: 36, width: chapterWidth, margin: EdgeInsets.symmetric(horizontal: chapterPadding)),
              Container(child: OutlineButton(child: Text('...'), onPressed: gotoToc), height: 36, width: chapterWidth, margin: EdgeInsets.only(left: chapterPadding)),
            ],
          ),
        ];
      }
      groupViews.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: chaptersVPadding / 2),
          child: Column(
            children: [
              Text(
                '・${group.title}・',
                style: Theme.of(context).textTheme.subtitle1,
              ),
              SizedBox(height: chaptersVPadding),
              // ****************************************************************
              // 每一组章节
              // ****************************************************************
              ...inGroupView,
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: chaptersHPadding, vertical: chaptersVPadding / 2),
      child: Column(
        // ****************************************************************
        // 所有章节
        // ****************************************************************
        children: groupViews,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_browser),
            tooltip: '打开浏览器',
            onPressed: () => launchInBrowser(
              context: context,
              url: widget.url,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _indicatorKey,
        onRefresh: _loadData,
        child: PlaceholderText.from(
          isLoading: _loading,
          errorText: _error,
          isEmpty: _data == null,
          setting: PlaceholderSetting(
            showProgress: true,
            loadingText: '加载中',
            retryText: '重试',
          ),
          onRefresh: () => _loadData(),
          childBuilder: (c) => Scrollbar(
            child: ListView(
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
                      stops: [0, 0.5, 1],
                      colors: [
                        Colors.blue[100],
                        Colors.orange[100],
                        Colors.purple[100],
                      ],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ****************************************************************
                      // 封面
                      // ****************************************************************
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: NetworkImageView(
                          url: _data.cover,
                          height: 160,
                          width: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // ****************************************************************
                      // 信息
                      // ****************************************************************
                      Container(
                        width: MediaQuery.of(context).size.width - 14 * 3 - 120,
                        height: 180.0 - 14 * 2,
                        margin: EdgeInsets.only(top: 14, bottom: 14, right: 14),
                        child: Wrap(
                          direction: Axis.vertical,
                          children: [
                            IconText(
                              icon: Icon(Icons.date_range, size: 20, color: Colors.orange),
                              text: Text('${_data.publishYear} ${_data.mangaZone}'),
                              space: 8,
                            ),
                            IconText(
                              icon: Icon(Icons.bookmark, size: 20, color: Colors.orange),
                              text: Text('${_data.genres.map((e) => e.title).join(' ')}'),
                              space: 8,
                            ),
                            IconText(
                              icon: Icon(Icons.person, size: 20, color: Colors.orange),
                              text: Text('${_data.authors.map((e) => e.name).join(' ')}'),
                              space: 8,
                            ),
                            IconText(
                              icon: Icon(Icons.trending_up, size: 20, color: Colors.orange),
                              text: Text('排名 ${_data.mangaRank}'),
                              space: 8,
                            ),
                            IconText(
                              icon: Icon(Icons.library_books, size: 20, color: Colors.orange),
                              text: Text('更新至 ${_data.newestChapter}'),
                              space: 8,
                            ),
                            IconText(
                              icon: Icon(Icons.access_time, size: 20, color: Colors.orange),
                              text: Text('${_data.newestDate} ${_data.finished ? '已完结' : '连载中'}'),
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
                                  width: 75,
                                  child: OutlineButton(
                                    padding: EdgeInsets.all(2),
                                    child: Text('订阅漫画'), // 取消订阅
                                    onPressed: () => Fluttertoast.showToast(msg: 'TODO'),
                                  ),
                                ),
                                SizedBox(width: 14),
                                Container(
                                  height: 28,
                                  width: 75,
                                  child: OutlineButton(
                                    padding: EdgeInsets.all(2),
                                    child: Text('开始阅读'), // 继续阅读
                                    onPressed: () => Fluttertoast.showToast(msg: 'TODO'),
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
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Colors.white,
                  child: RichText(
                    text: _showBriefIntroduction
                        ? TextSpan(
                            text: _data.briefIntroduction,
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: ' 展开详情',
                                style: TextStyle(color: Theme.of(context).primaryColor),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    _showBriefIntroduction = false;
                                    if (mounted) setState(() {});
                                  },
                              ),
                            ],
                          )
                        : TextSpan(
                            text: _data.introduction,
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: ' 收起介绍',
                                style: TextStyle(color: Theme.of(context).primaryColor),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    _showBriefIntroduction = true;
                                    if (mounted) setState(() {});
                                  },
                              ),
                            ],
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
                      onTap: () => Fluttertoast.showToast(msg: 'TODO'),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          children: [
                            RatingBar.builder(
                              direction: Axis.horizontal,
                              allowHalfRating: true,
                              itemCount: 5,
                              itemPadding: EdgeInsets.symmetric(horizontal: 4),
                              itemBuilder: (c, i) => Icon(Icons.star, color: Colors.amber),
                              initialRating: _data.averageScore / 2.0,
                              minRating: 0,
                              itemSize: 32,
                              ignoreGestures: true,
                              onRatingUpdate: (_) {},
                            ),
                            SizedBox(height: 6),
                            Text('平均分数: ${_data.averageScore} / 10.0，共 ${_data.scoreCount} 人评价'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(height: 12),
                // ****************************************************************
                // 章节列表头
                // ****************************************************************
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.only(left: 12, top: 2, bottom: 2, right: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '章节列表',
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _invertedOrder = false;
                                if (mounted) setState(() {});
                              },
                              child: Padding(
                                padding: EdgeInsets.only(top: 6, bottom: 6, left: 5, right: 10),
                                child: IconText(
                                  icon: Icon(
                                    Icons.keyboard_arrow_up,
                                    size: 18,
                                    color: !_invertedOrder ? Theme.of(context).primaryColor : Colors.black,
                                  ),
                                  text: Text(
                                    '正序',
                                    style: TextStyle(
                                      color: !_invertedOrder ? Theme.of(context).primaryColor : Colors.black,
                                    ),
                                  ),
                                  space: 0,
                                ),
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _invertedOrder = true;
                                if (mounted) setState(() {});
                              },
                              child: Padding(
                                padding: EdgeInsets.only(top: 6, bottom: 6, left: 5, right: 10),
                                child: IconText(
                                  icon: Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 18,
                                    color: _invertedOrder ? Theme.of(context).primaryColor : Colors.black,
                                  ),
                                  text: Text(
                                    '倒序',
                                    style: TextStyle(
                                      color: _invertedOrder ? Theme.of(context).primaryColor : Colors.black,
                                    ),
                                  ),
                                  space: 0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white,
                  child: Divider(height: 1, thickness: 1),
                ),
                // ****************************************************************
                // 章节列表
                // ****************************************************************
                _buildChapterListView(),
                Container(height: 12),
                // ****************************************************************
                // 其他
                // ****************************************************************
                Container(
                  height: 200,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
