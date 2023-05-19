import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/page/category_author.dart';
import 'package:manhuagui_flutter/page/page/category_manga.dart';
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
  late final _controller = TabController(length: 2, vsync: this);
  late final _keys = List.generate(2, (_) => GlobalKey<State<StatefulWidget>>());
  late final _actions = List.generate(2, (_) => ActionController());
  late final _tabs = [
    Tuple2('漫画类别', MangaCategorySubPage(key: _keys[0], action: _actions[0])),
    Tuple2('作者类别', AuthorCategorySubPage(key: _keys[1], action: _actions[1])),
  ];
  var _currentPageIndex = 0; // for app bar actions only
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _actions[_controller.index].invoke());
    _actions[0].addAction('updateSubPage', () => mountedSetState(() {})); // for manga category page
    _cancelHandlers.add(EventBusManager.instance.listen<AppSettingChangedEvent>((_) {
      _keys.where((k) => k.currentState?.mounted == true).forEach((k) => k.currentState?.setState(() {}));
      if (mounted) setState(() {});
    }));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
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
          tabs: [
            for (var t in _tabs)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  t.item1,
                  style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.white, fontSize: 16),
                ),
              ),
          ],
          onTap: (idx) {
            if (!_controller.indexIsChanging) {
              _actions[idx].invoke();
            }
          },
        ),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: true),
        actions: [
          if (_currentPageIndex == 0 && _actions[0].invoke('ifNeedBack') == true)
            AppBarActionButton(
              key: ValueKey('CategorySubPage_AppBarActionButton_Back'),
              icon: Icon(Icons.apps),
              tooltip: '返回类别列表',
              onPressed: () => _actions[0].invoke('back'),
            ),
          if (_currentPageIndex == 1)
            AppBarActionButton(
              key: ValueKey('CategorySubPage_AppBarActionButton_Find'),
              icon: Icon(Icons.person_search),
              tooltip: '寻找作者',
              onPressed: () => _actions[1].invoke('find'),
            ),
          AppBarActionButton(
            key: ValueKey('CategorySubPage_AppBarActionButton_Search'),
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
      body: PageChangedListener(
        callPageChangedAtEnd: false,
        onPageChanged: (i) {
          if (!_controller.indexIsChanging /* for `swipe manually` */ || i == _controller.index /* for `select tabBar` */) {
            _currentPageIndex = i;
            if (mounted) setState(() {});
          }
        },
        child: TabBarView(
          controller: _controller,
          physics: DefaultScrollPhysics.of(context),
          children: _tabs.map((t) => t.item2).toList(),
        ),
      ),
    );
  }
}
