import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/dlg/manga_dialog.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 漫画行，[TinyManga]，在 [MangaCategorySubPage] 使用
class TinyMangaLineView extends StatelessWidget {
  const TinyMangaLineView({
    Key? key,
    required this.manga,
    required this.history,
    this.flags,
    this.twoColumns = false,
    this.highlightRecent = true,
  }) : super(key: key);

  final TinyManga manga;
  final MangaHistory? history;
  final MangaCornerFlags? flags;
  final bool twoColumns;
  final bool highlightRecent;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: manga.cover,
      title: manga.title,
      icon1: Icons.notes,
      text1: '最新章节 ${manga.formattedNewestChapter}' /* no author information */,
      icon2: history == null || !history!.read ? CustomIcons.opened_left_star_book : Icons.import_contacts,
      text2: (history == null ? '未浏览' : (!history!.read ? '未开始阅读 仅浏览' : '最近阅读至 ${history!.chapterTitle}')) + (history == null ? '' : ' (${history!.formattedLastTimeOrDuration})'),
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
        extraData: MangaExtraDataForDialog.fromTinyManga(manga),
        eventSource: EventSource.general,
      ),
    );
  }
}
