import 'dart:convert';

import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';

class AuthPrefs {
  AuthPrefs._();

  static const _tokenKey = 'TOKEN'; // string
  static const _rememberUsernameKey = 'REMEMBER_USERNAME'; // bool
  static const _rememberPasswordKey = 'REMEMBER_PASSWORD'; // bool
  static const _usernamePasswordPairsKey = 'USERNAME_PASSWORD_PAIRS'; // list

  static Future<String> getToken() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    return prefs.getString(_tokenKey) ?? '';
  }

  static Future<void> setToken(String token) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    await prefs.setString(_tokenKey, token);
  }

  static Future<Tuple2<bool, bool>> getRememberOption() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var rememberUsername = prefs.getBool(_rememberUsernameKey) ?? true;
    var rememberPassword =  prefs.getBool(_rememberPasswordKey) ?? false;
    return Tuple2(rememberUsername, rememberPassword);
  }

  static Future<void> setRememberOption(bool rememberUsername, bool rememberPassword) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    await prefs.setBool(_rememberUsernameKey, rememberUsername);
    await prefs.setBool(_rememberPasswordKey, rememberPassword);
  }

  static Future<List<Tuple2<String, String>>> getUsernamePasswordPairs() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var pairs = prefs.getStringList(_usernamePasswordPairsKey) ?? []; // 新 > 旧
    var out = <Tuple2<String, String>>[];
    for (var jsn in pairs) {
      var m = json.decode(jsn) as Map<String, dynamic>;
      var username = m['username'];
      var password = m['password'];
      if (username == null || password == null) {
        continue;
      }
      out.add(Tuple2(username, password));
    }
    return out;
  }

  static Future<void> addUsernamePasswordPair(String username, String password) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var list = await getUsernamePasswordPairs();
    list.removeWhere((t) => t.item1 == username);
    list.insert(0, Tuple2(username, password)); // 新 > 旧
    var pairs = <String>[];
    for (var pair in list) {
      var m = <String, dynamic>{'username': pair.item1, 'password': pair.item2};
      var jsn = json.encode(m);
      pairs.add(jsn);
    }
    await prefs.setStringList(_usernamePasswordPairsKey, pairs);
  }

  static Future<void> removeUsernamePasswordPair(String username) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var list = await getUsernamePasswordPairs();
    list.removeWhere((t) => t.item1 == username);
    var pairs = <String>[];
    for (var pair in list) {
      var m = <String, dynamic>{'username': pair.item1, 'password': pair.item2};
      var jsn = json.encode(m);
      pairs.add(jsn);
    }
    await prefs.setStringList(_usernamePasswordPairsKey, pairs);
  }
}
