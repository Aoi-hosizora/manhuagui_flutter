import 'package:manhuagui_flutter/page/page/view_setting.dart';
import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewSettingPrefs {
  ViewSettingPrefs._();

  static const _viewDirectionKey = 'ViewSettingPrefs_viewDirection'; // int
  static const _showPageHintKey = 'ViewSettingPrefs_showPageHint'; // bool
  static const _showClockKey = 'ViewSettingPrefs_showClock'; // bool
  static const _showNetworkKey = 'ViewSettingPrefs_showNetwork'; // bool
  static const _showBatteryKey = 'ViewSettingPrefs_showBattery'; // bool
  static const _enablePageSpaceKey = 'ViewSettingPrefs_enablePageSpace'; // bool
  static const _keepScreenOnKey = 'ViewSettingPrefs_keepScreenOn'; // bool
  static const _fullscreenKey = 'ViewSettingPrefs_fullscreen'; // bool
  static const _preloadCountKey = 'ViewSettingPrefs_preloadCount'; // int

  static Future<ViewSetting> getSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var def = ViewSetting.defaultSetting();
    return ViewSetting(
      viewDirection: ViewDirectionExtension.fromInt(prefs.safeGetInt(_viewDirectionKey) ?? def.viewDirection.toInt()),
      showPageHint: prefs.safeGetBool(_showPageHintKey) ?? def.showPageHint,
      showClock: prefs.safeGetBool(_showClockKey) ?? def.showClock,
      showNetwork: prefs.safeGetBool(_showNetworkKey) ?? def.showNetwork,
      showBattery: prefs.safeGetBool(_showBatteryKey) ?? def.showBattery,
      enablePageSpace: prefs.safeGetBool(_enablePageSpaceKey) ?? def.enablePageSpace,
      keepScreenOn: prefs.safeGetBool(_keepScreenOnKey) ?? def.keepScreenOn,
      fullscreen: prefs.safeGetBool(_fullscreenKey) ?? def.fullscreen,
      preloadCount: prefs.safeGetInt(_preloadCountKey) ?? def.preloadCount,
    );
  }

  static Future<void> setSetting(ViewSetting setting) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    await prefs.setInt(_viewDirectionKey, setting.viewDirection.toInt());
    await prefs.setBool(_showPageHintKey, setting.showPageHint);
    await prefs.setBool(_showClockKey, setting.showClock);
    await prefs.setBool(_showNetworkKey, setting.showNetwork);
    await prefs.setBool(_showBatteryKey, setting.showBattery);
    await prefs.setBool(_enablePageSpaceKey, setting.enablePageSpace);
    await prefs.setBool(_keepScreenOnKey, setting.keepScreenOn);
    await prefs.setBool(_fullscreenKey, setting.fullscreen);
    await prefs.setInt(_preloadCountKey, setting.preloadCount);
  }

  static Future<void> upgradeFromVer1To2(SharedPreferences prefs) async {
    var def = ViewSetting.defaultSetting();
    await prefs.remove('SCROLL_DIRECTION');
    await prefs.migrateBool(oldKey: 'SHOW_PAGE_HINT', newKey: _showPageHintKey, defaultValue: def.showPageHint);
    await prefs.remove('USE_SWIPE_FOR_CHAPTER');
    await prefs.remove('USE_CLICK_FOR_CHAPTER');
    await prefs.remove('NEED_CHECK_FOR_CHAPTER');
    await prefs.migrateBool(oldKey: 'ENABLE_PAGE_SPACE', newKey: _enablePageSpaceKey, defaultValue: def.enablePageSpace);
    await prefs.migrateInt(oldKey: 'PRELOAD_COUNT', newKey: _preloadCountKey, defaultValue: def.preloadCount);
  }

  static Future<void> upgradeFromVer2To3(SharedPreferences prefs) async {
    // pass
  }
}
