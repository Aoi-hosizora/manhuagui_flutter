import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/page/author.dart';
import 'package:manhuagui_flutter/page/page/genre.dart';
import 'package:manhuagui_flutter/page/search.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';

/// 分类
class CategorySubPage extends StatefulWidget {
  const CategorySubPage({
    Key? key,
    this.action,
  }) : super(key: key);

  final ActionController? action;

  @override
  _CategorySubPageState createState() => _CategorySubPageState();
}

class _CategorySubPageState extends State<CategorySubPage> with SingleTickerProviderStateMixin {
  late final _controller = TabController(length: _tabs.length, vsync: this);
  var _selectedIndex = 0;
  late final _actions = List.generate(2, (_) => ActionController());
  late final _tabs = [
    Tuple2('类别', GenreSubPage(action: _actions[0])),
    Tuple2('漫画作者', AuthorSubPage(action: _actions[1])),
  ];

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _actions[_controller.index].invoke());
  }

  @override
  void dispose() {
    widget.action?.removeAction();
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
        leading: AppBarActionButton.leading(context: context),
        actions: [
          AppBarActionButton(
            icon: Icon(Icons.open_in_browser),
            tooltip: '用浏览器打开',
            onPressed: () => launchInBrowser(
              context: context,
              url: WEB_CATEGORY_URL,
            ),
          ),
          AppBarActionButton(
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
