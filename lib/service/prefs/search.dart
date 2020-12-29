import 'package:manhuagui_flutter/service/natives/prefs.dart';

const _SEARCH_HISTORY = 'SEARCH_HISTORY'; // string[]

/// 拿到搜索历史，按照时间新到旧排序
Future<List<String>> getSearchHistories() async {
  var prefs = await getPrefs();
  var l = prefs.getStringList(_SEARCH_HISTORY);
  return l ?? [];
}

/// 插入到搜索记录最前面
Future<void> addSearchHistory(String s) async {
  var prefs = await getPrefs();
  var l = prefs.getStringList(_SEARCH_HISTORY) ?? [];
  l.remove(s);
  l.insert(0, s);
  await prefs.setStringList(_SEARCH_HISTORY, l);
}

Future<void> removeSearchHistory(String s) async {
  var prefs = await getPrefs();
  var l = prefs.getStringList(_SEARCH_HISTORY) ?? [];
  l.remove(s);
  await prefs.setStringList(_SEARCH_HISTORY, l);
}

Future<void> clearSearchHistories() async {
  var prefs = await getPrefs();
  var l = prefs.getStringList(_SEARCH_HISTORY) ?? [];
  l.clear();
  await prefs.setStringList(_SEARCH_HISTORY, l);
}
