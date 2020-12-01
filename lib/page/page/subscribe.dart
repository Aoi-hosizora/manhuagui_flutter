import 'package:flutter/material.dart';

/// 订阅
class SubscribeSubPage extends StatefulWidget {
  const SubscribeSubPage({Key key}) : super(key: key);

  @override
  _SubscribeSubPageState createState() => _SubscribeSubPageState();
}

class _SubscribeSubPageState extends State<SubscribeSubPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: Text('订阅'),
      ),
      body: Center(
        child: Text('SubscribeSubPage'),
      ),
    );
  }
}
