import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/download_line.dart';
import 'package:manhuagui_flutter/service/storage/download_task.dart';

/// 漫画下载行（小），在 [DownloadPage] 使用
/// 漫画下载块（大），在 [DownloadMangaPage] 使用

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
          text1: progress.status == DownloadMangaLineStatus.waiting
              ? '等待下载中'
              : progress.status == DownloadMangaLineStatus.paused
                  ? '下载已暂停 (${progress.notFinishedChapterCount!} 章节共 ${progress.notFinishedPageCount!} 页未完成)'
                  : progress.status == DownloadMangaLineStatus.succeeded
                      ? '下载已完成'
                      : progress.status == DownloadMangaLineStatus.nupdate
                          ? '${progress.succeededChapterCount == progress.totalChapterCount ? '下载已完成' : '下载未完成'} (需要更新数据)'
                          : progress.notFinishedPageCount! < 0
                              ? '下载出错 (获取漫画信息失败)'
                              : '下载出错 (${progress.notFinishedChapterCount!} 章节共 ${progress.notFinishedPageCount!} 页未完成)',
          icon2: Icons.bar_chart,
          text2: progress.succeededChapterCount == progress.totalChapterCount //
              ? '已完成 ${progress.succeededChapterCount}/${progress.totalChapterCount} 章节 ($downloadedSize)'
              : '已开始 ${progress.startedChapterCount}/${progress.totalChapterCount}, 已完成 ${progress.succeededChapterCount}/${progress.totalChapterCount} ($downloadedSize)',
          icon3: Icons.access_time,
          text3: '任务创建于 ${mangaEntity.formattedUpdatedAtWithDuration}',
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
          text1: (progress.preparing && progress.gettingManga
                  ? '当前正在获取漫画信息'
                  : progress.preparing && !progress.gettingManga
                      ? '当前正在下载 ${progress.chapterTitle ?? '未知章节'}'
                      : '当前正在下载 ${progress.chapterTitle!} ${progress.triedPageCount!}/${progress.totalPageCount!}页') +
              (progress.status == DownloadMangaLineStatus.pausing ? ' (暂停中)' : ''),
          icon2: Icons.bar_chart,
          text2: progress.preparing && progress.gettingManga //
              ? '正在下载 ?/${progress.totalChapterCount}, 已完成 ${progress.succeededChapterCount}/${progress.totalChapterCount} ($downloadedSize)'
              : '正在下载 ${progress.startedChapterCount}/${progress.totalChapterCount}, 已完成 ${progress.succeededChapterCount}/${progress.totalChapterCount} ($downloadedSize)',
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
          text1: progress.status == DownloadMangaLineStatus.waiting
              ? '等待下载中'
              : progress.status == DownloadMangaLineStatus.paused
                  ? '下载已暂停 (${progress.notFinishedChapterCount!} 章节共 ${progress.notFinishedPageCount!} 页未完成)'
                  : progress.status == DownloadMangaLineStatus.succeeded
                      ? '下载已完成'
                      : progress.status == DownloadMangaLineStatus.nupdate
                          ? '${progress.succeededChapterCount == progress.totalChapterCount ? '下载已完成' : '下载未完成'} (需要更新数据)'
                          : progress.notFinishedPageCount! < 0
                              ? '下载出错 (获取漫画信息失败)'
                              : '下载出错 (${progress.notFinishedChapterCount!} 章节共 ${progress.notFinishedPageCount!} 页未完成)',
          icon2: Icons.bar_chart,
          text2: progress.succeededChapterCount == progress.totalChapterCount //
              ? '已完成 ${progress.succeededChapterCount}/${progress.totalChapterCount} 章节 ($downloadedSize)'
              : '已开始 ${progress.startedChapterCount}/${progress.totalChapterCount}, 已完成 ${progress.succeededChapterCount}/${progress.totalChapterCount} ($downloadedSize)',
          icon3: Icons.access_time,
          text3: '任务创建于 ${mangaEntity.formattedUpdatedAtWithDuration}',
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
          text1: (progress.preparing && progress.gettingManga
                  ? '当前正在获取漫画信息'
                  : progress.preparing && !progress.gettingManga
                      ? '当前正在下载 ${progress.chapterTitle ?? '未知章节'}'
                      : '当前正在下载 ${progress.chapterTitle!} ${progress.triedPageCount!}/${progress.totalPageCount!}页') +
              (progress.status == DownloadMangaLineStatus.pausing ? ' (暂停中)' : ''),
          icon2: Icons.bar_chart,
          text2: progress.preparing && progress.gettingManga //
              ? '正在下载 ?/${progress.totalChapterCount}, 已完成 ${progress.succeededChapterCount}/${progress.totalChapterCount} ($downloadedSize)'
              : '正在下载 ${progress.startedChapterCount}/${progress.totalChapterCount}, 已完成 ${progress.succeededChapterCount}/${progress.totalChapterCount} ($downloadedSize)',
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
    required this.succeededChapterCount,
    required this.startedChapterCount,
    required this.totalChapterCount,
    required int this.notFinishedPageCount,
    required int this.notFinishedChapterCount,
  })  : stopped = true,
        preparing = false,
        gettingManga = false,
        chapterTitle = null,
        triedPageCount = null,
        totalPageCount = null;

  const DownloadMangaLineProgress.whenPreparing({
    required this.status,
    required this.succeededChapterCount,
    required this.startedChapterCount,
    required this.totalChapterCount,
    required this.gettingManga,
    required this.chapterTitle,
  })  : stopped = false,
        preparing = true,
        notFinishedPageCount = null,
        notFinishedChapterCount = null,
        triedPageCount = null,
        totalPageCount = null;

  const DownloadMangaLineProgress.whenDownloading({
    required this.status,
    required this.succeededChapterCount,
    required this.startedChapterCount,
    required this.totalChapterCount,
    required String this.chapterTitle,
    required int this.triedPageCount,
    required int this.totalPageCount,
  })  : stopped = false,
        preparing = false,
        gettingManga = false,
        notFinishedPageCount = null,
        notFinishedChapterCount = null;

  // both
  final DownloadMangaLineStatus status;
  final int succeededChapterCount;
  final int startedChapterCount;
  final int totalChapterCount;

  // stopped
  final bool stopped;
  final int? notFinishedPageCount;
  final int? notFinishedChapterCount;

  // preparing / downloading
  final bool preparing;
  final bool gettingManga;
  final String? chapterTitle;
  final int? triedPageCount;
  final int? totalPageCount;

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
        } else if (entity.allChaptersEitherSucceededOrNeedUpdate) {
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
        succeededChapterCount: entity.successChaptersCount,
        startedChapterCount: entity.triedChaptersCount /* stopped => use entity data */,
        totalChapterCount: entity.totalChaptersCount /* stopped => use entity data */,
        notFinishedPageCount: entity.error ? -1 : entity.notFinishedPageCountInAll,
        notFinishedChapterCount: entity.error ? -1 : entity.notFinishedChaptersCount,
      );
    } else {
      // preparing / downloading / pausing => from task
      assert(
        status == DownloadMangaLineStatus.preparing || status == DownloadMangaLineStatus.downloading || status == DownloadMangaLineStatus.pausing,
        'status must be preparing, downloading or pausing when current progress is not stopped',
      );
      var mergedStartedCount = {/* task started */ ...task.progress.startedChapterIds ?? [], /* entity started */ ...entity.triedChapterIds}.length;
      var mergedTotalCount = {/* task total */ ...task.uncanceledChapterIds, /* entity total */ ...entity.totalChapterIds}.length;
      if (task.progress.manga == null || task.progress.currentChapter == null) {
        return DownloadMangaLineProgress.whenPreparing(
          status: status,
          succeededChapterCount: entity.successChaptersCount,
          startedChapterCount: task.progress.manga == null /* getting manga */
              ? entity.triedChaptersCount /* preparing manga => use entity data */
              : mergedStartedCount /* preparing chapter => use merged data */,
          totalChapterCount: mergedTotalCount /* preparing => use merged data */,
          gettingManga: task.progress.manga == null,
          chapterTitle: task.progress.currentChapterTitle,
        );
      } else {
        return DownloadMangaLineProgress.whenDownloading(
          status: status,
          succeededChapterCount: entity.successChaptersCount,
          startedChapterCount: mergedStartedCount /* downloading => use merged data */,
          totalChapterCount: mergedTotalCount /* downloading => use merged data */,
          chapterTitle: task.progress.currentChapter!.title,
          triedPageCount: task.progress.triedChapterPageCount ?? 0,
          totalPageCount: task.progress.currentChapter!.pageCount,
        );
      }
    }
  }
}
