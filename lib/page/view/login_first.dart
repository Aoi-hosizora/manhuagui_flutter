import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/page/login.dart';
import 'package:manhuagui_flutter/service/state/notifiable.dart';

class LoginFirstView extends StatefulWidget {
  const LoginFirstView({Key key}) : super(key: key);

  @override
  _LoginFirstViewState createState() => _LoginFirstViewState();
}

class _LoginFirstViewState extends State<LoginFirstView> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '请先登录',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 20),
          OutlineButton(
            child: Text('登录'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (c) => LoginPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
