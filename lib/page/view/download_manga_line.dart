import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

enum DownloadStatus {
  downloading,
  finished,
  pausing,
  error,
}

class DownloadProgress {
  const DownloadProgress({
    required this.preparing,
    required this.current,
    required this.total,
  });

  final bool preparing;
  final int current;
  final int total;
}

class DownloadMangaLineView extends StatelessWidget {
  const DownloadMangaLineView({
    Key? key,
    required this.mangaTitle,
    required this.mangaCover,
    required this.finishedChapterCount,
    required this.chapterCountInTask,
    required this.lastDownloadTime,
    required this.downloadStatus,
    required this.downloadingChapterTitle,
    required this.downloadProgress,
    required this.onActionPressed,
    required this.onLinePressed,
  }) : super(key: key);

  final String mangaTitle;
  final String mangaCover;
  final int finishedChapterCount;
  final int chapterCountInTask;
  final DateTime lastDownloadTime;
  final DownloadStatus downloadStatus;
  final String downloadingChapterTitle;
  final DownloadProgress downloadProgress;
  final void Function() onActionPressed;
  final void Function() onLinePressed;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView.custom(
      imageUrl: mangaCover,
      title: mangaTitle,
      rowsExceptTitle: [
        GeneralLineIconText(
          icon: Icons.download,
          text: '已下载章节 $finishedChapterCount/$chapterCountInTask (635.76K/?)',
        ),
        if (downloadStatus != DownloadStatus.downloading) ...[
          GeneralLineIconText(
            icon: Icons.access_time,
            text: '下载于 ${DateFormat('yyyy-MM-dd HH:mm:ss').format(lastDownloadTime)}',
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
        if (downloadStatus == DownloadStatus.downloading) ...[
          GeneralLineIconText(
            icon: Icons.download,
            text: '当前正在下载 $downloadingChapterTitle ' + (downloadProgress.preparing ? '' : '${downloadProgress.current}/${downloadProgress.total}页'),
          ),
          GeneralLineIconText(
            icon: null,
            text: '　',
          ),
        ],
      ],
      extraInStack: downloadStatus != DownloadStatus.downloading
          ? null
          : Positioned(
              bottom: 15,
              left: 75 + 14 * 2,
              right: 24 + 8 * 2 + 14,
              child: LinearProgressIndicator(
                value: (downloadProgress.preparing || downloadProgress.total == 0)
                    ? null //
                    : downloadProgress.current / downloadProgress.total,
              ),
            ),
      extraInStack2: Positioned(
        right: 0,
        bottom: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text(
                downloadStatus == DownloadStatus.finished
                    ? '已完成'
                    : downloadStatus == DownloadStatus.downloading
                        ? '1.23M/s'
                        : downloadStatus == DownloadStatus.pausing
                            ? '暂停中'
                            : '出错了',
                style: Theme.of(context).textTheme.bodyText2?.copyWith(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
              ),
            ),
            InkWell(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  downloadStatus != DownloadStatus.downloading ? Icons.play_arrow : Icons.pause,
                  size: 24,
                ),
              ),
              onTap: onActionPressed,
            ),
          ],
        ),
      ),
      onPressed: onLinePressed,
      // onLongPressed: () {},
    );
  }
}
