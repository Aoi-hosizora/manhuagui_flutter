import 'package:flutter/material.dart';
import 'package:flutter_ahlib/widget.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/page/author.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

/// View for [SmallAuthor] (Line style).
class SmallAuthorLineView extends StatefulWidget {
  const SmallAuthorLineView({
    Key key,
    @required this.author,
  })  : assert(author != null),
        super(key: key);

  final SmallAuthor author;

  @override
  _SmallAuthorLineViewState createState() => _SmallAuthorLineViewState();
}

class _SmallAuthorLineViewState extends State<SmallAuthorLineView> {
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
                url: widget.author.cover,
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
                      widget.author.name,
                      style: Theme.of(context).textTheme.subtitle1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: IconText(
                      icon: Icon(Icons.place, size: 20, color: Colors.orange),
                      text: Text(
                        widget.author.zone,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      space: 8,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: IconText(
                      icon: Icon(Icons.edit, size: 20, color: Colors.orange),
                      text: Text(
                        '共 ${widget.author.mangaCount} 部漫画',
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
                        '更新于 ${widget.author.newestDate}',
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
                  builder: (c) => AuthorPage(
                    id: widget.author.aid,
                    name: widget.author.name,
                    url: widget.author.url,
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
