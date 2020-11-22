import 'package:flutter/material.dart';

/// 我的
class MineSubPage extends StatefulWidget {
  const MineSubPage({Key key}) : super(key: key);

  @override
  _MineSubPageState createState() => _MineSubPageState();
}

class _MineSubPageState extends State<MineSubPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('MineSubPage'),
      ),
    );
  }
}
