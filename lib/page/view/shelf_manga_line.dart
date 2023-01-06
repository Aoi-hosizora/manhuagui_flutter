import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/page/view/manga_corner_icons.dart';

/// 书架漫画行，在 [ShelfSubPage] 使用
class ShelfMangaLineView extends StatelessWidget {
  const ShelfMangaLineView({
    Key? key,
    required this.manga,
    this.inDownload = false,
    this.inFavorite = false,
    this.inHistory = false,
    this.onLongPressed,
  }) : super(key: key);

  final ShelfManga manga;
  final bool inDownload;
  final bool inFavorite;
  final bool inHistory;
  final VoidCallback? onLongPressed;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: manga.cover,
      title: manga.title,
      icon1: Icons.subject,
      text1: '最新章节 ' + manga.newestChapter,
      icon2: Icons.update,
      text2: '更新于 ${manga.newestDuration}',
      icon3: Icons.import_contacts,
      text3: '最近阅读至 ${manga.lastChapter.isEmpty ? '未知章节' : manga.lastChapter} (${manga.lastDuration == '0分钟前' ? '不到1分钟前' : manga.lastDuration})',
      cornerIcons: buildMangaCornerIcons(inDownload: inDownload, inShelf: true, inFavorite: inFavorite, inHistory: inHistory),
      onPressed: () => Navigator.of(context).push(
        CustomPageRoute(
          context: context,
          builder: (c) => MangaPage(
            id: manga.mid,
            title: manga.title,
            url: manga.url,
          ),
        ),
      ),
      onLongPressed: onLongPressed,
    );
  }
}
