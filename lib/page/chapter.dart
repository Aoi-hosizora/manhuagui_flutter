import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/chapter.dart';

/// 章节
/// Page for [TinyMangaChapter].
class ChapterPage extends StatefulWidget {
  const ChapterPage({
    Key key,
    @required this.mangaTitle,
    @required this.chapter,
  })  : assert(chapter != null),
        super(key: key);

  final String mangaTitle;
  final TinyMangaChapter chapter;

  @override
  _ChapterPageState createState() => _ChapterPageState();
}

class _ChapterPageState extends State<ChapterPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: Text(widget.chapter.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.mangaTitle),
            Text(widget.chapter.title),
            Text('mid: ${widget.chapter.mid}'),
            Text('cid: ${widget.chapter.cid}'),
          ],
        ),
      ),
    );
  }
}
