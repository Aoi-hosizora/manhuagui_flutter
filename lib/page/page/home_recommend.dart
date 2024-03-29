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
import 'package:manhuagui_flutter/page/sep_favorite.dart';
import 'package:manhuagui_flutter/page/sep_history.dart';
import 'package:manhuagui_flutter/page/sep_ranking.dart';
import 'package:manhuagui_flutter/page/sep_recent.dart';
import 'package:manhuagui_flutter/page/sep_shelf.dart';
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
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadDataWhenInit());
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
  DateTime? _dataDateTime;
  var _error = '';

  void _loadDataWhenInit() {
    _loadData(considerOtherData: false); // 获取首页漫画分组数据 (共两次请求)
    Future.microtask(() async {
      await Future.delayed(Duration(milliseconds: 2500)); // 额外等待，获取各种漫画集合数据 (共两次请求)
      await _loadCollections(MangaCollectionType.values, onlyIfEmpty: false, needDelay: true);
    });
    Future.microtask(() async {
      await Future.delayed(Duration(milliseconds: 5000)); // 额外等待，获取一些受众排行榜数据 (共两次请求)
      await _loadRankings(MangaAudRankingType.values, onlyIfEmpty: false, needDelay: true);
    });
  }

  Future<void> _loadData({bool considerOtherData = true}) async {
    _loading = true;
    _error = '';
    if (mounted) setState(() {});

    // 如果未登录，刷新时异步检查登录状态
    if (!AuthManager.instance.logined) {
      Future.microtask(() async {
        var r = await AuthManager.instance.check();
        if (!r.logined && r.error != null) {
          Fluttertoast.showToast(msg: '无法检查登录状态：${r.error!.text}');
        }
      });
    }

    // 针对除漫画分组以外的数据 (下拉刷新)
    var refreshData = AppSetting.instance.ui.homepageRefreshData;
    if (considerOtherData && refreshData != HomepageRefreshData.onlyRecommend) {
      var onlyIfEmpty = refreshData == HomepageRefreshData.includeListIfEmpty;
      Future.microtask(() async {
        await Future.delayed(Duration(milliseconds: 1500));
        await _loadCollections(MangaCollectionType.values, onlyIfEmpty: onlyIfEmpty, needDelay: true);
      });
      Future.microtask(() async {
        await Future.delayed(Duration(milliseconds: 3000));
        await _loadRankings(MangaAudRankingType.values, onlyIfEmpty: onlyIfEmpty, needDelay: true);
      });
    }

    // 同步获取漫画分组数据
    final client = RestClient(DioManager.instance.dio);
    try {
      var result = await client.getHomepageMangas();
      _data = null;
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(kFlashListDuration);
      _data = result.data;
      _dataDateTime = DateTime.now();
      globalCategoryList ??= CategoryList(genres: result.data.genres, zones: result.data.zones, ages: result.data.ages); // 更新全局的漫画类别
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

  Future<void> _loadCollections(List<MangaCollectionType> types, {bool onlyIfEmpty = false, bool needDelay = false}) async {
    final client = RestClient(DioManager.instance.dio);

    if (types.contains(MangaCollectionType.rankings)) {
      // pass => #=50
    }

    if (types.contains(MangaCollectionType.recents)) {
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
        var result = await HistoryDao.getHistories(username: AuthManager.instance.username, includeUnread: includeUnread, page: 1, limit: 30); // #=30
        await Future.delayed(kFakeRefreshDuration * 1.5);
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
            if (needDelay) {
              await Future.delayed(Duration(milliseconds: 1000)); // 额外等待，我的书架
            }
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
        var condition = AppSetting.instance.ui.homepageFavorite.determineQueryCondition();
        var result = await FavoriteDao.getFavorites(username: AuthManager.instance.username, groupName: condition.item1, sortMethod: condition.item2, page: 1, limit: 20); // #=20
        await Future.delayed(kFakeRefreshDuration * 1.5);
        _favorites = result ?? [];
        if (mounted) setState(() {});
      });
    }

    if (types.contains(MangaCollectionType.downloads)) {
      Future.microtask(() async {
        _downloads = null; // loading
        if (mounted) setState(() {});
        var result = await DownloadDao.getMangas();
        await Future.delayed(kFakeRefreshDuration * 1.5);
        _downloads = result?.sublist(0, result.length.clamp(0, 20)) ?? []; // #=20
        if (mounted) setState(() {});
      });
    }
  }

  List<MangaRanking>? _qingnianRankings;
  List<MangaRanking>? _shaonvRankings;
  DateTime? _qingnianRankingDateTime;
  DateTime? _shaonvRankingDateTime;
  var _qingnianRankingsError = '';
  var _shaonvRankingsError = '';

  Future<void> _loadRankings(List<MangaAudRankingType> types, {bool onlyIfEmpty = false, bool needDelay = false}) async {
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
          _qingnianRankingDateTime = DateTime.now();
        } catch (e, s) {
          _qingnianRankings = []; // loaded but error
          _qingnianRankingsError = wrapError(e, s).text;
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
          if (needDelay) {
            await Future.delayed(Duration(milliseconds: 1000)); // 额外等待，我的书架
          }
          var result = await client.getDayRanking(type: 'shaonv'); // #=50
          _shaonvRankings = result.data.data;
          _shaonvRankingDateTime = DateTime.now();
        } catch (e, s) {
          _shaonvRankings = []; // loaded but error
          _shaonvRankingsError = wrapError(e, s).text;
        } finally {
          if (mounted) setState(() {});
        }
      });
    }
  }

  void _openSepPage(Widget page) {
    if (AppSetting.instance.ui.alwaysOpenNewListPage) {
      Navigator.of(context).push(CustomPageRoute(context: context, builder: (c) => page));
    } else {
      if (page is SepShelfPage) {
        EventBusManager.instance.fire(ToShelfRequestedEvent());
      } else if (page is SepFavoritePage) {
        EventBusManager.instance.fire(ToFavoriteRequestedEvent());
      } else if (page is SepHistoryPage) {
        EventBusManager.instance.fire(ToHistoryRequestedEvent());
      } else if (page is SepRecentPage) {
        EventBusManager.instance.fire(ToRecentRequestedEvent());
      } else if (page is SepRankingPage) {
        EventBusManager.instance.fire(ToRankingRequestedEvent());
      }
    }
  }

  Widget _buildCollection(String error, MangaCollectionType type) {
    return Padding(
      padding: EdgeInsets.only(top: 12),
      child: MangaCollectionView(
        type: type,
        ranking: type == MangaCollectionType.rankings ? _data!.daily : null,
        rankingDateTime: _dataDateTime,
        updates: type == MangaCollectionType.recents ? _updates : null,
        histories: type == MangaCollectionType.histories ? _histories : null,
        shelves: type == MangaCollectionType.shelves ? _shelves : null,
        favorites: type == MangaCollectionType.favorites ? _favorites : null,
        downloads: type == MangaCollectionType.downloads ? _downloads : null,
        error: error,
        username: !AuthManager.instance.logined ? null : AuthManager.instance.username,
        disableRefresh: type == MangaCollectionType.rankings || //
            (type == MangaCollectionType.recents && _updates == null) ||
            (type == MangaCollectionType.histories && _histories == null) ||
            (type == MangaCollectionType.shelves && _shelves == null) ||
            (type == MangaCollectionType.favorites && _favorites == null) ||
            (type == MangaCollectionType.downloads && _downloads == null),
        onRefreshPressed: type == MangaCollectionType.rankings
            ? null // don't show refresh button for ranking collection
            : () => _loadCollections([type], onlyIfEmpty: false, needDelay: false),
        onMorePressed: type == MangaCollectionType.rankings
            ? null // show right text rather than more button for ranking collection
            : () {
                if (type == MangaCollectionType.recents) _openSepPage(SepRecentPage());
                if (type == MangaCollectionType.histories) _openSepPage(SepHistoryPage());
                if (type == MangaCollectionType.shelves) _openSepPage(SepShelfPage());
                if (type == MangaCollectionType.favorites) _openSepPage(SepFavoritePage());
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
        shaonvRankings: _shaonvRankings,
        allRankingsDateTime: _dataDateTime,
        qingnianRankingsDateTime: _qingnianRankingDateTime,
        shaonvRankingsDateTime: _shaonvRankingDateTime,
        allRankingsError: '',
        qingnianRankingsError: _qingnianRankingsError,
        shaonvRankingsError: _shaonvRankingsError,
        mangaRows: AppSetting.instance.ui.audienceRankingRows,
        onRetryPressed: (t) => _loadRankings([t], onlyIfEmpty: false, needDelay: false),
        onFullPressed: (t) => Navigator.of(context).push(
          CustomPageRoute(
            context: context,
            builder: (c) => MangaAudRankingPage(
              type: t,
              rankings: t == MangaAudRankingType.all
                  ? _data!.daily
                  : t == MangaAudRankingType.qingnian
                      ? _qingnianRankings!
                      : _shaonvRankings!,
              rankingDatetime: t == MangaAudRankingType.all
                  ? _dataDateTime
                  : t == MangaAudRankingType.qingnian
                      ? _qingnianRankingDateTime
                      : _shaonvRankingDateTime,
            ),
          ),
        ),
        onMorePressed: () => _openSepPage(SepRankingPage()),
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
    // TODO 长截图 https://blog.csdn.net/weixin_38912070/article/details/126277033
    return Scaffold(
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () => _loadData(considerOtherData: true),
        child: PlaceholderText.from(
          isLoading: _loading,
          errorText: _error,
          isEmpty: _data == null,
          setting: PlaceholderSetting().copyWithChinese(),
          onRefresh: () => _loadData(considerOtherData: true),
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
                  padding: EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    children: [
                      ActionRowView.four(
                        action1: ActionItem.simple('我的书架', MdiIcons.bookshelf, () => _openSepPage(SepShelfPage())),
                        action2: ActionItem.simple('本地收藏', MdiIcons.bookmarkBoxMultipleOutline, () => _openSepPage(SepFavoritePage())),
                        action3: ActionItem.simple('阅读历史', Icons.history, () => _openSepPage(SepHistoryPage())),
                        action4: ActionItem.simple('下载列表', Icons.download, () => Navigator.of(context).push(CustomPageRoute(context: context, builder: (c) => DownloadPage()))),
                      ),
                      ActionRowView.four(
                        action1: ActionItem.simple('最近更新', Icons.cached, () => _openSepPage(SepRecentPage())),
                        action2: ActionItem.simple('漫画排行', Icons.trending_up, () => _openSepPage(SepRankingPage())),
                        action3: ActionItem.simple('随机漫画', Icons.shuffle, () => Navigator.of(context).push(CustomPageRoute(context: context, builder: (c) => MangaRandomPage()))),
                        action4: ActionItem.simple('外部浏览', Icons.open_in_browser, () => launchInBrowser(context: context, url: WEB_HOMEPAGE_URL)),
                      ),
                    ],
                  ),
                ),
                _buildCollection('', MangaCollectionType.rankings), // 今日漫画排行榜
                _buildCollection(_updatesError, MangaCollectionType.recents), // 最近更新的漫画
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
                        child: GenreChipListView(genres: _data!.genres.map((g) => g.toTiny()).toList()),
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
