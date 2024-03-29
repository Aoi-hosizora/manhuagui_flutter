import 'dart:async';

import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/prefs/auth.dart';
import 'package:synchronized/synchronized.dart';

class AuthData {
  const AuthData({
    required this.username,
    required this.token,
  });

  final String username;
  final String token;

  bool get logined => token.isNotEmpty;

  bool equals(AuthData? o) {
    return o != null && username == o.username && token == o.token;
  }
}

class AuthManager {
  AuthManager._();

  static AuthManager? _instance;

  static AuthManager get instance {
    _instance ??= AuthManager._();
    return _instance!;
  }

  var _data = AuthData(username: '', token: ''); // global auth data
  var _loading = false; // global loading flag

  AuthData get authData => _data;

  String get username => _data.username;

  String get token => _data.token;

  bool get logined => _data.logined;

  bool get loading => _loading;

  void record({required String username, required String token}) {
    _data = AuthData(username: username, token: token);
  }

  void Function() listen(void Function(AuthChangedEvent) onData) {
    return EventBusManager.instance.listen<AuthChangedEvent>(onData);
  }

  void Function() listenOnlyWhen(Tuple1<AuthData> authData /* mutable */, void Function(AuthChangedEvent) onData) {
    return EventBusManager.instance.listen<AuthChangedEvent>((ev) {
      if (!AuthManager.instance.authData.equals(authData.item)) {
        authData.item = AuthManager.instance.authData;
        onData.call(ev);
      }
    });
  }

  AuthChangedEvent notify({required bool logined, ErrorMessage? error}) {
    final ev = AuthChangedEvent(logined: logined, error: error);
    EventBusManager.instance.fire(ev);
    return ev;
  }

  final _lock = Lock();

  Future<AuthChangedEvent> check() async {
    return _lock.synchronized<AuthChangedEvent>(() async {
      // check if currently logined
      if (AuthManager.instance.logined) {
        return AuthManager.instance.notify(logined: true);
      }

      // no token stored in prefs
      var token = await AuthPrefs.getToken();
      if (token.isEmpty) {
        return AuthManager.instance.notify(logined: false);
      }

      // check stored token
      _loading = true;
      final client = RestClient(DioManager.instance.dio);
      try {
        var r = await client.checkUserLogin(token: token);
        AuthManager.instance.record(username: r.data.username, token: token);
        return AuthManager.instance.notify(logined: true);
      } catch (e, s) {
        var we = wrapError(e, s);
        if (we.type == ErrorType.resultError && we.response!.statusCode == 401) {
          await AuthPrefs.setToken('');
        }
        return AuthManager.instance.notify(logined: false, error: we);
      } finally {
        _loading = false;
      }
    });
  }
}

class AuthChangedEvent {
  const AuthChangedEvent({required this.logined, this.error});

  final bool logined;
  final ErrorMessage? error;
}
