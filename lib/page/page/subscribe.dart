import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/download.dart';
import 'package:manhuagui_flutter/page/page/history.dart';
import 'package:manhuagui_flutter/page/page/shelf.dart';
import 'package:manhuagui_flutter/page/search.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

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
  var _selectedIndex = 0;
  late final _actions = List.generate(2, (_) => ActionController());
  late final _tabs = [
    Tuple2('书架', ShelfSubPage(action: _actions[0])),
    Tuple2('浏览历史', HistorySubPage(action: _actions[1])),
  ];
  VoidCallback? _cancelHandler;

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _actions[_controller.index].invoke());
    _cancelHandler = EventBusManager.instance.listen<ToShelfRequestedEvent>((_) {
      _controller.animateTo(0);
    });
    _cancelHandler = EventBusManager.instance.listen<ToHistoryRequestedEvent>((_) {
      _controller.animateTo(1);
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
            icon: Icon(Icons.download),
            tooltip: '查看下载列表',
            onPressed: () => Navigator.of(context).push(
              CustomPageRoute(
                context: context,
                builder: (c) => DownloadPage(),
              ),
            ),
          ),
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
        children: _tabs.map((t) => t.item2).toList(),
      ),
    );
  }
}
