import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/service/storage/download_manga.dart';

class DownloadChapterLineView extends StatelessWidget {
  const DownloadChapterLineView({
    Key? key,
    required this.chapterEntity,
    required this.downloadTask,
    required this.onPressed,
    required this.onLongPressed,
  }) : super(key: key);

  final DownloadedChapter chapterEntity;
  final DownloadMangaQueueTask? downloadTask;
  final void Function() onPressed;
  final void Function()? onLongPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '【${chapterEntity.chapterGroup}】${chapterEntity.chapterTitle}',
            ),
            LinearProgressIndicator(
              value: null,
            ),
          ],
        ),
      ),
      onTap: onPressed,
      onLongPress: onLongPressed,
    );
  }
}
