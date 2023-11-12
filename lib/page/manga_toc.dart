import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/dlg/manga_dialog.dart';
import 'package:manhuagui_flutter/page/manga_viewer.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/fit_system_screenshot.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/page/view/manga_toc_badge.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/db/later_manga.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 漫画章节列表页，展示所给 [MangaChapterGroup] 信息
class MangaTocPage extends StatefulWidget {
  const MangaTocPage({
    Key? key,
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.chapterNeededData,
    required this.groups,
    this.showAppDrawer = true,
    required this.onChapterPressed,
    this.onManageHistoryPressed,
    this.canOperateHistory,
    this.toSwitchChapter,
    this.navigateWrapper,
  }) : super(key: key);

  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final MangaChapterNeededData chapterNeededData;
  final List<MangaChapterGroup> groups;
  final bool showAppDrawer;
  final void Function(int cid) onChapterPressed;
  final void Function()? onManageHistoryPressed;
  final bool Function(int cid)? canOperateHistory;
  final void Function(int cid)? toSwitchChapter;
  final NavigateWrapper? navigateWrapper;

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
    _cancelHandlers.add(EventBusManager.instance.listen<LaterChapterUpdatedEvent>((ev) => _updateByEvent(laterChapterEvent: ev)));
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
  Map<int, LaterChapter>? _laterChapters;
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
      _laterChapters = await LaterMangaDao.getLaterChaptersSet(username: AuthManager.instance.username, mid: widget.mangaId) ?? {};
      _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId);
      _downloadedChapters = _downloadEntity?.downloadedChapters.toChapterGroup(origin: widget.groups);
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _updateByEvent({
    HistoryUpdatedEvent? historyEvent,
    DownloadUpdatedEvent? downloadEvent,
    FootprintUpdatedEvent? footprintEvent,
    LaterChapterUpdatedEvent? laterChapterEvent,
  }) async {
    if (historyEvent != null && historyEvent.mangaId == widget.mangaId) {
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);
      if (mounted) setState(() {});
    }
    if (downloadEvent != null && downloadEvent.mangaId == widget.mangaId) {
      _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId);
      _downloadedChapters = _downloadEntity?.downloadedChapters.toChapterGroup(origin: widget.groups);
      if (mounted) setState(() {});
    }
    if (footprintEvent != null && footprintEvent.mangaId == widget.mangaId && !footprintEvent.fromMangaTocPage) {
      _footprints = await HistoryDao.getMangaFootprintsSet(username: AuthManager.instance.username, mid: widget.mangaId) ?? {};
      if (mounted) setState(() {});
    }
    if (laterChapterEvent != null && laterChapterEvent.mangaId == widget.mangaId && !laterChapterEvent.fromMangaTocPage) {
      _laterChapters = await LaterMangaDao.getLaterChaptersSet(username: AuthManager.instance.username, mid: widget.mangaId) ?? {};
      if (mounted) setState(() {});
    }
  }

  void _showChapterPopupMenu(int chapterId) {
    var chapter = widget.groups.findChapter(chapterId);
    if (chapter == null) {
      Fluttertoast.showToast(msg: '未在漫画章节列表中找到章节'); // almost unreachable
      return;
    }

    showPopupMenuForMangaToc(
      context: context,
      mangaId: widget.mangaId,
      mangaTitle: widget.mangaTitle,
      mangaCover: widget.mangaCover,
      mangaUrl: widget.mangaUrl,
      fromMangaPage: false,
      fromMangaTocPage: true,
      fromMangaHistoryPage: false,
      chapter: chapter,
      chapterNeededData: widget.chapterNeededData,
      onHistoryUpdated: (h) => mountedSetState(() => _history = h),
      onFootprintAdded: (fp) => mountedSetState(() => _footprints?[fp.chapterId] = fp),
      onFootprintsAdded: (fps) => mountedSetState(() => fps.forEach((fp) => _footprints?[fp.chapterId] = fp)),
      onFootprintsRemoved: (cids) => mountedSetState(() => _footprints?.removeWhere((key, _) => cids.contains(key))),
      onLaterAdded: null /* 本页不显示 later banner */,
      onLaterMarked: (l) => mountedSetState(() => _laterChapters?[l.chapterId] = l),
      onLaterUnmarked: (cid) => mountedSetState(() => _laterChapters?.remove(cid)),
      canOperateHistory: widget.canOperateHistory,
      toSwitchChapter: widget.toSwitchChapter == null ? null : () => widget.toSwitchChapter?.call(chapterId),
      navigateWrapper: widget.navigateWrapper,
    );
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
      drawer: !widget.showAppDrawer
          ? null
          : AppDrawer(
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
                  laterChecker: (cid) => _laterChapters?.containsKey(cid) == true,
                  customBadgeBuilder: (cid) => DownloadBadge.fromEntity(
                    entity: _downloadEntity?.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull,
                  ),
                  onChapterPressed: widget.onChapterPressed,
                  onChapterLongPressed: (cid) => _showChapterPopupMenu(cid),
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
