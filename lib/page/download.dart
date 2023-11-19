import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/dlg/list_assist_dialog.dart';
import 'package:manhuagui_flutter/page/dlg/manga_dialog.dart';
import 'package:manhuagui_flutter/page/dlg/setting_dl_dialog.dart';
import 'package:manhuagui_flutter/page/download_manga.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/download_manga_line.dart';
import 'package:manhuagui_flutter/page/view/fit_system_screenshot.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/multi_selection_fab.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/storage/download.dart';
import 'package:manhuagui_flutter/service/storage/download_task.dart';
import 'package:manhuagui_flutter/service/storage/queue_manager.dart';

/// 下载列表页，查询数据库并展示 [DownloadedManga] 列表信息，以及展示 [DownloadProgressChangedEvent] 进度信息
class DownloadPage extends StatefulWidget {
  const DownloadPage({
    Key? key,
  }) : super(key: key);

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> with FitSystemScreenshotMixin {
  final _rdvKey = GlobalKey<RefreshableDataViewState>();
  final _scrollViewKey = GlobalKey();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  final _msController = MultiSelectableController<ValueKey<int>>();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadProgressChangedEvent>((ev) => _updateByEvent(progressEvent: ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadUpdatedEvent>((ev) => _updateByEvent(entityEvent: ev)));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _controller.dispose();
    _fabController.dispose();
    _msController.dispose();
    super.dispose();
  }

  final _data = <DownloadedManga>[];
  var _total = 0;
  final _tasks = <int, DownloadMangaQueueTask>{};
  final _bytes = <int, int>{};
  var _searchKeyword = ''; // for query condition
  var _searchTitleOnly = true; // for query condition

  Future<List<DownloadedManga>> _getData() async {
    var data = await DownloadDao.getMangas(keyword: _searchKeyword, pureSearch: _searchTitleOnly) ?? [];
    _total = await DownloadDao.getMangaCount(keyword: _searchKeyword, pureSearch: _searchTitleOnly) ?? 0;
    _tasks.clear();
    for (var t in QueueManager.instance.getDownloadMangaQueueTasks()) {
      _tasks[t.mangaId] = t;
    }
    if (mounted) setState(() {});
    for (var entity in data) {
      getDownloadedMangaBytes(mangaId: entity.mangaId).then((b) => mountedSetState(() => _bytes[entity.mangaId] = b)); // 在每次刷新时都重新统计文件大小
    }
    return data;
  }

  Future<void> _updateByEvent({DownloadProgressChangedEvent? progressEvent, DownloadUpdatedEvent? entityEvent}) async {
    if (progressEvent != null) {
      var mangaId = progressEvent.mangaId;
      var task = QueueManager.instance.getDownloadMangaQueueTask(mangaId);
      if (progressEvent.finished) {
        mountedSetState(() => _tasks.removeWhere((key, _) => key == mangaId));
      } else if (task != null) {
        mountedSetState(() => _tasks[mangaId] = task);
        if (task.progress.stage == DownloadMangaProgressStage.waiting || task.progress.stage == DownloadMangaProgressStage.gotChapter) {
          getDownloadedMangaBytes(mangaId: mangaId).then((b) => mountedSetState(() => _bytes[mangaId] = b)); // 仅在最开始等待、以及每次获得新章节时才统计文件大小
        }
      }
    }

    if (entityEvent != null) {
      var mangaId = entityEvent.mangaId;
      var entity = await DownloadDao.getManga(mid: mangaId);
      if (entity != null && (_searchKeyword.isEmpty || _data.any((el) => el.mangaId == mangaId))) {
        // 只有在 **没在搜索**，或 **正在搜索且存在搜索结果中** 时，才更新列表
        _data.removeWhere((el) => el.mangaId == mangaId);
        _data.insert(0, entity);
        _data.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // 更新数据后按下载更新时间调整顺序
        if (mounted) setState(() {});
        getDownloadedMangaBytes(mangaId: mangaId).then((b) => mountedSetState(() => _bytes[mangaId] = b)); // 在每次数据库发生变化时都统计文件大小
      }
    }
  }

  Future<void> _toSearch() async {
    var result = await showKeywordDialogForSearching(
      context: context,
      title: '搜索漫画下载列表',
      textValue: _searchKeyword,
      optionTitle: '仅搜索漫画标题',
      optionValue: _searchTitleOnly,
      optionHint: (only) => only ? '当前选项使得本次仅搜索漫画标题' : '当前选项使得本次将搜索漫画ID以及漫画标题',
    );
    if (result != null && result.item1.isNotEmpty) {
      _searchKeyword = result.item1;
      _searchTitleOnly = result.item2;
      if (mounted) setState(() {});
      _rdvKey.currentState?.refresh();
    }
  }

  void _exitSearch() {
    _searchKeyword = ''; // 清空搜索关键词
    if (mounted) setState(() {});
    _rdvKey.currentState?.refresh();
  }

  Future<DownloadMangaQueueTask?> _pauseOrContinue({
    required bool toPause,
    required DownloadedManga entity,
    required DownloadMangaQueueTask? task,
    bool addTask = true,
  }) async {
    if (toPause) {
      // 暂停 => 取消任务
      if (task != null && !task.cancelRequested) {
        task.cancel();
      }
      return null;
    } else {
      // 继续 => 构造任务、同步准备、入队
      return await quickBuildDownloadMangaQueueTask(
        mangaId: entity.mangaId,
        mangaTitle: entity.mangaTitle,
        mangaCover: entity.mangaCover,
        mangaUrl: entity.mangaUrl,
        chapterIds: entity.downloadedChapters.map((el) => el.chapterId).toList(),
        alsoAddTask: addTask /* <<< */,
        throughGroupList: null,
        throughChapterList: entity.downloadedChapters,
      );
    }
  }

  Completer<void>? _allStartCompleter;

  Future<void> _allStartOrPause({required bool allStart, bool Function(int mangaId)? condition}) async {
    if (allStart) {
      // => 全部开始

      // 1. 先判断当前是否在"全部开始"
      if (_allStartCompleter != null) {
        return;
      }
      _allStartCompleter = Completer<void>();

      // 2. 逐漫画"继续下载"，异步，并等待所有"准备下载"结束
      var entities = await DownloadDao.getMangas() ?? _data; // mangas are in updated_at desc order
      entities = entities.where((el) => condition?.call(el.mangaId) ?? true).toList();
      var tasks = QueueManager.instance.getDownloadMangaQueueTasks();
      tasks = tasks.where((el) => condition?.call(el.mangaId) ?? true).toList();
      var prepareFutures = <Future<DownloadMangaQueueTask?>>[];
      for (var entity in entities) {
        var task = tasks.where((el) => el.mangaId == entity.mangaId).firstOrNull;
        if (task == null || task.cancelRequested) {
          // 继续下载但暂不入队，等待所有任务准备结束再一起入队
          prepareFutures.add(_pauseOrContinue(toPause: false, entity: entity, task: null, addTask: false));
        }
      }
      var newTasks = await Future.wait(prepareFutures);

      // 3. 按照下载时间逆序，将新的已准备好的下载任务一起入队
      var newTaskMap = <int, DownloadMangaQueueTask>{};
      for (var task in newTasks) {
        if (task != null) {
          newTaskMap[task.mangaId] = task;
        }
      }
      for (var entity in entities) {
        var newTask = newTaskMap[entity.mangaId];
        if (newTask != null) {
          QueueManager.instance.addTask(newTask); // 按顺序一起入队
        }
      }

      // 4. 记录"全部开始"已完成
      _allStartCompleter?.complete();
      _allStartCompleter = null;
    } else {
      // => 全部暂停

      // 1. 先取消目前所有的任务
      var tasks = QueueManager.instance.getDownloadMangaQueueTasks();
      tasks = tasks.where((el) => condition?.call(el.mangaId) ?? true).toList();
      for (var t in tasks) {
        if (!t.cancelRequested) {
          t.cancel();
        }
      }

      // 2. 等待"全部开始"结束
      await _allStartCompleter?.future;

      // 3. 再取消"全部开始"结束后所有的任务
      tasks = QueueManager.instance.getDownloadMangaQueueTasks();
      tasks = tasks.where((el) => condition?.call(el.mangaId) ?? true).toList();
      for (var t in tasks) {
        if (!t.cancelRequested) {
          t.cancel();
        }
      }
    }
  }

  void _showPopupMenu({required int mangaId}) {
    var manga = _data.where((el) => el.mangaId == mangaId).firstOrNull;
    if (manga == null) {
      return;
    }

    // 退出多选模式、弹出菜单
    _msController.exitMultiSelectionMode();
    showPopupMenuForMangaList(
      context: context,
      mangaId: manga.mangaId,
      mangaTitle: manga.mangaTitle,
      mangaCover: manga.mangaCover,
      mangaUrl: manga.mangaUrl,
      extraData: null,
      eventSource: EventSource.downloadPage,
    );
  }

  Future<void> _deleteMangas({required List<int> mangaIds}) async {
    var entities = _data.where((el) => mangaIds.contains(el.mangaId)).toList();
    if (entities.isEmpty) {
      return;
    }
    for (var entity in entities) {
      var task = QueueManager.instance.getDownloadMangaQueueTask(entity.mangaId);
      if (task != null) {
        Fluttertoast.showToast(msg: '请先暂停下载《${entity.mangaTitle}》，然后再删除漫画');
        return;
      }
    }

    // 不退出多选模式、先弹出菜单
    var alsoDeleteFile = AppSetting.instance.dl.defaultToDeleteFiles;
    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, _setState) => AlertDialog(
          title: Text('删除确认'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entities.length == 1) Text('是否删除《${entities.first.mangaTitle}》漫画？\n'),
              if (entities.length > 1)
                Text(
                  '是否删除以下 ${entities.length} 部漫画？\n\n' + //
                      ([for (int i = 0; i < entities.length; i++) '${i + 1}. 《${entities[i].mangaTitle}》'].join('\n') + '\n'),
                ),
              CheckboxListTile(
                title: Text('同时删除已下载的文件'),
                value: alsoDeleteFile,
                onChanged: (v) => _setState(() => alsoDeleteFile = v ?? false),
                visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(child: Text('删除'), onPressed: () => Navigator.of(c).pop(true)),
            TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
          ],
        ),
      ),
    );
    if (ok != true) {
      return;
    }

    // 退出多选模式、保存设置
    _msController.exitMultiSelectionMode();
    await updateDlSettingDefaultToDeleteFiles(alsoDeleteFile);

    // 更新数据库、更新列表显示
    for (var mangaId in mangaIds) {
      await DownloadDao.deleteManga(mid: mangaId);
      await DownloadDao.deleteAllChapters(mid: mangaId);
      _data.removeWhere((el) => el.mangaId == mangaId);
      _total--;
    }
    if (mounted) setState(() {});

    // 删除文件、最后再发送通知
    if (alsoDeleteFile) {
      for (var mangaId in mangaIds) {
        await deleteDownloadedManga(mangaId: mangaId);
      }
    }
    for (var mangaId in mangaIds) {
      EventBusManager.instance.fire(DownloadUpdatedEvent(mangaId: mangaId, source: EventSource.downloadPage));
    }
  }

  @override
  FitSystemScreenshotData get fitSystemScreenshotData => FitSystemScreenshotData(
        scrollViewKey: _scrollViewKey,
        scrollController: _controller,
      );

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_msController.multiSelecting) {
          _msController.exitMultiSelectionMode();
          return false;
        }
        if (_searchKeyword.isNotEmpty) {
          _exitSearch();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('下载列表'),
          leading: AppBarActionButton.leading(context: context, allowDrawerButton: false),
          actions: [
            if (_searchKeyword.isNotEmpty)
              AppBarActionButton(
                icon: Icon(Icons.search_off),
                tooltip: '退出搜索',
                onPressed: () => _exitSearch(),
              ),
            if (_searchKeyword.isEmpty)
              AppBarActionButton(
                icon: Icon(Icons.play_arrow),
                tooltip: '全部开始',
                onPressed: () => _allStartOrPause(allStart: true),
              ),
            AppBarActionButton(
              icon: Icon(Icons.pause),
              tooltip: '全部暂停',
              onPressed: () => _allStartOrPause(allStart: false),
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
                PopupMenuItem(
                  child: IconTextMenuItem(Icons.settings, '漫画下载设置'),
                  onTap: () => WidgetsBinding.instance?.addPostFrameCallback(
                    (_) => showDlSettingDialog(context: context),
                  ),
                ),
                PopupMenuItem(
                  child: IconTextMenuItem(Icons.search, '搜索列表中的漫画'),
                  onTap: () => WidgetsBinding.instance?.addPostFrameCallback((_) => _toSearch()),
                ),
                if (_searchKeyword.isNotEmpty)
                  PopupMenuItem(
                    child: IconTextMenuItem(Icons.search_off, '退出搜索'),
                    onTap: () => _exitSearch(),
                  ),
              ],
            ),
          ],
        ),
        drawer: AppDrawer(
          currentSelection: DrawerSelection.download,
        ),
        drawerEdgeDragWidth: MediaQuery.of(context).size.width,
        body: MultiSelectable<ValueKey<int>>(
          controller: _msController,
          stateSetter: () => mountedSetState(() {}),
          onModeChanged: (_) => mountedSetState(() {}),
          child: RefreshableListView<DownloadedManga>(
            key: _rdvKey,
            data: _data,
            getData: () => _getData(),
            scrollViewKey: _scrollViewKey,
            scrollController: _controller,
            setting: UpdatableDataViewSetting(
              padding: EdgeInsets.symmetric(vertical: 0),
              interactiveScrollbar: true,
              scrollbarMainAxisMargin: 2,
              scrollbarCrossAxisMargin: 2,
              placeholderSetting: PlaceholderSetting().copyWithChinese(),
              onPlaceholderStateChanged: (_, __) => _fabController.hide(),
              refreshFirst: true /* <<< refresh first */,
              clearWhenRefresh: false,
              clearWhenError: false,
              onStartRefreshing: () => _msController.exitMultiSelectionMode(),
            ),
            separator: Divider(height: 0, thickness: 1),
            itemBuilder: (c, _, entity) {
              DownloadMangaQueueTask? task = _tasks[entity.mangaId];
              return SelectableCheckboxItem<ValueKey<int>>(
                key: ValueKey<int>(entity.mangaId),
                checkboxBuilder: (_, __, tip) => CheckboxForSelectableItem(tip: tip, backgroundColor: Theme.of(context).scaffoldBackgroundColor),
                useFullRipple: true,
                onFullRippleLongPressed: (c, key, tip) => _msController.selectedItems.length == 1 && tip.selected ? _showPopupMenu(mangaId: key.value) : tip.toToggle?.call(),
                itemBuilder: (c, key, tip) => DownloadMangaLineView(
                  mangaEntity: entity,
                  downloadTask: task,
                  downloadedBytes: _bytes[entity.mangaId] ?? 0,
                  onActionPressed: () => _pauseOrContinue(toPause: task != null, entity: entity, task: task),
                  onLinePressed: () => Navigator.of(context).push(
                    CustomPageRoute(
                      context: context,
                      builder: (c) => DownloadMangaPage(
                        mangaId: entity.mangaId,
                      ),
                      settings: DownloadMangaPage.buildRouteSetting(
                        mangaId: entity.mangaId,
                      ),
                    ),
                  ),
                  onLineLongPressed: !tip.isNormal ? null : () => _msController.enterMultiSelectionMode(alsoSelect: [key]),
                ),
              );
            },
            extra: UpdatableDataViewExtraWidgets(
              outerTopWidgets: [
                ListHintView.textText(
                  leftText: '本地的漫画下载列表' + //
                      (_searchKeyword.isNotEmpty ? ' ("$_searchKeyword" 的搜索结果)' : ''),
                  rightText: '共 $_total 部',
                ),
              ],
            ),
          ).fitSystemScreenshot(this),
        ),
        floatingActionButton: MultiSelectionFabContainer(
          multiSelectableController: _msController,
          onCounterPressed: () {
            var mangaIds = _msController.selectedItems.map((e) => e.value).toList();
            var titles = _data.where((el) => mangaIds.contains(el.mangaId)).map((m) => '《${m.mangaTitle}》').toList();
            var allKeys = _data.map((el) => ValueKey(el.mangaId)).toList();
            MultiSelectionFabContainer.showCounterDialog(context, controller: _msController, selected: titles, allKeys: allKeys);
          },
          fabForMultiSelection: [
            MultiSelectionFabOption(
              child: Icon(Icons.more_horiz),
              tooltip: '查看更多选项',
              show: _msController.selectedItems.length == 1,
              onPressed: () => _showPopupMenu(mangaId: _msController.selectedItems.first.value),
            ),
            MultiSelectionFabOption(
              child: Icon(Icons.play_arrow),
              tooltip: '开始下载',
              onPressed: () {
                var mangaIds = _msController.selectedItems.map((e) => e.value).toList();
                _msController.exitMultiSelectionMode();
                _allStartOrPause(allStart: true, condition: (id) => mangaIds.contains(id));
              },
            ),
            MultiSelectionFabOption(
              child: Icon(Icons.pause),
              tooltip: '暂停下载',
              onPressed: () {
                var mangaIds = _msController.selectedItems.map((e) => e.value).toList();
                _msController.exitMultiSelectionMode();
                _allStartOrPause(allStart: false, condition: (id) => mangaIds.contains(id));
              },
            ),
            MultiSelectionFabOption(
              child: Icon(Icons.delete),
              tooltip: '删除下载漫画',
              onPressed: () => _deleteMangas(mangaIds: _msController.selectedItems.map((e) => e.value).toList()),
            ),
          ],
          fabForNormal: ScrollAnimatedFab(
            controller: _fabController,
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
