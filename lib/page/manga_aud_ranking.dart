import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/common.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/homepage_column.dart';
import 'package:manhuagui_flutter/page/view/manga_aud_ranking.dart';

/// 漫画受众排行榜页，展示所给单个 [MangaRanking] 列表信息
class MangaAudRankingPage extends StatefulWidget {
  const MangaAudRankingPage({
    Key? key,
    required this.columnTitle,
    required this.rankings,
  }) : super(key: key);

  final String columnTitle;
  final List<MangaRanking> rankings;

  @override
  State<MangaAudRankingPage> createState() => _MangaAudRankingPageState();
}

class _MangaAudRankingPageState extends State<MangaAudRankingPage> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('漫画受众排行榜'),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: false),
      ),
      drawer: AppDrawer(
        currentSelection: DrawerSelection.none,
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: ExtendedScrollbar(
        controller: _controller,
        interactive: true,
        mainAxisMargin: 2,
        crossAxisMargin: 2,
        child: ListView(
          controller: _controller,
          padding: EdgeInsets.zero,
          physics: AlwaysScrollableScrollPhysics(),
          children: [
            HomepageColumnView(
              title: widget.columnTitle,
              icon: Icons.emoji_events,
              rightText: '更新于 ${formatDatetimeAndDuration(DateTime.now(), FormatPattern.date)}',
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var manga in widget.rankings) ...[
                    if (manga.mid != widget.rankings.first.mid) //
                      Divider(height: 0, thickness: 1),
                    MangaAudRankingLineView(manga: manga),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScrollAnimatedFab(
        scrollController: _controller,
        condition: ScrollAnimatedCondition.direction,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: null,
          onPressed: () => _controller.scrollToTop(),
        ),
      ),
    );
  }
}
