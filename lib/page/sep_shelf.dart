import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/page/subscribe_shelf.dart';
import 'package:manhuagui_flutter/page/search.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 我的书架页，即 Separate [ShelfSubPage]
class SepShelfPage extends StatefulWidget {
  const SepShelfPage({
    Key? key,
  }) : super(key: key);

  @override
  _SepShelfPageState createState() => _SepShelfPageState();
}

class _SepShelfPageState extends State<SepShelfPage> {
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
        title: Text('我的书架'),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: true),
        actions: [
          AppBarActionButton(
            icon: Icon(Icons.sync),
            tooltip: '同步我的书架',
            onPressed: () => _action.invoke('sync'),
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
        currentSelection: DrawerSelection.shelf,
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: ShelfSubPage(
        action: _action,
        isSepPage: true,
      ),
    );
  }
}
