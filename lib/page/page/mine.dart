import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/user.dart';
import 'package:manhuagui_flutter/page/download.dart';
import 'package:manhuagui_flutter/page/image_viewer.dart';
import 'package:manhuagui_flutter/page/login.dart';
import 'package:manhuagui_flutter/page/message.dart';
import 'package:manhuagui_flutter/page/setting.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/login_first.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
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
  AuthData? _oldAuthData;

  var _loginChecking = true;
  var _loginCheckError = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandler = AuthManager.instance.listen(() => _oldAuthData, (ev) {
        _oldAuthData = AuthManager.instance.authData;
        _loginChecking = false;
        _loginCheckError = ev.error?.text ?? '';
        if (mounted) setState(() {});
        if (AuthManager.instance.logined) {
          WidgetsBinding.instance?.addPostFrameCallback((_) => _refreshIndicatorKey.currentState?.show());
        }
      });
      _loginChecking = true;
      await AuthManager.instance.check();
    });
  }

  @override
  void dispose() {
    _cancelHandler?.call();
    super.dispose();
  }

  var _loading = false;
  User? _data;
  var _error = '';
  var _checkining = false;

  Future<void> _loadUser() async {
    _loading = true;
    if (mounted) setState(() {});

    final client = RestClient(DioManager.instance.dio);
    try {
      var result = await client.getUserInfo(token: AuthManager.instance.token);
      _data = null;
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(kFlashListDuration);
      _data = result.data;
    } catch (e, s) {
      _data = null;
      var we = wrapError(e, s);
      _error = we.text;
      if (we.response?.statusCode == 401) {
        Fluttertoast.showToast(msg: '登录失效，请重新登录');
        Navigator.of(context).push(
          CustomPageRoute(
            context: context,
            builder: (c) => LoginPage(),
          ),
        );
      }
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _checkin() async {
    var password = await AuthPrefs.getUserPassword(AuthManager.instance.username);
    if (password == null) {
      await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('登录签到'),
          content: Text('只有在登录漫画柜时保存密码才能一键登录签到。'),
          actions: [
            TextButton(
              child: Text('确定'),
              onPressed: () => Navigator.of(c).pop(),
            ),
          ],
        ),
      );
      return;
    }

    final client = RestClient(DioManager.instance.dio);
    _checkining = true;
    if (mounted) setState(() {});
    try {
      await client.login(username: AuthManager.instance.username, password: password); // ignore token
    } catch (e, s) {
      Fluttertoast.showToast(msg: '登录签到失败，${wrapError(e, s).text}');
      return;
    } finally {
      _data = null;
      _checkining = false;
      if (mounted) setState(() {});
    }

    await _loadUser();
    if (_data != null) {
      Fluttertoast.showToast(msg: '登录签到成功，已累计登录${_data!.cumulativeDayCount}天');
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

  Widget _buildActionLine({required IconData icon, required String text, required void Function() action}) {
    return Material(
      color: Colors.white,
      child: InkWell(
        child: Padding(
          padding: EdgeInsets.only(left: 16, right: 12, top: 12, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconText(
                icon: Icon(icon, color: Colors.black54),
                text: Text(text, style: Theme.of(context).textTheme.bodyText1?.copyWith(fontSize: 16)),
                space: 16,
              ),
              Icon(Icons.chevron_right, color: Colors.black54),
            ],
          ),
        ),
        onTap: action,
      ),
    );
  }

  Widget _buildDivider({double thickness = 0.8, double indent = 10}) {
    return Divider(height: 0, thickness: thickness, indent: indent, endIndent: indent);
  }

  Widget _buildInfoLines({required String title, required List<String> lines}) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 15, right: 15, top: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: _buildDivider(thickness: 1, indent: 0),
          ),
          for (var line in lines)
            Padding(
              padding: EdgeInsets.only(left: 15, right: 15, bottom: 8),
              child: Text(
                line,
                style: Theme.of(context).textTheme.subtitle1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
    Widget _buildScaffold({required Widget body}) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            AppBarActionButton(
              icon: Icon(Icons.notifications, color: Colors.black54),
              tooltip: '历史消息',
              onPressed: () => Navigator.of(context).push(
                CustomPageRoute(
                  context: context,
                  builder: (c) => MessagePage(),
                ),
              ),
            ),
            AppBarActionButton(
              icon: Icon(Icons.settings, color: Colors.black54),
              tooltip: '应用设置',
              onPressed: () => Navigator.of(context).push(
                CustomPageRoute(
                  context: context,
                  builder: (c) => SettingPage(),
                ),
              ),
            ),
          ],
          foregroundColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        extendBodyBehindAppBar: true,
        body: PageView(
          physics: DefaultScrollPhysics.of(context),
          children: [body],
        ),
      );
    }

    if (_loginChecking || _loginCheckError.isNotEmpty || !AuthManager.instance.logined) {
      _data = null;
      _error = '';
      return _buildScaffold(
        body: LoginFirstView(
          checking: _loginChecking,
          error: _loginCheckError,
          onErrorRetry: () async {
            _loginChecking = true;
            _loginCheckError = '';
            if (mounted) setState(() {});
            await AuthManager.instance.check();
          },
        ),
      );
    }

    return _buildScaffold(
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
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
                        FullRippleWidget(
                          child: NetworkImageView(
                            url: _data!.avatar,
                            height: 75,
                            width: 75,
                          ),
                          onTap: () => Navigator.of(context).push(
                            CustomPageRoute(
                              context: context,
                              builder: (c) => ImageViewerPage(
                                url: _data!.avatar,
                                title: '我的头像',
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 8, left: 15, right: 15),
                          child: Text(
                            _data!.username,
                            style: Theme.of(context).textTheme.headline6?.copyWith(fontWeight: FontWeight.normal),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                color: Colors.white,
                child: ActionRowView.four(
                  action1: ActionItem.simple('用户中心', Icons.account_circle, () => launchInBrowser(context: context, url: USER_CENTER_URL)),
                  action2: ActionItem.simple('站内信息', Icons.message, () => launchInBrowser(context: context, url: MESSAGE_URL)),
                  action3: ActionItem.simple('登录签到', Icons.event_available, () => _checkin(), enable: !_checkining),
                  action4: ActionItem.simple('退出登录', Icons.logout, () => _logout(sure: false)),
                ),
              ),
              SizedBox(height: 12),
              _buildActionLine(text: '我的书架', icon: Icons.star_outlined, action: () => EventBusManager.instance.fire(ToShelfRequestedEvent())),
              _buildDivider(),
              _buildActionLine(text: '阅读历史', icon: Icons.history, action: () => EventBusManager.instance.fire(ToHistoryRequestedEvent())),
              _buildDivider(),
              _buildActionLine(text: '下载列表', icon: Icons.download, action: () => Navigator.of(context).push(CustomPageRoute(context: context, builder: (c) => DownloadPage()))),
              SizedBox(height: 12),
              _buildInfoLines(
                title: '个人信息',
                lines: [
                  '会员等级：${_data!.className}',
                  '个人成长值 / 账户积分：${_data!.score} 点',
                  '累计发送 ${_data!.totalCommentCount} 条评论，当前 ${_data!.unreadMessageCount} 条消息未读',
                  '注册时间：${_data!.registerTime}',
                ],
              ),
              SizedBox(height: 12),
              _buildInfoLines(
                title: '登录统计',
                lines: [
                  '本次登录IP (非本地)：${_data!.loginIp}',
                  '上次登录IP (非本地)：${_data!.lastLoginIp}',
                  '上次登录时间：${_data!.lastLoginTime}',
                  '累计登录天数：${_data!.cumulativeDayCount} 天',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
