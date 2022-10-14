import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

/// 书架漫画行，在 [ShelfSubPage] 使用
class ShelfMangaLineView extends StatelessWidget {
  const ShelfMangaLineView({
    Key? key,
    required this.manga,
  }) : super(key: key);

  final ShelfManga manga;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: manga.cover,
      title: manga.title,
      icon1: Icons.subject,
      text1: '最新章节 ' + manga.newestChapter,
      icon2: Icons.access_time,
      text2: '更新于 ${manga.newestDuration}',
      icon3: Icons.import_contacts,
      text3: '最近阅读至 ${manga.lastChapter.isEmpty ? '未知话' : manga.lastChapter} (${manga.lastDuration})',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (c) => MangaPage(
            id: manga.mid,
            title: manga.title,
            url: manga.url,
          ),
        ),
      ),
    );
  }
}
