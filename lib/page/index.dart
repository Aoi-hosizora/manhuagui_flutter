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
  final _scaffoldKey = GlobalKey<DrawerScaffoldState>();
  late final _controller = TabController(length: 4, vsync: this);
  final _physicsController = CustomScrollPhysicsController();
  late final _actions = List.generate(4, (_) => ActionController());
  late final _tabs = [
    Tuple3('首页', Icons.home, HomeSubPage(action: _actions[0])),
    Tuple3('分类', Icons.category, CategorySubPage(action: _actions[1])),
    Tuple3('订阅', Icons.loyalty, SubscribeSubPage(action: _actions[2])),
    Tuple3('我的', Icons.person, MineSubPage(action: _actions[3])),
  ];
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    _cancelHandlers.add(EventBusManager.instance.listen<ToRecommendRequestedEvent>((ev) => _jumpToPageByEvent(0, ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<ToShelfRequestedEvent>((ev) => _jumpToPageByEvent(2, ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<ToFavoriteRequestedEvent>((ev) => _jumpToPageByEvent(2, ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<ToHistoryRequestedEvent>((ev) => _jumpToPageByEvent(2, ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<ToRecentRequestedEvent>((ev) => _jumpToPageByEvent(0, ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<ToRankingRequestedEvent>((ev) => _jumpToPageByEvent(0, ev)));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _controller.dispose();
    _actions.forEach((a) => a.dispose());
    super.dispose();
  }

  Future<void> _jumpToPageByEvent(int index, dynamic event) async {
    if (_controller.index != index) {
      _controller.animateTo(index); // jump to target page with animation
      if (mounted) setState(() {}); // set state right after calling animateTo
      await Future.delayed(_controller.animationDuration); // wait for page transition animation
      EventBusManager.instance.fire(event); // refire event for JUST LOADED pages (only fire twice in total)
    }
  }

  DateTime? _lastBackPressedTime;

  Future<bool> _onWillPop() async {
    // call onWillPop for descendant elements
    var scopes = context.findDescendantElementsDFS<WillPopScope>(-1, (element) {
      if (element.widget is! WillPopScope) {
        return null;
      }
      return element.widget as WillPopScope;
    });
    if (scopes.isNotEmpty) {
      scopes.removeAt(0); // remove the first WillPopScope
    }
    for (var s in scopes) {
      var willPop = await s.onWillPop?.call(); // test onWillPop of descendants
      if (willPop != null && willPop == false) {
        return false;
      }
    }

    // close drawer and show snack bar
    if (_scaffoldKey.currentState?.isDrawerOpen == true || _scaffoldKey.currentState?.scaffoldState?.isDrawerOpen == true) {
      _scaffoldKey.currentState?.closeDrawer();
      return false;
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
        physicsController: _physicsController,
        implicitlyOverscrollableScaffold: true,
        body: DefaultScrollPhysics(
          physics: CustomScrollPhysics(controller: _physicsController),
          child: TabBarView(
            physics: NeverScrollableScrollPhysics(),
            controller: _controller,
            children: _tabs.map((t) => t.item3).toList(),
          ),
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            // highlightColor: null,
            // splashColor: Colors.transparent,
            splashFactory: CustomInkSplash.preferredSplashFactory,
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _controller.index,
            items: [
              for (var t in _tabs)
                BottomNavigationBarItem(
                  label: t.item1,
                  icon: Icon(t.item2),
                  tooltip: '',
                ),
            ],
            onTap: (i) {
              if (_controller.index == i) {
                _actions[i].invoke();
              } else {
                _controller.animateTo(i);
                if (mounted) setState(() {});
              }
            },
          ),
        ),
      ),
    );
  }
}
