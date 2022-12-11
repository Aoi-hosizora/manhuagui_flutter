import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/service/storage/download_task.dart';

/// 章节下载行，在 [DlUnfinishedSubPage] 使用（功能上实现了包括下载完和未下载完的所有状态）
class DownloadChapterLineView extends StatelessWidget {
  const DownloadChapterLineView({
    Key? key,
    required this.chapterEntity,
    required this.downloadTask,
    required this.onPressedWhenEnabled,
    required this.onPressedWhenDisabled,
    this.onLongPressed,
  }) : super(key: key);

  final DownloadedChapter chapterEntity;
  final DownloadMangaQueueTask? downloadTask;
  final void Function() onPressedWhenEnabled;
  final void Function() onPressedWhenDisabled;
  final void Function()? onLongPressed;

  Widget _buildGeneral({
    required BuildContext context,
    required String title,
    required String subTitle,
    required double? progress,
    required IconData icon,
    required bool disabled,
  }) {
    return InkWell(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(subTitle),
                    ],
                  ),
                  SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: progress,
                    color: disabled
                        ? Colors.grey // chapter downloading is unavailable
                        : Theme.of(context).progressIndicatorTheme.color,
                    backgroundColor: disabled
                        ? Colors.grey[300] // chapter downloading is unavailable
                        : Theme.of(context).progressIndicatorTheme.linearTrackColor,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(
                icon,
                size: 20,
                color: !disabled ? Theme.of(context).iconTheme.color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
      onTap: !disabled ? onPressedWhenEnabled : onPressedWhenDisabled,
      onLongPress: onLongPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    var progress = DownloadChapterLineProgress.fromEntityAndTask(entity: chapterEntity, task: downloadTask);

    // !!!
    final triedProgressText = '${progress.triedPageCount}/${progress.totalPageCount}';
    final successProgressText = '${progress.successPageCount}/${progress.totalPageCount}';
    final triedProgressValue = progress.totalPageCount == 0 ? 0.0 : progress.triedPageCount / progress.totalPageCount;
    final successProgressValue = progress.totalPageCount == 0 ? 0.0 : progress.successPageCount / progress.totalPageCount;

    final title = '【${chapterEntity.chapterGroup}】${chapterEntity.chapterTitle}';
    String subTitle;
    double? progressValue;
    IconData icon;
    switch (progress.status) {
      case DownloadChapterLineStatus.waiting: // use success
        subTitle = '$successProgressText (等待下载中)';
        progressValue = successProgressValue;
        icon = Icons.pause;
        break;
      case DownloadChapterLineStatus.preparing: // use success
        subTitle = '$successProgressText (正在获取章节信息)';
        progressValue = null;
        icon = Icons.pause;
        break;
      case DownloadChapterLineStatus.downloading: // use tried
        subTitle = '下载中，$triedProgressText';
        progressValue = triedProgressValue;
        icon = Icons.pause;
        break;
      case DownloadChapterLineStatus.pausing: // use tried
        subTitle = '$triedProgressText (暂停中)';
        progressValue = null;
        icon = Icons.pause;
        break;
      case DownloadChapterLineStatus.paused: // use success
        subTitle = '$successProgressText (${progress.unfinishedPageCount} 页未完成)';
        progressValue = successProgressValue;
        icon = Icons.play_arrow;
        break;
      case DownloadChapterLineStatus.succeeded: // use success
        subTitle = '已完成 ($successProgressText)';
        progressValue = successProgressValue;
        icon = Icons.file_download_done;
        break;
      case DownloadChapterLineStatus.update: // use success
        subTitle = '已完成 (需要更新数据)';
        progressValue = successProgressValue;
        icon = Icons.priority_high;
        break;
      case DownloadChapterLineStatus.failed: // use success
        subTitle = '$successProgressText (${progress.unfinishedPageCount} 页未完成)';
        progressValue = successProgressValue;
        icon = Icons.priority_high;
        break;
    }

    return _buildGeneral(
      context: context,
      title: title,
      subTitle: subTitle,
      progress: progressValue,
      icon: icon,
      disabled: !progress.isMangaDownloading || progress.status == DownloadChapterLineStatus.pausing,
    );
  }
}

enum DownloadChapterLineStatus {
  // 队列中
  waiting, // useEntity
  preparing, // useEntity
  downloading, // useTask
  pausing, // preparing (useEntity) / downloading (useTask)

  // 已结束
  paused, // useEntity
  succeeded, // useEntity
  update, // useEntity
  failed, // useEntity
}

class DownloadChapterLineProgress {
  const DownloadChapterLineProgress({
    required this.status,
    required this.isMangaDownloading,
    required this.totalPageCount,
    required this.triedPageCount,
    required this.successPageCount,
  });

  final DownloadChapterLineStatus status;
  final bool isMangaDownloading;
  final int totalPageCount;
  final int triedPageCount;
  final int successPageCount;

  int get unfinishedPageCount => totalPageCount - successPageCount;

  // !!!
  static DownloadChapterLineProgress fromEntityAndTask({required DownloadedChapter entity, required DownloadMangaQueueTask? task}) {
    assert(task == null || task.mangaId == entity.mangaId);
    DownloadChapterLineStatus status;

    var isMangaDownloading = task != null && !task.succeeded && task.mangaId == entity.mangaId && !task.canceled;
    if (task != null && !task.succeeded && task.mangaId == entity.mangaId) {
      if (task.canceled) {
        if (task.progress.currentChapterId == entity.chapterId) {
          status = DownloadChapterLineStatus.pausing; // pause when preparing or downloading
        } else {
          status = DownloadChapterLineStatus.paused; // >>>
        }
      } else if (task.progress.startedChapters == null) {
        status = DownloadChapterLineStatus.waiting;
      } else {
        if (task.progress.currentChapterId == entity.chapterId) {
          if (task.progress.currentChapter == null) {
            status = DownloadChapterLineStatus.preparing;
          } else {
            status = DownloadChapterLineStatus.downloading;
          }
        } else if (!task.progress.startedChapters!.any((el) => el?.cid == entity.chapterId)) {
          status = DownloadChapterLineStatus.waiting;
        } else {
          status = DownloadChapterLineStatus.paused; // >>>
        }
      }
    } else {
      status = DownloadChapterLineStatus.paused; // >>>
    }
    if (status == DownloadChapterLineStatus.paused) {
      if (entity.triedPageCount != entity.totalPageCount) {
        status = DownloadChapterLineStatus.paused;
      } else if (entity.successPageCount == entity.totalPageCount) {
        if (!entity.needUpdate) {
          status = DownloadChapterLineStatus.succeeded;
        } else {
          status = DownloadChapterLineStatus.update;
        }
      } else {
        status = DownloadChapterLineStatus.failed;
      }
    }

    var useTask = false;
    if (status == DownloadChapterLineStatus.downloading) {
      useTask = true;
    } else if (status == DownloadChapterLineStatus.pausing && task!.progress.currentChapterId == entity.chapterId && task.progress.currentChapter != null) {
      useTask = true;
    }
    if (useTask) {
      return DownloadChapterLineProgress(
        status: status,
        isMangaDownloading: isMangaDownloading,
        totalPageCount: task!.progress.currentChapter!.pageCount,
        triedPageCount: task.progress.triedChapterPageCount ?? 0,
        successPageCount: task.progress.successChapterPageCount ?? 0,
      );
    }
    return DownloadChapterLineProgress(
      status: status,
      isMangaDownloading: isMangaDownloading,
      totalPageCount: entity.totalPageCount,
      triedPageCount: entity.triedPageCount,
      successPageCount: entity.successPageCount,
    );
  }
}
