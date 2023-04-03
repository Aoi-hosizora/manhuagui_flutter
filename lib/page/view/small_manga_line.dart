import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/dlg/manga_dialog.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

/// 帶作者信息的漫画行，[SmallManga]，在 [SearchPage] 使用
class SmallMangaLineView extends StatelessWidget {
  const SmallMangaLineView({
    Key? key,
    required this.manga,
    this.flags,
    this.twoColumns = false,
  }) : super(key: key);

  final SmallManga manga;
  final MangaCornerFlags? flags;
  final bool twoColumns;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: manga.cover,
      title: manga.title,
      icon1: Icons.person,
      text1: manga.authors.map((a) => a.name).join('/'),
      icon2: Icons.notes,
      text2: '最新章节 ${manga.newestChapter}',
      icon3: Icons.update,
      text3: '${manga.finished ? '已完结' : '连载中'}・${manga.formattedNewestDateWithDuration}',
      cornerIcons: flags?.buildIcons(),
      twoColumns: twoColumns,
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
      onLongPressed: () => showPopupMenuForMangaList(
        context: context,
        mangaId: manga.mid,
        mangaTitle: manga.title,
        mangaCover: manga.cover,
        mangaUrl: manga.url,
      ),
    );
  }
}
