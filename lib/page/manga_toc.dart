import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/page/view/chapter_group.dart';

/// 漫画章节目录
/// Page for [MangaChapterGroup].
class MangaTocPage extends StatefulWidget {
  const MangaTocPage({
    Key key,
    @required this.mangaTitle,
    @required this.mangaCover,
    @required this.mangaUrl,
    @required this.groups,
    this.parentAction,
    this.highlightChapter,
  })  : assert(mangaTitle != null),
        assert(mangaCover != null),
        assert(mangaUrl != null),
        assert(groups != null),
        super(key: key);

  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final List<MangaChapterGroup> groups;
  final ActionController parentAction;
  final int highlightChapter;

  @override
  _MangaTocPageState createState() => _MangaTocPageState();
}

class _MangaTocPageState extends State<MangaTocPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: Text(widget.mangaTitle),
      ),
      body: Container(
        color: Colors.white,
        child: Scrollbar(
          child: ListView(
            children: [
              ChapterGroupView(
                groups: widget.groups,
                mangaTitle: widget.mangaTitle,
                mangaCover: widget.mangaCover,
                mangaUrl: widget.mangaUrl,
                complete: true,
                parentAction: widget.parentAction,
                highlightChapter: widget.highlightChapter,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
