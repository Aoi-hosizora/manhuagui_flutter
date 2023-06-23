import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/dlg/manga_dialog.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

/// 帶作者信息的漫画行，[SmallManga] / [SmallerManga]，在 [SearchPage] / [AuthorPage] / [RecentSubPage] / [OverallSubPage] 使用
class SmallMangaLineView extends StatelessWidget {
  const SmallMangaLineView({
    Key? key,
    required this.manga,
    required this.history,
    this.flags,
    this.twoColumns = false,
    this.highlightRecent = true,
  }) : super(key: key);

  final SmallerManga manga; // use smaller manga here
  final MangaHistory? history;
  final MangaCornerFlags? flags;
  final bool twoColumns;
  final bool highlightRecent;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: manga.cover,
      title: manga.title,
      icon1: Icons.person,
      text1: manga.authors.join('/'),
      icon2: Icons.notes,
      text2: '最新章节 ${manga.newestChapter}' + (history?.read != true ? '' : (manga.newestChapter == history!.chapterTitle ? ' (已阅读至该话)' : ' (阅读至 ${history!.shortChapterTitle})')),
      icon3: Icons.update,
      text3: '${manga.finished ? '已完结' : '连载中'}・${manga.formattedNewestDateWithDuration}',
      text3Color: !highlightRecent
          ? null
          : GeneralLineView.determineColorByNumber(
              manga.newestDateDayDuration,
              zero: GeneralLineView.textOrange,
              one: GeneralLineView.greyedTextOrange,
              two: GeneralLineView.moreGreyedTextOrange,
            ),
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
        extraData: MangaExtraDataForDialog.fromSmallerManga(manga),
      ),
    );
  }
}
