import 'package:flutter/material.dart';

/// 首页推荐
class RecommendSubPage extends StatefulWidget {
  const RecommendSubPage({Key key}) : super(key: key);

  @override
  _RecommendSubPageState createState() => _RecommendSubPageState();
}

class _RecommendSubPageState extends State<RecommendSubPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('RecommendSubPage'),
      ),
    );
  }
}
