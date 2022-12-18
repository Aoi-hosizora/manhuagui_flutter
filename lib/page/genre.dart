import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/page/page/category_genre.dart';

/// 漫画类别页，同 [GenreSubPage]
class GenrePage extends StatefulWidget {
  const GenrePage({
    Key? key,
    this.genres,
    required this.genre,
  })  : super(key: key);

  final List<TinyCategory>? genres;
  final TinyCategory genre;

  @override
  _GenrePageState createState() => _GenrePageState();
}

class _GenrePageState extends State<GenrePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('漫画类别'),
        leading: AppBarActionButton.leading(context: context),
      ),
      body: GenreSubPage(
        genres: widget.genres,
        defaultGenre: widget.genre,
      ),
    );
  }
}
