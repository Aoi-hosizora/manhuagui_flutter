import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/page/page/category.dart';
import 'package:manhuagui_flutter/page/page/home.dart';
import 'package:manhuagui_flutter/page/page/mine.dart';
import 'package:manhuagui_flutter/page/page/subscribe.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:permission_handler/permission_handler.dart';

/// 主页
class IndexPage extends StatefulWidget {
  const IndexPage({Key? key}) : super(key: key);

  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> with SingleTickerProviderStateMixin {
  late final _controller = TabController(length: 4, vsync: this);
  var _selectedIndex = 0;
  late final _actions = List.generate(4, (_) => ActionController());
  late final _tabs = [
    Tuple3('首页', Icons.home, HomeSubPage(action: _actions[0])),
    Tuple3('分类', Icons.category, CategorySubPage(action: _actions[1])),
    Tuple3('订阅', Icons.notifications, SubscribeSubPage(action: _actions[2])),
    Tuple3('我的', Icons.person, MineSubPage(action: _actions[3])),
  ];
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      var ok = await _checkPermission();
      if (!ok) {
        Fluttertoast.showToast(msg: '权限授予失败，Manhuagui 即将退出');
        SystemNavigator.pop();
      }
    });
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      print('check');
      var r = await AuthManager.instance.check();
      print('check 2');
      print(r);
      if (!r.logined && r.error != null) {
        Fluttertoast.showToast(msg: '无法检查登录状态：${r.error!.text}');
      }
    });
    _cancelHandlers.add(EventBusManager.instance.listen<ToShelfRequestedEvent>((_) {
      _controller.animateTo(2);
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<ToGenreRequestedEvent>((_) {
      _controller.animateTo(1);
    }));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((h) => h.call());
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

  DateTime? _lastBackPressedTime;

  Future<bool> _onWillPop() {
    DateTime now = DateTime.now();
    if (_lastBackPressedTime == null || now.difference(_lastBackPressedTime!) > Duration(seconds: 2)) {
      _lastBackPressedTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('再按一次退出'),
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: '退出',
            onPressed: () => SystemNavigator.pop(),
          ),
        ),
      );
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          controller: _controller,
          children: _tabs.map((t) => t.item3).toList(),
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
              _actions[_selectedIndex].invoke();
            } else {
              _controller.animateTo(index);
              _selectedIndex = index;
              if (mounted) setState(() {});
            }
          },
        ),
      ),
    );
  }
}
