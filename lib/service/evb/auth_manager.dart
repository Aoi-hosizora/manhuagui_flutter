import 'dart:async';

import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/prefs/auth.dart' as prefs;
import 'package:synchronized/synchronized.dart';

class AuthManager {
  AuthManager._();

  static AuthManager? _instance;

  static AuthManager get instance {
    _instance ??= AuthManager._();
    return _instance!;
  }

  String _username = ''; // global username
  String _token = ''; // global token

  String get username => _username;

  String get token => _token;

  bool get logined => _token.isNotEmpty;

  void login({required String username, required String token}) {
    _username = username;
    _token = token;
  }

  void logout() {
    _username = '';
    _token = '';
  }

  StreamSubscription<AuthChangedEvent> listen(Function() onData) {
    return EventBusManager.instance.on<AuthChangedEvent>().listen((_) {
      onData.call();
    });
  }

  void notify() {
    EventBusManager.instance.fire(AuthChangedEvent());
  }

  final _lock = Lock();

  Future<void> check() async {
    return _lock.synchronized(() async {
      // logined or no token stored
      if (AuthManager.instance.logined) {
        return;
      }
      var token = await prefs.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      // check token
      var client = RestClient(DioManager.instance.dio);
      try {
        var r = await client.checkUserLogin(token: token);
        AuthManager.instance.login(username: r.data.username, token: token);
        AuthManager.instance.notify();
      } catch (e, s) {
        var we = wrapError(e, s);
        print(we.text);
        if (we.type == ErrorType.resultError) {
          await prefs.removeToken();
        }
      }
    });
  }
}

class AuthChangedEvent {
  const AuthChangedEvent();
}
