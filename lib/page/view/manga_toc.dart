import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/page/manga_toc.dart';
import 'package:manhuagui_flutter/page/manga_viewer.dart';

/// 漫画章节目录，在 [MangaPage] / [MangaTocPage] 使用
class MangaTocView extends StatefulWidget {
  const MangaTocView({
    Key? key,
    required this.groups,
    required this.full,
    this.highlightedChapter = 0,
    this.lastChapterPage = 1,
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    this.predicate,
  }) : super(key: key);

  final List<MangaChapterGroup> groups;
  final bool full;
  final int highlightedChapter;
  final int lastChapterPage;
  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final bool Function(int cid)? predicate;

  @override
  _MangaTocViewState createState() => _MangaTocViewState();
}

class _MangaTocViewState extends State<MangaTocView> {
  var _invertedOrder = true;

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '章节列表',
          style: Theme.of(context).textTheme.subtitle1,
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _invertedOrder = false;
                    if (mounted) setState(() {});
                  },
                  child: Padding(
                    padding: EdgeInsets.only(top: 3, bottom: 3, left: 5, right: 10),
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
                    padding: EdgeInsets.only(top: 3, bottom: 3, left: 5, right: 10),
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
        ),
      ],
    );
  }

  Widget _buildItem({required TinyMangaChapter? chapter, required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: widget.highlightedChapter == chapter?.cid ? Theme.of(context).primaryColorLight.withOpacity(0.6) : null,
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  buttonTheme: ButtonTheme.of(context).copyWith(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                child: OutlinedButton(
                  child: Text(
                    chapter?.title ?? '...',
                    style: TextStyle(color: Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  ),
                  onPressed: () {
                    if (chapter == null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (c) => MangaTocPage(
                            mid: widget.mangaId,
                            mangaTitle: widget.mangaTitle,
                            mangaCover: widget.mangaCover,
                            mangaUrl: widget.mangaUrl,
                            groups: widget.groups,
                          ),
                        ),
                      );
                    } else {
                      var ok = widget.predicate?.call(chapter.cid) ?? true;
                      if (ok) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (c) => MangaViewerPage(
                              mid: chapter.mid,
                              mangaTitle: widget.mangaTitle,
                              mangaCover: widget.mangaCover,
                              mangaUrl: widget.mangaUrl,
                              chapterGroups: widget.groups,
                              cid: chapter.cid,
                              initialPage: widget.highlightedChapter == chapter.cid
                                  ? widget.lastChapterPage // has read
                                  : 1, // has not read
                            ),
                          ),
                        );
                      }
                    }
                  },
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

  Widget _buildGroupItems({required MangaChapterGroup group, required EdgeInsets padding, bool firstGroup = false}) {
    const hSpace = 8.0;
    const vSpace = 8.0;
    final width = (MediaQuery.of(context).size.width - 2 * padding.left - 3 * hSpace) / 4; // |   ▢ ▢ ▢ ▢   |

    List<TinyMangaChapter?> chapters = _invertedOrder ? group.chapters : group.chapters.reversed.toList();
    if (!widget.full) {
      if (firstGroup) {
        if (chapters.length > 12) {
          chapters = [...chapters.sublist(0, 11), null]; // X X X X | X X X X | X X X O
        }
      } else {
        if (chapters.length > 4) {
          chapters = [...chapters.sublist(0, 3), null]; // X X X O
        }
      }
    }

    return Padding(
      padding: padding,
      child: Wrap(
        spacing: hSpace,
        runSpacing: vSpace,
        children: [
          for (var chapter in chapters)
            _buildItem(
              chapter: chapter,
              width: width,
              height: 36,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) {
      return SizedBox(height: 0);
    }

    var groups = widget.groups;
    var specificGroups = widget.groups.where((g) => g.title == '单话');
    if (specificGroups.isNotEmpty) {
      var sGroup = specificGroups.first;
      groups = [sGroup];
      for (var group in widget.groups) {
        if (group.title != '单话' && group.chapters.length != sGroup.chapters.length) {
          groups.add(group);
        }
      }
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.only(left: 12, right: 4, top: 2, bottom: 2),
          child: _buildHeader(),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          color: Colors.white,
          child: Divider(height: 0, thickness: 1),
        ),
        for (var i = 0; i < groups.length; i++) ...[
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '・${groups[i].title}・',
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: _buildGroupItems(
              group: groups[i],
              padding: EdgeInsets.symmetric(horizontal: 12),
              firstGroup: i == 0,
            ),
          ),
        ],
        SizedBox(height: 10),
      ],
    );
  }
}
