import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/download_manga_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
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
  VoidCallback? _cancelHandler;

  @override
  void initState() {
    super.initState();
    _cancelHandler = EventBusManager.instance.listen<DownloadMangaProgressChangedEvent>((event) {
      _tasks[event.task.mangaId] = event.task;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cancelHandler?.call();
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

  Widget _buildItem(DownloadedManga item) {
    DownloadMangaQueueTask? task = _tasks[item.mangaId];

    return DownloadMangaLineView(
      mangaTitle: item.mangaTitle,
      mangaCover: item.mangaCover,
      status: task != null
          ? !task.canceled
              ? task.progress.stage == DownloadMangaProgressStage.waiting
                  ? DownloadLineStatus.waiting
                  : DownloadLineStatus.downloading
              : DownloadLineStatus.pausing
          : item.startedChapterCount != item.totalChapterCount
              ? DownloadLineStatus.paused
              : item.successChapterCount == item.totalChapterCount
                  ? DownloadLineStatus.succeeded
                  : DownloadLineStatus.failed,
      startedChapterCount: task?.progress.startedChapters?.length ?? item.startedChapterCount,
      totalChapterCountInTask: task?.chapterIds.length ?? item.totalChapterCount,
      lastDownloadTime: item.updatedAt,
      downloadProgress: task == null
          ? null
          : task.progress.currentChapter == null
              ? DownloadLineProgress.preparing()
              : DownloadLineProgress(
                  chapterTitle: task.progress.currentChapter!.title,
                  currentPageIndex: task.progress.currentChapterStartedPages?.length ?? 0,
                  totalPageCount: task.progress.currentChapter!.pageCount,
                ),
      onActionPressed: () async {
        if (task != null) {
          task.cancel();
        } else {
          // 1. 搜索章节列表
          var chapters = await DownloadDao.getChapters(mid: item.mangaId);
          if (chapters == null || chapters.isEmpty) {
            Fluttertoast.showToast(msg: '无法开始下载');
            return;
          }

          // 2. 构造下载任务
          var task = DownloadMangaQueueTask(
            mangaId: item.mangaId,
            chapterIds: chapters.map((el) => el.chapterId).toList(),
          );

          // !!!
          unawaited(
            Future.microtask(() async {
              // 3. 更新数据库
              var need = await task.prepare(
                mangaTitle: item.mangaTitle,
                mangaCover: item.mangaCover,
                mangaUrl: item.mangaUrl,
                getChapterTitleGroupPages: (cid) {
                  var chapter = chapters.where((el) => el.chapterId == cid).toList().firstOrNull;
                  if (chapter == null) {
                    return null;
                  }
                  var chapterTitle = chapter.chapterTitle;
                  var groupName = chapter.chapterGroup;
                  var chapterPageCount = chapter.totalPageCount;
                  return Tuple3(chapterTitle, groupName, chapterPageCount);
                },
              );

              if (need) {
                // 4. 入队等待执行结束
                await QueueManager.instance.addTask(task);
              }
            }),
          );
        }
      },
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
      onLineLongPressed: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('下载列表'),
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
        extra: UpdatableDataViewExtraWidgets(
          innerTopWidgets: [
            ListHintView.textText(
              leftText: '',
              rightText: '共 $_total 部',
            ),
          ],
        ),
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
