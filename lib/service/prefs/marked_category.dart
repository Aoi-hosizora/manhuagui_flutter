import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarkedCategoryPrefs {
  MarkedCategoryPrefs._();

  static const _markedCategoriesKey = StringListKey('MarkedCategoryPrefs_markedCategories');
  static const _remappedQingnianKey = StringKey('MarkedCategoryPrefs_remappedQingnian');
  static const _remappedShaonvKey = StringKey('MarkedCategoryPrefs_remappedShaonv');

  static List<TypedKey> get keys => [_markedCategoriesKey, _remappedQingnianKey, _remappedShaonvKey];

  static Future<List<String>> getMarkedCategories({SharedPreferences? prefs}) async {
    prefs ??= await PrefsManager.instance.loadPrefs();
    return prefs.safeGet<List<String>>(_markedCategoriesKey) ?? [];
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

  static Future<String?> getRemappedQingnianCategoryName() async {
    var data = await PrefsManager.instance.loadPrefs();
    return data.safeGet<String>(_remappedQingnianKey);
  }

  static Future<void> setRemappedQingnianCategoryName({required String remappedName}) async {
    var data = await PrefsManager.instance.loadPrefs();
    if (remappedName == qingnianAgeCategory.name) {
      await data.remove(_remappedQingnianKey.key);
    } else {
      await data.safeSet<String>(_remappedQingnianKey, remappedName);
    }
  }

  static Future<String?> getRemappedShaonvCategoryName() async {
    var data = await PrefsManager.instance.loadPrefs();
    return data.safeGet<String>(_remappedShaonvKey);
  }

  static Future<void> setRemappedShaonvCategoryName({required String remappedName}) async {
    var data = await PrefsManager.instance.loadPrefs();
    if (remappedName == shaonvAgeCategory.name) {
      await data.remove(_remappedShaonvKey.key);
    } else {
      await data.safeSet<String>(_remappedShaonvKey, remappedName);
    }
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
