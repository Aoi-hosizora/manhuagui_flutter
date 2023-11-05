import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/dlg/manga_dialog.dart';
import 'package:manhuagui_flutter/page/manga_viewer.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/chapter_grid.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/manga_simple_toc.dart';
import 'package:manhuagui_flutter/page/view/manga_toc_badge.dart';
import 'package:manhuagui_flutter/page/view/multi_selection_fab.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 漫画历史管理页，查询并展示 [MangaHistory] 以及 [ChapterFootprint] 信息
class MangaHistoryPage extends StatefulWidget {
  const MangaHistoryPage({
    Key? key,
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.chapterGroups,
    required this.chapterNeededData,
  }) : super(key: key);

  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final List<MangaChapterGroup> chapterGroups;
  final MangaChapterNeededData chapterNeededData;

  @override
  State<MangaHistoryPage> createState() => _MangaHistoryPageState();
}

enum _MangaHistoryPageMode {
  readOnly,
  unreadOnly,
  showAll,
}

class _MangaHistoryPageState extends State<MangaHistoryPage> {
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
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _controller.dispose();
    _msController.dispose();
    super.dispose();
  }

  var _loading = true; // initialize to true, fake loading flag
  MangaHistory? _history;
  Map<int, ChapterFootprint>? _footprints;
  DownloadedManga? _downloadEntity;
  var _columns = 4; // default to four columns
  var _orderInDefault = true; // default to order by number
  var _invertOrder = true; // default to order desc

  List<MangaChapterGroup>? _readGroups;
  List<MangaChapterGroup>? _unreadGroups;
  Set<int>? _readChapterIds;
  Set<int>? _unreadChapterIds;
  var _mode = _MangaHistoryPageMode.readOnly;

  List<MangaChapterGroup> get _currGroups => //
      _mode == _MangaHistoryPageMode.readOnly
          ? (_readGroups ?? [])
          : _mode == _MangaHistoryPageMode.unreadOnly
              ? (_unreadGroups ?? [])
              : widget.chapterGroups;

  Future<void> _loadData() async {
    _loading = true;
    if (mounted) setState(() {});

    try {
      await Future.delayed(Duration(milliseconds: 400)); // fake loading
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId); // 漫画历史
      _footprints = await HistoryDao.getMangaFootprintsSet(username: AuthManager.instance.username, mid: widget.mangaId) ?? {}; // 章节历史
      _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId); // 下载数据
      _loadDataForGroups();
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  void _loadDataForGroups() {
    _readGroups = widget.chapterGroups // preserve the original order
        .map((group) => MangaChapterGroup(title: group.title, chapters: group.chapters.where((c) => _footprints!.containsKey(c.cid)).toList()))
        .where((group) => group.chapters.isNotEmpty)
        .toList();

    _unreadGroups = widget.chapterGroups // preserve the original order
        .map((group) => MangaChapterGroup(title: group.title, chapters: group.chapters.where((c) => !_footprints!.containsKey(c.cid)).toList()))
        .where((group) => group.chapters.isNotEmpty)
        .toList();

    _readChapterIds = _readGroups!.allChapterIds.toSet();
    _unreadChapterIds = _unreadGroups!.allChapterIds.toSet();
  }

  Future<void> _updateByEvent({HistoryUpdatedEvent? historyEvent, DownloadUpdatedEvent? downloadEvent, FootprintUpdatedEvent? footprintEvent}) async {
    if (historyEvent != null && historyEvent.mangaId == widget.mangaId && !historyEvent.fromMangaHistoryPage) {
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);
      if (mounted) setState(() {});
    }
    if (downloadEvent != null && downloadEvent.mangaId == widget.mangaId) {
      _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId);
      if (mounted) setState(() {});
    }
    if (footprintEvent != null && footprintEvent.mangaId == widget.mangaId && !footprintEvent.fromMangaHistoryPage) {
      _footprints = await HistoryDao.getMangaFootprintsSet(username: AuthManager.instance.username, mid: widget.mangaId) ?? {};
      _loadDataForGroups();
      if (mounted) setState(() {});
    }
  }

  void _switchToMode(_MangaHistoryPageMode mode) {
    if (_mode != mode) {
      _mode = mode;
      _msController.exitMultiSelectionMode(); // 同时退出多选模式
      if (mounted) setState(() {});
    }
  }

  int Function(TinyMangaChapter a, TinyMangaChapter b) _getChapterCompareTo() {
    if (_orderInDefault || _mode != _MangaHistoryPageMode.readOnly) {
      return (a, b) {
        return a.number.compareTo(b.number); // sort using default method (see ChapterGridView)
      };
    }

    return (a, b) {
      var fpa = _footprints?[a.cid];
      var fpb = _footprints?[b.cid];
      if (fpa == null) {
        return -1; // fpa < fpb
      }
      if (fpb == null) {
        return 1; // fpa > fpb
      }
      return fpa.createdAt.compareTo(fpb.createdAt); // sort with createdAt field
    };
  }

  Future<void> _addChapterFootprints({required List<int> chapterIds}) async {
    chapterIds = chapterIds.where((el) => _unreadChapterIds?.contains(el) == true).toList();
    if (chapterIds.isEmpty) {
      Fluttertoast.showToast(msg: '所选章节都已被标记为已阅读');
      return;
    }

    // 不退出多选模式、先弹出对话框
    var selectedChapters = _unreadGroups!.allChapters.where((ch) => chapterIds.contains(ch.cid)).toList();
    if (selectedChapters.length > 1) {
      var ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('添加确认'),
          content: Text(
            '是否添加以下 ${selectedChapters.length} 项章节阅读历史？\n\n' + //
                [for (int i = 0; i < selectedChapters.length; i++) '${i + 1}. 《${selectedChapters[i].title}》'].join('\n'),
          ),
          scrollable: true,
          actions: [
            TextButton(child: Text('添加'), onPressed: () => Navigator.of(c).pop(true)),
            TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
          ],
        ),
      );
      if (ok != true) {
        return;
      }
    }

    // 退出多选模式、更新数据库、更新界面[↴]、发送通知
    // 本页引起的新增 => 更新列表显示
    _msController.exitMultiSelectionMode();

    var now = DateTime.now();
    var newFootprints = [
      for (var chapterId in chapterIds) //
        ChapterFootprint(mangaId: widget.mangaId, chapterId: chapterId, createdAt: now),
    ];
    var futures = [
      for (var newFootprint in newFootprints)
        HistoryDao.addOrUpdateFootprint(
          username: AuthManager.instance.username,
          footprint: newFootprint,
        ),
    ];
    await Future.wait(futures);

    for (var footprint in newFootprints) {
      _footprints?[footprint.chapterId] = footprint;
    }
    _loadDataForGroups();
    if (mounted) setState(() {});
    EventBusManager.instance.fire(FootprintUpdatedEvent(mangaId: widget.mangaId, chapterIds: chapterIds, reason: UpdateReason.added, fromMangaHistoryPage: true));
  }

  Future<void> _removeChapterFootprints({required List<int> chapterIds}) async {
    chapterIds = chapterIds.where((el) => _readChapterIds?.contains(el) == true).toList();
    if (chapterIds.isEmpty) {
      Fluttertoast.showToast(msg: '所选章节都还未被阅读');
      return;
    }

    // 不退出多选模式、先弹出对话框
    var selectedChapters = _readGroups!.allChapters.where((ch) => chapterIds.contains(ch.cid)).toList();
    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('删除确认'),
        content: selectedChapters.length == 1 //
            ? Text('是否删除《${selectedChapters.first.title}》章节阅读历史？')
            : Text(
                '是否删除以下 ${selectedChapters.length} 项章节阅读历史？\n\n' + //
                    [for (int i = 0; i < selectedChapters.length; i++) '${i + 1}. 《${selectedChapters[i].title}》'].join('\n'),
              ),
        scrollable: true,
        actions: [
          TextButton(child: Text('删除'), onPressed: () => Navigator.of(c).pop(true)),
          TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
        ],
      ),
    );
    if (ok != true) {
      return;
    }

    // 1. 退出多选模式、更新数据库
    _msController.exitMultiSelectionMode();

    // 2. 更新数据库
    var history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);
    var futures = <Future>[];
    for (var chapterId in chapterIds) {
      if (history?.chapterId == chapterId) {
        history = history?.copyWithNoCurrChapterOnly(lastTime: DateTime.now()); // 更新漫画历史
      } else if (history?.lastChapterId == chapterId) {
        history = history?.copyWithNoLastChapterOnly(lastTime: DateTime.now()); // 更新漫画历史
      }
      var f = HistoryDao.deleteFootprint(
        username: AuthManager.instance.username,
        mid: widget.mangaId,
        cid: chapterId,
      );
      futures.add(f);
    }
    if (history != null && history != _history) {
      await HistoryDao.addOrUpdateHistory(username: AuthManager.instance.username, history: history);
    } else {
      history = null;
    }
    await Future.wait(futures);

    // 3. 更新界面[↴]、弹出提示、发送通知
    // 本页引起的删除 => 更新列表显示
    for (var chapterId in chapterIds) {
      _footprints?.remove(chapterId);
    }
    _loadDataForGroups();
    if (history != null) {
      _history = history;
      EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: widget.mangaId, reason: UpdateReason.updated, fromMangaHistoryPage: true));
    }
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已删除 ${chapterIds.length} 条章节阅读历史')));
    EventBusManager.instance.fire(FootprintUpdatedEvent(mangaId: widget.mangaId, chapterIds: chapterIds, reason: UpdateReason.deleted, fromMangaHistoryPage: true));
    if (mounted) setState(() {});
  }

  Future<void> _deleteHistory() async {
    if (_history == null) {
      return;
    }

    // 不退出多选模式、先弹出对话框
    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('删除确认'),
        content: Text('是否删除《${_history!.mangaTitle}》阅读历史，以及所有章节的阅读历史？'),
        scrollable: true,
        actions: [
          TextButton(child: Text('删除'), onPressed: () => Navigator.of(c).pop(true)),
          TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
        ],
      ),
    );
    if (ok != true) {
      return;
    }

    // 退出多选模式、更新数据库、更新界面[↴]、发送通知
    // 本页引起的删除 => 返回上一页
    _msController.exitMultiSelectionMode();
    _history = _history!.copyWithNoCurrChapterAndLastChapter(lastTime: DateTime.now()); // 删除章节阅读历史，仅保留漫画浏览历史
    await HistoryDao.addOrUpdateHistory(username: AuthManager.instance.username, history: _history!);
    await HistoryDao.clearMangaFootprints(username: AuthManager.instance.username, mid: widget.mangaId); // 删除章节阅读历史
    if (mounted) setState(() {});
    EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: widget.mangaId, reason: UpdateReason.updated, fromMangaHistoryPage: true));
    EventBusManager.instance.fire(FootprintUpdatedEvent(mangaId: widget.mangaId, chapterIds: null, reason: UpdateReason.deleted, fromMangaHistoryPage: true));
    Navigator.of(context).pop();
  }

  void _showPopupMenu({required int chapterId}) {
    var chapter = _currGroups.findChapter(chapterId);
    if (chapter == null) {
      return;
    }

    // 退出多选模式、弹出菜单
    _msController.exitMultiSelectionMode();

    // (更新数据库)、更新界面[↴]、(弹出提示)、(发送通知)
    // 本页引起的更新 => 更新历史相关的界面
    showPopupMenuForMangaToc(
      context: context,
      mangaId: widget.mangaId,
      mangaTitle: widget.mangaTitle,
      mangaCover: widget.mangaCover,
      mangaUrl: widget.mangaUrl,
      fromMangaPage: false,
      chapter: chapter,
      chapterNeededData: widget.chapterNeededData,
      onHistoryUpdated: (h) => mountedSetState(() => _history = h),
      onFootprintAdded: (fp) => mountedSetState(() => _footprints?[fp.chapterId] = fp),
      onFootprintsAdded: (fps) => mountedSetState(() => fps.forEach((fp) => _footprints?[fp.chapterId] = fp)),
      onFootprintsRemoved: (cids) => mountedSetState(() => _footprints?.removeWhere((key, _) => cids.contains(key))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_msController.multiSelecting) {
          _msController.exitMultiSelectionMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.mangaTitle} 阅读历史'),
          leading: AppBarActionButton.leading(context: context, allowDrawerButton: false),
          actions: [
            AppBarActionButton(
              icon: Icon(CustomIcons.history_delete),
              tooltip: '删除漫画阅读历史',
              onPressed: () => _deleteHistory(),
            ),
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
                  Container(
                    color: Colors.white,
                    child: ActionRowView.five(
                      action1: ActionItem.simple(
                        '仅已阅读',
                        CustomIcons.eye_clock,
                        () => _switchToMode(_MangaHistoryPageMode.readOnly),
                        color: _mode == _MangaHistoryPageMode.readOnly ? Colors.deepOrange : null,
                      ),
                      action2: ActionItem.simple(
                        '仅未阅读',
                        CustomIcons.eye_star,
                        () => _switchToMode(_MangaHistoryPageMode.unreadOnly),
                        color: _mode == _MangaHistoryPageMode.unreadOnly ? Colors.deepOrange : null,
                      ),
                      action3: ActionItem.simple(
                        '全部章节',
                        CustomIcons.eye_menu,
                        () => _switchToMode(_MangaHistoryPageMode.showAll),
                        color: _mode == _MangaHistoryPageMode.showAll ? Colors.deepOrange : null,
                      ),
                      action4: _mode != _MangaHistoryPageMode.readOnly // sort by date only when readOnly
                          ? ActionItem.simple('默认排序', CustomIcons.sort_book_descending, null, enable: false)
                          : ActionItem.simple(
                              _orderInDefault ? '默认排序' : '时间排序',
                              _orderInDefault ? CustomIcons.sort_book_descending : MdiIcons.sortClockDescendingOutline,
                              () => mountedSetState(() => _orderInDefault = !_orderInDefault),
                            ),
                      action5: ActionItem.simple(
                        _invertOrder ? '逆序显示' : '正序显示',
                        _invertOrder ? MdiIcons.sortDescending : MdiIcons.sortAscending,
                        () => mountedSetState(() => _invertOrder = !_invertOrder),
                      ),
                    ),
                  ),
                  Container(
                    height: 12,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  MultiSelectable<ValueKey<int>>(
                    controller: _msController,
                    stateSetter: () => mountedSetState(() {}),
                    onModeChanged: (_) => mountedSetState(() {}),
                    child: MangaSimpleTocView(
                      groups: _currGroups,
                      invertOrder: _invertOrder,
                      compareTo: _getChapterCompareTo(),
                      columns: _columns,
                      highlightedChapters: [_history?.chapterId ?? 0],
                      highlighted2Chapters: [_history?.lastChapterId ?? 0],
                      showHighlight2: AppSetting.instance.ui.showLastHistory,
                      faintedChapters: _footprints?.keys.toList() ?? [],
                      showTriText: true,
                      getTriText: (c) => _footprints?[c.cid]?.formattedCreatedAt ?? '暂未阅读',
                      customBadgeBuilder: (cid) => DownloadBadge.fromEntity(
                        entity: _downloadEntity?.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull,
                      ),
                      itemBuilder: (_, chapterId, itemWidget) => chapterId == null
                          ? itemWidget // unreachable
                          : SelectableCheckboxItem<ValueKey<int>>(
                              key: ValueKey<int>(chapterId),
                              checkboxPosition: PositionArgument.fromLTRB(null, null, 0.9, 1),
                              checkboxBuilder: (_, __, tip) => CheckboxForSelectableItem(
                                tip: tip,
                                backgroundColor: chapterId == _history?.chapterId //
                                    ? ChapterGridView.defaultHighlightAppliedColor
                                    : chapterId == _history?.lastChapterId
                                        ? ChapterGridView.defaultHighlight2AppliedColor
                                        : Colors.white,
                                scale: 0.7,
                                scaleAlignment: Alignment.bottomRight,
                              ),
                              useFullRipple: true,
                              onFullRippleLongPressed: (_, key, tip) => tip.toToggle?.call(),
                              itemBuilder: (_, key, tip) => itemWidget /* single grid */,
                            ),
                      onChapterPressed: (cid) => _showPopupMenu(chapterId: cid),
                      onChapterLongPressed: _msController.multiSelecting
                          ? null //
                          : (chapterId) => _msController.enterMultiSelectionMode(alsoSelect: [ValueKey<int>(chapterId)]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: _loading
            ? null
            : MultiSelectionFabContainer(
                multiSelectableController: _msController,
                onCounterPressed: () {
                  var allChapters = (_currGroups.allChapters..sort(_getChapterCompareTo())).let((l) => !_invertOrder ? l : l.reversed.toList());
                  var chapterIds = _msController.selectedItems.map((e) => e.value).toList();
                  var titles = allChapters.where((el) => chapterIds.contains(el.cid)).map((m) => '《${m.title}》').toList();
                  var allKeys = allChapters.map((el) => ValueKey(el.cid)).toList();
                  MultiSelectionFabContainer.showCounterDialog(context, controller: _msController, selected: titles, allKeys: allKeys);
                },
                fabForMultiSelection: [
                  MultiSelectionFabOption(
                    child: Icon(Icons.more_horiz),
                    tooltip: '查看更多选项',
                    show: _msController.selectedItems.length == 1,
                    onPressed: () => _showPopupMenu(chapterId: _msController.selectedItems.first.value),
                  ),
                  MultiSelectionFabOption(
                    child: Icon(CustomIcons.history_plus),
                    tooltip: '标记为已阅读',
                    enable: _mode == _MangaHistoryPageMode.unreadOnly || _mode == _MangaHistoryPageMode.showAll,
                    onPressed: () => _addChapterFootprints(chapterIds: _msController.selectedItems.map((el) => el.value).toList()),
                  ),
                  MultiSelectionFabOption(
                    child: Icon(CustomIcons.history_minus),
                    tooltip: '删除阅读历史',
                    enable: _mode == _MangaHistoryPageMode.readOnly || _mode == _MangaHistoryPageMode.showAll,
                    onPressed: () => _removeChapterFootprints(chapterIds: _msController.selectedItems.map((el) => el.value).toList()),
                  ),
                ],
                fabForNormal: ScrollAnimatedFab(
                  scrollController: _controller,
                  condition: !_msController.multiSelecting ? ScrollAnimatedCondition.direction : ScrollAnimatedCondition.custom,
                  customBehavior: (_) => false,
                  fab: FloatingActionButton(
                    child: Icon(Icons.vertical_align_top),
                    heroTag: null,
                    onPressed: () => _controller.scrollToTop(),
                  ),
                ),
              ),
      ),
    );
  }
}
