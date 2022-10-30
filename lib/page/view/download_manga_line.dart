import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:intl/intl.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/download_line.dart';
import 'package:manhuagui_flutter/service/storage/download_manga_task.dart';

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
    var downloadedSize = filesize(downloadedBytes, 2, false);

    // !!!
    switch (progress.status) {
      case DownloadMangaLineStatus.waiting:
      case DownloadMangaLineStatus.paused:
      case DownloadMangaLineStatus.succeeded:
      case DownloadMangaLineStatus.failed:
        assert(
          progress.stopped,
          'progress.stopped must be true when status is not downloading and pausing',
        );
        return DownloadLineView(
          imageUrl: mangaEntity.mangaCover,
          title: mangaEntity.mangaTitle,
          icon1: Icons.download,
          text1: '已下载章节 ${progress.startedChapterCount}/${progress.totalChapterCount} ($downloadedSize)',
          icon2: Icons.access_time,
          text2: '下载于 ${DateFormat('yyyy-MM-dd HH:mm:ss').format(progress.lastDownloadTime!)}',
          icon3: Icons.bar_chart,
          text3: progress.status == DownloadMangaLineStatus.waiting
              ? '等待中'
              : progress.status == DownloadMangaLineStatus.paused
                  ? '已暂停 (${progress.notFinishedChapterCount!} 章节共 ${progress.notFinishedPageCount!} 页未完成)'
                  : progress.status == DownloadMangaLineStatus.succeeded
                      ? '已完成'
                      : progress.notFinishedPageCount! < 0
                          ? '下载出错'
                          : '下载出错 (${progress.notFinishedChapterCount!} 章节共 ${progress.notFinishedPageCount!} 页未完成)',
          showProgressBar: false,
          progressBarValue: null,
          disableAction: false,
          actionIcon: progress.status == DownloadMangaLineStatus.waiting ? Icons.pause : Icons.play_arrow,
          onActionPressed: onActionPressed,
          onLinePressed: onLinePressed,
          onLineLongPressed: onLineLongPressed,
        );
      case DownloadMangaLineStatus.downloading:
      case DownloadMangaLineStatus.pausing:
        assert(
          !progress.stopped,
          'progress.stopped must be false when status is downloading or pausing',
        );
        return DownloadLineView(
          imageUrl: mangaEntity.mangaCover,
          title: mangaEntity.mangaTitle,
          icon1: Icons.download,
          text1: '正在下载章节 ${progress.startedChapterCount}/${progress.totalChapterCount} ($downloadedSize)',
          icon2: Icons.download,
          text2: (progress.preparing
                  ? progress.gettingManga
                      ? '正在获取漫画信息'
                      : '当前正在下载 未知章节'
                  : '当前正在下载 ${progress.chapterTitle!} ${progress.triedPageCount!}/${progress.totalPageCount!}页') +
              (progress.status == DownloadMangaLineStatus.pausing ? ' (暂停中)' : ''),
          icon3: null,
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

/// 漫画下载行（大），在 [DownloadTocPage] 使用
class LargeDownloadMangaLineView extends StatelessWidget {
  const LargeDownloadMangaLineView({
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
    var downloadedSize = filesize(downloadedBytes, 2, false);

    // !!!
    switch (progress.status) {
      case DownloadMangaLineStatus.waiting:
      case DownloadMangaLineStatus.paused:
      case DownloadMangaLineStatus.succeeded:
      case DownloadMangaLineStatus.failed:
        assert(
          progress.stopped,
          'progress.stopped must be true when status is not downloading and pausing',
        );
        return LargeDownloadLineView(
          imageUrl: mangaEntity.mangaCover,
          title: mangaEntity.mangaTitle,
          icon1: Icons.download,
          text1: '已下载章节 ${progress.startedChapterCount}/${progress.totalChapterCount} ($downloadedSize)',
          icon2: Icons.access_time,
          text2: '下载于 ${DateFormat('yyyy-MM-dd HH:mm:ss').format(progress.lastDownloadTime!)}',
          icon3: Icons.bar_chart,
          text3: progress.status == DownloadMangaLineStatus.waiting
              ? '等待中'
              : progress.status == DownloadMangaLineStatus.paused
                  ? '已暂停 (${progress.notFinishedChapterCount!} 章节共 ${progress.notFinishedPageCount!} 页未完成)'
                  : progress.status == DownloadMangaLineStatus.succeeded
                      ? '已完成'
                      : progress.notFinishedPageCount! < 0
                          ? '下载出错'
                          : '下载出错 (${progress.notFinishedChapterCount!} 章节共 ${progress.notFinishedPageCount!} 页未完成)',
        );
      case DownloadMangaLineStatus.downloading:
      case DownloadMangaLineStatus.pausing:
        assert(
          !progress.stopped,
          'progress.stopped must be false when status is downloading or pausing',
        );
        return LargeDownloadLineView(
          imageUrl: mangaEntity.mangaCover,
          title: mangaEntity.mangaTitle,
          icon1: Icons.download,
          text1: '正在下载章节 ${progress.startedChapterCount}/${progress.totalChapterCount} ($downloadedSize)',
          icon2: Icons.download,
          text2: (progress.preparing
                  ? progress.gettingManga
                      ? '正在获取漫画信息'
                      : '当前正在下载 未知章节'
                  : '当前正在下载 ${progress.chapterTitle!} ${progress.triedPageCount!}/${progress.totalPageCount!}页') +
              (progress.status == DownloadMangaLineStatus.pausing ? ' (暂停中)' : ''),
          icon3: Icons.bar_chart,
          text3: progress.status == DownloadMangaLineStatus.pausing ? '暂停中' : '下载中',
        );
    }
  }
}

enum DownloadMangaLineStatus {
  // 队列中
  waiting, // stopped
  downloading, // preparing / running
  pausing, // preparing / running

  // 已结束
  paused, // stopped
  succeeded, // stopped
  failed, // stopped
}

class DownloadMangaLineProgress {
  const DownloadMangaLineProgress.stopped({
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

  const DownloadMangaLineProgress.preparing({
    required this.status,
    required this.startedChapterCount,
    required this.totalChapterCount,
    required this.gettingManga,
  })  : stopped = false,
        preparing = true,
        notFinishedPageCount = null,
        notFinishedChapterCount = null,
        lastDownloadTime = null,
        chapterTitle = null,
        triedPageCount = null,
        totalPageCount = null;

  const DownloadMangaLineProgress.running({
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

  // preparing / running
  final bool preparing;
  final bool gettingManga;
  final String? chapterTitle;
  final int? triedPageCount;
  final int? totalPageCount;

  // !!!
  static DownloadMangaLineProgress fromEntityAndTask({required DownloadedManga entity, required DownloadMangaQueueTask? task}) {
    DownloadMangaLineStatus status;
    if (task != null && !task.succeeded) {
      if (!task.canceled) {
        if (task.progress.stage == DownloadMangaProgressStage.waiting) {
          status = DownloadMangaLineStatus.waiting; // stopped
        } else {
          status = DownloadMangaLineStatus.downloading; // preparing / running
        }
      } else {
        status = DownloadMangaLineStatus.pausing; // preparing / running
      }
    } else {
      if (!entity.error) {
        if (entity.startedPageCountInAll != entity.totalPageCountInAll) {
          status = DownloadMangaLineStatus.paused; // stopped
        } else if (entity.successChapterIds.length == entity.totalChapterIds.length) {
          status = DownloadMangaLineStatus.succeeded; // stopped
        } else {
          status = DownloadMangaLineStatus.failed; // stopped (failed to get chapter or download page)
        }
      } else {
        status = DownloadMangaLineStatus.failed; // stopped (failed to get manga)
      }
    }

    if (task == null || task.succeeded || (!task.canceled && task.progress.stage == DownloadMangaProgressStage.waiting)) {
      // waiting / paused / succeeded / failed / failed
      assert(
        status != DownloadMangaLineStatus.downloading && status != DownloadMangaLineStatus.pausing,
        'status must not be downloading and pausing and current progress is stopped',
      );
      return DownloadMangaLineProgress.stopped(
        status: status,
        startedChapterCount: entity.startedChapterIds.length,
        totalChapterCount: entity.totalChapterIds.length,
        notFinishedPageCount: entity.error ? -1 : entity.totalPageCountInAll - entity.successPageCountInAll,
        notFinishedChapterCount: entity.error ? -1 : entity.failedChapterCount,
        lastDownloadTime: entity.updatedAt,
      );
    } else {
      // downloading / pausing
      assert(
        status == DownloadMangaLineStatus.downloading || status == DownloadMangaLineStatus.pausing,
        'status must be downloading or pausing and current progress is preparing or running',
      );
      if (task.progress.manga == null || task.progress.currentChapter == null) {
        return DownloadMangaLineProgress.preparing(
          status: status,
          startedChapterCount: task.progress.startedChapters?.length ?? 0,
          totalChapterCount: task.chapterIds.length,
          gettingManga: task.progress.manga == null,
        );
      } else {
        return DownloadMangaLineProgress.running(
          status: status,
          startedChapterCount: task.progress.startedChapters?.length ?? 0,
          totalChapterCount: task.chapterIds.length,
          chapterTitle: task.progress.currentChapter!.title,
          triedPageCount: task.progress.triedChapterPageCount ?? 0,
          totalPageCount: task.progress.currentChapter!.pageCount,
        );
      }
    }
  }
}
