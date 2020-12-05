import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/page/page/category.dart';
import 'package:manhuagui_flutter/page/page/home.dart';
import 'package:manhuagui_flutter/page/page/mine.dart';
import 'package:manhuagui_flutter/page/page/subscribe.dart';
import 'package:manhuagui_flutter/page/view/lazy_indexed_stack.dart';
import 'package:permission_handler/permission_handler.dart';

/// 主页
class IndexPage extends StatefulWidget {
  const IndexPage({Key key}) : super(key: key);

  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  DateTime _lastBackPressedTime;
  var _currentIndex = 0;
  var _items = <Tuple2<IconData, String>>[
    Tuple2(Icons.home, '首页'),
    Tuple2(Icons.category, '分类'),
    Tuple2(Icons.notifications, '订阅'),
    Tuple2(Icons.person, '我的'),
  ];
  var _pages = <Widget>[
    HomeSubPage(),
    CategorySubPage(),
    SubscribeSubPage(),
    MineSubPage(),
  ];

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
        body: LazyIndexedStack(
          index: _currentIndex,
          itemCount: _pages.length,
          itemBuilder: (_, i) => _pages[i],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          items: _items
              .map(
                (t) => BottomNavigationBarItem(
                  icon: Icon(t.item1),
                  label: t.item2,
                ),
              )
              .toList(),
          onTap: (index) {
            _currentIndex = index;
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }
}
