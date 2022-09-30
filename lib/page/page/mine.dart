import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/user.dart';
import 'package:manhuagui_flutter/page/setting.dart';
import 'package:manhuagui_flutter/page/view/login_first.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/prefs/auth.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';

/// 我的
class MineSubPage extends StatefulWidget {
  const MineSubPage({
    Key? key,
    this.action,
  }) : super(key: key);

  final ActionController? action;

  @override
  _MineSubPageState createState() => _MineSubPageState();
}

class _MineSubPageState extends State<MineSubPage> with AutomaticKeepAliveClientMixin {
  bool _loginChecking = true;
  VoidCallback? _cancelHandler;

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() {});
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _loginChecking = true;
      _cancelHandler = AuthManager.instance.listen(() {
        _loginChecking = false;
        if (mounted) setState(() {});
        if (AuthManager.instance.logined) {
          _loadUser();
        }
      });
      AuthManager.instance.check();
    });
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    _cancelHandler?.call();
    super.dispose();
  }

  bool _loading = false;
  User? _data;
  var _error = '';

  Future<void> _loadUser() async {
    _loading = true;
    if (mounted) setState(() {});

    final client = RestClient(DioManager.instance.dio);
    try {
      var result = await client.getUserInfo(token: AuthManager.instance.token);
      _data = null;
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _data = result.data;
    } catch (e, s) {
      _data = null;
      var we = wrapError(e, s);
      _error = we.text;
      if (we.response?.statusCode == 401) {
        _logout(sure: true);
      }
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _logout({bool sure = false}) async {
    if (sure) {
      await AuthPrefs.setToken('');
      AuthManager.instance.logout();
      AuthManager.instance.notify();
      return;
    }

    return showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('退出登录'),
        content: Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            child: Text('确定'),
            onPressed: () async {
              await AuthPrefs.setToken('');
              AuthManager.instance.logout();
              AuthManager.instance.notify();
              Navigator.of(c).pop();
            },
          ),
          TextButton(
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
    if (_loginChecking || !AuthManager.instance.logined) {
      _data = null;
      return Scaffold(
        body: LoginFirstView(
          checking: _loginChecking,
          showSettingButton: true,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUser,
      child: PlaceholderText.from(
        isLoading: _loading,
        errorText: _error,
        isEmpty: _data == null,
        setting: PlaceholderSetting().copyWithChinese(),
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
                      stops: const [0, 0.5, 1],
                      colors: [
                        Colors.blue[100]!,
                        Colors.orange[100]!,
                        Colors.purple[100]!,
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
                            url: _data!.avatar,
                            height: 75,
                            width: 75,
                            fit: BoxFit.cover,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 8, left: 15, right: 15),
                            child: Text(
                              _data!.username,
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
                      '您的会员等级：${_data!.className}',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                    child: Text(
                      '个人成长值：${_data!.score} 点',
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
                      '本次登录IP：${_data!.loginIp}',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                    child: Text(
                      '上次登录IP：${_data!.lastLoginIp}',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                    child: Text(
                      '注册时间：${_data!.registerTime}',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                    child: Text(
                      '上次登录时间：${_data!.lastLoginTime}',
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
                child: OutlinedButton(
                  child: Text('退出登录'),
                  onPressed: () => _logout(sure: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
