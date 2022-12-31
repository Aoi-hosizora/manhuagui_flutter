import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:intl/intl.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/download_line.dart';
import 'package:manhuagui_flutter/service/storage/download_task.dart';

/// 漫画下载行（小），在 [DownloadPage] 使用
class DownloadMangaLineView extends StatelessWidget {
  const DownloadMangaLineView({
    Key? key,
    required this.mangaEntity,
    required this.downloadTask,
    required this.downloadedBytes,
    required this.onActionPressed,
    required this.onLinePressed,
    required this.onLineLongPressed,
  }) : super(key: key);

  final DownloadedManga mangaEntity;
  final DownloadMangaQueueTask? downloadTask;
  final int downloadedBytes;
  final void Function() onActionPressed;
  final void Function() onLinePressed;
  final void Function()? onLineLongPressed;

  @override
  Widget build(BuildContext context) {
    var progress = DownloadMangaLineProgress.fromEntityAndTask(entity: mangaEntity, task: downloadTask);
    var downloadedSize = filesizeWithoutSpace(downloadedBytes, 2, true);

    // !!!
    switch (progress.status) {
      case DownloadMangaLineStatus.waiting:
      case DownloadMangaLineStatus.paused:
      case DownloadMangaLineStatus.succeeded:
      case DownloadMangaLineStatus.nupdate:
      case DownloadMangaLineStatus.failed:
        assert(
          progress.stopped,
          'progress.stopped must be true when status is not preparing, not downloading and not pausing',
        );
        return DownloadLineView(
          imageUrl: mangaEntity.mangaCover,
          title: mangaEntity.mangaTitle,
          icon1: Icons.download,
          text1: '已下载章节 ${progress.startedChapterCount}/${progress.totalChapterCount} ($downloadedSize)',
          icon2: Icons.bar_chart,
          text2: progress.status == DownloadMangaLineStatus.waiting
              ? '等待下载中'
              : progress.status == DownloadMangaLineStatus.paused
                  ? '已暂停 (${progress.notFinishedChapterCount!} 章节共 ${progress.notFinishedPageCount!} 页未完成)'
                  : progress.status == DownloadMangaLineStatus.succeeded
                      ? '下载已完成'
                      : progress.status == DownloadMangaLineStatus.nupdate
                          ? '下载已完成 (需要更新数据)'
                          : progress.notFinishedPageCount! < 0
                              ? '下载出错'
                              : '下载出错 (${progress.notFinishedChapterCount!} 章节共 ${progress.notFinishedPageCount!} 页未完成)',
          icon3: Icons.access_time,
          text3: '下载于 ${progress.formattedLastDownloadTime!}',
          showProgressBar: false,
          progressBarValue: null,
          disableAction: false,
          actionIcon: progress.status == DownloadMangaLineStatus.waiting ? Icons.pause : Icons.play_arrow,
          onActionPressed: onActionPressed,
          onLinePressed: onLinePressed,
          onLineLongPressed: onLineLongPressed,
        );
      case DownloadMangaLineStatus.preparing:
      case DownloadMangaLineStatus.downloading:
      case DownloadMangaLineStatus.pausing:
        assert(
          !progress.stopped,
          'progress.stopped must be false when status is preparing, downloading or pausing',
        );
        return DownloadLineView(
          imageUrl: mangaEntity.mangaCover,
          title: mangaEntity.mangaTitle,
          icon1: Icons.download,
          text1: '正在下载章节 ${progress.startedChapterCount}/${progress.totalChapterCount} ($downloadedSize)',
          icon2: Icons.bar_chart,
          text2: (progress.preparing
                  ? progress.gettingManga
                      ? '正在获取漫画信息'
                      : '当前正在下载 ${progress.chapterTitle ?? '未知章节'}'
                  : '当前正在下载 ${progress.chapterTitle!} ${progress.triedPageCount!}/${progress.totalPageCount!}页') +
              (progress.status == DownloadMangaLineStatus.pausing ? ' (暂停中)' : ''),
          icon3: Icons.downloading,
          text3: '　',
          showProgressBar: true,
          progressBarValue: progress.status == DownloadMangaLineStatus.pausing || progress.preparing
              ? null //
              : (progress.totalPageCount! == 0 ? 0.0 : progress.triedPageCount! / progress.totalPageCount!),
          disableAction: progress.status == DownloadMangaLineStatus.pausing,
          actionIcon: Icons.pause,
          onActionPressed: onActionPressed,
          onLinePressed: onLinePressed,
          onLineLongPressed: onLineLongPressed,
        );
    }
  }
}

