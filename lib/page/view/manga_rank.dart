import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

/// View for [MangaRank].
/// Used in [RankingSubPage].
class MangaRankView extends StatefulWidget {
  const MangaRankView({
    Key key,
    @required this.manga,
  })  : assert(manga != null),
        super(key: key);

  final MangaRank manga;

  @override
  _MangaRankViewState createState() => _MangaRankViewState();
}

class _MangaRankViewState extends State<MangaRankView> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              child: NetworkImageView(
                url: '$DEFAULT_MANGA_COVER_URL${widget.manga.mid}.jpg',
                height: 100,
                width: 75,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width - 14 * 4 - 75 - 35, // | ▢ ▢ ▢ |
              margin: EdgeInsets.only(top: 5, bottom: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      widget.manga.title,
                      style: Theme.of(context).textTheme.subtitle1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: IconText(
                      icon: Icon(Icons.edit, size: 20, color: Colors.orange),
                      text: Text(
                        widget.manga.finished ? '已完结' : '连载中',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      space: 8,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: IconText(
                      icon: Icon(Icons.subject, size: 20, color: Colors.orange),
                      text: Text(
                        (widget.manga.finished ? '共' : '更新至') + widget.manga.newestChapter,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      space: 8,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: IconText(
                      icon: Icon(Icons.access_time, size: 20, color: Colors.orange),
                      text: Text(
                        widget.manga.newestDate,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      space: 8,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              width: 35,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.manga.trend == 1
                      ? Icon(Icons.arrow_drop_up, color: Colors.blue[400])
                      : widget.manga.trend == 2
                          ? Icon(Icons.arrow_drop_down, color: Colors.red)
                          : Icon(Icons.remove, color: Colors.grey),
                  Text(
                    widget.manga.score.toString(),
                    style: Theme.of(context).textTheme.subtitle1.copyWith(color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
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
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (c) => MangaPage(
                    id: widget.manga.mid,
                    title: widget.manga.title,
                    url: widget.manga.url,
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
