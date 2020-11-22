import 'package:flutter/material.dart';

/// 分类漫画家
class AuthorSubPage extends StatefulWidget {
  const AuthorSubPage({Key key}) : super(key: key);

  @override
  _AuthorSubPageState createState() => _AuthorSubPageState();
}

class _AuthorSubPageState extends State<AuthorSubPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('AuthorSubPage'),
      ),
    );
  }
}
