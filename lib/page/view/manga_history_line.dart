import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/page/view/manga_corner_icons.dart';

/// 漫画阅读历史行，在 [HistorySubPage] 使用
class MangaHistoryLineView extends StatelessWidget {
  const MangaHistoryLineView({
    Key? key,
    required this.history,
    required this.onLongPressed,
    this.inDownload = false,
    this.inShelf = false,
    this.inFavorite = false,
  }) : super(key: key);

  final MangaHistory history;
  final Function()? onLongPressed;
  final bool inDownload;
  final bool inShelf;
  final bool inFavorite;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: history.mangaCover,
      title: history.mangaTitle,
      icon1: null,
      text1: null,
      icon2: !history.read ? CustomIcons.opened_empty_book : Icons.import_contacts,
      text2: !history.read ? '未开始阅读' : '阅读至 ${history.chapterTitle} 第${history.chapterPage}页',
      icon3: Icons.access_time,
      text3: '浏览于 ${history.formattedLastTime}',
      cornerIcons: buildMangaCornerIcons(inDownload: inDownload, inShelf: inShelf, inFavorite: inFavorite, inHistory: true),
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
