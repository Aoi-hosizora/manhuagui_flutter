import 'package:flutter/material.dart';

/// 首页排行
class RankingSubPage extends StatefulWidget {
  const RankingSubPage({Key key}) : super(key: key);

  @override
  _RankingSubPageState createState() => _RankingSubPageState();
}

class _RankingSubPageState extends State<RankingSubPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Center(
        child: Text('RankingSubPage'),
      ),
    );
  }
}
