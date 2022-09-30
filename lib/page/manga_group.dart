import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/manga_group.dart';

/// 漫画分组
/// Page for [MangaGroup].
class MangaGroupPage extends StatefulWidget {
  const MangaGroupPage({
    Key? key,
    required this.group,
    required this.type,
  }) : super(key: key);

  final MangaGroup group;
  final MangaGroupType type;

  @override
  _MangaGroupPageState createState() => _MangaGroupPageState();
}

class _MangaGroupPageState extends State<MangaGroupPage> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('漫画分组详细'),
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: 4, top: 2),
        child: MangaGroupView(
          group: widget.group,
          type: widget.type,
          controller: _controller,
          style: MangaGroupViewStyle.normalFull,
        ),
      ),
      floatingActionButton: ScrollAnimatedFab(
        scrollController: _controller,
        condition: ScrollAnimatedCondition.direction,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: null,
          onPressed: () => _controller.scrollToTop(),
        ),
      ),
    );
  }
}
