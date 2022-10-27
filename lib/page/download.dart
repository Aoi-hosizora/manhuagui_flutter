import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/download_manga_line.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/storage/download_manga.dart';
import 'package:manhuagui_flutter/service/storage/queue_manager.dart';

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
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadMangaProgressChangedEvent>((event) {
      _tasks[event.task.mangaId] = event.task;
      if (mounted) setState(() {});
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadedMangaEntityChangedEvent>((event) async {
      var newItem = await DownloadDao.getManga(mid: event.mid);
      if (newItem == null) {
        return;
      }
      _data.removeWhere((el) => el.mangaId == event.mid);
      _data.insert(0, newItem);
      _data.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (mounted) setState(() {});
    }));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call);
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  final _data = <DownloadedManga>[];
  var _total = 0;
  final _tasks = <int, DownloadMangaQueueTask>{};

  Future<List<DownloadedManga>> _getData() async {
    var data = await DownloadDao.getMangas() ?? [];
    _total = await DownloadDao.getMangaCount() ?? 0;
    _tasks.clear();
    for (var t in QueueManager.instance.tasks.whereType<DownloadMangaQueueTask>()) {
      _tasks[t.mangaId] = t;
    }
    if (mounted) setState(() {});
    return data;
  }

  Future<void> _onItemActionPressed(DownloadedManga item, DownloadMangaQueueTask? task) async {
    if (task != null && !task.canceled && !task.succeeded) {
      // => 暂停
      task.cancel();
      return;
    }

    // => 继续
    // 1. 构造下载任务
    var newTask = DownloadMangaQueueTask(
      mangaId: item.mangaId,
      chapterIds: item.downloadedChapters.map((el) => el.chapterId).toList(),
    );

    // !!!
    unawaited(
      Future.microtask(() async {
        // 2. 更新数据库
        var need = await newTask.prepare(
          mangaTitle: item.mangaTitle,
          mangaCover: item.mangaCover,
          mangaUrl: item.mangaUrl,
          getChapterTitleGroupPages: (cid) {
            var chapter = item.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull;
            if (chapter == null) {
              return null; // unreachable
            }
            var chapterTitle = chapter.chapterTitle;
            var groupName = chapter.chapterGroup;
            var chapterPageCount = chapter.totalPageCount;
            return Tuple3(chapterTitle, groupName, chapterPageCount);
          },
        );

        if (need) {
          // 3. 入队并等待执行结束
          await QueueManager.instance.addTask(newTask);
        }
      }),
    );
  }

  Future<void> _delete(DownloadedManga item) async {
    Future<void> delete(bool alsoDeleteFile) async {
      _data.remove(item);
      _total--;
      await DownloadDao.deleteManga(mid: item.mangaId);
      await DownloadDao.deleteAllChapters(mid: item.mangaId);
      if (mounted) setState(() {});
      if (alsoDeleteFile) {
        await deleteDownloadedManga(item.mangaId);
      }
    }

    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('漫画删除确认'),
        content: Text('是否删除 ${item.mangaTitle}？'),
        actions: [
          TextButton(
            child: Text('删除记录'),
            onPressed: () async {
              Navigator.of(c).pop();
              await delete(false);
            },
          ),
          TextButton(
            child: Text('删除记录与文件'),
            onPressed: () async {
              Navigator.of(c).pop();
              await delete(true);
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

  Widget _buildItem(DownloadedManga item) {
    DownloadMangaQueueTask? task = _tasks[item.mangaId];

    DownloadLineStatus status;
    if (task != null && !task.succeeded) {
      if (!task.canceled) {
        if (task.progress.stage == DownloadMangaProgressStage.waiting) {
          status = DownloadLineStatus.waiting; // stopped
        } else {
          status = DownloadLineStatus.downloading; // preparing / running
        }
      } else {
        status = DownloadLineStatus.pausing; // preparing / running
      }
    } else {
      if (item.startedChapterIds.length != item.totalChapterIds.length) {
        status = DownloadLineStatus.paused; // stopped
      } else {
        if (item.successChapterIds.length == item.totalChapterIds.length) {
          status = DownloadLineStatus.succeeded; // stopped
        } else {
          status = DownloadLineStatus.failed; // stopped
        }
      }
    }

    DownloadLineProgress progress;
    if (task == null || task.succeeded || (!task.canceled && task.progress.stage == DownloadMangaProgressStage.waiting)) {
      progress = DownloadLineProgress.stopped(
        startedChapterCount: item.startedChapterIds.length,
        totalChapterCount: item.totalChapterIds.length,
        failedPageCountInAll: item.failedPageCountInAll,
        lastDownloadTime: item.updatedAt,
      );
    } else if (task.progress.currentChapter == null) {
      progress = DownloadLineProgress.preparing(
        startedChapterCount: task.progress.startedChapters?.length ?? 0,
        totalChapterCount: task.chapterIds.length,
        gettingManga: task.progress.manga == null,
      );
    } else {
      progress = DownloadLineProgress.running(
        startedChapterCount: task.progress.startedChapters?.length ?? 0,
        totalChapterCount: task.chapterIds.length,
        chapterTitle: task.progress.currentChapter!.title,
        triedPageCount: (task.progress.successPageCountInChapter ?? 0) + (task.progress.failedPageCountInChapter ?? 0),
        totalPageCount: task.progress.currentChapter!.pageCount,
      );
    }

    return DownloadMangaLineView(
      mangaTitle: item.mangaTitle,
      mangaCover: item.mangaCover,
      status: status,
      progress: progress,
      onActionPressed: () => _onItemActionPressed(item, task),
      onLinePressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (c) => MangaPage(
              id: item.mangaId,
              title: item.mangaTitle,
              url: item.mangaUrl,
            ),
          ),
        );
      },
      onLineLongPressed: () => _delete(item),
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
            onPressed: () {},
          ),
          AppBarActionButton(
            icon: Icon(Icons.pause),
            tooltip: '全部暂停',
            onPressed: () {},
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
        itemBuilder: (c, _, item) => _buildItem(item),
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
