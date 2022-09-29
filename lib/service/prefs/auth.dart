import 'dart:convert';

import 'package:flutter_ahlib/util.dart';
import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';

const _token = 'TOKEN'; // string
const _rememberUsername = 'REMEMBER_USERNAME'; // bool
const _rememberPassword = 'REMEMBER_PASSWORD'; // bool
const _usernamePasswordPairs = 'USERNAME_PASSWORD_PAIRS'; // list

Future<String?> getToken() async {
  var prefs = await PrefsManager.instance.loadPrefs();
  return prefs.getString(_token);
}

Future<void> setToken(String token) async {
  var prefs = await PrefsManager.instance.loadPrefs();
  await prefs.setString(_token, token);
}

Future<void> removeToken() async {
  var prefs = await PrefsManager.instance.loadPrefs();
  await prefs.remove(_token);
}

Future<Tuple2<bool, bool>> getRememberOptions() async {
  var prefs = await PrefsManager.instance.loadPrefs();
  return Tuple2(prefs.getBool(_rememberUsername) ?? true, prefs.getBool(_rememberPassword) ?? false);
}

Future<void> setRememberOptions(bool rememberUsername, bool rememberPassword) async {
  var prefs = await PrefsManager.instance.loadPrefs();
  await prefs.setBool(_rememberUsername, rememberUsername);
  await prefs.setBool(_rememberPassword, rememberPassword);
}

Future<List<Tuple2<String, String>>> getUsernamePasswordPairs() async {
  var prefs = await PrefsManager.instance.loadPrefs();
  var pairs = prefs.getStringList(_usernamePasswordPairs) ?? [];
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

Future<void> addUsernamePasswordPair(String username, String password) async {
  var prefs = await PrefsManager.instance.loadPrefs();
  var list = await getUsernamePasswordPairs();
  list.removeWhere((t) => t.item1 == username);
  list.insert(0, Tuple2(username, password)); // 新 > 旧
  var pairs = <String>[];
  for (var pair in list) {
    var jsn = '{"username": "${pair.item1}", "password": "${pair.item2}"}';
    pairs.add(jsn);
  }
  await prefs.setStringList(_usernamePasswordPairs, pairs);
}

Future<void> removeUsernamePasswordPair(String username) async {
  var prefs = await PrefsManager.instance.loadPrefs();
  var list = await getUsernamePasswordPairs();
  list.removeWhere((t) => t.item1 == username);
  var pairs = <String>[];
  for (var pair in list) {
    var jsn = '{"username": "${pair.item1}", "password": "${pair.item2}"}';
    pairs.add(jsn);
  }
  await prefs.setStringList(_usernamePasswordPairs, pairs);
}
