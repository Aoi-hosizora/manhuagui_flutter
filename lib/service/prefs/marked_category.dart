import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarkedCategoryPrefs {
  MarkedCategoryPrefs._();

  static const _markedCategoriesKey = StringListKey('MarkedCategoryPrefs_markedCategories');

  static List<TypedKey> get keys => [_markedCategoriesKey];

  static Future<List<String>> getMarkedCategories({SharedPreferences? prefs}) async {
    prefs ??= await PrefsManager.instance.loadPrefs();
    return prefs.safeGet<List<String>>(_markedCategoriesKey) ?? [];
  }

  static Future<void> clearMarkedCategories() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    await prefs.safeSet<List<String>>(_markedCategoriesKey, []);
  }

  static Future<bool> isCategoryMarked({required String name}) async {
    var data = await getMarkedCategories();
    return data.any((el) => el == name);
  }

  static Future<List<String>> markCategory({required String name}) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var data = await getMarkedCategories();
    data.removeWhere((h) => h == name);
    data.insert(0, name); // 新 > 旧
    await prefs.safeSet<List<String>>(_markedCategoriesKey, data);
    return data;
  }

  static Future<List<String>> unmarkCategory({required String name}) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var data = await getMarkedCategories();
    data.removeWhere((h) => h == name);
    await prefs.safeSet<List<String>>(_markedCategoriesKey, data);
    return data;
  }

  static Future<void> upgradeFromVer1To2(SharedPreferences prefs) async {
    // pass
  }

  static Future<void> upgradeFromVer2To3(SharedPreferences prefs) async {
    // pass
  }

  static Future<void> upgradeFromVer3To4(SharedPreferences prefs) async {
    // pass
  }
}
