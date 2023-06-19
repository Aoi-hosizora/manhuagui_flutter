import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

/// 稍后阅读漫画行，在 [LaterMangaPage] 使用
class LaterMangaLineView extends StatelessWidget {
  const LaterMangaLineView({
    Key? key,
    required this.manga,
    required this.history,
    this.flags,
    this.twoColumns = false,
    this.onLongPressed,
  }) : super(key: key);

  final LaterManga manga;
  final MangaHistory? history;
  final MangaCornerFlags? flags;
  final bool twoColumns;
  final VoidCallback? onLongPressed;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: manga.mangaCover,
      title: manga.mangaTitle,
      icon1: Icons.notes,
      text1: '最新章节 ' + (manga.newestChapter == null || manga.newestDate == null ? '未知' : '${manga.newestChapter} (${manga.formattedNewestDateOrDuration})'),
      icon2: history == null || !history!.read ? CustomIcons.opened_left_star_book : Icons.import_contacts,
      text2: (history == null || !history!.read ? '未开始阅读' : '最近阅读至 ${history!.chapterTitle}') + ' (${history?.formattedLastTimeOrDuration ?? '未知时间'})',
      icon3: Icons.access_time,
      text3: '添加于 ${manga.formattedCreatedAtWithDuration}',
      cornerIcons: flags?.buildIcons(),
      twoColumns: twoColumns,
      onPressed: () => Navigator.of(context).push(
        CustomPageRoute(
          context: context,
          builder: (c) => MangaPage(
            id: manga.mangaId,
            title: manga.mangaTitle,
            url: manga.mangaUrl,
          ),
        ),
      ),
      onLongPressed: onLongPressed,
    );
  }
}
