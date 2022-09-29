import 'package:flutter/material.dart';
import 'package:flutter_ahlib/util.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/page/chapter.dart';
import 'package:manhuagui_flutter/page/manga_toc.dart';

/// View for [MangaChapterGroup].
/// Used in [MangaPage] and [MangaTocPage].
class ChapterGroupView extends StatefulWidget {
  const ChapterGroupView({
    Key? key,
    this.action,
    required this.groups,
    required this.complete,
    this.highlightChapter = 0,
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
  })  : assert(groups != null),
        assert(complete != null),
        assert(highlightChapter != null),
        assert(mangaId != null),
        assert(mangaTitle != null),
        assert(mangaCover != null),
        assert(mangaUrl != null),
        super(key: key);

  final ActionController action;
  final List<MangaChapterGroup> groups;
  final bool complete;
  final int highlightChapter;
  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;

  @override
  _ChapterGroupViewState createState() => _ChapterGroupViewState();
}

class _ChapterGroupViewState extends State<ChapterGroupView> {
  var _invertedOrder = true;

  Widget _buildGridItem(TinyMangaChapter chapter, int index, {double hSpace, double width, double height}) {
    // ****************************************************************
    // 每个章节
    // ****************************************************************
    return Container(
      width: width,
      height: height,
      margin: index == 0
          ? EdgeInsets.only(right: hSpace)
          : index == 3
              ? EdgeInsets.only(left: hSpace)
              : EdgeInsets.symmetric(horizontal: hSpace),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: chapter != null && widget.highlightChapter == chapter.cid ? Theme.of(context).primaryColor.withOpacity(0.5) : Colors.white,
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  buttonTheme: ButtonTheme.of(context).copyWith(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                child: OutlinedButton(
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
                              action: widget.action,
                              mid: widget.mangaId,
                              title: widget.mangaTitle,
                              cover: widget.mangaCover,
                              url: widget.mangaUrl,
                              groups: widget.groups,
                              highlightChapter: widget.highlightChapter,
                            )
                          : ChapterPage(
                              action: widget.action,
                              mid: chapter.mid,
                              cid: chapter.cid,
                              mangaTitle: widget.mangaTitle,
                              mangaCover: widget.mangaCover,
                              mangaUrl: widget.mangaUrl,
                            ),
                    ),
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
    );
  }

  Widget _buildSingleGroup(MangaChapterGroup group, {double hPadding, double vPadding, bool first = false}) {
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

    var hSpace = 3.0;
    var vSpace = 2 * hSpace;
    var width = (MediaQuery.of(context).size.width - 2 * hPadding - 6 * hSpace) / 4; // |   ▢  ▢  ▢  ▢   |
    var height = 36.0;

    var gridRows = <Widget>[];
    var rows = (chapters.length.toDouble() / 4).ceil();
    for (var r = 0; r < rows; r++) {
      var columns = <TinyMangaChapter>[
        for (var i = 4 * r; i < 4 * (r + 1) && i < chapters.length; i++) chapters[i],
      ];
      gridRows.add(
        // ****************************************************************
        // 分组中的每一行
        // ****************************************************************
        Row(
          children: [
            for (var i = 0; i < columns.length; i++)
              _buildGridItem(
                columns[i],
                i,
                hSpace: hSpace,
                width: width,
                height: height,
              ),
          ],
        ),
      );
      if (r != rows - 1) {
        gridRows.add(
          SizedBox(height: vSpace),
        );
      }
    }

    // ****************************************************************
    // 单个章节分组
    // ****************************************************************
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '・${group.title}・',
          style: Theme.of(context).textTheme.subtitle1,
        ),
        SizedBox(height: vPadding),
        ...gridRows,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groups.length == 0) {
      return SizedBox(height: 0);
    }

    var hPadding = 12.0;
    var vPadding = 10.0;
    var groups = widget.groups;
    var specificGroups = widget.groups.where((g) => g.title == '单话');
    if (specificGroups.length != 0) {
      var sGroup = specificGroups.first;
      groups = [sGroup];
      for (var group in widget.groups) {
        if (group.title != sGroup.title && group.chapters.length != sGroup.chapters.length) {
          groups.add(group);
        }
      }
    }

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
              // ****************************************************************
              // 两个排序按钮
              // ****************************************************************
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
        // 章节分组列表
        // ****************************************************************
        Container(
          padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding / 2),
          child: Column(
            children: [
              // ****************************************************************
              // 单个章节分组
              // ****************************************************************
              for (var i = 0; i < groups.length; i++)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: vPadding / 2),
                  child: _buildSingleGroup(
                    groups[i],
                    first: i == 0,
                    hPadding: hPadding,
                    vPadding: vPadding,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
