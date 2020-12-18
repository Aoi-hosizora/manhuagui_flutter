import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/page/history.dart';
import 'package:manhuagui_flutter/page/page/shelf.dart';
import 'package:manhuagui_flutter/page/search.dart';

/// 订阅
class SubscribeSubPage extends StatefulWidget {
  const SubscribeSubPage({
    Key key,
    this.action,
  }) : super(key: key);

  final ActionController action;

  @override
  _SubscribeSubPageState createState() => _SubscribeSubPageState();
}

class _SubscribeSubPageState extends State<SubscribeSubPage> with SingleTickerProviderStateMixin {
  TabController _controller;
  var _selectedIndex = 0;
  var _tabs = <String>['书架', '浏览历史'];
  var _actions = <ActionController>[];
  var _pages = <Widget>[];

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: _tabs.length,
      vsync: this,
    );
    _actions = List.generate(_tabs.length, (_) => ActionController());
    _pages = [
      ShelfSubPage(action: _actions[0]),
      HistorySubPage(action: _actions[1]),
    ];
    widget.action?.addAction('', () => _actions[_controller.index].invoke(''));
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
                  child: Text(t),
                ),
              )
              .toList(),
          onTap: (idx) {
            if (idx == _selectedIndex) {
              _actions[idx].invoke('');
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
        children: _pages,
      ),
    );
  }
}
