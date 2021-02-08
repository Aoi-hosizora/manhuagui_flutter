import 'dart:convert';

import 'package:flutter_ahlib/util.dart';
import 'package:manhuagui_flutter/service/natives/prefs.dart';

const _TOKEN = 'TOKEN'; // string
const _REMEMBER_USERNAME = 'REMEMBER_USERNAME'; // bool
const _REMEMBER_PASSWORD = 'REMEMBER_PASSWORD'; // bool
const _USERNAME_PASSWORD_PAIRS = 'USERNAME_PASSWORD_PAIRS'; // list

Future<String> getToken() async {
  var prefs = await getPrefs();
  return prefs.getString(_TOKEN);
}

Future<void> setToken(String token) async {
  var prefs = await getPrefs();
  await prefs.setString(_TOKEN, token);
}

Future<void> removeToken() async {
  var prefs = await getPrefs();
  await prefs.remove(_TOKEN);
}

Future<Tuple2<bool, bool>> getRememberOptions() async {
  var prefs = await getPrefs();
  return Tuple2(prefs.getBool(_REMEMBER_USERNAME) ?? true, prefs.getBool(_REMEMBER_PASSWORD) ?? false);
}

Future<void> setRememberOptions(bool rememberUsername, bool rememberPassword) async {
  var prefs = await getPrefs();
  await prefs.setBool(_REMEMBER_USERNAME, rememberUsername);
  await prefs.setBool(_REMEMBER_PASSWORD, rememberPassword);
}

Future<List<Tuple2<String, String>>> getUsernamePasswordPairs() async {
  var prefs = await getPrefs();
  var pairs = prefs.getStringList(_USERNAME_PASSWORD_PAIRS) ?? [];
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
  var prefs = await getPrefs();
  var list = await getUsernamePasswordPairs();
  list.removeWhere((t) => t.item1 == username);
  list.insert(0, Tuple2(username, password)); // 新 > 旧
  var pairs = <String>[];
  for (var pair in list) {
    var jsn = '{"username": "${pair.item1}", "password": "${pair.item2}"}';
    pairs.add(jsn);
  }
  await prefs.setStringList(_USERNAME_PASSWORD_PAIRS, pairs);
}

Future<void> removeUsernamePasswordPair(String username) async {
  var prefs = await getPrefs();
  var list = await getUsernamePasswordPairs();
  list.removeWhere((t) => t.item1 == username);
  var pairs = <String>[];
  for (var pair in list) {
    var jsn = '{"username": "${pair.item1}", "password": "${pair.item2}"}';
    pairs.add(jsn);
  }
  await prefs.setStringList(_USERNAME_PASSWORD_PAIRS, pairs);
}
