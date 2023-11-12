import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/chapter_grid.dart';
import 'package:manhuagui_flutter/service/storage/download_task.dart';

/// 章节下载行，在 [DlUnfinishedSubPage] 使用，功能上实现了包括下载完和未下载完的所有状态
class DownloadChapterLineView extends StatelessWidget {
  const DownloadChapterLineView({
    Key? key,
    required this.chapterEntity,
    required this.downloadTask,
    this.highlighted = false,
    this.highlighted2 = false,
    this.fainted = false,
    this.showLater = false,
    required this.onPressed,
    this.onLongPressed,
    required this.onPauseIconPressed,
    required this.onStartIconPressed,
    this.onIconLongPressed,
  }) : super(key: key);

  final DownloadedChapter chapterEntity;
  final DownloadMangaQueueTask? downloadTask;
  final bool highlighted;
  final bool highlighted2;
  final bool fainted;
  final bool showLater;
  final void Function() onPressed;
  final void Function()? onLongPressed;
  final void Function() onPauseIconPressed;
  final void Function() onStartIconPressed;
  final void Function()? onIconLongPressed;

  Widget _buildGeneral({
    required BuildContext context,
    required String title,
    required String subTitle,
    required double? progress,
    required IconData icon,
    required bool greyProgress,
    required bool greyIcon,
    required void Function() onIconPressed,
  }) {
    return InkWell(
      child: Padding(
        padding: EdgeInsets.only(left: 12),
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
                        child: TextGroup.normal(
                          texts: [
                            PlainTextItem(text: title),
                            if (showLater)
                              SpanItem(
                                span: WidgetSpan(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 5),
                                    child: Icon(
                                      Icons.schedule,
                                      size: 18,
                                      color: Colors.blueGrey.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: highlighted
                                ? ChapterGridView.defaultHighlightDeeperColor
                                : highlighted2
                                    ? ChapterGridView.defaultHighlight2DeeperColor
                                    : fainted
                                        ? ChapterGridView.defaultFaintTextAppliedColor
                                        : Colors.black,
                          ),
                        ),
                      ),
                      Text(subTitle, style: Theme.of(context).textTheme.bodyText2),
                    ],
                  ),
                  SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: progress,
                    color: greyProgress
                        ? Colors.grey // chapter is not in task
                        : Theme.of(context).progressIndicatorTheme.color,
                    backgroundColor: greyProgress
                        ? Colors.grey[300] // chapter is not in task
                        : Theme.of(context).progressIndicatorTheme.linearTrackColor,
                  ),
                ],
              ),
            ),
            InkWell(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  icon,
                  size: 22,
                  color: greyIcon
                      ? Colors.grey // downloading chapter is unavailable
                      : Theme.of(context).iconTheme.color,
                ),
              ),
              onTap: onIconPressed,
              onLongPress: onIconLongPressed,
            ),
          ],
        ),
      ),
      onTap: onPressed,
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
    void Function() onIconPressed;
    switch (progress.status) {
      case DownloadChapterLineStatus.waiting: // use successXXX
        subTitle = '$successProgressText (等待下载中)';
        progressValue = successProgressValue;
        icon = Icons.pause;
        onIconPressed = onPauseIconPressed;
        break;
      case DownloadChapterLineStatus.preparing: // use successXXX
        subTitle = '$successProgressText (正在获取章节信息)';
        progressValue = null;
        icon = Icons.pause;
        onIconPressed = onPauseIconPressed;
        break;
      case DownloadChapterLineStatus.downloading: // use triedXXX
        subTitle = '下载中，$triedProgressText';
        progressValue = triedProgressValue;
        icon = Icons.pause;
        onIconPressed = onPauseIconPressed;
        break;
      case DownloadChapterLineStatus.pausing: // use triedXXX
        subTitle = '$triedProgressText (暂停中)';
        progressValue = null;
        icon = Icons.block;
        onIconPressed = () {};
        break;
      case DownloadChapterLineStatus.paused: // use successXXX
        subTitle = '$successProgressText (${progress.unfinishedPageCount} 页未完成)';
        progressValue = successProgressValue;
        icon = Icons.play_arrow;
        onIconPressed = onStartIconPressed;
        break;
      case DownloadChapterLineStatus.succeeded: // use successXXX
        subTitle = '已完成 ($successProgressText)';
        progressValue = successProgressValue;
        icon = Icons.file_download_done;
        onIconPressed = onStartIconPressed;
        break;
      case DownloadChapterLineStatus.nupdate: // use successXXX
        subTitle = '已完成 (需要更新数据)';
        progressValue = successProgressValue;
        icon = Icons.update;
        onIconPressed = onStartIconPressed;
        break;
      case DownloadChapterLineStatus.failed: // use successXXX
        subTitle = '$successProgressText (${progress.unfinishedPageCount} 页未完成)';
        progressValue = successProgressValue;
        icon = Icons.priority_high;
        onIconPressed = onStartIconPressed;
        break;
    }

    return _buildGeneral(
      context: context,
      title: title,
      subTitle: subTitle,
      progress: progressValue,
      icon: icon,
      greyProgress: !progress.chapterInTask,
      greyIcon: !progress.chapterInTask || progress.status == DownloadChapterLineStatus.pausing,
      onIconPressed: onIconPressed,
    );
  }
}

