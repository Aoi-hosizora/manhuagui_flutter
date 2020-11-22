import 'package:flutter/material.dart';

/// 分类类别
class GenreSubPage extends StatefulWidget {
  const GenreSubPage({Key key}) : super(key: key);

  @override
  _GenreSubPageState createState() => _GenreSubPageState();
}

class _GenreSubPageState extends State<GenreSubPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Center(
        child: Text('GenreSubPage'),
      ),
    );
  }
}
