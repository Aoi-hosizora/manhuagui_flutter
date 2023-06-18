import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/common.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/manga_aud_ranking.dart';
import 'package:manhuagui_flutter/page/view/manga_ranking_line.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 漫画受众排行榜页，展示所给单个 [MangaRanking] 列表信息
class MangaAudRankingPage extends StatefulWidget {
  const MangaAudRankingPage({
    Key? key,
    required this.type,
    required this.rankings,
    required this.rankingDatetime,
    this.remappedQingnianCategory,
    this.remappedShaonvCategory,
  }) : super(key: key);

  final MangaAudRankingType type;
  final List<MangaRanking> rankings;
  final DateTime? rankingDatetime;
  final TinyCategory? remappedQingnianCategory;
  final TinyCategory? remappedShaonvCategory;

  @override
  State<MangaAudRankingPage> createState() => _MangaAudRankingPageState();
}

class _MangaAudRankingPageState extends State<MangaAudRankingPage> {
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
    _cancelHandlers.add(EventBusManager.instance.listen<AppSettingChangedEvent>((_) => mountedSetState(() {})));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _controller.dispose();
    _flagStorage.dispose();
    super.dispose();
  }

  late final _flagStorage = MangaCornerFlagStorage(stateSetter: () => mountedSetState(() {}));
  final _histories = <int, MangaHistory?>{};

  Future<void> _loadData() async {
    _flagStorage.queryAndStoreFlags(mangaIds: widget.rankings.map((e) => e.mid)).then((_) => mountedSetState(() {}));
    for (var item in widget.rankings) {
      _histories[item.mid] = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: item.mid);
    }
    if (mounted) setState(() {});
  }

  String _typeToString(MangaAudRankingType type) {
    return type == MangaAudRankingType.all
        ? '全部漫画'
        : type == MangaAudRankingType.qingnian
            ? '${(widget.remappedQingnianCategory ?? qingnianAgeCategory).title}漫画'
            : '${(widget.remappedShaonvCategory ?? shaonvAgeCategory).title}漫画';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_typeToString(widget.type)} 日排行榜'),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: false),
      ),
      drawer: AppDrawer(
        currentSelection: DrawerSelection.none,
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: RefreshableDataView<MangaRanking>(
        style: !AppSetting.instance.ui.showTwoColumns ? UpdatableDataViewStyle.listView : UpdatableDataViewStyle.gridView,
        data: widget.rankings,
        getData: null,
        scrollController: _controller,
        setting: UpdatableDataViewSetting(
          padding: EdgeInsets.symmetric(vertical: 0),
          interactiveScrollbar: true,
          scrollbarMainAxisMargin: 2,
          scrollbarCrossAxisMargin: 2,
          placeholderSetting: PlaceholderSetting().copyWithChinese(),
          onPlaceholderStateChanged: (_, __) => _fabController.hide(),
          refreshFirst: false /* not to refresh first for aud ranking list */,
          clearWhenRefresh: false,
          clearWhenError: false,
        ),
        separator: Divider(height: 0, thickness: 1),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 0.0,
          mainAxisSpacing: 0.0,
          childAspectRatio: GeneralLineView.getChildAspectRatioForTwoColumns(context),
        ),
        itemBuilder: (c, _, item) => MangaRankingLineView(
          manga: item,
          history: _histories[item.mid],
          flags: _flagStorage.getFlags(mangaId: item.mid),
          twoColumns: AppSetting.instance.ui.showTwoColumns,
          highlightRecent: AppSetting.instance.ui.highlightRecentMangas,
        ),
        extra: UpdatableDataViewExtraWidgets(
          outerTopWidgets: [
            ListHintView.textText(
              leftText: '漫画受众排行榜・${_typeToString(widget.type)}',
              rightText: '更新于 ${formatDatetimeAndDuration(widget.rankingDatetime ?? DateTime.now(), FormatPattern.date)}',
            ),
          ],
        ),
      ),
      floatingActionButton: ScrollAnimatedFab(
        controller: _fabController,
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
