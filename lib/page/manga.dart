import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga_detail.dart';
import 'package:manhuagui_flutter/page/view/chapter_group.dart';
import 'package:manhuagui_flutter/page/view/multilink_text.dart';
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

  @override
  void initState() {
    super.initState();
    _indicatorKey = GlobalKey<RefreshIndicatorState>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _indicatorKey?.currentState?.show());
  }

  Future<void> _loadData() {
    _loading = true;
    if (mounted) setState(() {});

    var dio = DioManager.instance.dio;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: Text(_data?.title ?? widget.title),
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
          setting: PlaceholderSetting().toChinese(),
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
                      Container(
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
                        width: MediaQuery.of(context).size.width - 14 * 3 - 120, // | ▢ ▢ |
                        margin: EdgeInsets.only(top: 14, bottom: 14, right: 14),
                        child: Wrap(
                          direction: Axis.vertical,
                          children: [
                            IconText(
                              icon: Icon(Icons.date_range, size: 20, color: Colors.orange),
                              text: Text('${_data.publishYear} ${_data.mangaZone}'),
                              space: 8,
                            ),
                            Row(
                              children: [
                                Icon(Icons.bookmark, size: 20, color: Colors.orange),
                                SizedBox(width: 8),
                                GenreListText(genres: _data.genres),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.person, size: 20, color: Colors.orange),
                                SizedBox(width: 8),
                                AuthorListText(authors: _data.authors),
                              ],
                            ),
                            IconText(
                              icon: Icon(Icons.trending_up, size: 20, color: Colors.orange),
                              text: Text('排名 ${_data.mangaRank}'),
                              space: 8,
                            ),
                            IconText(
                              icon: Icon(Icons.subject, size: 20, color: Colors.orange),
                              text: Text((_data.finished ? '共 ' : '更新至 ') + _data.newestChapter),
                              space: 8,
                            ),
                            IconText(
                              icon: Icon(Icons.access_time, size: 20, color: Colors.orange),
                              text: Text(_data.newestDate + (_data.finished ? ' 已完结' : ' 连载中')),
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
                  color: Colors.white,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => mountedSetState(() => _showBriefIntroduction = !_showBriefIntroduction),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: RichText(
                          text: TextSpan(
                            text: '',
                            style: Theme.of(context).textTheme.bodyText2.copyWith(fontSize: 13),
                            children: [
                              if (_showBriefIntroduction) ...[
                                TextSpan(text: _data.briefIntroduction),
                                TextSpan(
                                  text: ' 展开详情',
                                  style: TextStyle(color: Theme.of(context).primaryColor),
                                ),
                              ],
                              if (!_showBriefIntroduction) ...[
                                TextSpan(text: _data.introduction),
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
                          builder: (c) => MangaDetailPage(data: _data),
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
                                    initialRating: _data.averageScore / 2.0,
                                    minRating: 0,
                                    itemSize: 32,
                                    ignoreGestures: true,
                                    onRatingUpdate: (_) {},
                                  ),
                                  SizedBox(height: 4),
                                  Text('平均分数: ${_data.averageScore} / 10.0，共 ${_data.scoreCount} 人评价'),
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
                  child: ChapterGroupView(
                    groups: _data.chapterGroups,
                    mangaTitle: _data.title,
                    complete: false,
                  ),
                ),
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
