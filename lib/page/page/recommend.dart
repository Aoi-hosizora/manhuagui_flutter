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
  const RecommendSubPage({
    Key key,
    this.action,
  }) : super(key: key);

  final ActionController action;

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
    widget.action?.addAction('', () => print('RecommendSubPage'));
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

    var dio = DioManager.instance.dio;
    var client = RestClient(dio);
    return client.getHotSerialMangas().then((hot) async {
      var finished = await client.getFinishedMangas();
      var latest = await client.getLatestMangas();

      _error = '';
      _data.clear();
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _data.addAll([hot.data, finished.data, latest.data]);
    }).catchError((e) {
      _data.clear();
      _error = wrapError(e).text;
    }).whenComplete(() {
      _loading = false;
      if (mounted) setState(() {});
    });
  }

  Widget _buildColumn(MangaGroup group, String type, {bool first = false}) {
    var title = group.title.isEmpty ? type : (type + "・" + group.title);
    var icon = type == '热门连载'
        ? Icons.whatshot
        : type == '经典完结'
            ? Icons.hourglass_bottom
            : type == '最新上架'
                ? Icons.fiber_new
                : Icons.bookmark_border;

    final hSpace = 5.0;
    var width = (MediaQuery.of(context).size.width - hSpace * 4) / 3; // | ▢ ▢ ▢ |
    var height = width / 3 * 4;

    Widget buildBlock(TinyManga manga, {bool left = false}) => TinyMangaBlockView(
          manga: manga,
          width: width,
          height: height,
          margin: EdgeInsets.only(left: left ? hSpace : 0, right: hSpace),
          onMorePressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (c) => MangaGroupPage(
                group: group,
                title: title,
                icon: icon,
              ),
            ),
          ),
        );

    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: first ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: IconText(
              icon: Icon(icon, size: 20, color: Colors.orange),
              text: Text(title, style: Theme.of(context).textTheme.subtitle1),
              space: 6,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildBlock(group.mangas[0], left: true),
              buildBlock(group.mangas[1]),
              buildBlock(group.mangas[2]),
            ],
          ),
          SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildBlock(group.mangas[3], left: true),
              buildBlock(group.mangas[4]),
              buildBlock(null),
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
        onRefresh: () => _loadData(),
        child: PlaceholderText.from(
          isLoading: _loading,
          errorText: _error,
          isEmpty: _data?.isNotEmpty != true,
          setting: PlaceholderSetting().toChinese(),
          onRefresh: () => _loadData(),
          onChanged: (_, __) => _fabController.hide(),
          childBuilder: (c) => Scrollbar(
            child: ListView(
              controller: _controller,
              children: [
                _buildColumn(_data[0].topGroup, "热门连载", first: true),
                _buildColumn(_data[1].topGroup, "经典完结"),
                _buildColumn(_data[2].topGroup, "最新上架"),
                for (var group in _data[0].groups) _buildColumn(group, "热门连载"),
                for (var group in _data[1].groups) _buildColumn(group, "经典完结"),
                for (var group in _data[2].groups) _buildColumn(group, "最新上架"),
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
