import 'package:flutter/material.dart';

/// 我的
class MineSubPage extends StatefulWidget {
  const MineSubPage({Key key}) : super(key: key);

  @override
  _MineSubPageState createState() => _MineSubPageState();
}

class _MineSubPageState extends State<MineSubPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Center(
        child: Text('MineSubPage'),
      ),
    );
  }
}
