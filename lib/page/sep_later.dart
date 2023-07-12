import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/page/subscribe_later.dart';
import 'package:manhuagui_flutter/page/search.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 稍后阅读页，即 Separate [LaterSubPage]
class SepLaterPage extends StatefulWidget {
  const SepLaterPage({
    Key? key,
  }) : super(key: key);

  @override
  _SepLaterPageState createState() => _SepLaterPageState();
}

class _SepLaterPageState extends State<SepLaterPage> {
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
            icon: Icon(MdiIcons.calendarFilter),
            tooltip: '按日期搜索',
            onPressed: () => _action.invoke('date'),
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
        currentSelection: DrawerSelection.later,
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: LaterSubPage(
        action: _action,
        isSepPage: true,
      ),
    );
  }
}
