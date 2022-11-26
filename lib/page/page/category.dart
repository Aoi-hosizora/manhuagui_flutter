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
  late final _actions = List.generate(2, (_) => ActionController());
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
    _cancelHandler?.call();
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
        physics: DefaultCustomScrollPhysics.of(context),
        children: _tabs.map((t) => t.item2).toList(),
      ),
    );
  }
}
