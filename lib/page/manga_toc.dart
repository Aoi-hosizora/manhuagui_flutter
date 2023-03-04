import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 漫画章节列表页，展示所给 [MangaChapterGroup] 信息
class MangaTocPage extends StatefulWidget {
  const MangaTocPage({
    Key? key,
    required this.mangaId,
    required this.mangaTitle,
    required this.groups,
    required this.onChapterPressed,
    this.onChapterLongPressed,
  }) : super(key: key);

  final int mangaId;
  final String mangaTitle;
  final List<MangaChapterGroup> groups;
  final void Function(int cid) onChapterPressed;
  final void Function(int cid)? onChapterLongPressed;

  @override
  _MangaTocPageState createState() => _MangaTocPageState();
}

class _MangaTocPageState extends State<MangaTocPage> {
  final _controller = ScrollController();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
    _cancelHandlers.add(EventBusManager.instance.listen<HistoryUpdatedEvent>((ev) => _updateByEvent(historyEvent: ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadUpdatedEvent>((ev) => _updateByEvent(downloadEvent: ev)));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _controller.dispose();
    super.dispose();
  }

  var _loading = true; // initialize to true, fake loading flag
  MangaHistory? _history;
  DownloadedManga? _downloadEntity;
  var _columns = 4; // default to four columns

  Future<void> _loadData() async {
    _loading = true;
    if (mounted) setState(() {});

    try {
      await Future.delayed(Duration(milliseconds: 400)); // fake loading
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);
      _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId);
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _updateByEvent({HistoryUpdatedEvent? historyEvent, DownloadUpdatedEvent? downloadEvent}) async {
    if (historyEvent != null && historyEvent.mangaId == widget.mangaId) {
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);
      if (mounted) setState(() {});
    }
    if (downloadEvent != null && downloadEvent.mangaId == widget.mangaId) {
      _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mangaTitle),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: false),
        actions: [
          PopupMenuButton(
            child: Builder(
              builder: (c) => AppBarActionButton(
                icon: Icon(Icons.more_vert),
                tooltip: '更多选项',
                onPressed: () => c.findAncestorStateOfType<PopupMenuButtonState>()?.showButtonMenu(),
              ),
            ),
            itemBuilder: (_) => [
              for (var column in [2, 3, 4])
                PopupMenuItem(
                  child: IconTextMenuItem(
                    _columns == column ? Icons.radio_button_on : Icons.radio_button_off,
                    '显示$column列',
                  ),
                  onTap: () => mountedSetState(() => _columns = column),
                ),
            ],
          ),
        ],
      ),
      drawer: AppDrawer(
        currentSelection: DrawerSelection.none,
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: PlaceholderText(
        state: _loading ? PlaceholderState.loading : PlaceholderState.normal,
        setting: PlaceholderSetting().copyWithChinese(),
        childBuilder: (c) => Container(
          color: Colors.white,
          child: ExtendedScrollbar(
            controller: _controller,
            interactive: true,
            mainAxisMargin: 2,
            crossAxisMargin: 2,
            child: ListView(
              controller: _controller,
              padding: EdgeInsets.zero,
              physics: AlwaysScrollableScrollPhysics(),
              children: [
                MangaTocView(
                  groups: widget.groups,
                  full: true,
                  showPageCount: true,
                  columns: _columns,
                  highlightedChapters: [_history?.chapterId ?? 0],
                  customBadgeBuilder: (cid) => DownloadBadge.fromEntity(
                    entity: _downloadEntity?.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull,
                  ),
                  onChapterPressed: widget.onChapterPressed,
                  onChapterLongPressed: widget.onChapterLongPressed,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _loading
          ? null
          : ScrollAnimatedFab(
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
