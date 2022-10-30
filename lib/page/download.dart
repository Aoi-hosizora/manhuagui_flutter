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
import 'package:manhuagui_flutter/service/storage/download_manga.dart';
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

  var _setting = DlSetting.defaultSetting();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      // setting
      _setting = await DlSettingPrefs.getSetting();
      if (mounted) setState(() {});

      // progress related
      _cancelHandlers.add(EventBusManager.instance.listen<DownloadMangaProgressChangedEvent>((event) async {
        var mangaId = event.task.mangaId;
        if (!event.finished) {
          _tasks[mangaId] = event.task;
        } else {
          _tasks.removeWhere((key, _) => key == mangaId);
        }
        if (mounted) setState(() {});
        if (event.task.progress.stage == DownloadMangaProgressStage.waiting || event.task.progress.stage == DownloadMangaProgressStage.gotChapter) {
          // 只有在最开始等待、以及每次获得新章节数据时才遍历并获取文件大小
          getDownloadedMangaBytes(mangaId: mangaId).then((b) {
            _bytes[mangaId] = b;
            if (mounted) setState(() {});
          });
        }
      }));

      // entity related
      _cancelHandlers.add(EventBusManager.instance.listen<DownloadedMangaEntityChangedEvent>((event) async {
        var mangaId = event.mangaId;
        var newEntity = await DownloadDao.getManga(mid: mangaId);
        if (newEntity != null) {
          _data.removeWhere((el) => el.mangaId == mangaId);
          _data.insert(0, newEntity);
          _data.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          if (mounted) setState(() {});
          getDownloadedMangaBytes(mangaId: mangaId).then((b) {
            _bytes[mangaId] = b;
            if (mounted) setState(() {});
          });
        }
      }));
    });
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
    for (var task in QueueManager.instance.tasks.whereType<DownloadMangaQueueTask>()) {
      _tasks[task.mangaId] = task;
    }
    for (var entity in data) {
      _bytes[entity.mangaId] = await getDownloadedMangaBytes(mangaId: entity.mangaId); // TODO slow
    }
    if (mounted) setState(() {});
    return data;
  }

  Future<void> _pauseOrContinue({required DownloadedManga entity, required DownloadMangaQueueTask? task}) async {
    if (task != null && !task.canceled && !task.succeeded) {
      // => 暂停
      task.cancel();
      return;
    }

    // => 继续
    // 1. 构造下载任务
    var newTask = DownloadMangaQueueTask(
      mangaId: entity.mangaId,
      chapterIds: entity.downloadedChapters.map((el) => el.chapterId).toList(),
      parallel: _setting.downloadPagesTogether,
    );

    // 2. 更新数据库
    var need = await newTask.prepare(
      mangaTitle: entity.mangaTitle,
      mangaCover: entity.mangaCover,
      mangaUrl: entity.mangaUrl,
      getChapterTitleGroupPages: (cid) {
        var chapter = entity.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull;
        if (chapter == null) {
          return null; // unreachable
        }
        var chapterTitle = chapter.chapterTitle;
        var groupName = chapter.chapterGroup;
        var chapterPageCount = chapter.totalPageCount;
        return Tuple3(chapterTitle, groupName, chapterPageCount);
      },
    );

    // 3. 入队等待执行，异步
    if (need) {
      QueueManager.instance.addTask(newTask);
    }
  }

  Future<void> _delete(DownloadedManga entity) async {
    var alsoDeleteFile = _setting.defaultToDeleteFiles;
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, _setState) => AlertDialog(
          title: Text('漫画删除确认'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('是否删除 ${entity.mangaTitle}？'),
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
                if (alsoDeleteFile) {
                  await deleteDownloadedManga(entity.mangaId);
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

  Future<void> _allStartOrPause({required bool allStart}) async {
    if (allStart) {
      // => 全部开始
      var entities = await DownloadDao.getMangas() ?? _data;
      var tasks = QueueManager.instance.tasks.whereType<DownloadMangaQueueTask>();
      for (var entity in entities) {
        var task = tasks.where((el) => el.mangaId == entity.mangaId).firstOrNull;
        if (task == null || !task.canceled) {
          _pauseOrContinue(entity: entity, task: null);
        }
      }
    } else {
      // => 全部暂停
      for (var t in QueueManager.instance.tasks.whereType<DownloadMangaQueueTask>()) {
        if (!t.canceled) {
          t.cancel(); // TODO ???
        }
      }
    }
  }

  Future<void> _onSettingPressed() {
    var setting = _setting.copyWith(); // TODO 章节下载顺序
    return showDialog(
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
              _setting = setting;
              if (mounted) setState(() {});
              await DlSettingPrefs.setSetting(_setting);

              // apply settings
              var tasks = QueueManager.instance.tasks.whereType<DownloadMangaQueueTask>();
              for (var t in tasks) {
                t.changeParallel(_setting.downloadPagesTogether);
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
              MaterialPageRoute(
                builder: (c) => DownloadTocPage(
                  mangaId: entity.mangaId,
                  mangaTitle: entity.mangaTitle,
                  mangaCover: entity.mangaCover,
                  mangaUrl: entity.mangaUrl,
                ),
              ),
            ),
            onLineLongPressed: () => _delete(entity),
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
