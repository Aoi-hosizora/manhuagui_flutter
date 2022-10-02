import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/page/page/genre.dart';

/// 漫画类别页，同 [GenreSubPage]
class GenrePage extends StatefulWidget {
  const GenrePage({
    Key? key,
    required this.genre,
  })  : super(key: key);

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
      ),
      body: GenreSubPage(
        defaultGenre: widget.genre,
      ),
    );
  }
}
