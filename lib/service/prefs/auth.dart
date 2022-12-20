import 'dart:convert';

import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPrefs {
  AuthPrefs._();

  static const _tokenKey = StringKey('AuthPrefs_token');
  static const _rememberUsernameKey = BoolKey('AuthPrefs_rememberUsername');
  static const _rememberPasswordKey = BoolKey('AuthPrefs_rememberPassword');
  static const _usernamePasswordPairsKey = StringListKey('AuthPrefs_usernamePasswordPairs');

  static Future<String> getToken() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    return prefs.safeGet<String>(_tokenKey) ?? '';
  }

  static Future<void> setToken(String token) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    await prefs.safeSet<String>(_tokenKey, token);
  }

  static Future<Tuple2<bool, bool>> getRememberOption() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var rememberUsername = prefs.safeGet<bool>(_rememberUsernameKey) ?? true;
    var rememberPassword = prefs.safeGet<bool>(_rememberPasswordKey) ?? false;
    return Tuple2(rememberUsername, rememberPassword);
  }

  static Future<void> setRememberOption(bool rememberUsername, bool rememberPassword) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    await prefs.safeSet<bool>(_rememberUsernameKey, rememberUsername);
    await prefs.safeSet<bool>(_rememberPasswordKey, rememberPassword);
  }

  static Future<List<Tuple2<String, String>>> getUsernamePasswordPairs() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var data = prefs.safeGet<List<String>>(_usernamePasswordPairsKey) ?? [];
    return _usernamePasswordStringsToTuples(data);
  }

  static Future<String?> getUserPassword(String username) async {
    var data = await getUsernamePasswordPairs();
    return data.where((el) => el.item1 == username).firstOrNull?.item2;
  }

  static Future<List<Tuple2<String, String>>> addUsernamePasswordPair(String username, String password) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var data = await getUsernamePasswordPairs();
    data.removeWhere((t) => t.item1 == username);
    data.insert(0, Tuple2(username, password)); // 新 > 旧
    await prefs.safeSet<List<String>>(_usernamePasswordPairsKey, _usernamePasswordTuplesToStrings(data));
    return data;
  }

  static Future<List<Tuple2<String, String>>> removeUsernamePasswordPair(String username) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var data = await getUsernamePasswordPairs();
    data.removeWhere((t) => t.item1 == username);
    await prefs.safeSet<List<String>>(_usernamePasswordPairsKey, _usernamePasswordTuplesToStrings(data));
    return data;
  }

  static List<Tuple2<String, String>> _usernamePasswordStringsToTuples(List<String> data) {
    var out = <Tuple2<String, String>>[];
    for (var jsn in data) {
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

  static List<String> _usernamePasswordTuplesToStrings(List<Tuple2<String, String>> data) {
    var out = <String>[];
    for (var tup in data) {
      var m = <String, dynamic>{
        'username': tup.item1,
        'password': tup.item2,
      };
      var jsn = json.encode(m);
      out.add(jsn);
    }
    return out;
  }

  static Future<void> upgradeFromVer1To2(SharedPreferences prefs) async {
    await prefs.safeMigrate<String>('TOKEN', _tokenKey, defaultValue: '');
    await prefs.safeMigrate<bool>('REMEMBER_USERNAME', _rememberUsernameKey, defaultValue: true);
    await prefs.safeMigrate<bool>('REMEMBER_PASSWORD', _rememberPasswordKey, defaultValue: false);
    await prefs.safeMigrate<List<String>>('USERNAME_PASSWORD_PAIRS', _usernamePasswordPairsKey, defaultValue: []);
  }

  static Future<void> upgradeFromVer2To3(SharedPreferences prefs) async {
    // pass
  }
}
