import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/download.dart';
import 'package:manhuagui_flutter/page/login.dart';
import 'package:manhuagui_flutter/page/search.dart';
import 'package:manhuagui_flutter/page/setting.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';

enum DrawerSelection {
  none, // MangaPage / AuthorPage / DownloadTocPage
  home, // IndexPage
  search, // SearchPage
  download, // DownloadPage
  setting, // SettingPage
}

class MyDrawer extends StatefulWidget {
  const MyDrawer({
    Key? key,
    required this.currentSelection,
  }) : super(key: key);

  final DrawerSelection currentSelection;

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  VoidCallback? _cancelHandler;
  late CustomPageRouteThemeData? _routeTheme = CustomPageRouteTheme.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _cancelHandler = AuthManager.instance.listen(null, (_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _cancelHandler?.call();
    super.dispose();
  }

  void _gotoPage(Widget page) async {
    Navigator.of(context).push(
      CustomPageRoute(
        context: null,
        builder: (_) => page,
        transitionDuration: _routeTheme?.transitionDuration,
        reverseTransitionDuration: _routeTheme?.reverseTransitionDuration,
        barrierColor: _routeTheme?.barrierColor,
        barrierCurve: _routeTheme?.barrierCurve,
        disableCanTransitionTo: _routeTheme?.disableCanTransitionTo,
        disableCanTransitionFrom: _routeTheme?.disableCanTransitionFrom,
        transitionsBuilder: _routeTheme?.transitionsBuilder,
      ),
    );
  }

  Future<void> _popUntilFirst() async {
    await Future.delayed(kDrawerBaseSettleDuration);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _gotoHomePageTab(dynamic event) async {
    await _popUntilFirst();
    EventBusManager.instance.fire(event);
  }

  Widget _buildItem(String text, IconData icon, DrawerSelection? selection, void Function() action) {
    return ListTile(
      title: Text(text),
      leading: Icon(icon),
      selected: selection == null ? false : widget.currentSelection == selection,
      selectedTileColor: Colors.grey[300],
      onTap: () {
        if (widget.currentSelection == selection) {
          return;
        }
        _routeTheme = CustomPageRouteTheme.of(context); // get theme data before pop
        if (Scaffold.of(context).isDrawerOpen) {
          Navigator.of(context).pop();
        }
        action.call();
      },
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
                      '${ASSETS_PREFIX}ic_launcher_xxhdpi.png',
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
          _buildItem('下载列表', Icons.download, DrawerSelection.download, () => _gotoPage(DownloadPage())),
          Divider(thickness: 1),
          _buildItem('我的书架', Icons.star_outlined, null, () => _gotoHomePageTab(ToShelfRequestedEvent())),
          _buildItem('浏览历史', Icons.history, null, () => _gotoHomePageTab(ToHistoryRequestedEvent())),
          _buildItem('最近更新', Icons.cached, null, () => _gotoHomePageTab(ToRecentRequestedEvent())),
          _buildItem('漫画排行', Icons.trending_up, null, () => _gotoHomePageTab(ToRankingRequestedEvent())),
          Divider(thickness: 1),
          _buildItem('漫画柜官网', Icons.open_in_browser, null, () => launchInBrowser(context: context, url: WEB_HOMEPAGE_URL)),
          _buildItem('设置', Icons.settings, DrawerSelection.setting, () => _gotoPage(SettingPage())),
        ],
      ),
    );
  }
}
