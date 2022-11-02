import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/download.dart';
import 'package:manhuagui_flutter/page/index.dart';
import 'package:manhuagui_flutter/page/login.dart';
import 'package:manhuagui_flutter/page/setting.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';

enum DrawerSelection {
  none,
  home,
  login,
  download,
  setting,
}

class MyDrawer extends StatefulWidget {
  const MyDrawer({
    Key? key,
    required this.currentDrawerSelection,
  }) : super(key: key);

  final DrawerSelection currentDrawerSelection;

  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  late final _items = <DrawerItem>[
    DrawerPageItem.simple('主页', Icons.home, IndexPage(), DrawerSelection.home, autoCloseWhenTapped: false),
    if (!AuthManager.instance.logined) DrawerPageItem.simple('登录', Icons.login, LoginPage(), DrawerSelection.login),
    DrawerPageItem.simple('下载列表', Icons.download, DownloadPage(), DrawerSelection.download),
    DrawerWidgetItem.simple(Divider(thickness: 1)),
    DrawerActionItem.simple('我的书架', Icons.star_outlined, () => _turnToHomePageTab(ToShelfRequestedEvent()), autoCloseWhenTapped: false),
    DrawerActionItem.simple('浏览历史', Icons.history, () => _turnToHomePageTab(ToHistoryRequestedEvent()), autoCloseWhenTapped: false),
    DrawerActionItem.simple('最近更新', Icons.cached, () => _turnToHomePageTab(ToRecentRequestedEvent()), autoCloseWhenTapped: false),
    DrawerActionItem.simple('漫画排行', Icons.trending_up, () => _turnToHomePageTab(ToRankingRequestedEvent()), autoCloseWhenTapped: false),
    DrawerWidgetItem.simple(Divider(thickness: 1)),
    DrawerActionItem.simple('漫画柜官网', Icons.open_in_browser, () => launchInBrowser(context: context, url: WEB_HOMEPAGE_URL)),
    DrawerPageItem.simple('设置', Icons.settings, SettingPage(), DrawerSelection.setting),
  ];

  Future<void> _popUntilFirst() async {
    Navigator.of(context).pop();
    await Future.delayed(Duration(milliseconds: 246));
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _turnToHomePageTab(dynamic event) async {
    Navigator.of(context).pop();
    await Future.delayed(Duration(milliseconds: 246));
    Navigator.of(context).popUntil((r) => r.isFirst);
    EventBusManager.instance.fire(event);
  }

  void _navigatorTo(DrawerSelection? t, Widget page) async {
    if (t == DrawerSelection.home) {
      await _popUntilFirst();
    } else {
      Navigator.of(context).push(
        CustomPageRoute(
          context: context,
          builder: (_) => page,
        ),
      );
    }
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
                    !AuthManager.instance.logined ? '未登录用户' : AuthManager.instance.username,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
              ],
            ),
          ),
          DrawerListView<DrawerSelection>(
            items: _items,
            currentSelection: widget.currentDrawerSelection,
            onNavigatorTo: _navigatorTo,
          ),
        ],
      ),
    );
  }
}
