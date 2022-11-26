import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/page/app_setting.dart';
import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingPrefs {
  AppSettingPrefs._();

  static const _timeoutBehaviorKey = 'AppSetting_timeoutBehavior'; // int
  static const _dlTimeoutBehaviorKey = 'AppSetting_dlTimeoutBehavior'; // int
  static const _enableLoggerKey = 'AppSetting_enableLogger'; // bool
  static const _usingDownloadedPageKey = 'AppSetting_usingDownloadedPage'; // bool
  static const _defaultMangaOrderKey = 'AppSettingPrefs_defaultMangaOrder'; // int
  static const _defaultAuthorOrderKey = 'AppSettingPrefs_defaultAuthorOrder'; // int

  // TODO merge all settings to here

  static Future<AppSetting> getSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var def = AppSetting.defaultSetting();
    return AppSetting(
      timeoutBehavior: TimeoutBehaviorExtension.fromInt(prefs.safeGetInt(_timeoutBehaviorKey) ?? def.timeoutBehavior.toInt()),
      dlTimeoutBehavior: TimeoutBehaviorExtension.fromInt(prefs.safeGetInt(_dlTimeoutBehaviorKey) ?? def.dlTimeoutBehavior.toInt()),
      enableLogger: prefs.safeGetBool(_enableLoggerKey) ?? def.enableLogger,
      usingDownloadedPage: prefs.safeGetBool(_usingDownloadedPageKey) ?? def.usingDownloadedPage,
      defaultMangaOrder: MangaOrderExtension.fromInt(prefs.safeGetInt(_defaultMangaOrderKey) ?? def.defaultMangaOrder.toInt()),
      defaultAuthorOrder: AuthorOrderExtension.fromInt(prefs.safeGetInt(_defaultAuthorOrderKey) ?? def.defaultAuthorOrder.toInt()),
    );
  }

  static Future<void> setSetting(AppSetting setting) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    await prefs.setInt(_timeoutBehaviorKey, setting.timeoutBehavior.toInt());
    await prefs.setInt(_dlTimeoutBehaviorKey, setting.dlTimeoutBehavior.toInt());
    await prefs.setBool(_enableLoggerKey, setting.enableLogger);
    await prefs.setBool(_usingDownloadedPageKey, setting.usingDownloadedPage);
    await prefs.setInt(_defaultMangaOrderKey, setting.defaultMangaOrder.toInt());
    await prefs.setInt(_defaultAuthorOrderKey, setting.defaultAuthorOrder.toInt());
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
