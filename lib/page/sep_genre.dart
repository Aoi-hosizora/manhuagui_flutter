import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/page/page/category_genre.dart';
import 'package:manhuagui_flutter/page/search.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';

/// 漫画类别页，即 Separate [GenreSubPage]
class SepGenrePage extends StatefulWidget {
  const SepGenrePage({
    Key? key,
    required this.genre,
  }) : super(key: key);

  final TinyCategory genre;

  @override
  _SepGenrePageState createState() => _SepGenrePageState();
}

class _SepGenrePageState extends State<SepGenrePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('漫画类别'),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: true),
        actions: [
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
      body: GenreSubPage(
        defaultGenre: widget.genre,
      ),
    );
  }
}
