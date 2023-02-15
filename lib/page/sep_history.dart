import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/page/subscribe_history.dart';
import 'package:manhuagui_flutter/page/search.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 阅读历史页，即 Separate [HistorySubPage]
class SepHistoryPage extends StatefulWidget {
  const SepHistoryPage({
    Key? key,
  }) : super(key: key);

  @override
  _SepHistoryPageState createState() => _SepHistoryPageState();
}

class _SepHistoryPageState extends State<SepHistoryPage> {
  final _action = ActionController();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    _cancelHandlers.add(EventBusManager.instance.listen<AppSettingChangedEvent>((_) => mountedSetState(() {})));
  }

  @override
  void dispose() {
    _action.dispose();
    _cancelHandlers.forEach((c) => c.call());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('阅读历史'),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: true),
        actions: [
          AppBarActionButton(
            icon: Icon(Icons.delete),
            tooltip: '清空阅读历史',
            onPressed: () => _action.invoke('clear'),
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
      drawer: AppDrawer(
        currentSelection: DrawerSelection.history,
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: HistorySubPage(
        action: _action,
        isSepPage: true,
      ),
    );
  }
}
