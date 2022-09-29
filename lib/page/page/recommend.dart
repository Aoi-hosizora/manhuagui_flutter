import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_ahlib/list.dart';
import 'package:flutter_ahlib/widget.dart';
import 'package:flutter_ahlib/util.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/manga_carousel.dart';
import 'package:manhuagui_flutter/page/view/manga_column.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';

/// 首页推荐
/// Page for [HomepageMangaGroupList] / [MangaGroupList].
class RecommendSubPage extends StatefulWidget {
  const RecommendSubPage({
    Key? key,
    this.action,
  }) : super(key: key);

  final ActionController action;

  @override
  _RecommendSubPageState createState() => _RecommendSubPageState();
}

class _RecommendSubPageState extends State<RecommendSubPage> with AutomaticKeepAliveClientMixin {
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  final _indicatorKey = GlobalKey<RefreshIndicatorState>();
  var _carouselPages = <TinyBlockManga>[];
  var _loading = true;
  HomepageMangaGroupList _data;
  var _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _indicatorKey?.currentState?.show());
    widget.action?.addAction('', () => _controller.scrollToTop());
  }

  @override
  void dispose() {
    widget.action?.removeAction('');
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() {
    _loading = true;
    if (mounted) setState(() {});

    var dio = DioManager.instance.dio;
    var client = RestClient(dio);
    return client.getHomepageMangas().then((r) async {
      _error = '';
      _data = null;
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _data = r.data;
      var p1 = _data.serial.topGroup.mangas.sublist(0, 4);
      var p2 = _data.serial.groups.map((e) => e.mangas.first);
      var p3 = _data.serial.otherGroups.map((e) => e.mangas.first);
      _carouselPages = [
        ...{...p1, ...p2, ...p3}
      ];
    }).catchError((e) {
      _data = null;
      _error = wrapError(e).text;
    }).whenComplete(() {
      _loading = false;
      if (mounted) setState(() {});
    });
  }

  Widget _buildAction(String text, IconData icon, void Function() action) {
    return InkWell(
      onTap: () => action(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: IconText(
          alignment: IconTextAlignment.t2b,
          space: 8,
          icon: Icon(icon, color: Colors.black54),
          text: Text(text),
        ),
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
          isEmpty: _data == null,
          setting: PlaceholderSetting().toChinese(),
          onRefresh: () => _loadData(),
          onChanged: (_, __) => _fabController.hide(),
          childBuilder: (c) => Scrollbar(
            child: ListView(
              controller: _controller,
              children: [
                if (_carouselPages.length != 0) MangaCarouselView(mangas: _carouselPages),
                SizedBox(height: 12),
                Container(
                  color: Colors.white,
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 35, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildAction('我的书架', Icons.favorite, () => widget.action.invoke('to_shelf')),
                          _buildAction('最近更新', Icons.cached, () => widget.action.invoke('to_update')),
                          _buildAction('漫画排行', Icons.trending_up, () => widget.action.invoke('to_ranking')),
                          _buildAction('漫画分类', Icons.category, () => widget.action.invoke('to_genre')),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                MangaColumnView(group: _data.serial.topGroup, type: MangaGroupType.serial, showTopMargin: false), // 热门连载
                MangaColumnView(group: _data.finish.topGroup, type: MangaGroupType.finish), // 经典完结
                MangaColumnView(group: _data.latest.topGroup, type: MangaGroupType.latest), // 最新上架
                for (var group in _data.serial.groups) MangaColumnView(group: group, type: MangaGroupType.serial, small: true),
                for (var group in _data.finish.groups) MangaColumnView(group: group, type: MangaGroupType.finish, small: true),
                for (var group in _data.latest.groups) MangaColumnView(group: group, type: MangaGroupType.latest, small: true),
                for (var group in _data.serial.otherGroups) MangaColumnView(group: group, type: MangaGroupType.serial, small: true, singleLine: true),
                for (var group in _data.finish.otherGroups) MangaColumnView(group: group, type: MangaGroupType.finish, small: true, singleLine: true),
                for (var group in _data.latest.otherGroups) MangaColumnView(group: group, type: MangaGroupType.latest, small: true, singleLine: true),
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
          heroTag: 'RecommendSubPage',
          onPressed: () => _controller.scrollToTop(),
        ),
      ),
    );
  }
}
