import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/download.dart';
import 'package:manhuagui_flutter/page/manga_group.dart';
import 'package:manhuagui_flutter/page/manga_random.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/genre_chip_list.dart';
import 'package:manhuagui_flutter/page/view/homepage_column.dart';
import 'package:manhuagui_flutter/page/view/manga_carousel.dart';
import 'package:manhuagui_flutter/page/view/manga_collection.dart';
import 'package:manhuagui_flutter/page/view/manga_group.dart';
import 'package:manhuagui_flutter/page/view/warning_text.dart';
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
  AuthData? _oldAuthData;

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _controller.scrollToTop());
    WidgetsBinding.instance?.addPostFrameCallback((_) => _refreshIndicatorKey.currentState?.show());

    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandlers.add(AuthManager.instance.listen(() => _oldAuthData, (ev) {
        _oldAuthData = AuthManager.instance.authData;
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

  var _loading = true;
  HomepageMangaGroupList? _data;
  var _error = '';

  Future<void> _loadData() async {
    _loading = true;
    _data = null;
    _error = '';
    if (mounted) setState(() {});

    // 1. 异步获取各种数据
    _loadCollections(MangaCollectionType.values);

    // 2. 同步获取漫画分组数据
    final client = RestClient(DioManager.instance.dio);
    try {
      var result = await client.getHomepageMangas();
      _data = result.data;
      globalGenres = result.data.genres.map((e) => e.toTiny()).toList(); // 更新全局漫画类别
    } catch (e, s) {
      _error = wrapError(e, s).text;
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

  Future<void> _loadCollections(List<MangaCollectionType> types) async {
    final client = RestClient(DioManager.instance.dio);

    if (types.contains(MangaCollectionType.rankings)) {
      // pass => #=50
    }

    if (types.contains(MangaCollectionType.updates)) {
      Future.microtask(() async {
        _updates = null; // loading
        _updatesError = '';
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
        var result = await HistoryDao.getHistories(username: AuthManager.instance.username, page: 1, limit: 50); // #=50
        _histories = result ?? [];
        if (mounted) setState(() {});
      });
    }

    if (types.contains(MangaCollectionType.shelves)) {
      Future.microtask(() async {
        _shelves = null; // loading
        _shelvesError = '';
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
        var result = await FavoriteDao.getFavorites(username: AuthManager.instance.username, groupName: '', page: 1, limit: 20); // #=20
        _favorites = result ?? [];
        if (mounted) setState(() {});
      });
    }

    if (types.contains(MangaCollectionType.downloads)) {
      Future.microtask(() async {
        _downloads = null; // loading
        var result = await DownloadDao.getMangas();
        _downloads = result?.sublist(0, result.length.clamp(0, 20)) ?? []; // #=20
        if (mounted) setState(() {});
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
        onMorePressed: () {
          switch (type) {
            case MangaCollectionType.rankings:
              EventBusManager.instance.fire(ToRankingRequestedEvent());
              break;
            case MangaCollectionType.updates:
              EventBusManager.instance.fire(ToRecentRequestedEvent());
              break;
            case MangaCollectionType.histories:
              EventBusManager.instance.fire(ToHistoryRequestedEvent());
              break;
            case MangaCollectionType.shelves:
              EventBusManager.instance.fire(ToShelfRequestedEvent());
              break;
            case MangaCollectionType.favorites:
              EventBusManager.instance.fire(ToFavoriteRequestedEvent());
              break;
            case MangaCollectionType.downloads:
              Navigator.of(context).push(CustomPageRoute(context: context, builder: (c) => DownloadPage()));
              break;
          }
        },
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
                        action1: ActionItem.simple('我的书架', MdiIcons.bookshelf, () => EventBusManager.instance.fire(ToShelfRequestedEvent())), // Icons.star
                        action2: ActionItem.simple('本地收藏', MdiIcons.bookmarkBoxMultipleOutline, () => EventBusManager.instance.fire(ToFavoriteRequestedEvent())), // Icons.bookmark
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
                _buildCollection('', MangaCollectionType.rankings), // 日排行榜
                _buildCollection(_updatesError, MangaCollectionType.updates), // 最近更新
                _buildCollection('', MangaCollectionType.histories), // 阅读历史
                _buildCollection(_shelvesError, MangaCollectionType.shelves), // 我的书架
                _buildCollection('', MangaCollectionType.favorites), // 本地收藏
                _buildCollection('', MangaCollectionType.downloads), // 下载列表
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
                ),
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
