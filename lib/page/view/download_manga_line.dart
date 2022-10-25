import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

enum DownloadLineStatus {
  // 在队列中
  waiting,
  downloading,
  pausing,

  // 任务已结束
  paused,
  succeed,
  failed,
}

class DownloadTaskProgress {
  const DownloadTaskProgress.preparing()
      : preparingChapter = true,
        chapterTitle = null,
        currentPageIndex = null,
        totalPagesCount = null;

  const DownloadTaskProgress({
    required String this.chapterTitle,
    required int this.currentPageIndex,
    required int this.totalPagesCount,
  }) : preparingChapter = false;

  final bool preparingChapter;
  final String? chapterTitle;
  final int? currentPageIndex;
  final int? totalPagesCount;
}

class DownloadMangaLineView extends StatelessWidget {
  const DownloadMangaLineView({
    Key? key,
    required this.mangaTitle,
    required this.mangaCover,
    required this.status,
    required this.startedChaptersCount,
    required this.totalChaptersCountInTask,
    required this.lastDownloadTime,
    required this.downloadProgress,
    required this.onActionPressed,
    required this.onLinePressed,
    required this.onLineLongPressed,
  }) : super(key: key);

  final String mangaTitle;
  final String mangaCover;
  final DownloadLineStatus status;
  final int startedChaptersCount;
  final int totalChaptersCountInTask;
  final DateTime lastDownloadTime;
  final DownloadTaskProgress? downloadProgress;
  final void Function() onActionPressed;
  final void Function() onLinePressed;
  final void Function()? onLineLongPressed;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case DownloadLineStatus.waiting:
      case DownloadLineStatus.paused:
      case DownloadLineStatus.succeed:
      case DownloadLineStatus.failed:
        return _buildGeneral(
          context: context,
          icon1: Icons.download,
          text1: '已下载章节 $startedChaptersCount/$totalChaptersCountInTask (635.76K)',
          icon2: Icons.access_time,
          text2: '下载于 ${DateFormat('yyyy-MM-dd HH:mm:ss').format(lastDownloadTime)}',
          showProgressBar: false,
          progressBarValue: null,
          statusText: status == DownloadLineStatus.waiting
              ? '等待中'
              : status == DownloadLineStatus.paused
                  ? '已暂停'
                  : status == DownloadLineStatus.succeed
                      ? '已完成'
                      : '未完成 (xxx 页)',
          disableAction: false,
          actionIcon: status == DownloadLineStatus.waiting ? Icons.pause : Icons.play_arrow,
        );
      case DownloadLineStatus.downloading:
      case DownloadLineStatus.pausing:
        return _buildGeneral(
          context: context,
          icon1: Icons.download,
          text1: '正在下载章节 $startedChaptersCount/$totalChaptersCountInTask (635.76K)',
          icon2: Icons.download,
          text2: '当前正在下载 ${downloadProgress!.chapterTitle ?? '未知章节'} ' + //
              (downloadProgress!.preparingChapter ? '' : '${downloadProgress!.currentPageIndex!}/${downloadProgress!.totalPagesCount!}页'),
          showProgressBar: true,
          progressBarValue: status == DownloadLineStatus.pausing || downloadProgress!.preparingChapter || downloadProgress!.totalPagesCount! == 0
              ? null //
              : downloadProgress!.currentPageIndex! / downloadProgress!.totalPagesCount!,
          statusText: status == DownloadLineStatus.downloading
              ? '下载中 (1.23M/s)' //
              : '暂停中，请稍后',
          disableAction: status == DownloadLineStatus.pausing,
          actionIcon: Icons.pause,
        );
    }
  }

  Widget _buildGeneral({
    required BuildContext context,
    required IconData icon1,
    required String text1,
    required IconData icon2,
    required String text2,
    required bool showProgressBar,
    required double? progressBarValue,
    required String statusText,
    required bool disableAction,
    required IconData actionIcon,
  }) {
    return GeneralLineView.custom(
      imageUrl: mangaCover,
      title: mangaTitle,
      rowsExceptTitle: [
        GeneralLineIconText(
          icon: icon1,
          text: text1,
        ),
        GeneralLineIconText(
          icon: icon2,
          text: text2,
        ),
        GeneralLineIconText(
          icon: null,
          text: '　',
        ),
        // GeneralLineIconText(
        //   icon: Icons.subject,
        //   text: '上次阅读至 第x话 第xxx页', // 未开始阅读
        // ),
      ],
      extrasInStack: [
        if (showProgressBar)
          Positioned(
            bottom: 15, // 8 + 24 / 2
            left: 75 + 14 * 2,
            right: 24 + 8 * 2 + 14,
            child: LinearProgressIndicator(
              value: progressBarValue,
            ),
          ),
        Positioned(
          bottom: 24 + 8 * 2,
          right: 8,
          child: Text(statusText),
        ),
      ],
      topExtrasInStack: [
        Positioned(
          right: 0,
          bottom: 0,
          child: InkWell(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                actionIcon,
                size: 24,
                color: !disableAction ? Theme.of(context).iconTheme.color : Colors.grey,
              ),
            ),
            onTap: !disableAction ? onActionPressed : null,
          ),
        ),
      ],
      onPressed: onLinePressed,
      onLongPressed: onLineLongPressed,
    );
  }
}
