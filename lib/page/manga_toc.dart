import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/chapter.dart';

/// 漫画章节目录
/// Page for [MangaChapterGroup].
class MangaTocPage extends StatefulWidget {
  const MangaTocPage({
    Key key,
    @required this.title,
    @required this.groups,
  })  : assert(title != null),
        assert(groups != null),
        super(key: key);

  final String title;
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
        title: Text(widget.title),
      ),
      body: Center(
        child: Text('MangaTocPage'),
      ),
    );
  }
}
