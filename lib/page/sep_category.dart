import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/page/page/category_manga.dart';
import 'package:manhuagui_flutter/page/search.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';

/// 漫画类别页，即 Separate [MangaCategorySubPage]
class SepCategoryPage extends StatefulWidget {
  const SepCategoryPage({
    Key? key,
    required this.genre,
  }) : super(key: key);

  final TinyCategory genre;

  @override
  _SepCategoryPageState createState() => _SepCategoryPageState();
}

class _SepCategoryPageState extends State<SepCategoryPage> {
  final _action = ActionController();

  @override
  void initState() {
    super.initState();
    _action.addAction('updateSubPage', () => mountedSetState(() {}));
  }

  @override
  void dispose() {
    _action.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('漫画类别'),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: true),
        actions: [
          if (_action.invoke('ifNeedBack') == true)
            AppBarActionButton(
              key: ValueKey('SepCategoryPage_AppBarActionButton_Back'),
              icon: Icon(Icons.apps),
              tooltip: '返回类别列表',
              onPressed: () => _action.invoke('back'),
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
        currentSelection: DrawerSelection.none,
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: MangaCategorySubPage(
        action: _action,
        defaultGenre: widget.genre,
      ),
    );
  }
}
