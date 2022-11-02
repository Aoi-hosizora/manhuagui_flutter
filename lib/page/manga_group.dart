import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/manga_group.dart';
import 'package:manhuagui_flutter/page/view/my_drawer.dart';

/// 漫画分组页，展示所给 [MangaGroup] 信息
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
        title: Text('漫画分组'),
        leading: AppBarActionButton.leading(context: context),
      ),
      drawer: MyDrawer(
        currentDrawerSelection: DrawerSelection.none,
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: ScrollbarWithMore(
        controller: _controller,
        interactive: true,
        crossAxisMargin: 2,
        child: SingleChildScrollView(
          controller: _controller,
          child: MangaGroupView(
            group: widget.group,
            type: widget.type,
            controller: _controller,
            style: MangaGroupViewStyle.normalFull,
          ),
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
