import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/service/prefs/glb_setting.dart';
import 'package:manhuagui_flutter/service/prefs/auth.dart';
import 'package:manhuagui_flutter/service/prefs/dl_setting.dart';
import 'package:manhuagui_flutter/service/prefs/search_history.dart';
import 'package:manhuagui_flutter/service/prefs/view_setting.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsManager {
  PrefsManager._();

  static PrefsManager? _instance;

  static PrefsManager get instance {
    _instance ??= PrefsManager._();
    return _instance!;
  }

  SharedPreferences? _prefs; // global SharedPreferences instance

  Future<SharedPreferences> loadPrefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      await _checkUpgrade(_prefs!);
    }
    return _prefs!;
  }

  Future<SharedPreferences> reloadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  static const newestVersion = 2; // current newest SharedPreferences version

  Future<void> _checkUpgrade(SharedPreferences prefs) async {
    var version = prefs.getInt('VERSION') ?? 1;
    if (version == newestVersion) {
      return;
    }

    if (version <= 1) {
      version = 2; // 1 -> 2 upgrade
      await AuthPrefs.upgradeFromVer1To2(prefs);
      await DlSettingPrefs.upgradeFromVer1To2(prefs);
      await GlbSettingPrefs.upgradeFromVer1To2(prefs);
      await SearchHistoryPrefs.upgradeFromVer1To2(prefs);
      await ViewSettingPrefs.upgradeFromVer1To2(prefs);
    }
    if (version == 2) {
      // ...
    }

    prefs.setInt('VERSION', newestVersion);
  }
}

extension SharedPreferencesExtension on SharedPreferences {
  String? safeGetString(String key) => _safeGet<String>(() => getString(key));

  bool? safeGetBool(String key) => _safeGet<bool>(() => getBool(key));

  int? safeGetInt(String key) => _safeGet<int>(() => getInt(key));

  double? safeGetDouble(String key) => _safeGet<double>(() => getDouble(key));

  List<String>? safeGetStringList(String key) => _safeGet<List<String>>(() => getStringList(key));

  T? _safeGet<T>(T? Function() getter) {
    try {
      return getter();
    } catch (e, s) {
      globalLogger.e('_safeGet<$T>', e, s);
      return null;
    }
  }

  Future<bool> migrateString({required String oldKey, required String newKey, String? defaultValue}) async => //
      await _migrate<String>(oldKey, newKey, getString, setString, defaultValue);

  Future<bool> migrateBool({required String oldKey, required String newKey, bool? defaultValue}) async => //
      await _migrate<bool>(oldKey, newKey, getBool, setBool, defaultValue);

  Future<bool> migrateInt({required String oldKey, required String newKey, int? defaultValue}) async => //
      await _migrate<int>(oldKey, newKey, getInt, setInt, defaultValue);

  Future<bool> migrateDouble({required String oldKey, required String newKey, double? defaultValue}) async => //
      await _migrate<double>(oldKey, newKey, getDouble, setDouble, defaultValue);

  Future<bool> migrateStringList({required String oldKey, required String newKey, List<String>? defaultValue}) async => //
      await _migrate<List<String>>(oldKey, newKey, getStringList, setStringList, defaultValue);

  Future<bool> _migrate<T>(String oldKey, String newKey, T? Function(String) getter, Future<bool> Function(String, T) setter, T? defaultValue) async {
    if (oldKey == newKey) {
      return true;
    }
    try {
      T? data = getter(oldKey) ?? defaultValue;
      if (data != null) {
        var result = await setter(newKey, data);
        remove(oldKey);
        return result;
      }
    } catch (e, s) {
      globalLogger.e('_migrate<$T>', e, s);
    }
    return false;
  }
}
