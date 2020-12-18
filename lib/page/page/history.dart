import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

/// 订阅浏览历史
class HistorySubPage extends StatefulWidget {
  const HistorySubPage({
    Key key,
    this.action,
  }) : super(key: key);

  final ActionController action;

  @override
  _HistorySubPageState createState() => _HistorySubPageState();
}

class _HistorySubPageState extends State<HistorySubPage> with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    widget.action.addAction('', () => print('HistorySubPage'));
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: Text('HistorySubPage'),
    );
  }
}
