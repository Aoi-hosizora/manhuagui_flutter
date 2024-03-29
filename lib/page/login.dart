import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/service/prefs/auth.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';

/// 登录页
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _suggestionController = SuggestionsBoxController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
    WidgetsBinding.instance?.addPostFrameCallback((_) => _checkLogined());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  var _rememberUsername = true;
  var _rememberPassword = false;
  var _usernamePasswordPairs = <Tuple2<String, String>>[];
  var _passwordVisible = false;
  var _logining = false;

  Future<void> _loadData() async {
    var remTuple = await AuthPrefs.getRememberOption();
    _rememberUsername = remTuple.item1;
    _rememberPassword = remTuple.item2;
    _usernamePasswordPairs = await AuthPrefs.getUsernamePasswordPairs();
    if (_usernamePasswordPairs.isNotEmpty) {
      var currentUser = _usernamePasswordPairs.first;
      _usernameController.text = currentUser.item1;
      _passwordController.text = currentUser.item2;
    }
    if (mounted) setState(() {});
  }

  Future<void> _checkLogined() async {
    if (!AuthManager.instance.logined) {
      await AuthManager.instance.check();
      if (!AuthManager.instance.logined) {
        return;
      }
    }
    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('登录状态'),
        content: Text('检查到当前正以 "${AuthManager.instance.username}" 用户身份登录，是否保持该登录状态？'),
        actions: [
          TextButton(child: Text('确定'), onPressed: () => Navigator.of(c).pop(true)),
          TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
        ],
      ),
    );
    if (ok != true) {
      return;
    }

    // 再次通知一次，并关闭登录页面
    AuthManager.instance.notify(logined: true);
    Navigator.of(context).pop();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    _logining = true;
    if (mounted) setState(() {});
    var username = _usernameController.text.trim();
    var password = _passwordController.text.trim();

    final client = RestClient(DioManager.instance.dio);
    String token;
    try {
      var result = await client.login(username: username, password: password);
      token = result.data.token;
    } catch (e, s) {
      Fluttertoast.showToast(msg: wrapError(e, s).text);
      return;
    } finally {
      _logining = false;
      if (mounted) setState(() {});
    }

    // set state
    Fluttertoast.showToast(msg: '$username 登录成功');
    AuthManager.instance.record(username: username, token: token);
    AuthManager.instance.notify(logined: true);

    // save to prefs
    await AuthPrefs.setToken(token);
    await AuthPrefs.setRememberOption(_rememberUsername, _rememberPassword);
    if (!_rememberUsername) {
      await AuthPrefs.removeUsernamePasswordPair(username);
    } else if (_rememberPassword) {
      await AuthPrefs.addUsernamePasswordPair(username, password);
    } else {
      await AuthPrefs.addUsernamePasswordPair(username, '');
    }
    await AuthPrefs.setLoginDateTime(DateTime.now());

    // pop this page
    WidgetsBinding.instance?.addPostFrameCallback((_) => Navigator.of(context).maybePop());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('账号登录'),
        leading: AppBarActionButton.leading(context: context),
        actions: [
          AppBarActionButton(
            icon: Text('注册'),
            onPressed: () => showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: Text('用户注册'),
                content: Text('是否跳转到 Manhuagui 官网来注册？'),
                actions: [
                  TextButton(
                    child: Text('跳转'),
                    onPressed: () => launchInBrowser(
                      context: context,
                      url: REGISTER_URL,
                    ),
                  ),
                  TextButton(
                    child: Text('取消'),
                    onPressed: () => Navigator.of(c).pop(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 10, bottom: 10),
        child: Form(
          key: _formKey,
          child: ListView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 15, right: 15, top: 10),
                child: TypeAheadFormField(
                  suggestionsBoxController: _suggestionController,
                  suggestionsCallback: (pattern) => _usernamePasswordPairs.map((e) => e.item1).where((t) => t.contains(pattern)),
                  onSuggestionSelected: (_) {},
                  itemBuilder: (_, String username) => InkWell(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Text(username),
                    ),
                    onTap: () {
                      _suggestionController.close();
                      var tuples = _usernamePasswordPairs.where((t) => t.item1 == username);
                      if (tuples.isNotEmpty) {
                        var tuple = tuples.first;
                        _usernameController.text = tuple.item1;
                        _passwordController.text = tuple.item2;
                      } else {
                        _usernameController.text = username;
                      }
                    },
                    onLongPress: () => showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text('删除登录记录'),
                        content: Text('是否删除 "$username" 的登录记录？'),
                        actions: [
                          TextButton(
                            child: Text('删除'),
                            onPressed: () async {
                              Navigator.of(c).pop();
                              _usernamePasswordPairs.removeWhere((t) => t.item1 == username);
                              await AuthPrefs.removeUsernamePasswordPair(username);
                              if (mounted) setState(() {});
                            },
                          ),
                          TextButton(
                            child: Text('取消'),
                            onPressed: () => Navigator.of(c).pop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  validator: (value) => value?.trim().isNotEmpty != true ? '用户名不能为空' : null,
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: _usernameController,
                    autofocus: true,
                    enabled: !_logining,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 5),
                      labelText: '用户名',
                      hintText: '请输入用户名',
                      icon: Icon(Icons.person),
                    ),
                  ),
                  hideOnLoading: true,
                  hideOnEmpty: true,
                  hideOnError: true,
                  hideSuggestionsOnKeyboardHide: true,
                  suggestionsBoxVerticalOffset: 5,
                  suggestionsBoxDecoration: SuggestionsBoxDecoration(
                    offsetX: 40,
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 70,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 15, right: 15, top: 10),
                child: TextFormField(
                  controller: _passwordController,
                  enabled: !_logining,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                    labelText: '密码',
                    hintText: '请输入密码',
                    icon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Theme.of(context).hintColor,
                      ),
                      onPressed: () {
                        _passwordVisible = !_passwordVisible;
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                  validator: (value) => value?.trim().isNotEmpty != true ? '密码不能为空' : null,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 7, right: 7, top: 12),
                child: InkWell(
                  onTap: _logining ? null : () => mountedSetState(() => _rememberUsername = !_rememberUsername),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _rememberUsername,
                        onChanged: _logining ? null : (b) => mountedSetState(() => _rememberUsername = b ?? true),
                      ),
                      Text(
                        '记住账号',
                        style: !_logining ? null : TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 7, right: 7, top: 0),
                child: InkWell(
                  onTap: (_logining || !_rememberUsername) ? null : () => mountedSetState(() => _rememberPassword = !_rememberPassword),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _rememberUsername && _rememberPassword,
                        onChanged: (_logining) ? null : (b) => mountedSetState(() => _rememberPassword = b ?? false),
                      ),
                      Text(
                        '记住密码',
                        style: (_rememberUsername && !_logining) ? null : TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: !_logining
                      ? SizedBox(
                          height: 42,
                          width: 120,
                          child: ElevatedButton(
                            child: Text('登录'),
                            onPressed: _login,
                          ),
                        )
                      : SizedBox(
                          height: 42,
                          width: 42,
                          child: CircularProgressIndicator(),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
