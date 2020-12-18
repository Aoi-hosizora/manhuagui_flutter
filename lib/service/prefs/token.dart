import 'package:manhuagui_flutter/service/natives/prefs.dart';

const _TOKEN = "TOKEN";

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
