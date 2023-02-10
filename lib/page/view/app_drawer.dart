import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/download.dart';
import 'package:manhuagui_flutter/page/login.dart';
import 'package:manhuagui_flutter/page/message.dart';
import 'package:manhuagui_flutter/page/search.dart';
import 'package:manhuagui_flutter/page/sep_favorite.dart';
import 'package:manhuagui_flutter/page/sep_history.dart';
import 'package:manhuagui_flutter/page/sep_ranking.dart';
import 'package:manhuagui_flutter/page/sep_recent.dart';
import 'package:manhuagui_flutter/page/sep_shelf.dart';
import 'package:manhuagui_flutter/page/setting.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

enum DrawerSelection {
  none,
  // none => MangaPage / MangaTocPage / CommentsPage / DownloadMangaPage / MangaShelfCachePage / FavoriteAllPage
  //         AuthorPage / FavoriteAuthorPage / MangaGroupPage / MangaAudRankingPage / SepGenrePage

  home, // IndexPage
  search, // SearchPage

  shelf, // ShelfPage
  favorite, // FavoritePage
  history, // HistoryPage
  download, // DownloadPage
  recent, // RecentPage
  ranking, // RankingPage

  message, // MessagePage
  setting, // SettingPage
}

extension DrawerSelectionExtension on DrawerSelection {
  bool canBeReplaced() {
    // only list page can be replaced
    return this == DrawerSelection.shelf || //
        this == DrawerSelection.favorite ||
        this == DrawerSelection.history ||
        this == DrawerSelection.download ||
        this == DrawerSelection.recent ||
        this == DrawerSelection.ranking;
  }
}

class AppDrawer extends StatefulWidget {
  const AppDrawer({
    Key? key,
    required this.currentSelection,
  }) : super(key: key);

  final DrawerSelection currentSelection;

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _cancelHandlers = <VoidCallback>[];
  late var _routeTheme = CustomPageRouteTheme.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _cancelHandlers.add(AuthManager.instance.listen((_) => mountedSetState(() {})));
    });
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    super.dispose();
  }

  Future<void> _popUntilFirst() async {
    await Future.delayed(kDrawerBaseSettleDuration);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _gotoPage(Widget page, {bool canReplace = false}) {
    if (widget.currentSelection != DrawerSelection.home) {
      _navigateToPage(page, canReplace: canReplace);
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
      } else {
        _navigateToPage(page, canReplace: canReplace);
      }
    }
  }

  void _navigateToPage(Widget page, {bool canReplace = false}) {
    var isFirst = false;
    Navigator.of(context).popUntil((route) {
      isFirst = route.isFirst;
      return true;
    });

    var route = CustomPageRoute(
      context: null,
      builder: (_) => page,
      transitionDuration: _routeTheme?.transitionDuration,
      reverseTransitionDuration: _routeTheme?.reverseTransitionDuration,
      barrierColor: _routeTheme?.barrierColor,
      barrierCurve: _routeTheme?.barrierCurve,
      disableCanTransitionTo: _routeTheme?.disableCanTransitionTo,
      disableCanTransitionFrom: _routeTheme?.disableCanTransitionFrom,
      transitionsBuilder: _routeTheme?.transitionsBuilder,
    );
    if (!isFirst && canReplace && widget.currentSelection.canBeReplaced()) {
      Navigator.of(context).pushReplacement(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  Widget _buildItem(String text, IconData icon, DrawerSelection? selection, void Function() action) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.copyWith(
              bodyText1: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 16),
            ),
      ),
      child: ListTile(
        title: Text(text),
        leading: Icon(icon),
        selected: selection == null ? false : widget.currentSelection == selection,
        selectedTileColor: Colors.grey[300],
        onTap: () {
          if (widget.currentSelection == selection) {
            return;
          }
          _routeTheme = CustomPageRouteTheme.of(context); // get theme data before pop
          if (Scaffold.maybeOf(context)?.isDrawerOpen == true || DrawerScaffold.of(context)?.isDrawerOpen == true) {
            Navigator.of(context).pop();
          }
          action.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.4, 0.6, 1],
                colors: [
                  Colors.blue[100]!,
                  Colors.orange[100]!,
                  Colors.orange[100]!,
                  Colors.purple[100]!,
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey[600]!,
                          blurRadius: 5,
                          spreadRadius: -9,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      '${ASSETS_PREFIX}logo_xxhdpi.png',
                      height: 80,
                      width: 80,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Text(
                    AuthManager.instance.loading
                        ? '获取登录状态中...'
                        : !AuthManager.instance.logined
                            ? '未登录用户'
                            : AuthManager.instance.username,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
              ],
            ),
          ),
          _buildItem('主页', Icons.home, DrawerSelection.home, () => _popUntilFirst()),
          if (!AuthManager.instance.loading && !AuthManager.instance.logined) _buildItem('登录', Icons.login, null, () => _gotoPage(LoginPage())),
          _buildItem('搜索漫画', Icons.search, DrawerSelection.search, () => _gotoPage(SearchPage())),
          Divider(thickness: 1),
          _buildItem('我的书架', MdiIcons.bookshelf, DrawerSelection.shelf, () => _gotoPage(SepShelfPage(), canReplace: true)),
          _buildItem('本地收藏', MdiIcons.bookmarkBoxMultipleOutline, DrawerSelection.favorite, () => _gotoPage(SepFavoritePage(), canReplace: true)),
          _buildItem('阅读历史', Icons.history, DrawerSelection.history, () => _gotoPage(SepHistoryPage(), canReplace: true)),
          _buildItem('下载列表', Icons.download, DrawerSelection.download, () => _gotoPage(DownloadPage(), canReplace: true)),
          _buildItem('最近更新', Icons.cached, DrawerSelection.recent, () => _gotoPage(SepRecentPage(), canReplace: true)),
          _buildItem('漫画排行', Icons.trending_up, DrawerSelection.ranking, () => _gotoPage(SepRankingPage(), canReplace: true)),
          Divider(thickness: 1),
          _buildItem('漫画柜官网', Icons.open_in_browser, null, () => launchInBrowser(context: context, url: WEB_HOMEPAGE_URL)),
          _buildItem('应用消息', Icons.notifications, DrawerSelection.message, () => _gotoPage(MessagePage())),
          _buildItem('设置', Icons.settings, DrawerSelection.setting, () => _gotoPage(SettingPage())),
        ],
      ),
    );
  }
}
