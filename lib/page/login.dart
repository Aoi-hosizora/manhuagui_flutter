import 'package:flutter/material.dart';
import 'package:flutter_ahlib/util.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/service/natives/browser.dart';
import 'package:manhuagui_flutter/service/prefs/auth.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';
import 'package:manhuagui_flutter/service/state/auth.dart';

/// 登录
class LoginPage extends StatefulWidget {
  const LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _suggestionController = SuggestionsBoxController();
  var _passwordVisible = false;
  var _logining = false;
  var _rememberUsername = true;
  var _rememberPassword = false;
  var _usernamePasswordPairs = <Tuple2<String, String>>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var remTuple = await getRememberOptions();
      _rememberUsername = remTuple.item1;
      _rememberPassword = remTuple.item2;
      _usernamePasswordPairs = await getUsernamePasswordPairs();
      if (_usernamePasswordPairs.isNotEmpty) {
        var currentUser = _usernamePasswordPairs.first;
        _usernameController.text = currentUser.item1;
        _passwordController.text = currentUser.item2;
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState.validate()) {
      return;
    }

    _logining = true;
    if (mounted) setState(() {});
    var username = _usernameController.text.trim();
    var password = _passwordController.text.trim();

    var dio = DioManager.instance.dio;
    var client = RestClient(dio);
    ErrorMessage err;
    var result = await client.login(username: username, password: password).catchError((e) {
      err = wrapError(e);
    }).whenComplete(() {
      _logining = false;
      if (mounted) setState(() {});
    });
    if (err != null) {
      Fluttertoast.showToast(msg: err.text);
      return;
    }

    // state
    var token = result.data.token;
    Fluttertoast.showToast(msg: '$username 登录成功');
    AuthState.instance.token = token;
    AuthState.instance.username = username;
    AuthState.instance.notifyAll();

    // prefs
    setToken(token);
    await setRememberOptions(_rememberUsername, _rememberPassword);
    if (!_rememberUsername) {
      await removeUsernamePasswordPair(username);
    } else {
      if (_rememberPassword) {
        await addUsernamePasswordPair(username, password);
      } else {
        await addUsernamePasswordPair(username, '');
      }
    }

    // pop
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('账号登录'),
        centerTitle: true,
        toolbarHeight: 48,
        actions: [
          IconButton(
            icon: Text('注册'),
            onPressed: () => launchInBrowser(context: context, url: REGISTER_URL),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 10, bottom: 10),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 15, right: 15, top: 10),
                child: TypeAheadFormField(
                  textFieldConfiguration: TextFieldConfiguration(
                    autofocus: true,
                    controller: _usernameController,
                    enabled: !_logining,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 5),
                      labelText: '用户名',
                      hintText: '请输入用户名',
                      icon: Icon(Icons.person),
                    ),
                  ),
                  validator: (value) => value.trim().isEmpty ? '用户名不能为空' : null,
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
                        content: Text('确定要删除 $username 吗？'),
                        actions: [
                          FlatButton(
                            child: Text('删除'),
                            onPressed: () async {
                              Navigator.of(c).pop();
                              _usernamePasswordPairs.removeWhere((t) => t.item1 == username);
                              await removeUsernamePasswordPair(username);
                              if (mounted) setState(() {});
                            },
                          ),
                          FlatButton(
                            child: Text('取消'),
                            onPressed: () => Navigator.of(c).pop(),
                          ),
                        ],
                      ),
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
                  validator: (value) => value.trim().isEmpty ? '密码不能为空' : null,
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
                        onChanged: _logining ? null : (b) => mountedSetState(() => _rememberUsername = b),
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
                        onChanged: (_logining ?? !_rememberUsername) ? null : (b) => mountedSetState(() => _rememberPassword = b),
                      ),
                      Text(
                        '记住密码',
                        style: (_rememberUsername && !_logining) ? null : TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 2),
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
            ],
          ),
        ),
      ),
    );
  }
}
