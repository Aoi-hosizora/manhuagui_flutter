import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/page/login.dart';
import 'package:manhuagui_flutter/service/prefs/auth.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';
import 'package:manhuagui_flutter/service/state/auth.dart';
import 'package:synchronized/synchronized.dart';

var _lock = Lock();

class LoginFirstView extends StatefulWidget {
  const LoginFirstView({Key key}) : super(key: key);

  @override
  _LoginFirstViewState createState() => _LoginFirstViewState();
}

class _LoginFirstViewState extends State<LoginFirstView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lock.synchronized(() async {
        if (AuthState.instance.logined) {
          return;
        }
        var token = await getToken();
        if (token?.isNotEmpty != true || AuthState.instance.token == token) {
          return;
        }

        // check token
        var dio = DioManager.instance.dio;
        var client = RestClient(dio);
        dynamic err;
        var r = await client.checkUserLogin(token: token).catchError((e) => err = e);
        if (err != null) {
          await removeToken();
          return;
        }

        // notify
        AuthState.instance.token = token;
        AuthState.instance.username = r.data.username;
        AuthState.instance.notifyAll();
      });
    });
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
