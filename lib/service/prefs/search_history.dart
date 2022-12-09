import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryPrefs {
  SearchHistoryPrefs._();

  static const _searchHistoryKey = StringListKey('SearchHistoryPrefs_searchHistory');

  static List<TypedKey> get keys => [_searchHistoryKey];

  static Future<List<String>> getSearchHistories({SharedPreferences? prefs}) async {
    prefs ??= await PrefsManager.instance.loadPrefs();
    return prefs.safeGet<List<String>>(_searchHistoryKey) ?? [];
  }

  static Future<void> clearSearchHistories() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    await prefs.safeSet<List<String>>(_searchHistoryKey, []);
  }

  static Future<List<String>> addSearchHistory(String s) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var data = await getSearchHistories();
    data.remove(s);
    data.insert(0, s); // 新 > 旧
    await prefs.safeSet<List<String>>(_searchHistoryKey, data);
    return data;
  }

  static Future<List<String>> removeSearchHistory(String s) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var data = await getSearchHistories();
    data.remove(s);
    await prefs.safeSet<List<String>>(_searchHistoryKey, data);
    return data;
  }

  static Future<void> upgradeFromVer1To2(SharedPreferences prefs) async {
    await prefs.safeMigrate<List<String>>('SEARCH_HISTORY', _searchHistoryKey, defaultValue: []);
  }

  static Future<void> upgradeFromVer2To3(SharedPreferences prefs) async {
    // pass
  }
}
