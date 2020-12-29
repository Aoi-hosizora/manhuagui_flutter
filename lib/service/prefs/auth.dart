import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/service/natives/prefs.dart';

const _TOKEN = 'TOKEN'; // string
const _REMEMBER_USERNAME = 'REMEMBER_USERNAME'; // bool
const _REMEMBER_PASSWORD = 'REMEMBER_PASSWORD'; // bool
const _USERNAME = 'USERNAME'; // string
const _PASSWORD = 'PASSWORD'; // string

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

Future<Tuple2<bool, String>> getRememberedUsername() async {
  var prefs = await getPrefs();
  return Tuple2(prefs.getBool(_REMEMBER_USERNAME) ?? true, prefs.getString(_USERNAME));
}

Future<void> rememberUsername(String username) async {
  var prefs = await getPrefs();
  await prefs.setBool(_REMEMBER_USERNAME, true);
  await prefs.setString(_USERNAME, username);
}

Future<void> removeRememberedUsername() async {
  var prefs = await getPrefs();
  await prefs.setBool(_REMEMBER_USERNAME, false);
  await prefs.remove(_USERNAME);
}

Future<Tuple2<bool, String>> getRememberedPassword() async {
  var prefs = await getPrefs();
  return Tuple2(prefs.getBool(_REMEMBER_PASSWORD) ?? false, prefs.getString(_PASSWORD));
}

Future<void> rememberPassword(String password) async {
  var prefs = await getPrefs();
  await prefs.setBool(_REMEMBER_PASSWORD, true);
  await prefs.setString(_PASSWORD, password);
}

Future<void> removeRememberedPassword() async {
  var prefs = await getPrefs();
  await prefs.setBool(_REMEMBER_PASSWORD, false);
  await prefs.remove(_PASSWORD);
}
