import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

/// 漫画阅读历史行，在 [HistorySubPage] 使用
class MangaHistoryLineView extends StatelessWidget {
  const MangaHistoryLineView({
    Key? key,
    required this.history,
    this.flags,
    this.twoColumns = false,
    required this.onLongPressed,
  }) : super(key: key);

  final MangaHistory history;
  final MangaCornerFlags? flags;
  final bool twoColumns;
  final void Function()? onLongPressed;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: history.mangaCover,
      title: history.mangaTitle,
      icon1: null,
      text1: null,
      icon2: !history.read ? CustomIcons.opened_left_star_book : Icons.import_contacts,
      text2: !history.read ? '未开始阅读' : '阅读至 ${history.chapterTitle} 第${history.chapterPage}页',
      icon3: Icons.access_time,
      text3: (!history.read ? '浏览于 ' : '阅读于 ') + history.formattedLastTimeWithDuration,
      cornerIcons: flags?.buildIcons(),
      twoColumns: twoColumns,
      onPressed: () => Navigator.of(context).push(
        CustomPageRoute(
          context: context,
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
