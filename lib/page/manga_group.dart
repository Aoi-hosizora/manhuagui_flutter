import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/manga_column.dart';

/// 漫画分组
/// Page for [MangaGroup].
class MangaGroupPage extends StatefulWidget {
  const MangaGroupPage({
    Key key,
    @required this.group,
    @required this.type,
  })  : assert(group != null),
        assert(type != null),
        super(key: key);

  final MangaGroup group;
  final MangaGroupType type;

  @override
  _MangaGroupPageState createState() => _MangaGroupPageState();
}

class _MangaGroupPageState extends State<MangaGroupPage> {
  ScrollMoreController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollMoreController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: Text('漫画分组详细'),
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: 4, top: 2),
        child: MangaColumnView(
          group: widget.group,
          type: widget.type,
          controller: _controller,
          complete: true,
          showTopMargin: false,
        ),
      ),
      floatingActionButton: ScrollFloatingActionButton(
        scrollController: _controller,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: 'MangaGroupPage',
          onPressed: () => _controller.scrollTop(),
        ),
      ),
    );
  }
}
