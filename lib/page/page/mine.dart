import 'package:flutter/material.dart';
import 'package:flutter_ahlib/util.dart';
import 'package:flutter_ahlib/widget.dart';
import 'package:manhuagui_flutter/model/user.dart';
import 'package:manhuagui_flutter/page/setting.dart';
import 'package:manhuagui_flutter/page/view/login_first.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/service/prefs/auth.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';
import 'package:manhuagui_flutter/service/state/auth.dart';

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

class _MineSubPageState extends State<MineSubPage> with AutomaticKeepAliveClientMixin, NotifyReceiverMixin {
  bool _loading = false;
  User _data;
  String _error;

  @override
  String get receiverKey => 'MineSubPage';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthState.instance.logined) {
        if (mounted) setState(() {});
        _loadUser();
      }
    });
    AuthState.instance.registerDefault(this, () {
      if (mounted) setState(() {});
      if (AuthState.instance.logined) {
        _loadUser();
      }
    });
    widget.action?.addAction('', () {});
  }

  @override
  void dispose() {
    AuthState.instance.unregisterDefault(this);
    widget.action?.removeAction('');
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
      var we = wrapError(e);
      _error = we.text;
      if (we.httpCode == 401) {
        _logout();
      }
    }).whenComplete(() {
      _loading = false;
      if (mounted) setState(() {});
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('退出登录'),
        content: Text('确定要退出登录吗？'),
        actions: [
          FlatButton(
            child: Text('确定'),
            onPressed: () async {
              Navigator.of(c).pop();
              await removeToken();
              AuthState.instance.token = null;
              AuthState.instance.username = null;
              AuthState.instance.notifyAll();
            },
          ),
          FlatButton(
            child: Text('取消'),
            onPressed: () => Navigator.of(c).pop(),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!AuthState.instance.logined) {
      _data = null;
      return LoginFirstView();
    }

    return RefreshIndicator(
      onRefresh: _loadUser,
      child: PlaceholderText.from(
        isLoading: _loading,
        errorText: _error,
        isEmpty: _data == null,
        setting: PlaceholderSetting().toChinese(),
        onRefresh: () => _loadUser(),
        childBuilder: (c) => ListView(
          padding: EdgeInsets.zero,
          physics: AlwaysScrollableScrollPhysics(),
          children: [
            Stack(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0, 0.5, 1],
                      colors: [
                        Colors.blue[100],
                        Colors.orange[100],
                        Colors.purple[100],
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NetworkImageView(
                            url: _data.avatar,
                            height: 75,
                            width: 75,
                            fit: BoxFit.cover,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 8, left: 15, right: 15),
                            child: Text(
                              _data.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.subtitle1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top - 10,
                  right: 2.0 - 10,
                  child: ClipOval(
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        icon: Icon(Icons.settings, color: Colors.black54),
                        tooltip: '设置',
                        padding: EdgeInsets.all(25),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (c) => SettingPage(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                    child: Text(
                      '个人信息',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 10, right: 10, bottom: 4),
                    child: Divider(height: 1, thickness: 1),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                    child: Text(
                      '您的会员等级：${_data.className}',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                    child: Text(
                      '个人成长值：${_data.score} 点',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  SizedBox(height: 6),
                ],
              ),
            ),
            SizedBox(height: 12),
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                    child: Text(
                      '登录统计',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 10, right: 10, bottom: 4),
                    child: Divider(height: 1, thickness: 1),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                    child: Text(
                      '本次登录IP：${_data.loginIp}',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                    child: Text(
                      '上次登录IP：${_data.lastLoginIp}',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                    child: Text(
                      '注册时间：${_data.registerTime}',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                    child: Text(
                      '上次登录时间：${_data.lastLoginTime}',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  SizedBox(height: 6),
                ],
              ),
            ),
            Align(
              child: Container(
                padding: EdgeInsets.only(top: 10),
                child: OutlineButton(
                  child: Text('退出登录'),
                  onPressed: _logout,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
