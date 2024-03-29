import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/page/home_recent.dart';
import 'package:manhuagui_flutter/page/search.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';

/// 最近更新页，即 Separate [RecentSubPage]
class SepRecentPage extends StatefulWidget {
  const SepRecentPage({
    Key? key,
  }) : super(key: key);

  @override
  _SepRecentPageState createState() => _SepRecentPageState();
}

class _SepRecentPageState extends State<SepRecentPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('最近更新'),
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
      drawer: AppDrawer(
        currentSelection: DrawerSelection.recent,
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: RecentSubPage(),
    );
  }
}
