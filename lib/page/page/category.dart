import 'package:flutter/material.dart';
import 'package:flutter_ahlib/util.dart';
import 'package:manhuagui_flutter/page/page/author.dart';
import 'package:manhuagui_flutter/page/page/genre.dart';
import 'package:manhuagui_flutter/page/search.dart';

/// 分类
class CategorySubPage extends StatefulWidget {
  const CategorySubPage({
    Key key,
    this.action,
  }) : super(key: key);

  final ActionController action;

  @override
  _CategorySubPageState createState() => _CategorySubPageState();
}

class _CategorySubPageState extends State<CategorySubPage> with SingleTickerProviderStateMixin {
  TabController _controller;
  var _selectedIndex = 0;
  var _tabs = <String>['类别', '漫画家'];
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
      GenreSubPage(action: _actions[0]),
      AuthorSubPage(action: _actions[1]),
    ];
    widget.action?.addAction('', () => _actions[_controller.index].invoke(''));
    widget.action?.addAction('to_genre', () => _controller.animateTo(0));
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
