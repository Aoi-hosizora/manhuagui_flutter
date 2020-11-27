import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga_group.dart';
import 'package:manhuagui_flutter/page/view/tiny_manga_block.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';

/// 首页推荐
/// Page for [MangaGroupList].
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
    var title = group.title.isEmpty ? type : (type + "・" + group.title);
    var icon = type == '热门连载'
        ? Icons.whatshot
        : type == '经典完结'
            ? Icons.hourglass_bottom
            : type == '最新上架'
                ? Icons.fiber_new
                : Icons.bookmark_border;

    var vPadding = 5.0;
    var width = MediaQuery.of(context).size.width / 3 - vPadding * 2;
    var height = width / 3 * 4;

    Widget buildTinyMangaView(TinyManga manga) {
      if (manga == null) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: vPadding),
          width: width,
          height: height,
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
              child: Center(
                child: Text('查看更多...'),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (c) => MangaGroupPage(
                    group: group,
                    type: type,
                    icon: icon,
                  ),
                ),
              ),
            ),
          ),
        );
      }
      return TinyMangaBlockView(
        manga: manga,
        width: width,
        height: height,
        vPadding: vPadding,
      );
    }

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
                  icon,
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
              buildTinyMangaView(group.mangas[0]),
              buildTinyMangaView(group.mangas[1]),
              buildTinyMangaView(group.mangas[2]),
            ],
          ),
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTinyMangaView(group.mangas[3]),
              buildTinyMangaView(group.mangas[4]),
              buildTinyMangaView(null),
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
          heroTag: 'RecommendSubPage',
          onPressed: () => _controller.scrollTop(),
        ),
      ),
    );
  }
}
