import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/manga_group.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';

/// 首页推荐
class RecommendSubPage extends StatefulWidget {
  const RecommendSubPage({Key key}) : super(key: key);

  @override
  _RecommendSubPageState createState() => _RecommendSubPageState();
}

class _RecommendSubPageState extends State<RecommendSubPage> with AutomaticKeepAliveClientMixin {
  ScrollMoreController _controller;
  ScrollFabController _fabController;
  GlobalKey<RefreshIndicatorState> _indicatorKey;
  var _loading = true;
  var _data = <MangaGroupList>[];
  var _error = '';

  @override
  void initState() {
    super.initState();
    _controller = ScrollMoreController();
    _fabController = ScrollFabController();
    _indicatorKey = GlobalKey<RefreshIndicatorState>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _indicatorKey?.currentState?.show());
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() {
    _loading = true;
    if (mounted) setState(() {});

    var dio = DioManager.getInstance().dio;
    var client = RestClient(dio);
    return client.getHotSerialMangas().then((hotSerial) async {
      var finished = await client.getFinishedMangas();
      var newest = await client.getLatestMangas();

      _error = '';
      _data.clear();
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));

      _data.addAll([hotSerial.data, finished.data, newest.data]);
    }).catchError((e) {
      _data = [];
      _error = wrapError(e).text;
    }).whenComplete(() {
      _loading = false;
      if (mounted) setState(() {});
    });
  }

  Widget _buildMangaColumn(MangaGroup group, String type, {bool first = false}) {
    var paddingWidth = 5.0;
    var width = MediaQuery.of(context).size.width / 3 - paddingWidth * 2;
    var height = width / 3 * 4;
    var title = group.title.isEmpty ? type : (type + "・" + group.title);

    var buildMangaBlock = (TinyManga manga) {
      if (manga == null) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: paddingWidth),
          height: height,
          width: width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0, 0.5, 1],
              colors: [
                Colors.blue[100],
                Colors.orange[200],
                Colors.purple[100],
              ],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (c) => MangaGroupPage(
                    group: group,
                    title: title,
                  ),
                ),
              ),
              child: Center(
                child: Text('查看更多...'),
              ),
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: paddingWidth),
                height: height,
                width: width,
                child: Stack(
                  children: [
                    NetworkImageView(
                      url: manga.cover,
                      width: width,
                      height: height,
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (c) => MangaPage(
                                id: manga.mid,
                                title: manga.title,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: paddingWidth),
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  width: width,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 1],
                      colors: [
                        Color.fromRGBO(0, 0, 0, 0),
                        Color.fromRGBO(0, 0, 0, 1),
                      ],
                    ),
                  ),
                  child: Text(
                    (manga.finished ? '共' : '更新至') + manga.newestChapter,
                    style: TextStyle(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: width,
            margin: EdgeInsets.symmetric(horizontal: paddingWidth, vertical: 3),
            child: Text(
              manga.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    };

    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: first ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Icon(
                  type == '热门连载'
                      ? Icons.whatshot
                      : type == '经典完结'
                          ? Icons.hourglass_bottom
                          : type == '最新上架'
                              ? Icons.fiber_new
                              : Icons.bookmark_border,
                  size: 20,
                  color: Colors.orange,
                ),
                SizedBox(width: 6),
                Text(
                  title,
                  style: Theme.of(context).textTheme.subtitle1,
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildMangaBlock(group.mangas[0]),
              buildMangaBlock(group.mangas[1]),
              buildMangaBlock(group.mangas[2]),
            ],
          ),
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildMangaBlock(group.mangas[3]),
              buildMangaBlock(group.mangas[4]),
              buildMangaBlock(null),
            ],
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        key: _indicatorKey,
        onRefresh: _loadData,
        child: PlaceholderText.from(
          isLoading: _loading,
          errorText: _error,
          isEmpty: _data?.isNotEmpty != true,
          setting: PlaceholderSetting(
            showProgress: true,
            loadingText: '加载中',
            retryText: '重试',
          ),
          onRefresh: () => _loadData(),
          onChanged: (_) => _fabController.hide(),
          childBuilder: (c) => Scrollbar(
            child: ListView(
              controller: _controller,
              children: [
                _buildMangaColumn(_data[0].topGroup, "热门连载", first: true),
                _buildMangaColumn(_data[1].topGroup, "经典完结"),
                _buildMangaColumn(_data[2].topGroup, "最新上架"),
                for (var group in _data[0].groups) _buildMangaColumn(group, "热门连载"),
                for (var group in _data[1].groups) _buildMangaColumn(group, "经典完结"),
                for (var group in _data[2].groups) _buildMangaColumn(group, "最新上架"),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: ScrollFloatingActionButton(
        scrollController: _controller,
        fabController: _fabController,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          onPressed: () => _controller.scrollTop(),
        ),
      ),
    );
  }
}
