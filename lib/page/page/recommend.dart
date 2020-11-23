import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
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
  var _loading = true;
  var _data = <MangaPageGroupList>[];
  String _error;

  @override
  void initState() {
    super.initState();
    _controller = ScrollMoreController();
    _fabController = ScrollFabController();
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() {
    _loading = true;
    _data = null;
    _error = "";
    if (mounted) setState(() {});

    var dio = DioManager.getInstance().dio;
    var client = RestClient(dio);
    return client.getHotSerialMangas().then((hotSerial) async {
      var finished = await client.getFinishedMangas();
      var newest = await client.getLatestMangas();
      _data = [hotSerial.data, finished.data, newest.data];
    }).catchError((e) {
      _error = wrapError(e).text;
    }).whenComplete(() {
      _loading = false;
      if (mounted) setState(() {});
    });
  }

  Widget _buildMangaColumn(MangaPageGroup group, String type, {bool first = false}) {
    var paddingWidth = 5.0;
    var width = MediaQuery.of(context).size.width / 3 - paddingWidth * 2;
    var height = width / 3 * 4;

    var buildMangaBlock = (TinyMangaPage manga, Color color) {
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
                Colors.blue[200],
                Colors.orange[200],
                Colors.purple[200],
              ],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
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
                color: color,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                  ),
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
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
            child: Text(
              group.title.isEmpty ? type : (type + "・" + group.title),
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildMangaBlock(group.mangas[0], Colors.red),
              buildMangaBlock(group.mangas[1], Colors.orange),
              buildMangaBlock(group.mangas[2], Colors.blue),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildMangaBlock(group.mangas[3], Colors.green),
              buildMangaBlock(group.mangas[4], Colors.purple),
              buildMangaBlock(null, null),
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
