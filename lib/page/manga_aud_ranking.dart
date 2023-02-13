import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/common.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/homepage_column.dart';
import 'package:manhuagui_flutter/page/view/manga_aud_ranking.dart';
import 'package:manhuagui_flutter/page/view/manga_ranking_line.dart';

/// 漫画受众排行榜页，展示所给单个 [MangaRanking] 列表信息
class MangaAudRankingPage extends StatefulWidget {
  const MangaAudRankingPage({
    Key? key,
    required this.type,
    required this.rankings,
  }) : super(key: key);

  final MangaAudRankingType type;
  final List<MangaRanking> rankings;

  @override
  State<MangaAudRankingPage> createState() => _MangaAudRankingPageState();
}

class _MangaAudRankingPageState extends State<MangaAudRankingPage> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _controller.dispose();
    _flagStorage.dispose();
    super.dispose();
  }

  late final _flagStorage = MangaCornerFlagStorage(stateSetter: () => mountedSetState(() {}));

  Future<void> _loadData() async {
    _flagStorage.queryAndStoreFlags(mangaIds: widget.rankings.map((e) => e.mid)).then((_) => mountedSetState(() {}));
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
              title: '日排行榜 - ' +
                  (widget.type == MangaAudRankingType.all
                      ? '全部漫画'
                      : widget.type == MangaAudRankingType.qingnian
                          ? '青年漫画'
                          : widget.type == MangaAudRankingType.shaonian
                              ? '少年漫画'
                              : '少女漫画'),
              icon: Icons.emoji_events,
              rightText: '更新于 ${formatDatetimeAndDuration(DateTime.now(), FormatPattern.date)}',
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var manga in widget.rankings) ...[
                    if (manga.mid != widget.rankings.first.mid) //
                      Divider(height: 0, thickness: 1),
                    MangaRankingLineView(
                      manga: manga,
                      flags: _flagStorage.getFlags(mangaId: manga.mid),
                    ),
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
