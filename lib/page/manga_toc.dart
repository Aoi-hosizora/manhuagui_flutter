import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/page/view/chapter_group.dart';

/// 漫画章节目录
/// Page for [MangaChapterGroup].
class MangaTocPage extends StatefulWidget {
  const MangaTocPage({
    Key key,
    @required this.mangaTitle,
    @required this.groups,
  })  : assert(mangaTitle != null),
        assert(groups != null),
        super(key: key);

  final String mangaTitle;
  final List<MangaChapterGroup> groups;

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
                complete: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
