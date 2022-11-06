import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/download.dart';
import 'package:manhuagui_flutter/page/index.dart';
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

class MyDrawer extends StatelessWidget {
  const MyDrawer({
    Key? key,
    required this.currentSelection,
  }) : super(key: key);

  final DrawerSelection currentSelection;

  Future<void> _popUntilFirst(BuildContext context) async {
    await Future.delayed(Duration(milliseconds: 246)); // _kBaseSettleDuration
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _gotoPage(BuildContext context, Widget page, [bool popUntilFirst = false]) async {
    if (popUntilFirst) {
      await _popUntilFirst(context);
    } else {
      Navigator.of(context).push(
        CustomPageRoute(
          context: context,
          builder: (_) => page,
        ),
      );
    }
  }

  Future<void> _gotoHomePageTab(BuildContext context, dynamic event) async {
    await _popUntilFirst(context);
    EventBusManager.instance.fire(event);
  }

  Widget _buildItem(BuildContext context, String text, IconData icon, DrawerSelection? selection, void Function() action) {
    return ListTile(
      title: Text(text),
      leading: Icon(icon),
      selected: selection == null ? false : currentSelection == selection,
      selectedTileColor: Colors.grey[300],
      onTap: () {
        if (Scaffold.of(context).isDrawerOpen) {
          Navigator.of(context).pop();
        }
        action.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final BuildContext c = context;
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
                    !AuthManager.instance.logined ? '未登录用户' : AuthManager.instance.username,
                    style: Theme.of(c).textTheme.subtitle1,
                  ),
                ),
              ],
            ),
          ),
          _buildItem(c, '主页', Icons.home, DrawerSelection.home, () => _gotoPage(c, IndexPage(), true)),
          if (!AuthManager.instance.logined) _buildItem(c, '登录', Icons.login, null, () => _gotoPage(c, LoginPage())),
          _buildItem(c, '搜索漫画', Icons.search, DrawerSelection.search, () => _gotoPage(c, SearchPage())),
          _buildItem(c, '下载列表', Icons.download, DrawerSelection.download, () => _gotoPage(c, DownloadPage())),
          Divider(),
          _buildItem(c, '我的书架', Icons.star_outlined, null, () => _gotoHomePageTab(c, ToShelfRequestedEvent())),
          _buildItem(c, '浏览历史', Icons.history, null, () => _gotoHomePageTab(c, ToHistoryRequestedEvent())),
          _buildItem(c, '最近更新', Icons.cached, null, () => _gotoHomePageTab(c, ToRecentRequestedEvent())),
          _buildItem(c, '漫画排行', Icons.trending_up, null, () => _gotoHomePageTab(c, ToRankingRequestedEvent())),
          Divider(),
          _buildItem(c, '漫画柜官网', Icons.open_in_browser, null, () => launchInBrowser(context: c, url: WEB_HOMEPAGE_URL)),
          _buildItem(c, '设置', Icons.settings, DrawerSelection.setting, () => _gotoPage(c, SettingPage())),
        ],
      ),
    );
  }
}
