import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/page/subscribe_favorite.dart';
import 'package:manhuagui_flutter/page/search.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';

/// 本地收藏页，即 Separate [FavoriteSubPage]
class SepFavoritePage extends StatefulWidget {
  const SepFavoritePage({
    Key? key,
  }) : super(key: key);

  @override
  _SepFavoritePageState createState() => _SepFavoritePageState();
}

class _SepFavoritePageState extends State<SepFavoritePage> {
  final _action = ActionController();
  final _physicsController = CustomScrollPhysicsController();

  @override
  void dispose() {
    _action.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DrawerScaffold(
      appBar: AppBar(
        title: Text('本地收藏'),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: true),
        actions: [
          AppBarActionButton(
            icon: Icon(Icons.bookmark_border),
            tooltip: '管理本地收藏',
            onPressed: () => _action.invoke('manage'),
          ),
          AppBarActionButton(
            icon: Icon(Icons.search),
            tooltip: '搜索漫画',
            onPressed: () => Navigator.of(context).push(
              CustomPageRoute(
                context: context,
                builder: (c) => SearchPage(),
              ),
            ),
          ),
        ],
      ),
      drawer: AppDrawer(
        currentSelection: DrawerSelection.favorite,
      ),
      drawerEdgeDragWidth: null,
      physicsController: _physicsController /* shared physics controller */,
      checkPhysicsControllerForOverscroll: true,
      implicitlyOverscrollableScaffold: true,
      implicitPageViewScrollPhysics: CustomScrollPhysics(controller: _physicsController),
      body: DefaultScrollPhysics(
        physics: CustomScrollPhysics(controller: _physicsController),
        child: FavoriteSubPage(
          action: _action,
          isSepPage: true,
        ),
      ),
    );
  }
}
