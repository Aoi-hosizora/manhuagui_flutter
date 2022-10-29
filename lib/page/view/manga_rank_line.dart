import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

/// 漫画排名行，在 [RankingSubPage] 使用
class MangaRankLineView extends StatelessWidget {
  const MangaRankLineView({
    Key? key,
    required this.manga,
  }) : super(key: key);

  final MangaRank manga;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: manga.cover,
      title: manga.title,
      icon1: Icons.edit,
      text1: manga.finished ? '已完结' : '连载中',
      icon2: Icons.subject,
      text2: '最新章节 ${manga.newestChapter}',
      icon3: Icons.access_time,
      text3: '更新于 ${manga.newestDate}',
      extraWidthInRow: 35 + 14,
      extrasInRow: [
        Container(
          margin: EdgeInsets.only(right: 14, top: 5, bottom: 5),
          width: 35,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              manga.trend == 1
                  ? Icon(Icons.arrow_drop_up, color: Colors.red) // up
                  : manga.trend == 2
                      ? Icon(Icons.arrow_drop_down, color: Colors.blue[400]) // down
                      : Icon(Icons.remove, color: Colors.grey),
              Text(
                manga.score.toString(),
                style: Theme.of(context).textTheme.subtitle1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
      extrasInStack: [
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: manga.order == 1
                  ? Colors.red
                  : manga.order == 2
                      ? Colors.deepOrange
                      : manga.order == 3
                          ? Colors.orange
                          : Colors.grey[400],
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24)),
            ),
            child: Container(
              padding: EdgeInsets.only(top: 2, left: manga.order < 10 ? 12 : 6.5),
              child: Text(
                manga.order.toString(),
                style: Theme.of(context).textTheme.bodyText2?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
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
