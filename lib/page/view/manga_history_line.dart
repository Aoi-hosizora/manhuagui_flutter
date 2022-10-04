import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

/// 漫画浏览历史行，在 [HistorySubPage] 使用
class MangaHistoryLineView extends StatelessWidget {
  const MangaHistoryLineView({
    Key? key,
    required this.history,
    required this.onLongPressed,
  }) : super(key: key);

  final MangaHistory history;
  final Function() onLongPressed;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: history.mangaCover,
      title: history.mangaTitle,
      icon1: history.read ? Icons.subject : null,
      text1: history.read ? '阅读至 ${history.chapterTitle}' : null,
      icon2: history.read ? Icons.import_contacts : Icons.subject,
      text2: history.read ? '第${history.chapterPage}页' : '未开始阅读',
      icon3: Icons.access_time,
      text3: DateFormat('yyyy-MM-dd HH:mm:ss').format(history.lastTime),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (c) => MangaPage(
            id: history.mangaId,
            title: history.mangaTitle,
            url: history.mangaUrl,
          ),
        ),
      ),
      onLongPressed: onLongPressed,
    );
  }
}
