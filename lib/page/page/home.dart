import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/page/overall.dart';
import 'package:manhuagui_flutter/page/page/ranking.dart';
import 'package:manhuagui_flutter/page/page/recent.dart';
import 'package:manhuagui_flutter/page/page/recommend.dart';
import 'package:manhuagui_flutter/page/search.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 首页
class HomeSubPage extends StatefulWidget {
  const HomeSubPage({
    Key? key,
    this.action,
  }) : super(key: key);

  final ActionController? action;

  @override
  _HomeSubPageState createState() => _HomeSubPageState();
}

class _HomeSubPageState extends State<HomeSubPage> with SingleTickerProviderStateMixin {
  late final _controller = TabController(length: _tabs.length, vsync: this);
  var _selectedIndex = 0;
  late final _actions = List.generate(4, (_) => ActionController());
  late final _tabs = [
    Tuple2('推荐', RecommendSubPage(action: _actions[0])),
    Tuple2('更新', RecentSubPage(action: _actions[1])),
    Tuple2('全部', OverallSubPage(action: _actions[2])),
    Tuple2('排行', RankingSubPage(action: _actions[3])),
  ];
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _actions[_controller.index].invoke());
    _cancelHandlers.add(EventBusManager.instance.listen<ToRecentRequestedEvent>((_) {
      _controller.animateTo(1);
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<ToRankingRequestedEvent>((_) {
      _controller.animateTo(3);
    }));
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    _cancelHandlers.forEach((h) => h.call());
    _controller.dispose();
    _actions.forEach((a) => a.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TabBar(
          controller: _controller,
          isScrollable: true,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _tabs
              .map(
                (t) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    t.item1,
                    style: Theme.of(context).textTheme.subtitle1?.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                  ),
                ),
              )
              .toList(),
          onTap: (idx) {
            if (idx == _selectedIndex) {
              _actions[idx].invoke();
            } else {
              _selectedIndex = idx;
            }
          },
        ),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: true),
        actions: [
          AppBarActionButton(
            icon: Icon(Icons.search),
            tooltip: '搜索漫画',
            onPressed: () => Navigator.of(context).push(
              CustomPageRoute(
                context: context,
                builder: (c) => SearchPage(),
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _controller,
        physics: DefaultScrollPhysics.of(context),
        children: _tabs.map((t) => t.item2).toList(),
      ),
    );
  }
}
