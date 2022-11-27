import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingPrefs {
  AppSettingPrefs._();

  static Future<void> loadAllSettings() async {
    await loadViewSetting();
    await loadDlSetting();
    await loadOtherSetting();
  }

  static Future<void> saveAllSettings() async {
    await saveViewSetting();
    await saveDlSetting();
    await saveOtherSetting();
  }

  static const _viewDirectionKey = 'AppSettingPrefs_viewDirection'; // int
  static const _showPageHintKey = 'AppSettingPrefs_showPageHint'; // bool
  static const _showClockKey = 'AppSettingPrefs_showClock'; // bool
  static const _showNetworkKey = 'AppSettingPrefs_showNetwork'; // bool
  static const _showBatteryKey = 'AppSettingPrefs_showBattery'; // bool
  static const _enablePageSpaceKey = 'AppSettingPrefs_enablePageSpace'; // bool
  static const _keepScreenOnKey = 'AppSettingPrefs_keepScreenOn'; // bool
  static const _fullscreenKey = 'AppSettingPrefs_fullscreen'; // bool
  static const _preloadCountKey = 'AppSettingPrefs_preloadCount'; // int

  static Future<void> loadViewSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var def = ViewSetting.defaultSetting;
    var setting = ViewSetting(
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
    AppSetting.instance.update(view: setting);
  }

  static Future<void> saveViewSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var setting = AppSetting.instance.view;
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

  static const _invertDownloadOrderKey = 'AppSettingPrefs_invertDownloadOrder'; // int
  static const _defaultToDeleteFilesKey = 'AppSettingPrefs_defaultToDeleteFiles'; // bool
  static const _downloadPagesTogetherKey = 'AppSettingPrefs_downloadPagesTogether'; // int

  static Future<void> loadDlSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var def = DlSetting.defaultSetting;
    var setting = DlSetting(
      invertDownloadOrder: prefs.safeGetBool(_invertDownloadOrderKey) ?? def.invertDownloadOrder,
      defaultToDeleteFiles: prefs.safeGetBool(_defaultToDeleteFilesKey) ?? def.defaultToDeleteFiles,
      downloadPagesTogether: prefs.safeGetInt(_downloadPagesTogetherKey) ?? def.downloadPagesTogether,
    );
    AppSetting.instance.update(dl: setting);
  }

  static Future<void> saveDlSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var setting = AppSetting.instance.dl;
    await prefs.setBool(_invertDownloadOrderKey, setting.invertDownloadOrder);
    await prefs.setBool(_defaultToDeleteFilesKey, setting.defaultToDeleteFiles);
    await prefs.setInt(_downloadPagesTogetherKey, setting.downloadPagesTogether);
  }

  static const _timeoutBehaviorKey = 'AppSettingPrefs_timeoutBehavior'; // int
  static const _dlTimeoutBehaviorKey = 'AppSettingPrefs_dlTimeoutBehavior'; // int
  static const _enableLoggerKey = 'AppSettingPrefs_enableLogger'; // bool
  static const _usingDownloadedPageKey = 'AppSettingPrefs_usingDownloadedPage'; // bool
  static const _defaultMangaOrderKey = 'AppSettingPrefs_defaultMangaOrder'; // int
  static const _defaultAuthorOrderKey = 'AppSettingPrefs_defaultAuthorOrder'; // int

  static Future<void> loadOtherSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var def = OtherSetting.defaultSetting;
    var setting = OtherSetting(
      timeoutBehavior: TimeoutBehaviorExtension.fromInt(prefs.safeGetInt(_timeoutBehaviorKey) ?? def.timeoutBehavior.toInt()),
      dlTimeoutBehavior: TimeoutBehaviorExtension.fromInt(prefs.safeGetInt(_dlTimeoutBehaviorKey) ?? def.dlTimeoutBehavior.toInt()),
      enableLogger: prefs.safeGetBool(_enableLoggerKey) ?? def.enableLogger,
      usingDownloadedPage: prefs.safeGetBool(_usingDownloadedPageKey) ?? def.usingDownloadedPage,
      defaultMangaOrder: MangaOrderExtension.fromInt(prefs.safeGetInt(_defaultMangaOrderKey) ?? def.defaultMangaOrder.toInt()),
      defaultAuthorOrder: AuthorOrderExtension.fromInt(prefs.safeGetInt(_defaultAuthorOrderKey) ?? def.defaultAuthorOrder.toInt()),
    );
    AppSetting.instance.update(other: setting);
  }

  static Future<void> saveOtherSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var setting = AppSetting.instance.other;
    await prefs.setInt(_timeoutBehaviorKey, setting.timeoutBehavior.toInt());
    await prefs.setInt(_dlTimeoutBehaviorKey, setting.dlTimeoutBehavior.toInt());
    await prefs.setBool(_enableLoggerKey, setting.enableLogger);
    await prefs.setBool(_usingDownloadedPageKey, setting.usingDownloadedPage);
    await prefs.setInt(_defaultMangaOrderKey, setting.defaultMangaOrder.toInt());
    await prefs.setInt(_defaultAuthorOrderKey, setting.defaultAuthorOrder.toInt());
  }

  static Future<void> upgradeFromVer1To2(SharedPreferences prefs) async {
    var viewDef = ViewSetting.defaultSetting;
    await prefs.remove('SCROLL_DIRECTION');
    await prefs.migrateBool(oldKey: 'SHOW_PAGE_HINT', newKey: 'ViewSettingPrefs_showPageHint', defaultValue: viewDef.showPageHint);
    await prefs.remove('USE_SWIPE_FOR_CHAPTER');
    await prefs.remove('USE_CLICK_FOR_CHAPTER');
    await prefs.remove('NEED_CHECK_FOR_CHAPTER');
    await prefs.migrateBool(oldKey: 'ENABLE_PAGE_SPACE', newKey: 'ViewSettingPrefs_enablePageSpace', defaultValue: viewDef.enablePageSpace);
    await prefs.migrateInt(oldKey: 'PRELOAD_COUNT', newKey: 'ViewSettingPrefs_preloadCount', defaultValue: viewDef.preloadCount);
  }

  static Future<void> upgradeFromVer2To3(SharedPreferences prefs) async {
    var viewDef = ViewSetting.defaultSetting;
    await prefs.migrateInt(oldKey: 'ViewSettingPrefs_viewDirection', newKey: _viewDirectionKey, defaultValue: viewDef.viewDirection.toInt());
    await prefs.migrateBool(oldKey: 'ViewSettingPrefs_showPageHint', newKey: _showPageHintKey, defaultValue: viewDef.showPageHint);
    await prefs.migrateBool(oldKey: 'ViewSettingPrefs_showClock', newKey: _showClockKey, defaultValue: viewDef.showClock);
    await prefs.migrateBool(oldKey: 'ViewSettingPrefs_showNetwork', newKey: _showNetworkKey, defaultValue: viewDef.showNetwork);
    await prefs.migrateBool(oldKey: 'ViewSettingPrefs_showBattery', newKey: _showBatteryKey, defaultValue: viewDef.showBattery);
    await prefs.migrateBool(oldKey: 'ViewSettingPrefs_enablePageSpace', newKey: _enablePageSpaceKey, defaultValue: viewDef.enablePageSpace);
    await prefs.migrateBool(oldKey: 'ViewSettingPrefs_keepScreenOn', newKey: _keepScreenOnKey, defaultValue: viewDef.keepScreenOn);
    await prefs.migrateBool(oldKey: 'ViewSettingPrefs_fullscreen', newKey: _fullscreenKey, defaultValue: viewDef.fullscreen);
    await prefs.migrateInt(oldKey: 'ViewSettingPrefs_preloadCount', newKey: _preloadCountKey, defaultValue: viewDef.preloadCount);

    var dlDef = DlSetting.defaultSetting;
    await prefs.migrateBool(oldKey: 'DlSettingPrefs_invertDownloadOrder', newKey: _invertDownloadOrderKey, defaultValue: dlDef.invertDownloadOrder);
    await prefs.migrateBool(oldKey: 'DlSettingPrefs_defaultToDeleteFiles', newKey: _defaultToDeleteFilesKey, defaultValue: dlDef.defaultToDeleteFiles);
    await prefs.migrateInt(oldKey: 'DlSettingPrefs_downloadPagesTogether', newKey: _downloadPagesTogetherKey, defaultValue: dlDef.downloadPagesTogether);

    var otherDef = OtherSetting.defaultSetting;
    await prefs.migrateInt(oldKey: 'GlbSetting_timeoutBehavior', newKey: _timeoutBehaviorKey, defaultValue: otherDef.timeoutBehavior.toInt());
    await prefs.migrateInt(oldKey: 'GlbSetting_dlTimeoutBehavior', newKey: _dlTimeoutBehaviorKey, defaultValue: otherDef.dlTimeoutBehavior.toInt());
    await prefs.migrateBool(oldKey: 'GlbSetting_enableLogger', newKey: _enableLoggerKey, defaultValue: otherDef.enableLogger);
    await prefs.migrateBool(oldKey: 'GlbSetting_usingDownloadedPage', newKey: _usingDownloadedPageKey, defaultValue: otherDef.usingDownloadedPage);
  }
}
