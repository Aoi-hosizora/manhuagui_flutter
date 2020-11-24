import 'package:flutter/material.dart';

/// 漫画页
class MangaPage extends StatefulWidget {
  const MangaPage({Key key, @required this.id, @required this.title})
      : assert(id != null),
        assert(title != null),
        super(key: key);

  final int id;
  final String title;

  @override
  _MangaPageState createState() => _MangaPageState();
}

class _MangaPageState extends State<MangaPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: Text(widget.title),
      ),
      body: Center(
        child: Text('MangaPage'),
      ),
    );
  }
}
