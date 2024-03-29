import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/manga_group.dart';

/// 漫画分组页，展示所给 [MangaGroupList] (三个 [MangaGroup]) 信息
class MangaGroupPage extends StatefulWidget {
  const MangaGroupPage({
    Key? key,
    required this.groupList,
  }) : super(key: key);

  final MangaGroupList groupList;

  @override
  _MangaGroupPageState createState() => _MangaGroupPageState();
}

class _MangaGroupPageState extends State<MangaGroupPage> {
  final _controller = ScrollController();
  final _physicsController = CustomScrollPhysicsController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DrawerScaffold(
      appBar: AppBar(
        title: Text('漫画分组'),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: false),
      ),
      drawer: AppDrawer(
        currentSelection: DrawerSelection.none,
      ),
      drawerEdgeDragWidth: null,
      physicsController: _physicsController,
      implicitlyOverscrollableScaffold: true,
      body: ExtendedScrollbar(
        controller: _controller,
        interactive: true,
        mainAxisMargin: 2,
        crossAxisMargin: 2,
        child: ListView(
          controller: _controller,
          padding: EdgeInsets.zero,
          physics: AlwaysScrollableScrollPhysics(),
          children: [
            DefaultScrollPhysics(
              physics: CustomScrollPhysics(controller: _physicsController),
              child: MangaGroupView(
                groupList: widget.groupList,
                style: MangaGroupViewStyle.normalFull,
              ),
            ),
          ],
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
