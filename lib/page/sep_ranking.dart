import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/page/home_ranking.dart';
import 'package:manhuagui_flutter/page/search.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';

/// 漫画排行榜页，即 Separate [RankingSubPage]
class SepRankingPage extends StatefulWidget {
  const SepRankingPage({
    Key? key,
  }) : super(key: key);

  @override
  _SepRankingPageState createState() => _SepRankingPageState();
}

class _SepRankingPageState extends State<SepRankingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('漫画排行榜'),
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
        currentSelection: DrawerSelection.ranking,
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: RankingSubPage(),
    );
  }
}
