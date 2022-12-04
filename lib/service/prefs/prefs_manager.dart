import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/service/prefs/app_setting.dart';
import 'package:manhuagui_flutter/service/prefs/auth.dart';
import 'package:manhuagui_flutter/service/prefs/read_message.dart';
import 'package:manhuagui_flutter/service/prefs/search_history.dart';
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

  static const newestVersion = 3; // current newest SharedPreferences version

  Future<void> _checkUpgrade(SharedPreferences prefs) async {
    var version = prefs.getInt('VERSION') ?? 1;
    if (version == newestVersion) {
      return;
    }

    if (version <= 1) {
      version = 2; // 1 -> 2 upgrade
      await AppSettingPrefs.upgradeFromVer1To2(prefs);
      await AuthPrefs.upgradeFromVer1To2(prefs);
      await ReadMessagePrefs.upgradeFromVer1To2(prefs);
      await SearchHistoryPrefs.upgradeFromVer1To2(prefs);
    }
    if (version == 2) {
      version = 3; // 2 -> 3 upgrade
      await AppSettingPrefs.upgradeFromVer2To3(prefs);
      await AuthPrefs.upgradeFromVer2To3(prefs);
      await ReadMessagePrefs.upgradeFromVer2To3(prefs);
      await SearchHistoryPrefs.upgradeFromVer2To3(prefs);
    }

    prefs.setInt('VERSION', newestVersion);
  }
}

class TypedKey<T> {
  const TypedKey(this.key);

  final String key;
}

typedef StringKey = TypedKey<String>;
typedef BoolKey = TypedKey<bool>;
typedef IntKey = TypedKey<int>;
typedef DoubleKey = TypedKey<double>;
typedef StringListKey = TypedKey<List<String>>;

extension SharedPreferencesExtension on SharedPreferences {
  T? safeGet<T>(TypedKey<T> key) {
    try {
      if (key is TypedKey<String>) {
        return getString(key.key) as T?;
      }
      if (key is TypedKey<bool>) {
        return getBool(key.key) as T?;
      }
      if (key is TypedKey<int>) {
        return getInt(key.key) as T?;
      }
      if (key is TypedKey<double>) {
        return getDouble(key.key) as T?;
      }
      if (key is TypedKey<List<String>>) {
        return getStringList(key.key) as T?;
      }
      throw ArgumentError('Invalid type: $T');
    } catch (e, s) {
      globalLogger.e('safeGet<$T>', e, s);
      return null;
    }
  }

  Future<bool> safeSet<T>(TypedKey<T> key, T value) async {
    try {
      if (value is String) {
        return await setString(key.key, value);
      }
      if (value is bool) {
        return await setBool(key.key, value);
      }
      if (value is int) {
        return await setInt(key.key, value);
      }
      if (value is double) {
        return await setDouble(key.key, value);
      }
      if (value is List<String>) {
        return await setStringList(key.key, value);
      }
      throw ArgumentError('Invalid type: $T');
    } catch (e, s) {
      globalLogger.e('safeSet<$T>', e, s);
      return false;
    }
  }

  Future<bool> safeMigrate<T>(dynamic oldKey, TypedKey<T> newKey, {T? defaultValue}) async {
    if (oldKey is String) oldKey = TypedKey<T>(oldKey);
    if (oldKey is! TypedKey<T>) {
      globalLogger.e('Invalid oldKey type: ${oldKey.runtimeType}, want TypedKey<$T>');
      return false;
    }

    if (oldKey.key == newKey.key) {
      return true;
    }
    try {
      T? data = safeGet(oldKey) ?? defaultValue;
      if (data != null) {
        var result = await safeSet(newKey, data);
        if (result) {
          await remove(oldKey.key);
        }
        return result;
      }
    } catch (e, s) {
      globalLogger.e('migrate<$T>', e, s);
    }
    return false;
  }

  int? copyToMap(Map<String, Object> anotherMap, List<TypedKey> keys) {
    var oldLength = anotherMap.length;
    for (var key in keys) {
      var value = safeGet(key); // depending on types
      if (value != null) {
        anotherMap[key.key] = value;
      }
    }
    var rows = anotherMap.length - oldLength;
    return rows; // non-null
  }
}
