import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

/// View for [TinyManga].
class TinyMangaView extends StatefulWidget {
  const TinyMangaView({
    Key key,
    @required this.manga,
    @required this.height,
    @required this.width,
    @required this.paddingWidth,
  })  : assert(manga != null),
        assert(height != null && width != null && paddingWidth != null),
        super(key: key);

  final TinyManga manga;
  final double height;
  final double width;
  final double paddingWidth;

  @override
  _TinyMangaViewState createState() => _TinyMangaViewState();
}

class _TinyMangaViewState extends State<TinyMangaView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: widget.paddingWidth),
              height: widget.height,
              width: widget.width,
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
                margin: EdgeInsets.symmetric(horizontal: widget.paddingWidth),
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
          margin: EdgeInsets.symmetric(horizontal: widget.paddingWidth, vertical: 3),
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
