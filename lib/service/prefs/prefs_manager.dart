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
      await _upgradePrefs(_prefs!);
    }
    return _prefs!;
  }

  Future<SharedPreferences> reloadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  static const _newestVersion = 3;

  Future<void> _upgradePrefs(SharedPreferences prefs) async {
    var version = prefs.getInt('VERSION') ?? 1;
    if (version == _newestVersion) {
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

    prefs.setInt('VERSION', _newestVersion);
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
  T? safeGet<T>(TypedKey<T> key, {bool canThrow = false}) {
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
      if (key is TypedKey<List>) {
        return getStringList(key.key) as T?;
      }
      throw ArgumentError('Invalid type: $T');
    } catch (e, s) {
      if (canThrow) rethrow;
      globalLogger.e('safeGet<$T>', e, s);
      return null;
    }
  }

  Future<bool> safeSet<T>(TypedKey<T> key, T value, {bool canThrow = false}) async {
    try {
      if (key is TypedKey<String> && value is String) {
        return await setString(key.key, value);
      }
      if (key is TypedKey<bool> && value is bool) {
        return await setBool(key.key, value);
      }
      if (key is TypedKey<int> && value is int) {
        return await setInt(key.key, value);
      }
      if (key is TypedKey<double> && value is double) {
        return await setDouble(key.key, value);
      }
      if (key is TypedKey<List> && value is List) {
        if (value is List<String>) {
          return await setStringList(key.key, value);
        }
        return await setStringList(key.key, value.map((v) => v.toString()).toList());
      }
      throw ArgumentError('Invalid type: ${TypedKey<T>} <-> $T');
    } catch (e, s) {
      if (canThrow) rethrow;
      globalLogger.e('safeSet<$T>', e, s);
      return false;
    }
  }

  Future<bool> safeMigrate<T>(dynamic oldKey, TypedKey<T> newKey, {T? defaultValue}) async {
    if (oldKey is String) {
      oldKey = TypedKey<T>(oldKey);
    }
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
      globalLogger.e('safeMigrate<$T>', e, s);
    }
    return false;
  }

  Future<int?> copyTo(Map<String, dynamic> map, List<TypedKey> keys) async {
    try {
      var rows = 0;
      for (var key in keys) {
        var value = safeGet(key, canThrow: true);
        if (value != null) {
          print('${key.key} $value');
          map[key.key] = value;
          rows++;
        }
      }
      return rows;
    } catch (e, s) {
      globalLogger.e('copyTo_map', e, s);
      return null;
    }
  }
}

extension JsonMapExtension on Map<String, dynamic> {
  Future<int?> copyTo(SharedPreferences prefs, List<TypedKey> keys) async {
    try {
      var rows = 0;
      for (var key in keys) {
        var value = this[key.key];
        if (value != null) {
          print('${key.key} $value');
          await prefs.safeSet(key, value, canThrow: true);
          rows++;
        }
      }
      return rows;
    } catch (e, s) {
      globalLogger.e('copyTo_prefs', e, s);
      return null;
    }
  }
}
