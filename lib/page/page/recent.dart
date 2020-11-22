import 'package:flutter/material.dart';

/// 首页更新
class RecentSubPage extends StatefulWidget {
  const RecentSubPage({Key key}) : super(key: key);

  @override
  _RecentSubPageState createState() => _RecentSubPageState();
}

class _RecentSubPageState extends State<RecentSubPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Center(
        child: Text('RecentSubPage'),
      ),
    );
  }
}
