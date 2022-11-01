import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/download_toc.dart';
import 'package:manhuagui_flutter/page/page/dl_setting.dart';
import 'package:manhuagui_flutter/page/view/download_manga_line.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/prefs/dl_setting.dart';
import 'package:manhuagui_flutter/service/storage/download_image.dart';
import 'package:manhuagui_flutter/service/storage/download_manga_task.dart';
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

    // progress related
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadMangaProgressChangedEvent>((event) async {
      if (event.finished) {
        _tasks.removeWhere((key, _) => key == event.mangaId);
        if (mounted) setState(() {});
      } else {
        var task = QueueManager.instance.getDownloadMangaQueueTask(event.mangaId);
        if (task != null) {
          _tasks[event.mangaId] = task;
          if (mounted) setState(() {});
          if (task.progress.stage == DownloadMangaProgressStage.waiting || task.progress.stage == DownloadMangaProgressStage.gotChapter) {
            getDownloadedMangaBytes(mangaId: event.mangaId).then((b) {
              _bytes[event.mangaId] = b; // 只有在最开始等待、以及每次获得新章节时才遍历统计文件大小
              if (mounted) setState(() {});
            });
          }
        }
      }
    }));

    // entity related
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadedMangaEntityChangedEvent>((event) async {
      var newEntity = await DownloadDao.getManga(mid: event.mangaId);
      if (newEntity != null) {
        _data.removeWhere((el) => el.mangaId == event.mangaId);
        _data.insert(0, newEntity);
        _data.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        if (mounted) setState(() {});
        getDownloadedMangaBytes(mangaId: event.mangaId).then((b) {
          _bytes[event.mangaId] = b; // 在每次数据库发生变化时都遍历统计文件大小
          if (mounted) setState(() {});
        });
      }
    }));
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
      getDownloadedMangaBytes(mangaId: entity.mangaId).then((b) {
        _bytes[entity.mangaId] = b;
        if (mounted) setState(() {});
      });
    }
    return data;
  }

  Future<DownloadMangaQueueTask?> _pauseOrContinue({required DownloadedManga entity, required DownloadMangaQueueTask? task, bool addTask = true}) async {
    if (task != null && !task.canceled && !task.succeeded) {
      // 暂停 => 取消任务
      task.cancel();
      return null;
    }

    // 继续 => 快速构造下载任务，同步更新数据库，并根据 addTask 参数按要求入队
    var setting = await DlSettingPrefs.getSetting();
    DownloadMangaQueueTask? newTask = await quickBuildDownloadMangaQueueTask(
      mangaId: entity.mangaId,
      mangaTitle: entity.mangaTitle,
      mangaCover: entity.mangaCover,
      mangaUrl: entity.mangaUrl,
      chapterIds: entity.downloadedChapters.map((el) => el.chapterId).toList(),
      parallel: setting.downloadPagesTogether,
      invertOrder: setting.invertDownloadOrder,
      addToTask: false,
      throughChapterList: entity.downloadedChapters,
    );
    if (addTask && newTask != null) {
      QueueManager.instance.addTask(newTask);
    }
    return newTask;
  }

  Future<void> _deleteManga(DownloadedManga entity) async {
    var setting = await DlSettingPrefs.getSetting();
    var alsoDeleteFile = setting.defaultToDeleteFiles;
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, _setState) => AlertDialog(
          title: Text('漫画删除确认'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('是否删除漫画《${entity.mangaTitle}》？'),
              SizedBox(height: 5),
              CheckboxListTile(
                title: Text('同时删除已下载的文件'),
                value: alsoDeleteFile,
                onChanged: (v) {
                  alsoDeleteFile = v ?? false;
                  _setState(() {});
                },
                dense: false,
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

                var setting = await DlSettingPrefs.getSetting();
                setting = setting.copyWith(defaultToDeleteFiles: alsoDeleteFile);
                await DlSettingPrefs.setSetting(setting);
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

  Completer<void>? _allStartCompleter;

  Future<void> _allStartOrPause({required bool allStart}) async {
    if (allStart) {
      // => 全部开始

      // 1. 先判断当前是否在"全部开始"
      if (_allStartCompleter != null) {
        return;
      }
      _allStartCompleter = Completer<void>();

      // 2. 逐漫画继续下载，异步，并等待所有"下载准备"结束
      var entities = await DownloadDao.getMangas() ?? _data;
      var tasks = QueueManager.instance.getDownloadMangaQueueTasks();
      var prepares = <Future<DownloadMangaQueueTask?>>[];
      for (var entity in entities) {
        var task = tasks.where((el) => el.mangaId == entity.mangaId).firstOrNull;
        if (task == null || !task.canceled) {
          prepares.add(_pauseOrContinue(entity: entity, task: null, addTask: false));
        }
      }
      var newTasks = await Future.wait(prepares);

      // 3. 按照下载时间逆序，并将新的下载任务入队
      var newTaskMap = <int, DownloadMangaQueueTask>{};
      for (var task in newTasks) {
        if (task != null) {
          newTaskMap[task.mangaId] = task;
        }
      }
      for (var entity in entities) {
        var newTask = newTaskMap[entity.mangaId];
        if (newTask != null) {
          QueueManager.instance.addTask(newTask);
        }
      }

      // 4. 记录"全部开始"已完成
      _allStartCompleter?.complete();
      _allStartCompleter = null;
    } else {
      // => 全部暂停

      // 1. 先取消目前所有的任务
      for (var t in QueueManager.instance.getDownloadMangaQueueTasks()) {
        if (!t.canceled) {
          t.cancel();
        }
      }

      // 2. 等待"全部开始"结束
      await _allStartCompleter?.future;

      // 3. 再取消"全部开始"结束后所有的任务
      for (var t in QueueManager.instance.getDownloadMangaQueueTasks()) {
        if (!t.canceled) {
          t.cancel();
        }
      }
    }
  }

  Future<void> _onSettingPressed() async {
    var setting = await DlSettingPrefs.getSetting();
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('下载设置'),
        content: DlSettingSubPage(
          setting: setting,
          onSettingChanged: (s) => setting = s,
        ),
        actions: [
          TextButton(
            child: Text('确定'),
            onPressed: () async {
              Navigator.of(c).pop();
              await DlSettingPrefs.setSetting(setting);
              for (var t in QueueManager.instance.getDownloadMangaQueueTasks()) {
                t.changeParallel(setting.downloadPagesTogether);
              }
            },
          ),
          TextButton(
            child: Text('取消'),
            onPressed: () => Navigator.of(c).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('下载列表 (共 $_total 部)'),
        leading: AppBarActionButton.leading(context: context),
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
            onPressed: () => _onSettingPressed(),
          ),
        ],
      ),
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
            onActionPressed: () => _pauseOrContinue(entity: entity, task: task),
            onLinePressed: () => Navigator.of(context).push(
              CustomMaterialPageRoute(
                context: context,
                builder: (c) => DownloadTocPage(
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
