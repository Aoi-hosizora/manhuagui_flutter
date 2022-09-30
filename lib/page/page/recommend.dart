import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/manga_carousel.dart';
import 'package:manhuagui_flutter/page/view/manga_group.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 首页-推荐
class RecommendSubPage extends StatefulWidget {
  const RecommendSubPage({
    Key? key,
    this.action,
  }) : super(key: key);

  final ActionController? action;

  @override
  _RecommendSubPageState createState() => _RecommendSubPageState();
}

class _RecommendSubPageState extends State<RecommendSubPage> with AutomaticKeepAliveClientMixin {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _refreshIndicatorKey.currentState?.show());
    widget.action?.addAction(() => _controller.scrollToTop());
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  var _loading = true;
  HomepageMangaGroupList? _data;
  var _error = '';

  Future<void> _loadData() async {
    _loading = true;
    if (mounted) setState(() {});

    final client = RestClient(DioManager.instance.dio);
    try {
      var r = await client.getHomepageMangas();
      _data = null;
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _data = r.data;
    } catch (e, s) {
      _data = null;
      _error = wrapError(e, s).text;
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
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
        key: _refreshIndicatorKey,
        onRefresh: () => _loadData(),
        child: PlaceholderText.from(
          isLoading: _loading,
          errorText: _error,
          isEmpty: _data == null,
          setting: PlaceholderSetting().copyWithChinese(),
          onRefresh: () => _loadData(),
          onChanged: (_, __) => _fabController.hide(),
          childBuilder: (c) => ScrollbarWithMore(
            interactive: true,
            crossAxisMargin: 2,
            child: ListView(
              controller: _controller,
              children: [
                MangaCarouselView(
                  mangas: _data!.carouselMangas,
                  height: 220,
                  imageWidth: 165,
                ),
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
                          _buildAction('我的书架', Icons.favorite, () => EventBusManager.instance.fire(ToShelfRequestedEvent())),
                          _buildAction('最近更新', Icons.cached, () => EventBusManager.instance.fire(ToRecentRequestedEvent())),
                          _buildAction('漫画排行', Icons.trending_up, () => EventBusManager.instance.fire(ToRankingRequestedEvent())),
                          _buildAction('漫画分类', Icons.category, () => EventBusManager.instance.fire(ToGenreRequestedEvent())),
                        ],
                      ),
                    ),
                  ),
                ),
                MangaGroupView(
                  group: _data!.serial.topGroup,
                  type: MangaGroupType.serial,
                  style: MangaGroupViewStyle.normalTruncate,
                  margin: EdgeInsets.only(top: 12),
                  padding: EdgeInsets.only(bottom: 6),
                ), // 热门连载
                MangaGroupView(
                  group: _data!.finish.topGroup,
                  type: MangaGroupType.finish,
                  style: MangaGroupViewStyle.normalTruncate,
                  margin: EdgeInsets.only(top: 12),
                  padding: EdgeInsets.only(bottom: 6),
                ), // 经典完结
                MangaGroupView(
                  group: _data!.latest.topGroup,
                  type: MangaGroupType.latest,
                  style: MangaGroupViewStyle.normalTruncate,
                  margin: EdgeInsets.only(top: 12),
                  padding: EdgeInsets.only(bottom: 6),
                ), // 最新上架
                for (var group in _data!.serial.groups)
                  MangaGroupView(
                    group: group,
                    type: MangaGroupType.serial,
                    style: MangaGroupViewStyle.smallTruncate,
                    margin: EdgeInsets.only(top: 12),
                    padding: EdgeInsets.only(bottom: 6),
                  ), // 热门连载...
                for (var group in _data!.finish.groups)
                  MangaGroupView(
                    group: group,
                    type: MangaGroupType.finish,
                    style: MangaGroupViewStyle.smallTruncate,
                    margin: EdgeInsets.only(top: 12),
                    padding: EdgeInsets.only(bottom: 6),
                  ), // 经典完结...
                for (var group in _data!.latest.groups)
                  MangaGroupView(
                    group: group,
                    type: MangaGroupType.latest,
                    style: MangaGroupViewStyle.smallTruncate,
                    margin: EdgeInsets.only(top: 12),
                    padding: EdgeInsets.only(bottom: 6),
                  ), // 最新上架...
                for (var group in _data!.serial.otherGroups)
                  MangaGroupView(
                    group: group,
                    type: MangaGroupType.serial,
                    style: MangaGroupViewStyle.smallOneLine,
                    margin: EdgeInsets.only(top: 12),
                    padding: EdgeInsets.only(bottom: 6),
                  ), // 热门连载...
                for (var group in _data!.finish.otherGroups)
                  MangaGroupView(
                    group: group,
                    type: MangaGroupType.finish,
                    style: MangaGroupViewStyle.smallOneLine,
                    margin: EdgeInsets.only(top: 12),
                    padding: EdgeInsets.only(bottom: 6),
                  ), // 经典完结...
                for (var group in _data!.latest.otherGroups)
                  MangaGroupView(
                    group: group,
                    type: MangaGroupType.latest,
                    style: MangaGroupViewStyle.smallOneLine,
                    margin: EdgeInsets.only(top: 12),
                    padding: EdgeInsets.only(bottom: 6),
                  ), // 热门连载...
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
