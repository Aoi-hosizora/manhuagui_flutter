import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:intl/intl.dart';
import 'package:manhuagui_flutter/model/entity.dart';
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
    var lastTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(history.lastTime);
    void onPressed() {
      Navigator.of(context).push(
        CustomMaterialPageRoute(
          context: context,
          builder: (c) => MangaPage(
            id: history.mangaId,
            title: history.mangaTitle,
            url: history.mangaUrl,
          ),
        ),
      );
    }

    if (!history.read) {
      return GeneralLineView(
        imageUrl: history.mangaCover,
        title: history.mangaTitle,
        icon1: null,
        text1: null,
        icon2: Icons.subject,
        text2: '未开始阅读',
        icon3: Icons.access_time,
        text3: lastTime,
        onPressed: onPressed,
        onLongPressed: onLongPressed,
      );
    }
    return GeneralLineView(
      imageUrl: history.mangaCover,
      title: history.mangaTitle,
      icon1: Icons.subject,
      text1: '阅读至 ${history.chapterTitle}',
      icon2: Icons.import_contacts,
      text2: '第${history.chapterPage}页',
      icon3: Icons.access_time,
      text3: lastTime,
      onPressed: onPressed,
      onLongPressed: onLongPressed,
    );
  }
}
