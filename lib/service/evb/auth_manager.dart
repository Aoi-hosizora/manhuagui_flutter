import 'dart:async';

import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/prefs/auth.dart';
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

  void record({required String username, required String token}) {
    _username = username;
    _token = token;
  }

  void Function() listen(Function() onData) {
    return EventBusManager.instance.listen<AuthChangedEvent>((_) {
      onData.call();
    });
  }

  void notify() {
    EventBusManager.instance.fire(AuthChangedEvent());
  }

  final _lock = Lock();

  Future<bool> check() async {
    return _lock.synchronized<bool>(() async {
      // logined
      if (AuthManager.instance.logined) {
        AuthManager.instance.notify();
        return true;
      }

      // no token stored in prefs
      var token = await AuthPrefs.getToken();
      if (token.isEmpty) {
        AuthManager.instance.notify(); // need ???
        return false;
      }

      // check stored token
      final client = RestClient(DioManager.instance.dio);
      try {
        var r = await client.checkUserLogin(token: token);
        AuthManager.instance.record(username: r.data.username, token: token);
        AuthManager.instance.notify();
        return true;
      } catch (e, s) {
        var we = wrapError(e, s);
        print(we.text);
        if (we.type == ErrorType.resultError) {
          await AuthPrefs.setToken('');
        }
        AuthManager.instance.notify();
        return false;
      }
    });
  }
}

class AuthChangedEvent {
  const AuthChangedEvent();
}
