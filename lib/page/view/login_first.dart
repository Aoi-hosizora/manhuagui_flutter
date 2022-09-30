import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/page/login.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';

class LoginFirstView extends StatefulWidget {
  const LoginFirstView({Key? key}) : super(key: key);

  @override
  _LoginFirstViewState createState() => _LoginFirstViewState();
}

class _LoginFirstViewState extends State<LoginFirstView> {
  @override
  void initState() {
    super.initState();
    AuthManager.instance.check();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_open,
            size: 50,
            color: Colors.grey,
          ),
          SizedBox(height: 10),
          Text(
            '未登录，请先登录',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 10),
          OutlinedButton(
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
