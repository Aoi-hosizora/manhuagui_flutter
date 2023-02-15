import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/download.dart';
import 'package:manhuagui_flutter/page/manga_aud_ranking.dart';
import 'package:manhuagui_flutter/page/manga_group.dart';
import 'package:manhuagui_flutter/page/manga_random.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/genre_chip_list.dart';
import 'package:manhuagui_flutter/page/view/homepage_column.dart';
import 'package:manhuagui_flutter/page/view/manga_aud_ranking.dart';
import 'package:manhuagui_flutter/page/view/manga_carousel.dart';
import 'package:manhuagui_flutter/page/view/manga_collection.dart';
import 'package:manhuagui_flutter/page/view/manga_group.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _controller.scrollToTop());
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _loadData(); // 获取首页漫画分组数据
      Future.delayed(Duration(milliseconds: 1500)).then((_) => _loadCollections(MangaCollectionType.values)); // 额外等待，获取各种漫画集合数据
      Future.delayed(Duration(milliseconds: 4000)).then((_) => _loadRankings(MangaAudRankingType.values)); // 额外等待，获取一些受众排行榜数据
    });
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandlers.add(AuthManager.instance.listenOnlyWhen(Tuple1(AuthManager.instance.authData), (_) {
        if (mounted) setState(() {});
        _loadCollections([MangaCollectionType.shelves, MangaCollectionType.favorites, MangaCollectionType.histories]);
      }));
    });
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    widget.action?.removeAction();
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  var _loading = true; // initialize to true
  HomepageMangaGroupList? _data;
  var _error = '';

  Future<void> _loadData() async {
    _loading = true;
    _error = '';
    if (mounted) setState(() {});

    // 如果未登录，刷新时异步检查登录状态
    if (!AuthManager.instance.logined) {
      AuthManager.instance.check();
    }

    // 针对除漫画分组以外的数据，在刷新时仅获取空数据
    _loadCollections(MangaCollectionType.values, onlyIfEmpty: true);
    _loadRankings(MangaAudRankingType.values, onlyIfEmpty: true);

    // 同步获取漫画分组数据
    final client = RestClient(DioManager.instance.dio);
    try {
      var result = await client.getHomepageMangas();
      _data = null;
      if (mounted) setState(() {});
      await Future.delayed(kFlashListDuration);
      _data = result.data;
      globalGenres ??= result.data.genres.map((e) => e.toTiny()).toList(); // 更新全局漫画类别
    } catch (e, s) {
      _error = wrapError(e, s).text;
      if (_data != null) {
        Fluttertoast.showToast(msg: _error);
      }
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  List<TinyManga>? _updates;
  List<MangaHistory>? _histories;
  List<ShelfManga>? _shelves;
  List<FavoriteManga>? _favorites;
  List<DownloadedManga>? _downloads;
  var _updatesError = '';
  var _shelvesError = '';

  Future<void> _loadCollections(List<MangaCollectionType> types, {bool onlyIfEmpty = false} /* default to request */) async {
    final client = RestClient(DioManager.instance.dio);

    if (types.contains(MangaCollectionType.rankings)) {
      // pass => #=50
    }

    if (types.contains(MangaCollectionType.updates)) {
      Future.microtask(() async {
        if (onlyIfEmpty && (_updates == null || _updates!.isNotEmpty)) {
          return; // loading or not empty => ignore
        }
        _updates = null; // loading
        _updatesError = '';
        if (mounted) setState(() {});
        try {
          var result = await client.getRecentUpdatedMangas(page: 0); // #=42
          _updates = result.data.data;
        } catch (e, s) {
          _updates = []; // loaded but error
          _updatesError = wrapError(e, s).text;
        } finally {
          if (mounted) setState(() {});
        }
      });
    }

    if (types.contains(MangaCollectionType.histories)) {
      Future.microtask(() async {
        _histories = null; // loading
        if (mounted) setState(() {});
        var includeUnread = AppSetting.instance.ui.includeUnreadInHome;
        var result = await HistoryDao.getHistories(username: AuthManager.instance.username, includeUnread: includeUnread, page: 1, limit: 50); // #=50
        await Future.delayed(kFakeRefreshDuration);
        _histories = result ?? [];
        if (mounted) setState(() {});
      });
    }

    if (types.contains(MangaCollectionType.shelves)) {
      Future.microtask(() async {
        if (onlyIfEmpty && (_shelves == null || _shelves!.isNotEmpty)) {
          return; // loading or not empty => ignore
        }
        _shelves = null; // loading
        _shelvesError = '';
        if (mounted) setState(() {});
        if (AuthManager.instance.logined) {
          try {
            var result = await client.getShelfMangas(token: AuthManager.instance.token, page: 1); // #=20
            _shelves = result.data.data;
          } catch (e, s) {
            _shelves = []; // loaded but error
            _shelvesError = wrapError(e, s).text;
          } finally {
            if (mounted) setState(() {});
          }
        } else {
          _shelves = []; // loaded but unauthorized
          _shelvesError = '用户未登录';
          if (mounted) setState(() {});
        }
      });
    }

    if (types.contains(MangaCollectionType.favorites)) {
      Future.microtask(() async {
        _favorites = null; // loading
        if (mounted) setState(() {});
        var result = await FavoriteDao.getFavorites(username: AuthManager.instance.username, groupName: '', page: 1, limit: 20); // #=20
        await Future.delayed(kFakeRefreshDuration);
        _favorites = result ?? [];
        if (mounted) setState(() {});
      });
    }

    if (types.contains(MangaCollectionType.downloads)) {
      Future.microtask(() async {
        _downloads = null; // loading
        if (mounted) setState(() {});
        var result = await DownloadDao.getMangas();
        await Future.delayed(kFakeRefreshDuration);
        _downloads = result?.sublist(0, result.length.clamp(0, 20)) ?? []; // #=20
        if (mounted) setState(() {});
      });
    }
  }

  List<MangaRanking>? _qingnianRankings;
  List<MangaRanking>? _shaonianRankings;
  List<MangaRanking>? _shaonvRankings;
  var _qingnianRankingsError = '';
  var _shaonianRankingsError = '';
  var _shaonvRankingsError = '';

  Future<void> _loadRankings(List<MangaAudRankingType> types, {bool onlyIfEmpty = false} /* default to request */) async {
    final client = RestClient(DioManager.instance.dio);

    if (types.contains(MangaAudRankingType.all)) {
      // pass => #=50
    }

    if (types.contains(MangaAudRankingType.qingnian)) {
      Future.microtask(() async {
        if (onlyIfEmpty && (_qingnianRankings == null || _qingnianRankings!.isNotEmpty)) {
          return; // loading or not empty => ignore
        }
        _qingnianRankings = null; // loading
        _qingnianRankingsError = '';
        if (mounted) setState(() {});
        try {
          var result = await client.getDayRanking(type: 'qingnian'); // #=50
          _qingnianRankings = result.data.data;
        } catch (e, s) {
          _qingnianRankings = []; // loaded but error
          _qingnianRankingsError = wrapError(e, s).text;
        } finally {
          if (mounted) setState(() {});
        }
      });
    }

    if (types.contains(MangaAudRankingType.shaonian)) {
      Future.microtask(() async {
        if (onlyIfEmpty && (_shaonianRankings == null || _shaonianRankings!.isNotEmpty)) {
          return; // loading or not empty => ignore
        }
        _shaonianRankings = null; // loading
        _shaonianRankingsError = '';
        if (mounted) setState(() {});
        try {
          await Future.delayed(Duration(milliseconds: 1000)); // 额外等待，少年漫画日排行榜基本与全部漫画一致
          var result = await client.getDayRanking(type: 'shaonian'); // #=50
          _shaonianRankings = result.data.data;
        } catch (e, s) {
          _shaonianRankings = []; // loaded but error
          _shaonianRankingsError = wrapError(e, s).text;
        } finally {
          if (mounted) setState(() {});
        }
      });
    }

    if (types.contains(MangaAudRankingType.shaonv)) {
      Future.microtask(() async {
        if (onlyIfEmpty && (_shaonvRankings == null || _shaonvRankings!.isNotEmpty)) {
          return; // loading or not empty => ignore
        }
        _shaonvRankings = null; // loading
        _shaonvRankingsError = '';
        if (mounted) setState(() {});
        try {
          var result = await client.getDayRanking(type: 'shaonv'); // #=50
          _shaonvRankings = result.data.data;
        } catch (e, s) {
          _shaonvRankings = []; // loaded but error
          _shaonvRankingsError = wrapError(e, s).text;
        } finally {
          if (mounted) setState(() {});
        }
      });
    }
  }

  Widget _buildCollection(String error, MangaCollectionType type) {
    return Padding(
      padding: EdgeInsets.only(top: 12),
      child: MangaCollectionView(
        type: type,
        ranking: type == MangaCollectionType.rankings ? _data!.daily : null,
        updates: type == MangaCollectionType.updates ? _updates : null,
        histories: type == MangaCollectionType.histories ? _histories : null,
        shelves: type == MangaCollectionType.shelves ? _shelves : null,
        favorites: type == MangaCollectionType.favorites ? _favorites : null,
        downloads: type == MangaCollectionType.downloads ? _downloads : null,
        error: error,
        username: !AuthManager.instance.logined ? null : AuthManager.instance.username,
        disableRefresh: type == MangaCollectionType.rankings || //
            (type == MangaCollectionType.updates && _updates == null) ||
            (type == MangaCollectionType.histories && _histories == null) ||
            (type == MangaCollectionType.shelves && _shelves == null) ||
            (type == MangaCollectionType.favorites && _favorites == null) ||
            (type == MangaCollectionType.downloads && _downloads == null),
        onRefreshPressed: type == MangaCollectionType.rankings
            ? null // don't show refresh button for ranking collection
            : () => _loadCollections([type]),
        onMorePressed: type == MangaCollectionType.rankings
            ? null // show right text rather than more button for ranking collection
            : () {
                if (type == MangaCollectionType.updates) EventBusManager.instance.fire(ToRecentRequestedEvent());
                if (type == MangaCollectionType.histories) EventBusManager.instance.fire(ToHistoryRequestedEvent());
                if (type == MangaCollectionType.shelves) EventBusManager.instance.fire(ToShelfRequestedEvent());
                if (type == MangaCollectionType.favorites) EventBusManager.instance.fire(ToFavoriteRequestedEvent());
                if (type == MangaCollectionType.downloads) Navigator.of(context).push(CustomPageRoute(context: context, builder: (c) => DownloadPage()));
              },
      ),
    );
  }

  Widget _buildAudRanking() {
    return Padding(
      padding: EdgeInsets.only(top: 12),
      child: MangaAudRankingView(
        allRankings: _data!.daily,
        qingnianRankings: _qingnianRankings,
        shaonianRankings: _shaonianRankings,
        shaonvRankings: _shaonvRankings,
        allRankingsError: '',
        qingnianRankingsError: _qingnianRankingsError,
        shaonianRankingsError: _shaonianRankingsError,
        shaonvRankingsError: _shaonvRankingsError,
        mangaCount: AppSetting.instance.ui.audienceRankingRows,
        onRetryPressed: (t) => _loadRankings([t]),
        onFullPressed: (t) => Navigator.of(context).push(
          CustomPageRoute(
            context: context,
            builder: (c) => MangaAudRankingPage(
              type: t,
              rankings: t == MangaAudRankingType.all
                  ? _data!.daily
                  : t == MangaAudRankingType.qingnian
                      ? _qingnianRankings!
                      : t == MangaAudRankingType.shaonian
                          ? _shaonianRankings!
                          : _shaonvRankings!,
            ),
          ),
        ),
        onMorePressed: () => EventBusManager.instance.fire(ToRankingRequestedEvent()),
      ),
    );
  }

  Widget _buildGroupList(MangaGroupList groupList) {
    return Padding(
      padding: EdgeInsets.only(top: 12),
      child: MangaGroupView(
        groupList: groupList, // 包括置顶漫画 (topGroup)、分类别漫画 (groups1, groups2)
        style: MangaGroupViewStyle.smallTruncated,
        onMorePressed: () => Navigator.of(context).push(
          CustomPageRoute(
            context: context,
            builder: (c) => MangaGroupPage(
              groupList: groupList,
            ),
          ),
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
          childBuilder: (c) => ExtendedScrollbar(
            controller: _controller,
            interactive: true,
            mainAxisMargin: 2,
            crossAxisMargin: 2,
            child: ListView(
              controller: _controller,
              padding: EdgeInsets.zero,
              physics: AlwaysScrollableScrollPhysics(),
              cacheExtent: 999999 /* <<< keep states in ListView */,
              children: [
                MangaCarouselView(
                  mangas: _data!.carouselMangas,
                  height: 240,
                  imageWidth: 180,
                ),
                SizedBox(height: 12),
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      ActionRowView.four(
                        action1: ActionItem.simple('我的书架', MdiIcons.bookshelf, () => EventBusManager.instance.fire(ToShelfRequestedEvent())),
                        action2: ActionItem.simple('本地收藏', MdiIcons.bookmarkBoxMultipleOutline, () => EventBusManager.instance.fire(ToFavoriteRequestedEvent())),
                        action3: ActionItem.simple('阅读历史', Icons.history, () => EventBusManager.instance.fire(ToHistoryRequestedEvent())),
                        action4: ActionItem.simple('下载列表', Icons.download, () => Navigator.of(context).push(CustomPageRoute(context: context, builder: (c) => DownloadPage()))),
                      ),
                      ActionRowView.four(
                        action1: ActionItem.simple('最近更新', Icons.cached, () => EventBusManager.instance.fire(ToRecentRequestedEvent())),
                        action2: ActionItem.simple('漫画排行', Icons.trending_up, () => EventBusManager.instance.fire(ToRankingRequestedEvent())),
                        action3: ActionItem.simple('随机漫画', Icons.shuffle, () => Navigator.of(context).push(CustomPageRoute(context: context, builder: (c) => MangaRandomPage(parentContext: context)))),
                        action4: ActionItem.simple('外部浏览', Icons.open_in_browser, () => launchInBrowser(context: context, url: WEB_HOMEPAGE_URL)),
                      ),
                    ],
                  ),
                ),
                _buildCollection('', MangaCollectionType.rankings), // 今日漫画排行榜
                _buildCollection(_updatesError, MangaCollectionType.updates), // 最近更新的漫画
                _buildCollection('', MangaCollectionType.histories), // 我的阅读历史
                _buildAudRanking(), // 漫画受众排行榜
                _buildCollection(_shelvesError, MangaCollectionType.shelves), // 我的书架
                _buildCollection('', MangaCollectionType.favorites), // 我的本地收藏
                _buildCollection('', MangaCollectionType.downloads), // 漫画下载列表
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: HomepageColumnView(
                    title: '所有的漫画剧情类别',
                    icon: Icons.category,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        child: GenreChipListView(genres: _data!.genres),
                      ),
                    ),
                  ),
                ), // 剧情类别
                SizedBox(height: 12),
                WarningTextView(
                  text: '由于漫画柜官方主页的推荐已有很长一段时间没有更新，因此以下推荐列表也一直保持不变。',
                  isWarning: false,
                ),
                _buildGroupList(_data!.serial), // 热门连载
                _buildGroupList(_data!.finish), // 经典完结
                _buildGroupList(_data!.latest), // 最新上架
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      '已经划到底了~',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
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
