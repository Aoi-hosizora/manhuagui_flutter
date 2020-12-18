import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/view/login_first.dart';
import 'package:manhuagui_flutter/service/state/auth.dart';
import 'package:manhuagui_flutter/service/state/notifiable.dart';

/// 我的
class MineSubPage extends StatefulWidget {
  const MineSubPage({
    Key key,
    this.action,
  }) : super(key: key);

  final ActionController action;

  @override
  _MineSubPageState createState() => _MineSubPageState();
}

class _MineSubPageState extends State<MineSubPage> with AutomaticKeepAliveClientMixin, NotifiableMixin {
  @override
  void initState() {
    super.initState();
    AuthState.instance.registerListener(this, () => mountedSetState(() {}));
    widget.action?.addAction('', () => print('MineSubPage'));
  }

  @override
  void dispose() {
    AuthState.instance.unregisterListener(this);
    super.dispose();
  }

  @override
  String get key => 'MineSubPage';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!AuthState.instance.logined) {
      return LoginFirstView();
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('token: ${AuthState.instance.token}'),
            OutlineButton(
              child: Text('退出登录'),
              onPressed: () {
                AuthState.instance.token = null;
                AuthState.instance.notifyAll();
              },
            ),
          ],
        ),
      ),
    );
  }
}
