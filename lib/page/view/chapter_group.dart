import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/page/chapter.dart';
import 'package:manhuagui_flutter/page/manga_toc.dart';

/// View for [MangaChapterGroup].
class ChapterGroupView extends StatefulWidget {
  const ChapterGroupView({
    Key key,
    @required this.groups,
    @required this.mangaTitle,
    @required this.complete,
  })  : assert(groups != null),
        assert(mangaTitle != null),
        assert(complete != null),
        super(key: key);

  final List<MangaChapterGroup> groups;
  final String mangaTitle;
  final bool complete;

  @override
  _ChapterGroupViewState createState() => _ChapterGroupViewState();
}

class _ChapterGroupViewState extends State<ChapterGroupView> {
  var _invertedOrder = true;

  Widget _buildChapterView(TinyMangaChapter chapter, int index, {double padding, double height, double width}) {
    return Container(
      child: Stack(
        children: [
          Positioned.fill(
            child: OutlineButton(
              child: Text(
                chapter == null ? '...' : chapter.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (c) => chapter == null
                      ? MangaTocPage(
                          mangaTitle: widget.mangaTitle,
                          groups: widget.groups,
                        )
                      : ChapterPage(
                          chapter: chapter,
                          mangaTitle: widget.mangaTitle,
                        ),
                ),
              ),
            ),
          ),
          if (chapter?.isNew == true)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 1, horizontal: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(2),
                    topRight: Radius.circular(1),
                  ),
                ),
                child: Text(
                  'NEW',
                  style: TextStyle(fontSize: 9, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      height: height,
      width: width,
      margin: index == 0
          ? EdgeInsets.only(right: padding)
          : index == 3
              ? EdgeInsets.only(left: padding)
              : EdgeInsets.symmetric(horizontal: padding),
    );
  }

  Widget _buildSingleChapterGroupView(MangaChapterGroup group, {double hPadding, double vPadding, bool first = false}) {
    var padding = 3.0;
    var width = (MediaQuery.of(context).size.width - 2 * hPadding - 6 * padding) / 4;
    var height = 36.0;

    var chapters = _invertedOrder ? group.chapters : group.chapters.reversed.toList();
    if (!widget.complete) {
      if (first) {
        if (chapters.length > 12) {
          chapters = [...chapters.sublist(0, 11), null];
        }
      } else {
        if (chapters.length > 4) {
          chapters = [...chapters.sublist(0, 3), null];
        }
      }
    }

    var chaptersView = <Widget>[];
    var rows = (chapters.length.toDouble() / 4).ceil();
    for (var r = 0; r < rows; r++) {
      var columns = <TinyMangaChapter>[
        for (var i = 4 * r; i < 4 * (r + 1) && i < chapters.length; i++) chapters[i],
      ];
      chaptersView.add(
        Row(
          children: [
            for (var i = 0; i < columns.length; i++)
              _buildChapterView(
                columns[i],
                i,
                padding: padding,
                width: width,
                height: height,
              ),
          ],
        ),
      );
      if (r != rows - 1) {
        chaptersView.add(
          SizedBox(height: padding * 2),
        );
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: vPadding / 2),
      child: Column(
        children: [
          Text(
            '・${group.title}・',
            style: Theme.of(context).textTheme.subtitle1,
          ),
          SizedBox(height: vPadding),
          ...chaptersView,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groups.length == 0) {
      return SizedBox(height: 0);
    }

    var hPadding = 12.0;
    var vPadding = 10.0;

    return Column(
      children: [
        // ****************************************************************
        // 头
        // ****************************************************************
        Container(
          color: Colors.white,
          padding: EdgeInsets.only(left: 12, top: 2, bottom: 2, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '章节列表',
                style: Theme.of(context).textTheme.subtitle1,
              ),
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _invertedOrder = false;
                        if (mounted) setState(() {});
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 6, bottom: 6, left: 5, right: 10),
                        child: IconText(
                          icon: Icon(
                            Icons.keyboard_arrow_up,
                            size: 18,
                            color: !_invertedOrder ? Theme.of(context).primaryColor : Colors.black,
                          ),
                          text: Text(
                            '正序',
                            style: TextStyle(
                              color: !_invertedOrder ? Theme.of(context).primaryColor : Colors.black,
                            ),
                          ),
                          space: 0,
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _invertedOrder = true;
                        if (mounted) setState(() {});
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 6, bottom: 6, left: 5, right: 10),
                        child: IconText(
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: _invertedOrder ? Theme.of(context).primaryColor : Colors.black,
                          ),
                          text: Text(
                            '倒序',
                            style: TextStyle(
                              color: _invertedOrder ? Theme.of(context).primaryColor : Colors.black,
                            ),
                          ),
                          space: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          color: Colors.white,
          child: Divider(height: 1, thickness: 1),
        ),
        // ****************************************************************
        // 章节列表
        // ****************************************************************
        Container(
          padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding / 2),
          child: Column(
            children: [
              // ****************************************************************
              // 章节分组
              // ****************************************************************
              for (var i = 0; i < widget.groups.length; i++)
                _buildSingleChapterGroupView(
                  widget.groups[i],
                  first: i == 0,
                  hPadding: hPadding,
                  vPadding: vPadding,
                )
            ],
          ),
        ),
      ],
    );
  }
}
