import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:intl/intl.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

/// View for [HistoryManga].
/// Used in [HistorySubPage].
class MangaHistoryLineView extends StatefulWidget {
  const MangaHistoryLineView({
    Key? key,
    required this.history,
    required this.onLongPressed,
  }) : super(key: key);

  final MangaHistory history;
  final Function() onLongPressed;

  @override
  _MangaHistoryLineViewState createState() => _MangaHistoryLineViewState();
}

class _MangaHistoryLineViewState extends State<MangaHistoryLineView> {
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
                url: widget.history.mangaCover,
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
                      widget.history.mangaTitle,
                      style: Theme.of(context).textTheme.subtitle1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.history.read)
                    Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: IconText(
                        icon: Icon(Icons.subject, size: 20, color: Colors.orange),
                        text: Text(
                          '阅读至 ${widget.history.chapterTitle}',
                          style: TextStyle(color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        space: 8,
                      ),
                    ),
                  if (widget.history.read)
                    Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: IconText(
                        icon: Icon(Icons.import_contacts, size: 20, color: Colors.orange),
                        text: Text(
                          '第${widget.history.chapterPage}页',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        space: 8,
                      ),
                    ),
                  if (!widget.history.read) SizedBox(height: 22),
                  if (!widget.history.read)
                    Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: IconText(
                        icon: Icon(Icons.subject, size: 20, color: Colors.orange),
                        text: Text(
                          '未开始阅读',
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
                        DateFormat('yyyy-MM-dd HH:mm:ss').format(widget.history.lastTime),
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
                    id: widget.history.mangaId,
                    title: widget.history.mangaTitle,
                    url: widget.history.mangaUrl,
                  ),
                ),
              ),
              onLongPress: () => widget.onLongPressed(),
            ),
          ),
        ),
      ],
    );
  }
}
