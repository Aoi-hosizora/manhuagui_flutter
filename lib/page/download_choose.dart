import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/dlg/setting_dl_dialog.dart';
import 'package:manhuagui_flutter/page/download.dart';
import 'package:manhuagui_flutter/page/download_manga.dart';
import 'package:manhuagui_flutter/page/view/chapter_grid.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/fit_system_screenshot.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/page/view/manga_toc_badge.dart';
import 'package:manhuagui_flutter/page/view/multi_selection_fab.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/db/later_manga.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/storage/download_task.dart';

/// 选择下载章节页，展示所给 [MangaChapterGroup] 列表信息，并提供章节选择功能
class DownloadChoosePage extends StatefulWidget {
  const DownloadChoosePage({
    Key? key,
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.groups,
  }) : super(key: key);

  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final List<MangaChapterGroup> groups;

  @override
  State<DownloadChoosePage> createState() => _DownloadChoosePageState();
}

class _DownloadChoosePageState extends State<DownloadChoosePage> with FitSystemScreenshotMixin {
  final _listViewKey = GlobalKey();
  final _controller = ScrollController();
  final _msController = MultiSelectableController<ValueKey<int>>();
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
    _msController.dispose();
    super.dispose();
  }

  var _loading = true; // initialize to true, fake loading flag
  late final _allChapterIds = widget.groups.allChapterIds;
  MangaHistory? _history;
  Map<int, ChapterFootprint>? _footprints;
  Map<int, LaterChapter>? _laterChapters;
  DownloadedManga? _downloadEntity;
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
    } finally {
      _loading = false;
      _msController.enterMultiSelectionMode(); // 默认进入多选模式
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
      if (mounted) setState(() {});
    }
    if (footprintEvent != null && footprintEvent.mangaId == widget.mangaId) {
      _footprints = await HistoryDao.getMangaFootprintsSet(username: AuthManager.instance.username, mid: widget.mangaId) ?? {};
      if (mounted) setState(() {});
    }
    if (laterChapterEvent != null && laterChapterEvent.mangaId == widget.mangaId) {
      _laterChapters = await LaterMangaDao.getLaterChaptersSet(username: AuthManager.instance.username, mid: widget.mangaId) ?? {};
      if (mounted) setState(() {});
    }
  }

  Future<void> _downloadManga() async {
    // 1. 获取需要下载的章节
    var selected = _msController.selectedItems.map((el) => el.value).toList();
    if (selected.isEmpty) {
      Fluttertoast.showToast(msg: '请选择需要下载的章节');
      return;
    }
    var chapterIds = filterNeedDownloadChapterIds(chapterIds: selected, downloadedChapters: _downloadEntity?.downloadedChapters ?? []);
    if (chapterIds.isEmpty) {
      Fluttertoast.showToast(msg: '所选章节均已下载完毕');
      return;
    }

    // 2. 显示下载确认
    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('下载确认'),
        content: Text('是否下载所选的 ${chapterIds.length} 个章节？'),
        actions: [
          TextButton(child: Text('下载'), onPressed: () => Navigator.of(c).pop(true)),
          TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
        ],
      ),
    );
    if (ok != true) {
      return;
    }

    // 3. 快速构造下载任务，同步更新数据库，并入队异步等待执行
    await quickBuildDownloadMangaQueueTask(
      mangaId: widget.mangaId,
      mangaTitle: widget.mangaTitle,
      mangaCover: widget.mangaCover,
      mangaUrl: widget.mangaUrl,
      chapterIds: chapterIds.toList(),
      alsoAddTask: true,
      throughGroupList: widget.groups,
      throughChapterList: null,
    );

    // 4. 更新界面，并显示提示
    // await _loadDownloadedChapters(); => 由事件通知更新章节信息
    _msController.unselectAll();
    _isAllSelected = false;
    if (mounted) setState(() {});
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已添加 ${chapterIds.length} 个章节至漫画下载任务'),
        action: SnackBarAction(
          label: '查看',
          onPressed: () => Navigator.of(context).push(
            CustomPageRoute(
              context: context,
              builder: (c) => DownloadMangaPage(
                mangaId: widget.mangaId,
                gotoDownloading: true,
              ),
              settings: DownloadMangaPage.buildRouteSetting(
                mangaId: widget.mangaId,
              ),
            ),
          ),
        ),
      ),
    );
  }

  var _isAllSelected = false;

  void _onSelectChanged() {
    _isAllSelected = _msController.selectedItems.length == _allChapterIds.length;
    if (mounted) setState(() {});
  }

  void _selectAllOrUnselectAll() {
    if (_msController.selectedItems.length == _allChapterIds.length) {
      _msController.unselectAll();
      _isAllSelected = false;
    } else {
      _msController.select(_allChapterIds.map((el) => ValueKey(el)));
      _isAllSelected = true;
    }
    if (mounted) setState(() {});
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
        title: Text('下载 ${widget.mangaTitle}'),
        leading: AppBarActionButton.leading(context: context),
        actions: [
          AppBarActionButton(
            icon: Icon(!_isAllSelected ? Icons.select_all : Icons.deselect),
            tooltip: !_isAllSelected ? '全选' : '取消全选',
            onPressed: _selectAllOrUnselectAll,
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
              PopupMenuItem(
                child: IconTextMenuItem(Icons.settings, '漫画下载设置'),
                onTap: () => WidgetsBinding.instance?.addPostFrameCallback(
                  (_) => showDlSettingDialog(context: context),
                ),
              ),
              PopupMenuItem(
                child: IconTextMenuItem(Icons.download, '查看下载任务详情'),
                onTap: () => WidgetsBinding.instance?.addPostFrameCallback(
                  (_) => Navigator.of(context).push(
                    CustomPageRoute(
                      context: context,
                      builder: (c) => DownloadMangaPage(
                        mangaId: widget.mangaId,
                      ),
                      settings: DownloadMangaPage.buildRouteSetting(
                        mangaId: widget.mangaId,
                      ),
                    ),
                  ),
                ),
              ),
              PopupMenuItem(
                child: IconTextMenuItem(Icons.format_list_bulleted, '查看下载列表'),
                onTap: () => WidgetsBinding.instance?.addPostFrameCallback(
                  (_) => Navigator.of(context).push(
                    CustomPageRoute(
                      context: context,
                      builder: (c) => DownloadPage(),
                    ),
                  ),
                ),
              ),
              PopupMenuDivider(),
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
                WarningTextView(
                  text: '本应用为第三方漫画柜客户端，请不要连续下载过多章节，避免因短时间内的频繁访问而导致当前IP被漫画柜封禁。',
                  isWarning: true,
                ),
                MultiSelectable<ValueKey<int>>(
                  controller: _msController,
                  stateSetter: () {
                    _onSelectChanged();
                    mountedSetState(() {});
                  },
                  onModeChanged: (_) => mountedSetState(() {}),
                  exitWhenNoSelect: false /* 不退出多选模式 */,
                  child: MangaTocView(
                    groups: widget.groups,
                    full: true,
                    columns: _columns,
                    highlightedChapters: [_history?.chapterId ?? 0],
                    highlighted2Chapters: [_history?.lastChapterId ?? 0],
                    showHighlight2: AppSetting.instance.ui.showLastHistory,
                    faintedChapters: _footprints?.keys.toList() ?? [],
                    laterChecker: (cid) => _laterChapters?.containsKey(cid) == true,
                    customBadgeBuilder: (cid) => DownloadBadge.fromEntity(
                      entity: _downloadEntity?.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull,
                    ),
                    itemBuilder: (_, chapterId, itemWidget) => chapterId == null
                        ? itemWidget
                        : SelectableCheckboxItem<ValueKey<int>>(
                            key: ValueKey<int>(chapterId),
                            checkboxPosition: PositionArgument.fromLTRB(null, null, 0.9, 1),
                            checkboxBuilder: (_, __, tip) => tip.selected
                                ? CheckboxForSelectableItem(
                                    tip: tip,
                                    backgroundColor: chapterId == _history?.chapterId //
                                        ? ChapterGridView.defaultHighlightAppliedColor
                                        : chapterId == _history?.lastChapterId
                                            ? ChapterGridView.defaultHighlight2AppliedColor
                                            : Colors.white,
                                    scale: 0.85, // larger than dl toc
                                    scaleAlignment: Alignment.bottomRight,
                                  )
                                : SizedBox.shrink(),
                            useFullRipple: true,
                            onFullRippleLongPressed: (_, key, tip) => tip.toToggle?.call(),
                            itemBuilder: (_, key, tip) => itemWidget /* single grid */,
                          ),
                    onChapterPressed: (_) {},
                  ),
                ),
              ],
            ).fitSystemScreenshot(this),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_loading)
            ScrollAnimatedFab(
              scrollController: _controller,
              condition: ScrollAnimatedCondition.direction,
              fab: FloatingActionButton(
                child: Icon(Icons.vertical_align_top),
                heroTag: null,
                onPressed: () => _controller.scrollToTop(),
              ),
            ),
          SizedBox(height: kFloatingActionButtonMargin),
          FloatingActionButton(
            child: Icon(Icons.download),
            heroTag: null,
            onPressed: () => _downloadManga(),
          ),
        ],
      ),
    );
  }
}
