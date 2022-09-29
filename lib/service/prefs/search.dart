import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';

const _searchHistory = 'SEARCH_HISTORY'; // string[]

/// 拿到搜索历史，按照时间新到旧排序
Future<List<String>> getSearchHistories() async {
  var prefs = await PrefsManager.instance.loadPrefs();
  var l = prefs.getStringList(_searchHistory);
  return l ?? [];
}

/// 插入到搜索记录最前面
Future<void> addSearchHistory(String s) async {
  var prefs = await PrefsManager.instance.loadPrefs();
  var l = prefs.getStringList(_searchHistory) ?? [];
  l.remove(s);
  l.insert(0, s);
  await prefs.setStringList(_searchHistory, l);
}

Future<void> removeSearchHistory(String s) async {
  var prefs = await PrefsManager.instance.loadPrefs();
  var l = prefs.getStringList(_searchHistory) ?? [];
  l.remove(s);
  await prefs.setStringList(_searchHistory, l);
}

Future<void> clearSearchHistories() async {
  var prefs = await PrefsManager.instance.loadPrefs();
  var l = prefs.getStringList(_searchHistory) ?? [];
  l.clear();
  await prefs.setStringList(_searchHistory, l);
}
