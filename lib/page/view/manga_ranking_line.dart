import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/page/view/manga_corner_icons.dart';

/// 漫画排名行，在 [RankingSubPage] 使用
class MangaRankingLineView extends StatelessWidget {
  const MangaRankingLineView({
    Key? key,
    required this.manga,
    this.inDownload = false,
    this.inShelf = false,
    this.inFavorite = false,
    this.inHistory = false,
  }) : super(key: key);

  final MangaRanking manga;
  final bool inDownload;
  final bool inShelf;
  final bool inFavorite;
  final bool inHistory;

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
      cornerIcons: buildMangaCornerIcons(inDownload: inDownload, inShelf: inShelf, inFavorite: inFavorite, inHistory: inHistory),
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
              color: manga.order == 1
                  ? Colors.red
                  : manga.order == 2
                      ? Colors.orange
                      : manga.order == 3
                          ? Colors.yellow[600]
                          : Colors.grey[400],
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28)),
            ),
            child: Container(
              padding: EdgeInsets.only(top: 3, left: manga.order < 10 ? 12 : 7),
              child: Text(
                manga.order.toString(),
                style: Theme.of(context).textTheme.bodyText2?.copyWith(color: Colors.white),
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
    );
  }
}
