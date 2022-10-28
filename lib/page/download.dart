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

/// 下载列表页，查询数据库并展示 [DownloadedManga] 列表信息
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
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      // progress related
      _cancelHandlers.add(EventBusManager.instance.listen<DownloadMangaProgressChangedEvent>((event) async {
        var mangaId = event.task.mangaId;
        if (!event.finished) {
          _tasks[mangaId] = event.task;
        } else {
          _tasks.removeWhere((key, _) => key == mangaId);
        }
        if (event.task.progress.stage == DownloadMangaProgressStage.waiting || event.task.progress.stage == DownloadMangaProgressStage.gotChapter) {
          // 只有在最开始等待、以及每次获得新章节数据时才遍历并获取文件大小
          _bytes[mangaId] = await getDownloadedMangaBytes(mangaId: mangaId);
        }
        if (mounted) setState(() {});
      }));

      // entity related
      _cancelHandlers.add(EventBusManager.instance.listen<DownloadedMangaEntityChangedEvent>((event) async {
        var mangaId = event.mid;
        var newItem = await DownloadDao.getManga(mid: mangaId);
        if (newItem != null) {
          _data.removeWhere((el) => el.mangaId == mangaId);
          _data.insert(0, newItem);
          _data.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          _bytes[mangaId] = await getDownloadedMangaBytes(mangaId: mangaId);
          if (mounted) setState(() {});
        }
      }));
    });
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
  final _bytes = <int, int>{};

  Future<List<DownloadedManga>> _getData() async {
    var data = await DownloadDao.getMangas() ?? [];
    _total = await DownloadDao.getMangaCount() ?? 0;
    _tasks.clear();
    for (var task in QueueManager.instance.tasks.whereType<DownloadMangaQueueTask>()) {
      _tasks[task.mangaId] = task;
    }
    for (var item in data) {
      _bytes[item.mangaId] = await getDownloadedMangaBytes(mangaId: item.mangaId);
    }
    if (mounted) setState(() {});
    return data;
  }

  Future<void> _pauseOrContinue({required DownloadedManga item, required DownloadMangaQueueTask? task}) async {
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

    // 3. 入队等待执行，异步
    if (need) {
      QueueManager.instance.addTask(newTask);
    }
  }

  Future<void> _delete(DownloadedManga item) async {
    var alsoDeleteFile = false;

    Future<void> realDelete(bool alsoDeleteFile) async {
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
      builder: (c) => StatefulBuilder(
        builder: (c, _setState) => AlertDialog(
          title: Text('漫画删除确认'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('是否删除 ${item.mangaTitle}？'),
              SizedBox(height: 5),
              CheckboxListTile(
                title: Text('同时删除已下载的文件'),
                value: alsoDeleteFile,
                onChanged: (v) {
                  alsoDeleteFile = v ?? false;
                  _setState(() {});
                },
                dense: false,
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('删除'),
              onPressed: () async {
                Navigator.of(c).pop();
                await realDelete(alsoDeleteFile);
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
      if (!item.error) {
        if (item.startedPageCountInAll != item.totalPageCountInAll) {
          status = DownloadLineStatus.paused; // stopped
        } else if (item.successChapterIds.length == item.totalChapterIds.length) {
          status = DownloadLineStatus.succeeded; // stopped
        } else {
          status = DownloadLineStatus.failed; // stopped (failed to get chapter or download page)
        }
      } else {
        status = DownloadLineStatus.failed; // stopped (failed to get manga)
      }
    }

    DownloadLineProgress progress;
    var downloadBytes = _bytes[item.mangaId] ?? 0;
    if (task == null || task.succeeded || (!task.canceled && task.progress.stage == DownloadMangaProgressStage.waiting)) {
      progress = DownloadLineProgress.stopped(
        startedChapterCount: item.startedChapterIds.length,
        totalChapterCount: item.totalChapterIds.length,
        downloadedBytes: downloadBytes,
        notFinishedPageCount: item.error ? -1 : item.totalPageCountInAll - item.successPageCountInAll,
        lastDownloadTime: item.updatedAt,
      );
    } else if (task.progress.manga == null || task.progress.currentChapter == null) {
      progress = DownloadLineProgress.preparing(
        startedChapterCount: task.progress.startedChapters?.length ?? 0,
        totalChapterCount: task.chapterIds.length,
        downloadedBytes: downloadBytes,
        gettingManga: task.progress.manga == null,
      );
    } else {
      progress = DownloadLineProgress.running(
        startedChapterCount: task.progress.startedChapters?.length ?? 0,
        totalChapterCount: task.chapterIds.length,
        downloadedBytes: downloadBytes,
        chapterTitle: task.progress.currentChapter!.title,
        triedPageCount: (task.progress.successChapterPageCount ?? 0) + (task.progress.failedChapterPageCount ?? 0),
        totalPageCount: task.progress.currentChapter!.pageCount,
      );
    }

    return DownloadMangaLineView(
      mangaTitle: item.mangaTitle,
      mangaCover: item.mangaCover,
      status: status,
      progress: progress,
      onActionPressed: () => _pauseOrContinue(item: item, task: task),
      onLinePressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (c) => MangaPage(
            id: item.mangaId,
            title: item.mangaTitle,
            url: item.mangaUrl,
          ),
        ),
      ),
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
