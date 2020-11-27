import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

/// View for [TinyManga].
/// Used in [RecommendSubPage] and [MangaGroupPage].
class TinyMangaBlockView extends StatefulWidget {
  const TinyMangaBlockView({
    Key key,
    @required this.manga,
    @required this.width,
    @required this.height,
    @required this.vPadding,
  })  : assert(manga != null),
        assert(height != null),
        assert(width != null),
        assert(vPadding != null),
        super(key: key);

  final TinyManga manga;
  final double width;
  final double height;
  final double vPadding;

  @override
  _TinyMangaBlockViewState createState() => _TinyMangaBlockViewState();
}

class _TinyMangaBlockViewState extends State<TinyMangaBlockView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: widget.vPadding),
              width: widget.width,
              height: widget.height,
              child: Stack(
                children: [
                  NetworkImageView(
                    url: widget.manga.cover,
                    width: widget.width,
                    height: widget.height,
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
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: widget.vPadding),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                width: widget.width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 1],
                    colors: [
                      Color.fromRGBO(0, 0, 0, 0),
                      Color.fromRGBO(0, 0, 0, 1),
                    ],
                  ),
                ),
                child: Text(
                  (widget.manga.finished ? '共' : '更新至') + widget.manga.newestChapter,
                  style: TextStyle(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        Container(
          width: widget.width,
          margin: EdgeInsets.symmetric(horizontal: widget.vPadding, vertical: 3),
          child: Text(
            widget.manga.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
