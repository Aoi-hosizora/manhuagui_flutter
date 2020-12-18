import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/page/page/category.dart';
import 'package:manhuagui_flutter/page/page/home.dart';
import 'package:manhuagui_flutter/page/page/mine.dart';
import 'package:manhuagui_flutter/page/page/subscribe.dart';
import 'package:permission_handler/permission_handler.dart';

/// 主页
class IndexPage extends StatefulWidget {
  const IndexPage({Key key}) : super(key: key);

  @override
  _IndexPageState createState() => _IndexPageState();
}

class _PageItem {
  const _PageItem({
    @required this.title,
    @required this.icon,
    @required this.page,
    @required this.action,
  })  : assert(title != null),
        assert(icon != null),
        assert(page != null),
        assert(action != null);

  final String title;
  final IconData icon;
  final Widget page;
  final ActionController action;
}

class _IndexPageState extends State<IndexPage> {
  var _currentIndex = 0;
  var _items = <_PageItem>[];
  var _pages = <Widget>[];
  PageController _controller;
  DateTime _lastBackPressedTime;

  @override
  void initState() {
    super.initState();
    _controller = PageController();

    var homeAction = ActionController();
    var categoryAction = ActionController();
    var subscribeAction = ActionController();
    var mineAction = ActionController();
    _items = [
      _PageItem(title: '首页', icon: Icons.home, page: HomeSubPage(actionController: homeAction), action: homeAction),
      _PageItem(title: '分类', icon: Icons.category, page: CategorySubPage(actionController: categoryAction), action: categoryAction),
      _PageItem(title: '订阅', icon: Icons.notifications, page: SubscribeSubPage(actionController: subscribeAction), action: subscribeAction),
      _PageItem(title: '我的', icon: Icons.person, page: MineSubPage(actionController: mineAction), action: mineAction),
    ];
    _pages = _items.map((item) => item.page).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _checkPermission() async {
    if (!(await Permission.storage.status).isGranted) {
      var r = await Permission.storage.request();
      return r.isGranted;
    }
    return true;
  }

  Future<bool> _onWillPop() async {
    DateTime now = DateTime.now();
    if (_lastBackPressedTime == null || now.difference(_lastBackPressedTime) > Duration(seconds: 2)) {
      _lastBackPressedTime = now;
      Fluttertoast.showToast(msg: '再按一次退出');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    _checkPermission().then((ok) {
      if (!ok) {
        Fluttertoast.showToast(msg: '权限授予失败，退出应用');
        SystemNavigator.pop();
      }
    });

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: PageView.builder(
          physics: NeverScrollableScrollPhysics(),
          controller: _controller,
          itemCount: _items.length,
          itemBuilder: (_, idx) => _pages[idx],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          items: _items
              .map(
                (t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  label: t.title,
                ),
              )
              .toList(),
          onTap: (index) async {
            if (_currentIndex == index) {
              _items[index].action.invoke('');
              return;
            }
            _controller.animateToPage(index, duration: kTabScrollDuration, curve: Curves.ease);

            // var target = index > _currentIndex ? _currentIndex + 1 : _currentIndex - 1;
            // var newPages = <Widget>[]..addAll(_pages);
            // newPages[target] = _pages[index];
            // newPages[index] = _pages[target];
            // _pages = newPages;
            // if (mounted) setState(() {});
            //
            // var result = _controller.animateToPage(target, duration: kTabScrollDuration, curve: Curves.ease);
            // result.then((_) async {
            //   _pages = _items.map((item) => item.page).toList();
            //   if (mounted) setState(() {});
            // });

            _currentIndex = index;
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }
}
