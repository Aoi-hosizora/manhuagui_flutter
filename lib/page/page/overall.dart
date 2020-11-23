import 'package:flutter/material.dart';

/// 首页全部
class OverallSubPage extends StatefulWidget {
  const OverallSubPage({Key key}) : super(key: key);

  @override
  _OverallSubPageState createState() => _OverallSubPageState();
}

class _OverallSubPageState extends State<OverallSubPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Center(
        child: Text('OverallSubPage'),
      ),
    );
  }
}
