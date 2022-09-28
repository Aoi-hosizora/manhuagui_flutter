import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/page/page/genre.dart';

/// 类别
/// Page for [TinyCategory].
class GenrePage extends StatefulWidget {
  const GenrePage({
    Key key,
    required this.genre,
  })  : assert(genre != null),
        super(key: key);

  final TinyCategory genre;

  @override
  _GenrePageState createState() => _GenrePageState();
}

class _GenrePageState extends State<GenrePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: Text('漫画分类'),
      ),
      body: GenreSubPage(
        defaultGenre: widget.genre,
      ),
    );
  }
}
