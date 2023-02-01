import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 书架漫画行，在 [ShelfSubPage] 使用
class ShelfMangaLineView extends StatelessWidget {
  const ShelfMangaLineView({
    Key? key,
    required this.manga,
    required this.history,
    this.flags,
    this.onLongPressed,
  }) : super(key: key);

  final ShelfManga manga;
  final MangaHistory? history;
  final MangaCornerFlags? flags;
  final VoidCallback? onLongPressed;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: manga.cover,
      title: manga.title,
      icon1: Icons.notes,
      text1: '最新章节 ' + manga.newestChapter,
      icon2: !AppSetting.instance.other.useLocalDataInShelf //
          ? Icons.import_contacts
          : (history == null || !history!.read ? MdiIcons.notebookOutline : Icons.import_contacts),
      text2: !AppSetting.instance.other.useLocalDataInShelf //
          ? '最近阅读至 ${manga.lastChapter.isEmpty ? '未知章节' : manga.lastChapter} (${manga.formattedLastTimeForShelfLine})'
          : ((history == null || !history!.read ? '未开始阅读' : '最近阅读至 ${history!.chapterTitle}') + ' (${history?.formattedLastTimeOrDuration ?? '未知时间'})'),
      icon3: Icons.update,
      text3: '更新于 ${manga.formattedNewestTimeForShelfLine}',
      cornerIcons: flags?.buildIcons(),
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
