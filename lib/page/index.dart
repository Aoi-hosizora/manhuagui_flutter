import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/page/category.dart';
import 'package:manhuagui_flutter/page/page/home.dart';
import 'package:manhuagui_flutter/page/page/mine.dart';
import 'package:manhuagui_flutter/page/page/subscribe.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 主页
class IndexPage extends StatefulWidget {
  const IndexPage({Key? key}) : super(key: key);

  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final _controller = TabController(length: 4, vsync: this);
  final _physicsController = CustomScrollPhysicsController();
  var _selectedIndex = 0;
  late final _actions = List.generate(4, (_) => ActionController());
  late final _tabs = [
    Tuple3('首页', Icons.home, HomeSubPage(action: _actions[0], physicsController: _physicsController)),
    Tuple3('分类', Icons.category, CategorySubPage(action: _actions[1], physicsController: _physicsController)),
    Tuple3('订阅', Icons.loyalty, SubscribeSubPage(action: _actions[2], physicsController: _physicsController)),
    Tuple3('我的', Icons.person, MineSubPage(action: _actions[3], physicsController: _physicsController)),
  ];
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    _cancelHandlers.add(EventBusManager.instance.listen<ToShelfRequestedEvent>((ev) => _jumpToPageByEvent(2, ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<ToHistoryRequestedEvent>((ev) => _jumpToPageByEvent(2, ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<ToGenreRequestedEvent>((ev) => _jumpToPageByEvent(1, ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<ToRecentRequestedEvent>((ev) => _jumpToPageByEvent(0, ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<ToRankingRequestedEvent>((ev) => _jumpToPageByEvent(0, ev)));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((h) => h.call());
    _controller.dispose();
    _actions.forEach((a) => a.dispose());
    super.dispose();
  }

  Future<void> _jumpToPageByEvent<T>(int index, T event) async {
    _controller.animateTo(index);
    if (_selectedIndex != index) {
      // need to wait for animating, and then re-fire event (only fire twice in total)
      await Future.delayed(_controller.animationDuration);
      EventBusManager.instance.fire(event);
    }
    _selectedIndex = index;
    if (mounted) setState(() {});
  }

  DateTime? _lastBackPressedTime;

  Future<bool> _onWillPop() async {
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      return true; // close drawer
    }
    var now = DateTime.now();
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
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: DrawerScaffold(
        key: _scaffoldKey,
        drawer: AppDrawer(
          currentSelection: DrawerSelection.home,
        ),
        drawerEdgeDragWidth: null,
        drawerExtraDragTriggers: [
          DrawerDragTrigger(
            top: 0,
            height: MediaQuery.of(context).padding.top + Theme.of(context).appBarTheme.toolbarHeight!,
            dragWidth: MediaQuery.of(context).size.width,
          ),
          DrawerDragTrigger(
            bottom: 0,
            height: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight,
            dragWidth: MediaQuery.of(context).size.width,
          ),
        ],
        physicsController: _physicsController,
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          controller: _controller,
          children: _tabs.map((t) => t.item3).toList(),
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            highlightColor: null,
            splashColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
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
      ),
    );
  }
}
