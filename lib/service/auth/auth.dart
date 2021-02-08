import 'package:manhuagui_flutter/service/prefs/auth.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';
import 'package:manhuagui_flutter/service/state/auth.dart';
import 'package:synchronized/synchronized.dart';

// mutex lock for checkAuth
var _lock = Lock();

Future<void> checkAuth() async {
  return _lock.synchronized(() async {
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
}
