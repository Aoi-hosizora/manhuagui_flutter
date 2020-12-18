import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/service/state/auth.dart';

/// 登录
class LoginPage extends StatefulWidget {
  const LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('登录'),
        centerTitle: true,
        toolbarHeight: 48,
      ),
      body: Center(
        child: OutlineButton(
          child: Text('test'),
          onPressed: () {
            AuthState.instance.token = '123';
            AuthState.instance.notifyAll();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
