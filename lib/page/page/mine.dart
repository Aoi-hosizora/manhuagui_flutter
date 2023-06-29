import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/user.dart';
import 'package:manhuagui_flutter/page/dlg/setting_ui_dialog.dart';
import 'package:manhuagui_flutter/page/download.dart';
import 'package:manhuagui_flutter/page/image_viewer.dart';
import 'package:manhuagui_flutter/page/later_manga.dart';
import 'package:manhuagui_flutter/page/login.dart';
import 'package:manhuagui_flutter/page/message.dart';
import 'package:manhuagui_flutter/page/sep_favorite.dart';
import 'package:manhuagui_flutter/page/sep_history.dart';
import 'package:manhuagui_flutter/page/sep_shelf.dart';
import 'package:manhuagui_flutter/page/setting.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
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
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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
  late final _controller = ScrollController()..addListener(() => mountedSetState(() {}));
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandlers.add(AuthManager.instance.listen((ev) => _updateByAuthEvent(ev))); // !!! with checking AuthManager.instance.authData
      await AuthManager.instance.check();
    });
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _controller.dispose();
    super.dispose();
  }

  var _authChecking = !AuthManager.instance.logined; // initialize to true when not logined
  var _authData = AuthManager.instance.authData;
  var _authError = '';

  void _updateByAuthEvent(AuthChangedEvent event) {
    if (_authChecking) {
      _authChecking = false;
      if (mounted) setState(() {});
    }
    if (AuthManager.instance.authData.equals(_authData)) {
      return;
    }

    _authData = AuthManager.instance.authData;
    _authError = event.error?.text ?? '';
    if (_authError.isNotEmpty) {
      return;
    }

    if (!AuthManager.instance.logined) {
      _data = null;
      _error = '';
    } else {
      // 登录状态变更，刷新用户信息
      WidgetsBinding.instance?.addPostFrameCallback((_) => _refreshIndicatorKey.currentState?.show());
    }
    if (mounted) setState(() {});
  }

  var _loading = true; // initialize to true
  User? _data;
  DateTime? _currLoginDateTime;
  var _error = '';
  var _checkining = false;

  Future<void> _loadData() async {
    _loading = true;
    if (mounted) setState(() {});

    if (!AuthManager.instance.logined) {
      _data = null;
      _error = '';
      _loading = false;
      if (mounted) setState(() {});
      return;
    }

    final client = RestClient(DioManager.instance.dio);
    try {
      var result = await client.getUserInfo(token: AuthManager.instance.token);
      _data = null;
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(kFlashListDuration);
      _data = result.data;
      _currLoginDateTime = await AuthPrefs.getLoginDateTime();
    } catch (e, s) {
      _data = null;
      var we = wrapError(e, s);
      _error = we.text;

      // redirect to login page when 401
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
    if (!AuthManager.instance.logined) {
      Fluttertoast.showToast(msg: '用户未登录');
      return;
    }
    var password = await AuthPrefs.getUserPassword(AuthManager.instance.username);
    if (password == null || password.isEmpty) {
      await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('登录签到'),
          content: Text('只有在登录漫画柜时勾选 "保存密码" 才能一键登录签到。'),
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

    _checkining = true;
    if (mounted) setState(() {});

    final client = RestClient(DioManager.instance.dio);
    try {
      var username = AuthManager.instance.username;
      var result = await client.login(username: username, password: password);
      var token = result.data.token;

      // record login state and update token
      AuthManager.instance.record(username: username, token: token);
      AuthManager.instance.notify(logined: true);
      await AuthPrefs.setToken(token);

      // update login time and reload user data
      await AuthPrefs.setLoginDateTime(DateTime.now());
      await _loadData();
      if (_data != null) {
        Fluttertoast.showToast(msg: '登录签到成功，已累计登录${_data!.cumulativeDayCount}天');
      }
    } catch (e, s) {
      var error = wrapError(e, s).text;
      Fluttertoast.showToast(msg: '登录签到失败，$error');
    } finally {
      _checkining = false;
      if (mounted) setState(() {});
    }
  }

  void _showAutoCheckinPopupMenu() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('自动登录签到'),
        content: Text(
          !AppSetting.instance.ui.enableAutoCheckin //
              ? '当前自动登录签到功能尚未开启，是否开启该功能？\n\n注：只有在登录漫画柜时勾选 "保存密码" 才能自动登录签到。'
              : '当前已经开启自动登录签到功能，是否关闭该功能？',
        ),
        actions: [
          TextButton(
            child: Text(!AppSetting.instance.ui.enableAutoCheckin ? '开启' : '关闭'),
            onPressed: () async {
              Navigator.of(c).pop();
              await updateUiSettingEnableAutoCheckin(!AppSetting.instance.ui.enableAutoCheckin);
              Fluttertoast.showToast(msg: '自动登录签到功能已' + (AppSetting.instance.ui.enableAutoCheckin ? '开启' : '关闭'));
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
                text: Text(text, style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 16)),
                space: 14,
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

  Widget _buildInfoLines({required IconData icon, required String title, required List<String> lines, String? hint}) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: IconText(
                  icon: Icon(icon, color: Colors.black54),
                  text: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  space: 14,
                ),
              ),
              if (hint != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16 - 6, vertical: 10 - 6),
                  child: HelpIconView(
                    title: title,
                    hint: hint,
                    tooltip: '提示',
                    rectangle: false,
                    padding: EdgeInsets.all(6),
                    iconSize: 22,
                    iconColor: Colors.black54,
                  ),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
            child: _buildDivider(thickness: 1, indent: 0),
          ),
          for (var line in lines)
            Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 10),
              child: Text(
                line,
                style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 16),
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

    Widget _buildScaffold({required Widget body, Text? title}) {
      final showBackground = _controller.hasClients && _controller.offset >= 180 - Theme.of(context).appBarTheme.toolbarHeight!;
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(Theme.of(context).appBarTheme.toolbarHeight!),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 150),
            color: showBackground ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withOpacity(0),
            child: AppBar(
              title: showBackground && title != null ? title : null,
              automaticallyImplyLeading: false,
              actions: [
                AppBarActionButton(
                  icon: Icon(Icons.notifications, color: showBackground ? null : Colors.black54),
                  tooltip: '应用消息',
                  onPressed: () => Navigator.of(context).push(
                    CustomPageRoute(
                      context: context,
                      builder: (c) => MessagePage(),
                    ),
                  ),
                ),
                AppBarActionButton(
                  icon: Icon(Icons.settings, color: showBackground ? null : Colors.black54),
                  tooltip: '应用设置',
                  onPressed: () => Navigator.of(context).push(
                    CustomPageRoute(
                      context: context,
                      builder: (c) => SettingPage(),
                    ),
                  ),
                ),
              ],
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
        ),
        extendBodyBehindAppBar: true,
        body: PageView(
          physics: DefaultScrollPhysics.of(context),
          children: [body],
        ),
      );
    }

    if (_authChecking || _authError.isNotEmpty || !AuthManager.instance.logined) {
      _data = null;
      _error = '';
      return _buildScaffold(
        body: LoginFirstView(
          checking: _authChecking,
          error: _authError,
          onErrorRetry: () async {
            _authChecking = true;
            _authError = '';
            if (mounted) setState(() {});
            await AuthManager.instance.check();
          },
        ),
      );
    }

    return _buildScaffold(
      title: _data == null ? null : Text(_data!.username),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadData,
        child: PlaceholderText.from(
          isLoading: _loading,
          errorText: _error,
          isEmpty: _data == null,
          setting: PlaceholderSetting().copyWithChinese(),
          onRefresh: () => _loadData(),
          childBuilder: (c) => ListView(
            controller: _controller,
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
                            quality: FilterQuality.high,
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
                  action3: ActionItem.simple('登录签到', !_checkining ? Icons.event_available : null, () => _checkin(), longPress: _showAutoCheckinPopupMenu, enable: !_checkining),
                  action4: ActionItem.simple('退出登录', Icons.logout, () => _logout(sure: false)),
                ),
              ),
              SizedBox(height: 12),
              _buildActionLine(
                text: '我的书架',
                icon: MdiIcons.bookshelf,
                action: !AppSetting.instance.ui.alwaysOpenNewListPage //
                    ? () => EventBusManager.instance.fire(ToShelfRequestedEvent())
                    : () => Navigator.of(context).push(CustomPageRoute(context: context, builder: (c) => SepShelfPage())),
              ),
              _buildDivider(),
              _buildActionLine(
                text: '本地收藏',
                icon: MdiIcons.bookmarkBoxMultipleOutline,
                action: !AppSetting.instance.ui.alwaysOpenNewListPage //
                    ? () => EventBusManager.instance.fire(ToFavoriteRequestedEvent())
                    : () => Navigator.of(context).push(CustomPageRoute(context: context, builder: (c) => SepFavoritePage())),
              ),
              _buildDivider(),
              _buildActionLine(
                text: '稍后阅读',
                icon: MdiIcons.bookClockOutline,
                action: () => Navigator.of(context).push(CustomPageRoute(context: context, builder: (c) => LaterMangaPage())),
              ),
              _buildDivider(),
              _buildActionLine(
                text: '阅读历史',
                icon: Icons.history,
                action: !AppSetting.instance.ui.alwaysOpenNewListPage //
                    ? () => EventBusManager.instance.fire(ToHistoryRequestedEvent())
                    : () => Navigator.of(context).push(CustomPageRoute(context: context, builder: (c) => SepHistoryPage())),
              ),
              _buildDivider(),
              _buildActionLine(
                text: '下载列表',
                icon: Icons.download,
                action: () => Navigator.of(context).push(CustomPageRoute(context: context, builder: (c) => DownloadPage())),
              ),
              SizedBox(height: 12),
              _buildInfoLines(
                icon: Icons.account_box,
                title: '个人信息',
                lines: [
                  '会员等级：${_data!.className}',
                  '个人成长值 / 账户积分：${_data!.score} 点',
                  '累计发送 ${_data!.totalCommentCount} 条评论，当前 ${_data!.unreadMessageCount} 条消息未读',
                  '注册时间：${_data!.formattedRegisterTime}', // XXXX-XX-XX XX:XX:XX
                ],
              ),
              SizedBox(height: 12),
              _buildInfoLines(
                icon: Icons.poll,
                title: '登录统计',
                hint: '提示："当前登录时间"仅记录在移动端本地，跨设备不同步。\n\n提示："登录IP"并非指本设备的IP地址，而是指本第三方应用使用的服务器的IP地址。',
                lines: [
                  '当前登录时间：${_data!.formattedCurrLoginTimeWithDuration(_currLoginDateTime)}', // XXXX-XX-XX XX:XX:XX (X天前)
                  '上回登录时间：${_data!.formattedLastLoginTimeWithDuration}', // XXXX-XX-XX XX:XX:XX (X天前)
                  '累计登录时长：${_data!.cumulativeDayCount}天，' + (!_data!.isTodayLogined(_currLoginDateTime) ? '今天未登录签到' : '今天已登录签到'),
                  '当前登录IP：${_data!.loginIp}',
                  '上回登录IP：${_data!.lastLoginIp}',
                ],
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
