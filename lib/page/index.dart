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

class _IndexPageState extends State<IndexPage> {
  PageController _controller;
  var _selectedIndex = 0;
  DateTime _lastBackPressedTime;
  var _tabs = <Tuple2<String, IconData>>[
    Tuple2('首页', Icons.home),
    Tuple2('分类', Icons.category),
    Tuple2('订阅', Icons.notifications),
    Tuple2('我的', Icons.person),
  ];
  var _actions = <ActionController>[];
  var _pages = <Widget>[];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _actions = List.generate(_tabs.length, (_) => ActionController());
    _pages = [
      HomeSubPage(action: _actions[0]),
      CategorySubPage(action: _actions[1]),
      SubscribeSubPage(action: _actions[2]),
      MineSubPage(action: _actions[3]),
    ];
    _actions[0].addAction('to_shelf', () {
      _controller.animateToPage(2, duration: kTabScrollDuration, curve: Curves.easeOutQuad);
      _actions[2].invoke('to_shelf');
    });
    _actions[0].addAction('to_genre', () {
      _controller.animateToPage(1, duration: kTabScrollDuration, curve: Curves.easeOutQuad);
      _actions[1].invoke('to_genre');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _actions.forEach((a) => a.dispose());
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
          onPageChanged: (index) {
            _selectedIndex = index;
            if (mounted) setState(() {});
          },
          itemCount: _tabs.length,
          itemBuilder: (_, idx) => _pages[idx],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          items: _tabs
              .map(
                (t) => BottomNavigationBarItem(
                  label: t.item1,
                  icon: Icon(t.item2),
                ),
              )
              .toList(),
          onTap: (index) async {
            if (_selectedIndex == index) {
              _actions[_selectedIndex].invoke('');
            } else {
              _controller.animateToPage(index, duration: kTabScrollDuration, curve: Curves.easeOutQuad);
              if (mounted) setState(() {});
            }
          },
        ),
      ),
    );
  }
}
