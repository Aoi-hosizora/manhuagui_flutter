import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/page/page/category.dart';
import 'package:manhuagui_flutter/page/page/home.dart';
import 'package:manhuagui_flutter/page/page/mine.dart';
import 'package:manhuagui_flutter/page/page/subscribe.dart';
import 'package:permission_handler/permission_handler.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({Key key}) : super(key: key);

  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
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

  @override
  Widget build(BuildContext context) {
    _checkPermission().then((ok) {
      if (!ok) {
        Fluttertoast.showToast(msg: 'Permission denied');
        SystemNavigator.pop();
      }
    });

    return Scaffold(
      body: _pages[_currentIndex],
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
    );
  }
}