/// 漫画下载块（大），在 [DownloadMangaPage] 使用
class DownloadMangaBlockView extends StatelessWidget {
  const DownloadMangaBlockView({
    Key? key,
    required this.mangaEntity,
    required this.downloadTask,
    required this.downloadedBytes,
  }) : super(key: key);

  final DownloadedManga mangaEntity;
  final DownloadMangaQueueTask? downloadTask;
  final int downloadedBytes;

  @override
  Widget build(BuildContext context) {
    var progress = DownloadMangaLineProgress.fromEntityAndTask(entity: mangaEntity, task: downloadTask);
    var downloadedSize = filesizeWithoutSpace(downloadedBytes, 2, true);

    // !!!
    switch (progress.status) {
      case DownloadMangaLineStatus.waiting:
      case DownloadMangaLineStatus.paused:
      case DownloadMangaLineStatus.succeeded:
      case DownloadMangaLineStatus.nupdate:
      case DownloadMangaLineStatus.failed:
        assert(
          progress.stopped,
          'progress.stopped must be true when status is not preparing, not downloading and not pausing',
        );
        return DownloadBlockView(
          imageUrl: mangaEntity.mangaCover,
          title: mangaEntity.mangaTitle,
          icon1: Icons.download,
          text1: '已下载章节 ${progress.startedChapterCount}/${progress.totalChapterCount} ($downloadedSize)',
          icon2: Icons.bar_chart,
          text2: progress.status == DownloadMangaLineStatus.waiting
              ? '等待下载中'
              : progress.status == DownloadMangaLineStatus.paused
                  ? '已暂停 (${progress.notFinishedChapterCount!} 章节共 ${progress.notFinishedPageCount!} 页未完成)'
                  : progress.status == DownloadMangaLineStatus.succeeded
                      ? '下载已完成'
                      : progress.status == DownloadMangaLineStatus.nupdate
                          ? '下载已完成 (需要更新数据)'
                          : progress.notFinishedPageCount! < 0
                              ? '下载出错'
                              : '下载出错 (${progress.notFinishedChapterCount!} 章节共 ${progress.notFinishedPageCount!} 页未完成)',
          icon3: Icons.access_time,
          text3: '下载于 ${progress.formattedLastDownloadTime!}',
          showProgressBar: false,
          progressBarValue: null,
        );
      case DownloadMangaLineStatus.preparing:
      case DownloadMangaLineStatus.downloading:
      case DownloadMangaLineStatus.pausing:
        assert(
          !progress.stopped,
          'progress.stopped must be false when status is preparing, downloading or pausing',
        );
        return DownloadBlockView(
          imageUrl: mangaEntity.mangaCover,
          title: mangaEntity.mangaTitle,
          icon1: Icons.download,
          text1: '正在下载章节 ${progress.startedChapterCount}/${progress.totalChapterCount} ($downloadedSize)',
          icon2: Icons.bar_chart,
          text2: (progress.preparing
                  ? progress.gettingManga
                      ? '正在获取漫画信息'
                      : '当前正在下载 ${progress.chapterTitle ?? '未知章节'}'
                  : '当前正在下载 ${progress.chapterTitle!} ${progress.triedPageCount!}/${progress.totalPageCount!}页') +
              (progress.status == DownloadMangaLineStatus.pausing ? ' (暂停中)' : ''),
          icon3: Icons.downloading,
          text3: '　',
          showProgressBar: true,
          progressBarValue: progress.status == DownloadMangaLineStatus.pausing || progress.preparing
              ? null //
              : (progress.totalPageCount! == 0 ? 0.0 : progress.triedPageCount! / progress.totalPageCount!),
        );
    }
  }
}

enum DownloadMangaLineStatus {
  // 队列中
  waiting, // whenStopped
  preparing, // whenPreparing
  downloading, // whenDownloading
  pausing, // whenPreparing / whenDownloading

  // 已结束
  paused, // whenStopped
  succeeded, // whenStopped
  nupdate, // whenStopped
  failed, // whenStopped
}

class DownloadMangaLineProgress {
  const DownloadMangaLineProgress.whenStopped({
    required this.status,
    required this.startedChapterCount,
    required this.totalChapterCount,
    required int this.notFinishedPageCount,
    required int this.notFinishedChapterCount,
    required DateTime this.lastDownloadTime,
  })  : stopped = true,
        preparing = false,
        gettingManga = false,
        chapterTitle = null,
        triedPageCount = null,
        totalPageCount = null;

  const DownloadMangaLineProgress.whenPreparing({
    required this.status,
    required this.startedChapterCount,
    required this.totalChapterCount,
    required this.gettingManga,
    required this.chapterTitle,
  })  : stopped = false,
        preparing = true,
        notFinishedPageCount = null,
        notFinishedChapterCount = null,
        lastDownloadTime = null,
        triedPageCount = null,
        totalPageCount = null;

