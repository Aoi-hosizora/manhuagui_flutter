import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/page/page/recent.dart';
import 'package:manhuagui_flutter/page/page/recommend.dart';

/// 首页
class HomeSubPage extends StatefulWidget {
  const HomeSubPage({Key key}) : super(key: key);

  @override
  _HomeSubPageState createState() => _HomeSubPageState();
}

class _HomeSubPageState extends State<HomeSubPage> with SingleTickerProviderStateMixin {
  TabController _controller;
  var _tabs = <String>['推荐', '更新'];
  var _pages = <Widget>[
    RecommendSubPage(),
    RecentSubPage(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: _tabs.length,
      vsync: this,
    );
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
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_browser),
            tooltip: '打开浏览器',
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.search),
            tooltip: '搜索',
            onPressed: () {},
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
