import 'package:flutter/material.dart';
import 'package:flutter_ahlib/util.dart';
import 'package:manhuagui_flutter/page/page/history.dart';
import 'package:manhuagui_flutter/page/page/shelf.dart';
import 'package:manhuagui_flutter/page/search.dart';

/// 订阅
class SubscribeSubPage extends StatefulWidget {
  const SubscribeSubPage({
    Key? key,
    this.action,
  }) : super(key: key);

  final ActionController? action;

  @override
  _SubscribeSubPageState createState() => _SubscribeSubPageState();
}

class _SubscribeSubPageState extends State<SubscribeSubPage> with SingleTickerProviderStateMixin {
  late final _controller = TabController(length: _tabs.length, vsync: this);
  late final _actions = List.generate(_tabs.length, (_) => ActionController());
  var _selectedIndex = 0;
  late final _tabs = [
    Tuple2('书架', ShelfSubPage(action: _actions[0])),
    Tuple2('浏览历史', HistorySubPage(action: _actions[1])),
  ];

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _actions[_controller.index].invoke());
    widget.action?.addAction('to_shelf', () => _controller.animateTo(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    _actions.forEach((a) => a.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: TabBar(
          controller: _controller,
          isScrollable: true,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: Theme.of(context).primaryTextTheme.subtitle1,
          tabs: _tabs
              .map(
                (t) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text(t.item1),
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
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            tooltip: '搜索',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (c) => SearchPage(),
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _controller,
        children: _tabs.map((t) => t.item2).toList(),
      ),
    );
  }
}
