import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/dlg/manga_dialog.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

/// 漫画排名行，在 [RankingSubPage] / [MangaAudRankingPage] 使用
class MangaRankingLineView extends StatelessWidget {
  const MangaRankingLineView({
    Key? key,
    required this.manga,
    required this.history,
    this.flags,
    this.twoColumns = false,
    this.highlightRecent = true,
  }) : super(key: key);

  final MangaRanking manga;
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
      text1: manga.authors.map((a) => a.name).join('/'),
      icon2: Icons.notes,
      text2: '最新章节 ${manga.newestChapter}' + //
          ((history == null ? '' : (!history!.read ? ' (仅浏览)' : (manga.newestChapter == history!.chapterTitle ? ' (已阅读至该话)' : ' (阅读至 ${history!.shortChapterTitle})')))),
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
      extraRightPaddingForTitle: 28 - 14 + 5 /* badge width - line horizontal padding + extra space */,
      extrasInStack: [
        Positioned(
          top: 0,
          bottom: 0,
          right: 25,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              manga.trend == 1
                  ? Icon(Icons.arrow_drop_up, size: 26, color: Colors.red) // up
                  : manga.trend == 2
                      ? Icon(Icons.arrow_drop_down, size: 26, color: Colors.blue[400]) // down
                      : Transform.scale(scaleX: 0.6, child: Icon(Icons.remove, size: 26, color: Colors.grey[600])) /* no change */,
              Text(
                manga.score.toString(),
                style: Theme.of(context).textTheme.bodyText1?.copyWith(
                      color: manga.trend == 1 ? Colors.red : (manga.trend == 2 ? Colors.blue[400] : Colors.grey[600]),
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: manga.order == 1 ? Colors.red : (manga.order == 2 ? Colors.orange : (manga.order == 3 ? Colors.yellow[600] : Colors.grey[400])),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28)),
            ),
            alignment: Alignment.topRight,
            child: SizedBox(
              width: 28 * 0.8,
              height: 28 * 0.85,
              child: Center(
                child: Text(
                  manga.order.toString(),
                  style: Theme.of(context).textTheme.bodyText2?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
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
        extraData: MangaExtraDataForDialog.fromMangaRanking(manga),
      ),
    );
  }
}
