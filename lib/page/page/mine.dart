import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/user.dart';
import 'package:manhuagui_flutter/page/login.dart';
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
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  VoidCallback? _cancelHandler;

  var _loginChecking = true;
  var _loginCheckError = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandler = AuthManager.instance.listen((ev) {
        _loginChecking = false;
        _loginCheckError = ev.error?.text ?? '';
        if (mounted) setState(() {});
        if (AuthManager.instance.logined) {
          WidgetsBinding.instance?.addPostFrameCallback((_) => _refreshIndicatorKey.currentState?.show());
        }
      });
      _loginChecking = true;
      await AuthManager.instance.check();
      // _loginChecking = false;
      // if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
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
        Fluttertoast.showToast(msg: '登录失效，请重新登录');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (c) => LoginPage(),
          ),
        );
      }
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _logout({bool sure = false}) async {
    if (sure) {
      await AuthPrefs.setToken('');
      AuthManager.instance.record(username: '', token: '');
      AuthManager.instance.notify(logined: false);
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
              Navigator.of(c).pop();
              await _logout(sure: true);
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
    var positionedTransparentAppBar = Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          AppBarActionButton(
            icon: Icon(Icons.settings, color: Colors.black54),
            tooltip: '设置',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (c) => SettingPage(),
              ),
            ),
          ),
        ],
        foregroundColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );

    if (_loginChecking || _loginCheckError.isNotEmpty || !AuthManager.instance.logined) {
      _data = null;
      _error = '';
      return Stack(
        children: [
          Positioned.fill(
            child: LoginFirstView(
              checking: _loginChecking,
              error: _loginCheckError,
              onErrorRetry: () async {
                _loginChecking = true;
                _loginCheckError = '';
                if (mounted) setState(() {});
                await AuthManager.instance.check();
                // _loginChecking = false;
                // if (mounted) setState(() {});
              },
            ),
          ),
          positionedTransparentAppBar,
        ],
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: () => _loadUser(),
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
                  Container(
                    height: MediaQuery.of(context).padding.top + 180,
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
                  Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          child: Text(
                            '个人信息',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Divider(height: 0, thickness: 1),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            '您的会员等级：${_data!.className}',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            '个人成长值：${_data!.score} 点',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ),
                        SizedBox(height: 8),
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
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          child: Text(
                            '登录统计',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Divider(height: 0, thickness: 1),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            '本次登录IP：${_data!.loginIp}',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            '上次登录IP：${_data!.lastLoginIp}',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            '注册时间：${_data!.registerTime}',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            '上次登录时间：${_data!.lastLoginTime}',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ),
                        SizedBox(height: 8),
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
          ),
        ),
        positionedTransparentAppBar,
      ],
    );
  }
}
