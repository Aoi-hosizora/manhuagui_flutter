import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/download.dart';
import 'package:manhuagui_flutter/page/manga_random.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/manga_carousel.dart';
import 'package:manhuagui_flutter/page/view/manga_group.dart';
import 'package:manhuagui_flutter/page/view/warning_text.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';

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
    widget.action?.addAction(() => _controller.scrollToTop());
    WidgetsBinding.instance?.addPostFrameCallback((_) => _refreshIndicatorKey.currentState?.show());
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

  Widget _buildGroup(MangaGroup group, MangaGroupType type, MangaGroupViewStyle style) {
    return MangaGroupView(
      group: group,
      type: type,
      style: style,
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.only(bottom: 6),
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
            controller: _controller,
            interactive: true,
            crossAxisMargin: 2,
            child: ListView(
              controller: _controller,
              padding: EdgeInsets.zero,
              physics: AlwaysScrollableScrollPhysics(),
              children: [
                MangaCarouselView(
                  mangas: _data!.carouselMangas,
                  height: 220,
                  imageWidth: 165,
                ),
                SizedBox(height: 12),
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      ActionRowView.four(
                        action1: ActionItem.simple('我的书架', Icons.star_outlined, () => EventBusManager.instance.fire(ToShelfRequestedEvent())),
                        action2: ActionItem.simple('浏览历史', Icons.history, () => EventBusManager.instance.fire(ToHistoryRequestedEvent())),
                        action3: ActionItem.simple('下载列表', Icons.download, () => Navigator.of(context).push(CustomMaterialPageRoute.simple(context, (c) => DownloadPage()))),
                        action4: ActionItem.simple('随机漫画', Icons.shuffle, () => Navigator.of(context).push(CustomMaterialPageRoute.simple(context, (c) => MangaRandomPage()))),
                      ),
                      ActionRowView.four(
                        action1: ActionItem.simple('漫画类别', Icons.category, () => EventBusManager.instance.fire(ToGenreRequestedEvent())),
                        action2: ActionItem.simple('最近更新', Icons.cached, () => EventBusManager.instance.fire(ToRecentRequestedEvent())),
                        action3: ActionItem.simple('漫画排行', Icons.trending_up, () => EventBusManager.instance.fire(ToRankingRequestedEvent())),
                        action4: ActionItem.simple('外部打开', Icons.open_in_browser, () => launchInBrowser(context: context, url: WEB_HOMEPAGE_URL)),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 12),
                WarningTextView(
                  text: '由于漫画柜主页推荐的漫画已有一段时间没有更新，因此本页的推荐列表也没有更新。',
                  isWarning: false,
                ),
                _buildGroup(_data!.serial.topGroup, MangaGroupType.serial, MangaGroupViewStyle.normalTruncate), // 热门连载
                _buildGroup(_data!.finish.topGroup, MangaGroupType.finish, MangaGroupViewStyle.normalTruncate), // 经典完结
                _buildGroup(_data!.latest.topGroup, MangaGroupType.latest, MangaGroupViewStyle.normalTruncate), // 最新上架
                for (var group in _data!.serial.groups) _buildGroup(group, MangaGroupType.serial, MangaGroupViewStyle.smallTruncate), // 热门连载...
                for (var group in _data!.finish.groups) _buildGroup(group, MangaGroupType.finish, MangaGroupViewStyle.smallTruncate), // 经典完结...
                for (var group in _data!.latest.groups) _buildGroup(group, MangaGroupType.latest, MangaGroupViewStyle.smallTruncate), // 最新上架...
                for (var group in _data!.serial.otherGroups) _buildGroup(group, MangaGroupType.serial, MangaGroupViewStyle.smallOneLine), // 热门连载...
                for (var group in _data!.finish.otherGroups) _buildGroup(group, MangaGroupType.finish, MangaGroupViewStyle.smallOneLine), // 经典完结...
                for (var group in _data!.latest.otherGroups) _buildGroup(group, MangaGroupType.latest, MangaGroupViewStyle.smallOneLine), // 最新上架...
                SizedBox(height: 12),
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
