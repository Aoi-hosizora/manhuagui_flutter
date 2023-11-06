import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/fit_system_screenshot.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/page/view/manga_toc_badge.dart';
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
    this.onManageHistoryPressed,
  }) : super(key: key);

  final int mangaId;
  final String mangaTitle;
  final List<MangaChapterGroup> groups;
  final void Function(int cid) onChapterPressed;
  final void Function(int cid)? onChapterLongPressed;
  final void Function()? onManageHistoryPressed;

  @override
  _MangaTocPageState createState() => _MangaTocPageState();
}

class _MangaTocPageState extends State<MangaTocPage> with FitSystemScreenshotMixin {
  final _listViewKey = GlobalKey();
  final _controller = ScrollController();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
    _cancelHandlers.add(EventBusManager.instance.listen<AppSettingChangedEvent>((_) => mountedSetState(() {})));
    _cancelHandlers.add(EventBusManager.instance.listen<HistoryUpdatedEvent>((ev) => _updateByEvent(historyEvent: ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadUpdatedEvent>((ev) => _updateByEvent(downloadEvent: ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<FootprintUpdatedEvent>((ev) => _updateByEvent(footprintEvent: ev)));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _controller.dispose();
    super.dispose();
  }

  var _loading = true; // initialize to true, fake loading flag
  MangaHistory? _history;
  Map<int, ChapterFootprint>? _footprints;
  DownloadedManga? _downloadEntity;
  List<MangaChapterGroup>? _downloadedChapters;
  var _downloadOnly = false;
  var _columns = 4; // default to four columns

  Future<void> _loadData() async {
    _loading = true;
    if (mounted) setState(() {});

    try {
      await Future.delayed(Duration(milliseconds: 400)); // fake loading
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);
      _footprints = await HistoryDao.getMangaFootprintsSet(username: AuthManager.instance.username, mid: widget.mangaId) ?? {};
      _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId);
      _downloadedChapters = _downloadEntity?.downloadedChapters.toChapterGroup(origin: widget.groups);
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _updateByEvent({HistoryUpdatedEvent? historyEvent, DownloadUpdatedEvent? downloadEvent, FootprintUpdatedEvent? footprintEvent}) async {
    if (historyEvent != null && historyEvent.mangaId == widget.mangaId) {
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);
      if (mounted) setState(() {});
    }
    if (downloadEvent != null && downloadEvent.mangaId == widget.mangaId) {
      _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId);
      _downloadedChapters = _downloadEntity?.downloadedChapters.toChapterGroup(origin: widget.groups);
      if (mounted) setState(() {});
    }
    if (footprintEvent != null && footprintEvent.mangaId == widget.mangaId) {
      _footprints = await HistoryDao.getMangaFootprintsSet(username: AuthManager.instance.username, mid: widget.mangaId) ?? {};
      if (mounted) setState(() {});
    }
  }

  @override
  FitSystemScreenshotData get fitSystemScreenshotData => FitSystemScreenshotData(
        scrollViewKey: _listViewKey,
        scrollController: _controller,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mangaTitle),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: false),
        actions: [
          AppBarActionButton(
            icon: Icon(_downloadOnly ? CustomIcons.eye_download : CustomIcons.eye_menu),
            tooltip: _downloadOnly ? '当前仅显示下载章节' : '当前显示着全部章节',
            onPressed: () => mountedSetState(() => _downloadOnly = !_downloadOnly),
          ),
          PopupMenuButton<dynamic>(
            child: Builder(
              builder: (c) => AppBarActionButton(
                icon: Icon(Icons.more_vert),
                tooltip: '更多选项',
                onPressed: () => c.findAncestorStateOfType<PopupMenuButtonState>()?.showButtonMenu(),
              ),
            ),
            itemBuilder: (_) => [
              if (widget.onManageHistoryPressed != null) ...[
                PopupMenuItem(
                  child: IconTextMenuItem(CustomIcons.history_menu, '管理章节阅读历史'),
                  onTap: () => WidgetsBinding.instance?.addPostFrameCallback(
                    (_) => widget.onManageHistoryPressed?.call(),
                  ),
                ),
                PopupMenuDivider(),
              ],
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
              key: _listViewKey,
              controller: _controller,
              padding: EdgeInsets.zero,
              physics: AlwaysScrollableScrollPhysics(),
              children: [
                MangaTocView(
                  groups: !_downloadOnly ? widget.groups : (_downloadedChapters ?? []),
                  full: true,
                  tocTitle: !_downloadOnly ? '章节列表' : '章节列表 (仅下载)',
                  columns: _columns,
                  highlightedChapters: [_history?.chapterId ?? 0],
                  highlighted2Chapters: [_history?.lastChapterId ?? 0],
                  showHighlight2: AppSetting.instance.ui.showLastHistory,
                  faintedChapters: _footprints?.keys.toList() ?? [],
                  customBadgeBuilder: (cid) => DownloadBadge.fromEntity(
                    entity: _downloadEntity?.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull,
                  ),
                  onChapterPressed: widget.onChapterPressed,
                  onChapterLongPressed: widget.onChapterLongPressed,
                ),
              ],
            ).fitSystemScreenshot(this),
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
