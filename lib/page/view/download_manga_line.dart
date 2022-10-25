import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

enum DownloadLineStatus {
  // 在队列中
  waiting, // stopped
  downloading, // preparing / running
  pausing, // preparing / running

  // 任务已结束
  paused, // stopped
  succeeded, // stopped
  failed, // stopped
}

class DownloadLineProgress {
  const DownloadLineProgress.stopped({
    required this.startedChapterCount,
    required this.totalChapterCount,
    required int this.failedPageCountInAll,
    required DateTime this.lastDownloadTime,
  })  : stopped = true,
        preparing = false,
        chapterTitle = null,
        triedPageCount = null,
        totalPageCount = null;

  const DownloadLineProgress.preparing({
    required this.startedChapterCount,
    required this.totalChapterCount,
  })  : stopped = false,
        preparing = true,
        failedPageCountInAll = null,
        lastDownloadTime = null,
        chapterTitle = null,
        triedPageCount = null,
        totalPageCount = null;

  const DownloadLineProgress.running({
    required this.startedChapterCount,
    required this.totalChapterCount,
    required String this.chapterTitle,
    required int this.triedPageCount,
    required int this.totalPageCount,
  })  : stopped = false,
        preparing = false,
        failedPageCountInAll = null,
        lastDownloadTime = null;

  // stopped
  final bool stopped;
  final int startedChapterCount;
  final int totalChapterCount;
  final int? failedPageCountInAll;
  final DateTime? lastDownloadTime;

  // running
  final bool preparing;
  final String? chapterTitle;
  final int? triedPageCount;
  final int? totalPageCount;
}

class DownloadMangaLineView extends StatelessWidget {
  const DownloadMangaLineView({
    Key? key,
    required this.mangaTitle,
    required this.mangaCover,
    required this.status,
    required this.progress,
    required this.onActionPressed,
    required this.onLinePressed,
    required this.onLineLongPressed,
  }) : super(key: key);

  final String mangaTitle;
  final String mangaCover;
  final DownloadLineStatus status;
  final DownloadLineProgress progress;
  final void Function() onActionPressed;
  final void Function() onLinePressed;
  final void Function()? onLineLongPressed;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case DownloadLineStatus.waiting:
      case DownloadLineStatus.paused:
      case DownloadLineStatus.succeeded:
      case DownloadLineStatus.failed:
        assert(
          progress.stopped,
          'progress.stopped must be true when status is not downloading and pausing',
        );
        return _buildGeneral(
          context: context,
          icon1: Icons.download,
          text1: '已下载章节 ${progress.startedChapterCount}/${progress.totalChapterCount} (635.76K)',
          icon2: Icons.access_time,
          text2: '下载于 ${DateFormat('yyyy-MM-dd HH:mm:ss').format(progress.lastDownloadTime!)}',
          icon3: null,
          text3: '　',
          showProgressBar: false,
          progressBarValue: null,
          statusText: status == DownloadLineStatus.waiting
              ? '等待中'
              : status == DownloadLineStatus.paused
                  ? '已暂停'
                  : status == DownloadLineStatus.succeeded
                      ? '已完成'
                      : '未完成 (${progress.failedPageCountInAll!} 页)',
          disableAction: false,
          actionIcon: status == DownloadLineStatus.waiting ? Icons.pause : Icons.play_arrow,
        );
      case DownloadLineStatus.downloading:
      case DownloadLineStatus.pausing:
        assert(
          !progress.stopped,
          'progress.stopped must be false when status is downloading or pausing',
        );
        return _buildGeneral(
          context: context,
          icon1: Icons.download,
          text1: '正在下载章节 ${progress.startedChapterCount}/${progress.totalChapterCount} (635.76K)',
          icon2: Icons.download,
          text2: progress.preparing
              ? '当前正在下载 未知章节' //
              : '当前正在下载 ${progress.chapterTitle!}，已下载 ${progress.triedPageCount!}/${progress.totalPageCount!}页',
          icon3: null,
          text3: '　',
          showProgressBar: true,
          progressBarValue: status == DownloadLineStatus.pausing || progress.preparing || progress.totalPageCount! == 0
              ? null //
              : progress.triedPageCount! / progress.totalPageCount!,
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
    required IconData? icon3,
    required String? text3,
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
          icon: icon3,
          text: text3,
        ),
        // GeneralLineIconText(
        //   icon: Icons.subject,
        //   text: '上次阅读至 第x话 第xxx页', // 未开始阅读
        // ),
      ],
      extrasInStack: [
        if (showProgressBar)
          Positioned(
            bottom: 15, // 5 + 24 / 2
            left: 75 + 14 * 2,
            right: 24 + 5 * 2 + 14,
            child: LinearProgressIndicator(
              value: progressBarValue,
            ),
          ),
        Positioned(
          bottom: 24 + 5 * 2,
          right: 5,
          child: Text(
            statusText,
            style: Theme.of(context).textTheme.bodyText2?.copyWith(
                  color: Colors.grey,
                  fontSize: 14,
                ),
          ),
        ),
      ],
      topExtrasInStack: [
        Positioned(
          right: 0,
          bottom: 0,
          child: InkWell(
            child: Padding(
              padding: EdgeInsets.all(5),
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
