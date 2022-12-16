import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/download_manga.dart';
import 'package:manhuagui_flutter/page/page/dl_setting.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/download_manga_line.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/storage/download.dart';
import 'package:manhuagui_flutter/service/storage/download_task.dart';
import 'package:manhuagui_flutter/service/storage/queue_manager.dart';

/// 下载列表页，查询数据库并展示 [DownloadedManga] 列表信息，以及展示 [DownloadMangaProgressChangedEvent] 进度信息
class DownloadPage extends StatefulWidget {
  const DownloadPage({
    Key? key,
  }) : super(key: key);

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    var updater = _updateData();
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadMangaProgressChangedEvent>((ev) => updater.item1(ev.mangaId, ev.finished)));
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadedMangaEntityChangedEvent>((ev) => updater.item2(ev.mangaId)));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  final _data = <DownloadedManga>[];
  var _total = 0;
  final _tasks = <int, DownloadMangaQueueTask>{};
  final _bytes = <int, int>{};

  Future<List<DownloadedManga>> _getData() async {
    var data = await DownloadDao.getMangas() ?? [];
    _total = await DownloadDao.getMangaCount() ?? 0;
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

  Tuple2<void Function(int, bool), void Function(int)> _updateData() {
    void throughProgress(final int mangaId, final bool finished) async {
      var task = QueueManager.instance.getDownloadMangaQueueTask(mangaId);
      if (finished) {
        mountedSetState(() => _tasks.removeWhere((key, _) => key == mangaId));
      } else if (task != null) {
        mountedSetState(() => _tasks[mangaId] = task);
        if (task.progress.stage == DownloadMangaProgressStage.waiting || task.progress.stage == DownloadMangaProgressStage.gotChapter) {
          getDownloadedMangaBytes(mangaId: mangaId).then((b) => mountedSetState(() => _bytes[mangaId] = b)); // 仅在最开始等待、以及每次获得新章节时才统计文件大小
        }
      }
    }

    void throughEntity(final int mangaId) async {
      var entity = await DownloadDao.getManga(mid: mangaId);
      if (entity != null) {
        _data.removeWhere((el) => el.mangaId == mangaId);
        _data.insert(0, entity);
        _data.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        if (mounted) setState(() {});
        getDownloadedMangaBytes(mangaId: mangaId).then((b) => mountedSetState(() => _bytes[mangaId] = b)); // 在每次数据库发生变化时都统计文件大小
      }
    }

    return Tuple2(throughProgress, throughEntity);
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
    }

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

  Completer<void>? _allStartCompleter;

  Future<void> _allStartOrPause({required bool allStart}) async {
    if (allStart) {
      // => 全部开始

      // 1. 先判断当前是否在"全部开始"
      if (_allStartCompleter != null) {
        return;
      }
      _allStartCompleter = Completer<void>();

      // 2. 逐漫画"继续下载"，异步，并等待所有"准备下载"结束
      var entities = await DownloadDao.getMangas() ?? _data; // 按照下载时间逆序
      var tasks = QueueManager.instance.getDownloadMangaQueueTasks();
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
          QueueManager.instance.addTask(newTask); // 一起入队
        }
      }

      // 4. 记录"全部开始"已完成
      _allStartCompleter?.complete();
      _allStartCompleter = null;
    } else {
      // => 全部暂停

      // 1. 先取消目前所有的任务
      for (var t in QueueManager.instance.getDownloadMangaQueueTasks()) {
        if (!t.cancelRequested) {
          t.cancel();
        }
      }

      // 2. 等待"全部开始"结束
      await _allStartCompleter?.future;

      // 3. 再取消"全部开始"结束后所有的任务
      for (var t in QueueManager.instance.getDownloadMangaQueueTasks()) {
        if (!t.cancelRequested) {
          t.cancel();
        }
      }
    }
  }

  Future<void> _deleteManga(DownloadedManga entity) async {
    var alsoDeleteFile = AppSetting.instance.dl.defaultToDeleteFiles;
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, _setState) => AlertDialog(
          title: Text('漫画删除确认'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('是否删除《${entity.mangaTitle}》？'),
              SizedBox(height: 5),
              CheckboxListTile(
                title: Text('同时删除已下载的文件'),
                value: alsoDeleteFile,
                onChanged: (v) {
                  alsoDeleteFile = v ?? false;
                  _setState(() {});
                },
                visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('删除'),
              onPressed: () async {
                Navigator.of(c).pop();
                _data.remove(entity);
                _total--;
                await DownloadDao.deleteManga(mid: entity.mangaId);
                await DownloadDao.deleteAllChapters(mid: entity.mangaId);
                if (mounted) setState(() {});
                await updateDlSettingDefaultToDeleteFiles(alsoDeleteFile);
                if (alsoDeleteFile) {
                  await deleteDownloadedManga(mangaId: entity.mangaId);
                }
              },
            ),
            TextButton(
              child: Text('取消'),
              onPressed: () => Navigator.of(c).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('下载列表 (共 $_total 部)'),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: false),
        actions: [
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
          AppBarActionButton(
            icon: Icon(Icons.settings),
            tooltip: '下载设置',
            onPressed: () => showDlSettingDialog(context: context),
          ),
        ],
      ),
      drawer: AppDrawer(
        currentSelection: DrawerSelection.download,
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: RefreshableListView<DownloadedManga>(
        data: _data,
        getData: () => _getData(),
        scrollController: _controller,
        setting: UpdatableDataViewSetting(
          padding: EdgeInsets.symmetric(vertical: 0),
          interactiveScrollbar: true,
          scrollbarCrossAxisMargin: 2,
          placeholderSetting: PlaceholderSetting().copyWithChinese(),
          onPlaceholderStateChanged: (_, __) => _fabController.hide(),
          refreshFirst: true,
          clearWhenRefresh: false,
          clearWhenError: false,
        ),
        separator: Divider(height: 0, thickness: 1),
        itemBuilder: (c, _, entity) {
          DownloadMangaQueueTask? task = _tasks[entity.mangaId];
          return DownloadMangaLineView(
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
            onLineLongPressed: () => _deleteManga(entity),
          );
        },
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
