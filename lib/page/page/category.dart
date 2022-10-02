import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/page/author.dart';
import 'package:manhuagui_flutter/page/page/genre.dart';
import 'package:manhuagui_flutter/page/search.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

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
  late final _actions = List.generate(_tabs.length, (_) => ActionController());
  late final _tabs = [
    Tuple2('类别', GenreSubPage(action: _actions[0])),
    Tuple2('漫画作者', AuthorSubPage(action: _actions[1])),
  ];
  VoidCallback? _cancelHandler;

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _actions[_controller.index].invoke());
    _cancelHandler = EventBusManager.instance.listen<ToGenreRequestedEvent>((_) {
      _controller.animateTo(0);
    });
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    _cancelHandler?.call();
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