  const DownloadMangaLineProgress.whenDownloading({
    required this.status,
    required this.startedChapterCount,
    required this.totalChapterCount,
    required String this.chapterTitle,
    required int this.triedPageCount,
    required int this.totalPageCount,
  })  : stopped = false,
        preparing = false,
        gettingManga = false,
        notFinishedPageCount = null,
        notFinishedChapterCount = null,
        lastDownloadTime = null;

  // both
  final DownloadMangaLineStatus status;
  final int startedChapterCount;
  final int totalChapterCount;

  // stopped
  final bool stopped;
  final int? notFinishedPageCount;
  final int? notFinishedChapterCount;
  final DateTime? lastDownloadTime;

  // preparing / downloading
  final bool preparing;
  final bool gettingManga;
  final String? chapterTitle;
  final int? triedPageCount;
  final int? totalPageCount;

  String? get formattedLastDownloadTime => lastDownloadTime == null ? null : DateFormat('yyyy-MM-dd HH:mm:ss').format(lastDownloadTime!);

  // !!!
  static DownloadMangaLineProgress fromEntityAndTask({required DownloadedManga entity, required DownloadMangaQueueTask? task}) {
    DownloadMangaLineStatus status;
    if (task != null) {
      if (!task.cancelRequested) {
        if (!task.startDoing) {
          status = DownloadMangaLineStatus.waiting; // whenStopped
        } else if (task.progress.manga == null || task.progress.currentChapter == null) {
          status = DownloadMangaLineStatus.preparing; // whenPreparing
        } else {
          status = DownloadMangaLineStatus.downloading; // whenDownloading
        }
      } else {
        status = DownloadMangaLineStatus.pausing; // whenPreparing / whenDownloading
      }
    } else {
      if (!entity.error) {
        if (entity.triedPageCountInAll != entity.totalPageCountInAll) {
          status = DownloadMangaLineStatus.paused; // whenStopped
        } else if (entity.allChaptersSucceeded) {
          if (!entity.needUpdate) {
            status = DownloadMangaLineStatus.succeeded; // whenStopped
          } else {
            status = DownloadMangaLineStatus.nupdate; // whenStopped
          }
        } else {
          status = DownloadMangaLineStatus.failed; // whenStopped (failed to get chapter or download page)
        }
      } else {
        status = DownloadMangaLineStatus.failed; // whenStopped (failed to get manga)
      }
    }

    if (task == null || (!task.cancelRequested && !task.startDoing)) {
      // waiting / paused / succeeded / update / failed => from entity
      assert(
        status != DownloadMangaLineStatus.preparing && status != DownloadMangaLineStatus.downloading && status != DownloadMangaLineStatus.pausing,
        'status must not be preparing, downloading and pausing when current progress is stopped',
      );
      return DownloadMangaLineProgress.whenStopped(
        status: status,
        startedChapterCount: entity.triedChapterIds.length,
        totalChapterCount: entity.totalChapterIds.length,
        notFinishedPageCount: entity.error ? -1 : entity.totalPageCountInAll - entity.successPageCountInAll,
        notFinishedChapterCount: entity.error ? -1 : entity.failedChapterCount,
        lastDownloadTime: entity.updatedAt,
      );
    } else {
      // preparing / downloading / pausing => from task
      assert(
        status == DownloadMangaLineStatus.preparing || status == DownloadMangaLineStatus.downloading || status == DownloadMangaLineStatus.pausing,
        'status must be preparing, downloading or pausing when current progress is not stopped',
      );
      var taskStarted = task.progress.startedChapterIds ?? [], taskTotal = task.uncanceledChapterIds;
      var entityStarted = entity.triedChapterIds, entityTotal = entity.totalChapterIds;
      var mergedStarted = {...taskStarted, ...entityStarted}, mergedTotal = {...taskTotal, ...entityTotal};
      if (task.progress.manga == null || task.progress.currentChapter == null) {
        return DownloadMangaLineProgress.whenPreparing(
          status: status,
          startedChapterCount: mergedStarted.length,
          totalChapterCount: mergedTotal.length,
          gettingManga: task.progress.manga == null,
          chapterTitle: task.progress.currentChapterTitle,
        );
      } else {
        return DownloadMangaLineProgress.whenDownloading(
          status: status,
          startedChapterCount: mergedStarted.length,
          totalChapterCount: mergedTotal.length,
          chapterTitle: task.progress.currentChapter!.title,
          triedPageCount: task.progress.triedChapterPageCount ?? 0,
          totalPageCount: task.progress.currentChapter!.pageCount,
        );
      }
    }
  }
}
