import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/user.dart';
import 'package:manhuagui_flutter/page/view/login_first.dart';
import 'package:manhuagui_flutter/service/prefs/auth.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';
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
  bool _loading = false;
  User _data;
  String _error;

  @override
  void initState() {
    super.initState();
    AuthState.instance.registerListener(this, () => mountedSetState(() {}));
    widget.action?.addAction('', () => print('MineSubPage'));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUser());
  }

  @override
  void dispose() {
    AuthState.instance.unregisterListener(this);
    super.dispose();
  }

  Future<bool> _loadUser() {
    _loading = true;
    if (mounted) setState(() {});

    var dio = DioManager.instance.dio;
    var client = RestClient(dio);
    return client.getUserInfo(token: AuthState.instance.token).then((r) async {
      _error = '';
      _data = null;
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _data = r.data;
    }).catchError((e) {
      _data = null;
      _error = wrapError(e).text;
    }).whenComplete(() {
      _loading = false;
      if (mounted) setState(() {});
    });
  }

  @override
  String get key => 'MineSubPage';

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
          title: Text('我的'),
        ),
        body: LoginFirstView(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: Text('我的'),
      ),
      body: PlaceholderText.from(
        isLoading: _loading,
        errorText: _error,
        isEmpty: _data == null,
        setting: PlaceholderSetting().toChinese(),
        onRefresh: () => _loadUser(),
        childBuilder: (c) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('token: ${AuthState.instance.token}'),
              Text('username: ${_data.username}'),
              OutlineButton(
                child: Text('退出登录'),
                onPressed: () async {
                  await removeToken();
                  AuthState.instance.token = null;
                  AuthState.instance.notifyAll();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
