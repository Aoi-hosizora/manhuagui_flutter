import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';

class SearchHistoryPrefs {
  SearchHistoryPrefs._();

  static const _searchHistoryKey = 'SEARCH_HISTORY'; // list

  static Future<List<String>> getSearchHistories() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var l = prefs.getStringList(_searchHistoryKey); // 新 > 旧
    return l ?? [];
  }

  static Future<void> addSearchHistory(String s) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var l = prefs.getStringList(_searchHistoryKey) ?? [];
    l.remove(s);
    l.insert(0, s); // 新 > 旧
    await prefs.setStringList(_searchHistoryKey, l);
  }

  static Future<void> removeSearchHistory(String s) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var l = prefs.getStringList(_searchHistoryKey) ?? [];
    l.remove(s);
    await prefs.setStringList(_searchHistoryKey, l);
  }

  static Future<void> clearSearchHistories() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var l = prefs.getStringList(_searchHistoryKey) ?? [];
    l.clear();
    await prefs.setStringList(_searchHistoryKey, l);
  }
}
