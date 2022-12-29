import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

/// 漫画行，[TinyManga]，在 [RecentSubPage] / [OverallSubPage] / [GenreSubPage] / [AuthorPage] / [SearchPage] 使用
class TinyMangaLineView extends StatelessWidget {
  const TinyMangaLineView({
    Key? key,
    required this.manga,
  }) : super(key: key);

  final TinyManga manga;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: manga.cover,
      title: manga.title,
      icon1: Icons.edit,
      text1: manga.finished ? '已完结' : '连载中',
      icon2: Icons.subject,
      text2: '最新章节 ${manga.newestChapter}',
      icon3: Icons.update,
      text3: '更新于 ${manga.newestDate}',
      // TODO 添加 "已添加至书架" "已被置顶" "已被浏览" 三个图标
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
    );
  }
}
