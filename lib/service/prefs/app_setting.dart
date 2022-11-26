import 'package:manhuagui_flutter/page/page/app_setting.dart';
import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingPrefs {
  AppSettingPrefs._();

  static const _timeoutBehaviorKey = 'AppSetting_timeoutBehavior'; // int
  static const _dlTimeoutBehaviorKey = 'AppSetting_dlTimeoutBehavior'; // int
  static const _enableLoggerKey = 'AppSetting_enableLogger'; // bool
  static const _usingDownloadedPageKey = 'AppSetting_usingDownloadedPage'; // bool

  // TODO merge all settings to here

  static Future<AppSetting> getSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var def = AppSetting.defaultSetting();
    return AppSetting(
      timeoutBehavior: TimeoutBehaviorExtension.fromInt(prefs.safeGetInt(_timeoutBehaviorKey) ?? def.timeoutBehavior.toInt()),
      dlTimeoutBehavior: TimeoutBehaviorExtension.fromInt(prefs.safeGetInt(_dlTimeoutBehaviorKey) ?? def.dlTimeoutBehavior.toInt()),
      enableLogger: prefs.safeGetBool(_enableLoggerKey) ?? def.enableLogger,
      usingDownloadedPage: prefs.safeGetBool(_usingDownloadedPageKey) ?? def.usingDownloadedPage,
    );
  }

  static Future<void> setSetting(AppSetting setting) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    await prefs.setInt(_timeoutBehaviorKey, setting.timeoutBehavior.toInt());
    await prefs.setInt(_dlTimeoutBehaviorKey, setting.dlTimeoutBehavior.toInt());
    await prefs.setBool(_enableLoggerKey, setting.enableLogger);
    await prefs.setBool(_usingDownloadedPageKey, setting.usingDownloadedPage);
  }

  static Future<void> upgradeFromVer1To2(SharedPreferences prefs) async {
    // pass
  }

  static Future<void> upgradeFromVer2To3(SharedPreferences prefs) async {
    var def = AppSetting.defaultSetting();
    await prefs.migrateInt(oldKey: 'GlbSetting_timeoutBehavior', newKey: _timeoutBehaviorKey, defaultValue: def.timeoutBehavior.toInt());
    await prefs.migrateInt(oldKey: 'GlbSetting_dlTimeoutBehavior', newKey: _dlTimeoutBehaviorKey, defaultValue: def.dlTimeoutBehavior.toInt());
    await prefs.migrateBool(oldKey: 'GlbSetting_enableLogger', newKey: _enableLoggerKey, defaultValue: def.enableLogger);
    await prefs.migrateBool(oldKey: 'GlbSetting_usingDownloadedPage', newKey: _usingDownloadedPageKey, defaultValue: def.usingDownloadedPage);
  }
}
