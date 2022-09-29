import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

/// View for [ShelfManga].
/// Used in [ShelfSubPage].
class ShelfMangaLineView extends StatefulWidget {
  const ShelfMangaLineView({
    Key? key,
    required this.manga,
  })  : assert(manga != null),
        super(key: key);

  final ShelfManga manga;

  @override
  _ShelfMangaLineViewState createState() => _ShelfMangaLineViewState();
}

class _ShelfMangaLineViewState extends State<ShelfMangaLineView> {
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
                url: widget.manga.cover,
                height: 100,
                width: 75,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width - 14 * 3 - 75, // | ▢ ▢ |
              margin: EdgeInsets.only(top: 5, bottom: 5, right: 14),
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
                      icon: Icon(Icons.subject, size: 20, color: Colors.orange),
                      text: Text(
                        '更新至 ' + widget.manga.newestChapter,
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
                        '更新于 ${widget.manga.newestDuration}',
                        style: TextStyle(color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      space: 8,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: IconText(
                      icon: Icon(Icons.import_contacts, size: 20, color: Colors.orange),
                      text: Text(
                        '最近阅读至 ${widget.manga.lastChapter.isEmpty ? '未知话' : widget.manga.lastChapter} (${widget.manga.lastDuration})',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      space: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    );
  }
}