enum DownloadChapterLineStatus {
  // 队列中
  waiting, // fromEntity
  preparing, // fromEntity
  downloading, // fromTask
  pausing, // fromEntity (when preparing) / fromTask (when downloading)

  // 已结束
  paused, // fromEntity
  succeeded, // fromEntity
  nupdate, // fromEntity
  failed, // fromEntity
}

class DownloadChapterLineProgress {
  const DownloadChapterLineProgress({
    required this.status,
    required this.chapterInTask,
    required this.totalPageCount,
    required this.triedPageCount,
    required this.successPageCount,
  });

  final DownloadChapterLineStatus status;
  final bool chapterInTask;
  final int totalPageCount;
  final int triedPageCount;
  final int successPageCount;

  int get unfinishedPageCount => totalPageCount - successPageCount;

  // !!!
  static DownloadChapterLineProgress fromEntityAndTask({required DownloadedChapter entity, required DownloadMangaQueueTask? task}) {
    assert(task == null || task.mangaId == entity.mangaId);
    DownloadChapterLineStatus status;

    var chapterInTask = false;
    if (task != null && task.mangaId == entity.mangaId && task.isChapterInTask(entity.chapterId)) {
      chapterInTask = true; // 当前章节在下载任务中且有效
      if (task.cancelRequested) {
        if (task.progress.currentChapterId == entity.chapterId) {
          status = DownloadChapterLineStatus.pausing; // pausing when preparing or downloading
        } else {
          status = DownloadChapterLineStatus.paused; // >>> 待进一步细化
        }
      } else if (task.progress.currentChapterId == entity.chapterId && task.isChapterCancelRequested(entity.chapterId)) {
        status = DownloadChapterLineStatus.pausing; // pausing when downloading
      } else if (task.progress.startedChapterIds == null) {
        status = DownloadChapterLineStatus.waiting; // getting manga
      } else {
        if (task.progress.currentChapterId == entity.chapterId) {
          if (task.progress.currentChapter == null) {
            status = DownloadChapterLineStatus.preparing; // getting chapter
          } else {
            status = DownloadChapterLineStatus.downloading; // downloading chapter
          }
        } else if (!task.progress.startedChapterIds!.contains(entity.chapterId)) {
          status = DownloadChapterLineStatus.waiting; // chapter not started
        } else {
          status = DownloadChapterLineStatus.paused; // >>> 待进一步细化
        }
      }
    } else {
      status = DownloadChapterLineStatus.paused; // >>> 待进一步细化
    }
    if (status == DownloadChapterLineStatus.paused /* <<< 进一步细化 */) {
      if (!entity.allTried) {
        status = DownloadChapterLineStatus.paused;
      } else if (entity.succeeded) {
        if (!entity.needUpdate) {
          status = DownloadChapterLineStatus.succeeded;
        } else {
          status = DownloadChapterLineStatus.nupdate;
        }
      } else {
        status = DownloadChapterLineStatus.failed;
      }
    }

    var fromTask = false;
    if (status == DownloadChapterLineStatus.downloading) {
      fromTask = true; // downloading
    } else if (status == DownloadChapterLineStatus.pausing) {
      if (task != null && task.cancelRequested && task.progress.currentChapterId == entity.chapterId && task.progress.currentChapter != null) {
        fromTask = true; // pausing when downloading (manga canceled)
      }
      if (task != null && !task.cancelRequested && task.progress.currentChapterId == entity.chapterId && task.isChapterCancelRequested(entity.chapterId)) {
        fromTask = true; // pausing when downloading (chapter canceled)
      }
    }
    if (fromTask) {
      return DownloadChapterLineProgress(
        status: status,
        chapterInTask: chapterInTask,
        totalPageCount: task!.progress.currentChapter?.pageCount ?? 0,
        triedPageCount: task.progress.triedChapterPageCount ?? 0,
        successPageCount: task.progress.successChapterPageCount ?? 0,
      );
    } else {
      return DownloadChapterLineProgress(
        status: status,
        chapterInTask: chapterInTask,
        totalPageCount: entity.totalPageCount,
        triedPageCount: entity.triedPageCount,
        successPageCount: entity.successPageCount,
      );
    }
  }
}
