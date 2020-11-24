import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';
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
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: NetworkImageView(
                          url: _data.cover,
                          height: 160,
                          width: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width - 12 * 3 - 120,
                        height: 180.0 - 15 * 2,
                        margin: EdgeInsets.only(top: 15, bottom: 15, right: 12),
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
                            SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 24,
                                  width: 75,
                                  child: OutlineButton(
                                    padding: EdgeInsets.all(2),
                                    child: Text('订阅漫画'),
                                    onPressed: () {},
                                  ),
                                ),
                                SizedBox(width: 12),
                                Container(
                                  height: 24,
                                  width: 75,
                                  child: OutlineButton(
                                    padding: EdgeInsets.all(2),
                                    child: Text('继续阅读'),
                                    onPressed: () {},
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  color: Colors.white,
                  child: RichText(
                    text: _showBriefIntroduction
                        ? TextSpan(
                            text: _data.briefIntroduction,
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: '查看更多',
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
                                text: ' 隐藏',
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
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  color: Colors.white,
                  child: Divider(height: 1, thickness: 1),
                ),
                Container(
                  color: Colors.white,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Fluttertoast.showToast(msg: 'TODO'),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                Divider(height: 1, thickness: 1),
                Text('章节信息......'),
                Text('章节信息......'),
                Text('章节信息......'),
                Text('章节信息......'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
