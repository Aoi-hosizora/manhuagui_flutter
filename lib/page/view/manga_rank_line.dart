import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

/// 漫画排名行，在 [RankingSubPage] 使用
class MangaRankLineView extends StatefulWidget {
  const MangaRankLineView({
    Key? key,
    required this.manga,
  }) : super(key: key);

  final MangaRank manga;

  @override
  _MangaRankLineViewState createState() => _MangaRankLineViewState();
}

class _MangaRankLineViewState extends State<MangaRankLineView> {
  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: widget.manga.cover,
      title: widget.manga.title,
      icon1: Icons.edit,
      text1: widget.manga.finished ? '已完结' : '连载中',
      icon2: Icons.subject,
      text2: (widget.manga.finished ? '共 ' : '更新至 ') + widget.manga.newestChapter,
      icon3: Icons.access_time,
      text3: '更新于 ${widget.manga.newestDate}',
      extraWidthInRow: 35,
      extraInRow: Container(
        margin: EdgeInsets.only(right: 14, top: 5, bottom: 5),
        width: 35,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.manga.trend == 1
                ? Icon(Icons.arrow_drop_up, color: Colors.red) // up
                : widget.manga.trend == 2
                    ? Icon(Icons.arrow_drop_down, color: Colors.blue[400]) // down
                    : Icon(Icons.remove, color: Colors.grey),
            Text(
              widget.manga.score.toString(),
              style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      extraInStack: Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: widget.manga.order == 1
                ? Colors.red
                : widget.manga.order == 2
                    ? Colors.deepOrange
                    : widget.manga.order == 3
                        ? Colors.orange
                        : Colors.grey[400],
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24)),
          ),
          child: Container(
            padding: EdgeInsets.only(top: 3, left: widget.manga.order < 10 ? 12 : 7),
            child: Text(
              widget.manga.order.toString(),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (c) => MangaPage(
            id: widget.manga.mid,
            title: widget.manga.title,
            url: widget.manga.url,
          ),
        ),
      ),
    );
  }
}
