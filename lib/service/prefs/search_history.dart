import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryPrefs {
  SearchHistoryPrefs._();

  static const _searchHistoryKey = 'SearchHistoryPrefs_searchHistory'; // list

  static Future<List<String>> getSearchHistories() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    return prefs.safeGetStringList(_searchHistoryKey) ?? [];
  }

  static Future<void> clearSearchHistories() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    await prefs.setStringList(_searchHistoryKey, []);
  }

  static Future<List<String>> addSearchHistory(String s) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var data = await getSearchHistories();
    data.remove(s);
    data.insert(0, s); // 新 > 旧
    await prefs.setStringList(_searchHistoryKey, data);
    return data;
  }

  static Future<List<String>> removeSearchHistory(String s) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var data = await getSearchHistories();
    data.remove(s);
    await prefs.setStringList(_searchHistoryKey, data);
    return data;
  }

  static Future<void> upgradeFromVer1To2(SharedPreferences prefs) async {
    await prefs.migrateStringList(oldKey: 'SEARCH_HISTORY', newKey: _searchHistoryKey, defaultValue: []);
  }

  static Future<void> upgradeFromVer2To3(SharedPreferences prefs) async {
    // pass
  }
}
