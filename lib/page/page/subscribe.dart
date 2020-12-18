import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/view/login_first.dart';
import 'package:manhuagui_flutter/service/state/auth.dart';
import 'package:manhuagui_flutter/service/state/notifiable.dart';

/// 订阅
class SubscribeSubPage extends StatefulWidget {
  const SubscribeSubPage({
    Key key,
    this.actionController,
  }) : super(key: key);

  final ActionController actionController;

  @override
  _SubscribeSubPageState createState() => _SubscribeSubPageState();
}

class _SubscribeSubPageState extends State<SubscribeSubPage> with AutomaticKeepAliveClientMixin, NotifiableMixin {
  @override
  void initState() {
    super.initState();
    AuthState.instance.registerListener(this, () => mountedSetState(() {}));
  }

  @override
  void dispose() {
    AuthState.instance.unregisterListener(this);
    super.dispose();
  }

  @override
  String get key => 'SubscribeSubPage';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!AuthState.instance.logined) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          toolbarHeight: 45,
          title: Text('订阅'),
        ),
        body: Center(
          child: LoginFirstView(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: Text('订阅'),
      ),
      body: Center(
        child: Text('token: ${AuthState.instance.token}'),
      ),
    );
  }
}
