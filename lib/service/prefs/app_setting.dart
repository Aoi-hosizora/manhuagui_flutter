import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingPrefs {
  AppSettingPrefs._();

  static List<TypedKey> get keys => [...viewSettingKeys, ...dlSettingKeys, ...uiSettingKeys, ...otherSettingKeys];

  static Future<void> loadAllSettings({bool alsoFireEvent = true}) async {
    var view = await _loadViewSetting();
    var dl = await _loadDlSetting();
    var ui = await _loadUiSetting();
    var other = await _loadOtherSetting();
    AppSetting.instance.update(view: view, dl: dl, ui: ui, other: other, alsoFireEvent: alsoFireEvent);
  }

  static Future<void> saveAllSettings() async {
    await saveViewSetting();
    await saveDlSetting();
    await saveUiSetting();
    await saveOtherSetting();
  }

  // ============
  // view setting
  // ============

  static const _viewDirectionKey = IntKey('AppSettingPrefs_viewDirection');
  static const _showPageHintKey = BoolKey('AppSettingPrefs_showPageHint');
  static const _showClockKey = BoolKey('AppSettingPrefs_showClock');
  static const _showNetworkKey = BoolKey('AppSettingPrefs_showNetwork');
  static const _showBatteryKey = BoolKey('AppSettingPrefs_showBattery');
  static const _enablePageSpaceKey = BoolKey('AppSettingPrefs_enablePageSpace');
  static const _keepScreenOnKey = BoolKey('AppSettingPrefs_keepScreenOn');
  static const _fullscreenKey = BoolKey('AppSettingPrefs_fullscreen');
  static const _preloadCountKey = IntKey('AppSettingPrefs_preloadCount');

  static List<TypedKey> get viewSettingKeys => [
        _viewDirectionKey,
        _showPageHintKey,
        _showClockKey,
        _showNetworkKey,
        _showBatteryKey,
        _enablePageSpaceKey,
        _keepScreenOnKey,
        _fullscreenKey,
        _preloadCountKey,
      ];

  static Future<ViewSetting> _loadViewSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var def = ViewSetting.defaultSetting;
    return ViewSetting(
      viewDirection: ViewDirectionExtension.fromInt(prefs.safeGet<int>(_viewDirectionKey) ?? def.viewDirection.toInt()),
      showPageHint: prefs.safeGet<bool>(_showPageHintKey) ?? def.showPageHint,
      showClock: prefs.safeGet<bool>(_showClockKey) ?? def.showClock,
      showNetwork: prefs.safeGet<bool>(_showNetworkKey) ?? def.showNetwork,
      showBattery: prefs.safeGet<bool>(_showBatteryKey) ?? def.showBattery,
      enablePageSpace: prefs.safeGet<bool>(_enablePageSpaceKey) ?? def.enablePageSpace,
      keepScreenOn: prefs.safeGet<bool>(_keepScreenOnKey) ?? def.keepScreenOn,
      fullscreen: prefs.safeGet<bool>(_fullscreenKey) ?? def.fullscreen,
      preloadCount: prefs.safeGet<int>(_preloadCountKey) ?? def.preloadCount,
    );
  }

  static Future<void> saveViewSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var setting = AppSetting.instance.view;
    await prefs.safeSet<int>(_viewDirectionKey, setting.viewDirection.toInt());
    await prefs.safeSet<bool>(_showPageHintKey, setting.showPageHint);
    await prefs.safeSet<bool>(_showClockKey, setting.showClock);
    await prefs.safeSet<bool>(_showNetworkKey, setting.showNetwork);
    await prefs.safeSet<bool>(_showBatteryKey, setting.showBattery);
    await prefs.safeSet<bool>(_enablePageSpaceKey, setting.enablePageSpace);
    await prefs.safeSet<bool>(_keepScreenOnKey, setting.keepScreenOn);
    await prefs.safeSet<bool>(_fullscreenKey, setting.fullscreen);
    await prefs.safeSet<int>(_preloadCountKey, setting.preloadCount);
  }

  // ==========
  // dl setting
  // ==========

  static const _invertDownloadOrderKey = BoolKey('AppSettingPrefs_invertDownloadOrder');
  static const _defaultToDeleteFilesKey = BoolKey('AppSettingPrefs_defaultToDeleteFiles');
  static const _downloadPagesTogetherKey = IntKey('AppSettingPrefs_downloadPagesTogether');
  static const _defaultToOnlineModeKey = BoolKey('AppSettingPrefs_defaultToOnlineMode');
  static const _usingDownloadedPageKey = BoolKey('AppSettingPrefs_usingDownloadedPage');

  static List<TypedKey> get dlSettingKeys => [
        _invertDownloadOrderKey,
        _defaultToDeleteFilesKey,
        _downloadPagesTogetherKey,
        _defaultToOnlineModeKey,
        _usingDownloadedPageKey,
      ];

  static Future<DlSetting> _loadDlSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var def = DlSetting.defaultSetting;
    return DlSetting(
      invertDownloadOrder: prefs.safeGet<bool>(_invertDownloadOrderKey) ?? def.invertDownloadOrder,
      defaultToDeleteFiles: prefs.safeGet<bool>(_defaultToDeleteFilesKey) ?? def.defaultToDeleteFiles,
      downloadPagesTogether: prefs.safeGet<int>(_downloadPagesTogetherKey) ?? def.downloadPagesTogether,
      defaultToOnlineMode: prefs.safeGet<bool>(_defaultToOnlineModeKey) ?? def.defaultToOnlineMode,
      usingDownloadedPage: prefs.safeGet<bool>(_usingDownloadedPageKey) ?? def.usingDownloadedPage,
    );
  }

  static Future<void> saveDlSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var setting = AppSetting.instance.dl;
    await prefs.safeSet<bool>(_invertDownloadOrderKey, setting.invertDownloadOrder);
    await prefs.safeSet<bool>(_defaultToDeleteFilesKey, setting.defaultToDeleteFiles);
    await prefs.safeSet<int>(_downloadPagesTogetherKey, setting.downloadPagesTogether);
    await prefs.safeSet<bool>(_defaultToOnlineModeKey, setting.defaultToOnlineMode);
    await prefs.safeSet<bool>(_usingDownloadedPageKey, setting.usingDownloadedPage);
  }

  // ==========
  // ui setting
  // ==========

  static const _defaultMangaOrderKey = IntKey('AppSettingPrefs_defaultMangaOrder');
  static const _defaultAuthorOrderKey = IntKey('AppSettingPrefs_defaultAuthorOrder');
  static const _enableCornerIconsKey = BoolKey('AppSettingPrefs_enableCornerIcons');
  static const _showMangaReadIconKey = BoolKey('AppSettingPrefs_showMangaReadIcon');
  static const _regularGroupRowsKey = IntKey('AppSettingPrefs_regularGroupRows');
  static const _otherGroupRowsKey = IntKey('AppSettingPrefs_otherGroupRows');
  static const _clickToSearchKey = BoolKey('AppSettingPrefs_clickToSearch');
  static const _includeUnreadInHomeKey = BoolKey('AppSettingPrefs_includeUnreadInHome');
  static const _audienceMangaRowsKey = IntKey('AppSettingPrefs_audienceMangaRows');
  static const _alwaysOpenNewListPageKey = BoolKey('AppSettingPrefs_alwaysOpenNewListPage');

  static List<TypedKey> get uiSettingKeys => [
        _defaultMangaOrderKey,
        _defaultAuthorOrderKey,
        _enableCornerIconsKey,
        _showMangaReadIconKey,
        _regularGroupRowsKey,
        _otherGroupRowsKey,
        _clickToSearchKey,
        _includeUnreadInHomeKey,
        _audienceMangaRowsKey,
        _alwaysOpenNewListPageKey,
      ];

  static Future<UiSetting> _loadUiSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var def = UiSetting.defaultSetting;
    return UiSetting(
      defaultMangaOrder: MangaOrderExtension.fromInt(prefs.safeGet<int>(_defaultMangaOrderKey) ?? def.defaultMangaOrder.toInt()),
      defaultAuthorOrder: AuthorOrderExtension.fromInt(prefs.safeGet<int>(_defaultAuthorOrderKey) ?? def.defaultAuthorOrder.toInt()),
      enableCornerIcons: prefs.safeGet<bool>(_enableCornerIconsKey) ?? def.enableCornerIcons,
      showMangaReadIcon: prefs.safeGet<bool>(_showMangaReadIconKey) ?? def.showMangaReadIcon,
      regularGroupRows: prefs.safeGet<int>(_regularGroupRowsKey) ?? def.regularGroupRows,
      otherGroupRows: prefs.safeGet<int>(_otherGroupRowsKey) ?? def.otherGroupRows,
      clickToSearch: prefs.safeGet<bool>(_clickToSearchKey) ?? def.clickToSearch,
      includeUnreadInHome: prefs.safeGet<bool>(_includeUnreadInHomeKey) ?? def.includeUnreadInHome,
      audienceRankingRows: prefs.safeGet<int>(_audienceMangaRowsKey) ?? def.audienceRankingRows,
      alwaysOpenNewListPage: prefs.safeGet<bool>(_alwaysOpenNewListPageKey) ?? def.alwaysOpenNewListPage,
    );
  }

  static Future<void> saveUiSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var setting = AppSetting.instance.ui;
    await prefs.safeSet<int>(_defaultMangaOrderKey, setting.defaultMangaOrder.toInt());
    await prefs.safeSet<int>(_defaultAuthorOrderKey, setting.defaultAuthorOrder.toInt());
    await prefs.safeSet<bool>(_enableCornerIconsKey, setting.enableCornerIcons);
    await prefs.safeSet<bool>(_showMangaReadIconKey, setting.showMangaReadIcon);
    await prefs.safeSet<int>(_regularGroupRowsKey, setting.regularGroupRows);
    await prefs.safeSet<int>(_otherGroupRowsKey, setting.otherGroupRows);
    await prefs.safeSet<bool>(_clickToSearchKey, setting.clickToSearch);
    await prefs.safeSet<bool>(_includeUnreadInHomeKey, setting.includeUnreadInHome);
    await prefs.safeSet<int>(_audienceMangaRowsKey, setting.audienceRankingRows);
    await prefs.safeSet<bool>(_alwaysOpenNewListPageKey, setting.alwaysOpenNewListPage);
  }

  // =============
  // other setting
  // =============

  static const _timeoutBehaviorKey = IntKey('AppSettingPrefs_timeoutBehavior');
  static const _dlTimeoutBehaviorKey = IntKey('AppSettingPrefs_dlTimeoutBehavior');
  static const _imgTimeoutBehaviorKey = IntKey('AppSettingPrefs_imgTimeoutBehavior');
  static const _enableLoggerKey = BoolKey('AppSettingPrefs_enableLogger');
  static const _showDebugErrorMsgKey = BoolKey('AppSettingPrefs_showDebugErrorMsg');
  static const _useNativeShareSheetKey = BoolKey('AppSettingPrefs_useNativeShareSheet');

  static List<TypedKey> get otherSettingKeys => [
        _timeoutBehaviorKey,
        _dlTimeoutBehaviorKey,
        _imgTimeoutBehaviorKey,
        _enableLoggerKey,
        _showDebugErrorMsgKey,
        _useNativeShareSheetKey,
      ];

  static Future<OtherSetting> _loadOtherSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var def = OtherSetting.defaultSetting;
    return OtherSetting(
      timeoutBehavior: TimeoutBehaviorExtension.fromInt(prefs.safeGet<int>(_timeoutBehaviorKey) ?? def.timeoutBehavior.toInt()),
      dlTimeoutBehavior: TimeoutBehaviorExtension.fromInt(prefs.safeGet<int>(_dlTimeoutBehaviorKey) ?? def.dlTimeoutBehavior.toInt()),
      imgTimeoutBehavior: TimeoutBehaviorExtension.fromInt(prefs.safeGet<int>(_imgTimeoutBehaviorKey) ?? def.imgTimeoutBehavior.toInt()),
      enableLogger: prefs.safeGet<bool>(_enableLoggerKey) ?? def.enableLogger,
      showDebugErrorMsg: prefs.safeGet<bool>(_showDebugErrorMsgKey) ?? def.showDebugErrorMsg,
      useNativeShareSheet: prefs.safeGet<bool>(_useNativeShareSheetKey) ?? def.useNativeShareSheet,
    );
  }

  static Future<void> saveOtherSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var setting = AppSetting.instance.other;
    await prefs.safeSet<int>(_timeoutBehaviorKey, setting.timeoutBehavior.toInt());
    await prefs.safeSet<int>(_dlTimeoutBehaviorKey, setting.dlTimeoutBehavior.toInt());
    await prefs.safeSet<int>(_imgTimeoutBehaviorKey, setting.imgTimeoutBehavior.toInt());
    await prefs.safeSet<bool>(_enableLoggerKey, setting.enableLogger);
    await prefs.safeSet<bool>(_showDebugErrorMsgKey, setting.showDebugErrorMsg);
    await prefs.safeSet<bool>(_useNativeShareSheetKey, setting.useNativeShareSheet);
  }

  // ===
  // ...
  // ===

  static Future<void> upgradeFromVer1To2(SharedPreferences prefs) async {
    var viewDef = ViewSetting.defaultSetting;
    await prefs.remove('SCROLL_DIRECTION');
    await prefs.safeMigrate<bool>('SHOW_PAGE_HINT', BoolKey('ViewSettingPrefs_showPageHint'), defaultValue: viewDef.showPageHint);
    await prefs.remove('USE_SWIPE_FOR_CHAPTER');
    await prefs.remove('USE_CLICK_FOR_CHAPTER');
    await prefs.remove('NEED_CHECK_FOR_CHAPTER');
    await prefs.safeMigrate<bool>('ENABLE_PAGE_SPACE', BoolKey('ViewSettingPrefs_enablePageSpace'), defaultValue: viewDef.enablePageSpace);
    await prefs.safeMigrate<int>('PRELOAD_COUNT', IntKey('ViewSettingPrefs_preloadCount'), defaultValue: viewDef.preloadCount);
  }

  static Future<void> upgradeFromVer2To3(SharedPreferences prefs) async {
    var viewDef = ViewSetting.defaultSetting;
    await prefs.safeMigrate<int>('ViewSettingPrefs_viewDirection', _viewDirectionKey, defaultValue: viewDef.viewDirection.toInt());
    await prefs.safeMigrate<bool>('ViewSettingPrefs_showPageHint', _showPageHintKey, defaultValue: viewDef.showPageHint);
    await prefs.safeMigrate<bool>('ViewSettingPrefs_showClock', _showClockKey, defaultValue: viewDef.showClock);
    await prefs.safeMigrate<bool>('ViewSettingPrefs_showNetwork', _showNetworkKey, defaultValue: viewDef.showNetwork);
    await prefs.safeMigrate<bool>('ViewSettingPrefs_showBattery', _showBatteryKey, defaultValue: viewDef.showBattery);
    await prefs.safeMigrate<bool>('ViewSettingPrefs_enablePageSpace', _enablePageSpaceKey, defaultValue: viewDef.enablePageSpace);
    await prefs.safeMigrate<bool>('ViewSettingPrefs_keepScreenOn', _keepScreenOnKey, defaultValue: viewDef.keepScreenOn);
    await prefs.safeMigrate<bool>('ViewSettingPrefs_fullscreen', _fullscreenKey, defaultValue: viewDef.fullscreen);
    await prefs.safeMigrate<int>('ViewSettingPrefs_preloadCount', _preloadCountKey, defaultValue: viewDef.preloadCount);

    var dlDef = DlSetting.defaultSetting;
    await prefs.safeMigrate<bool>('DlSettingPrefs_invertDownloadOrder', _invertDownloadOrderKey, defaultValue: dlDef.invertDownloadOrder);
    await prefs.safeMigrate<bool>('DlSettingPrefs_defaultToDeleteFiles', _defaultToDeleteFilesKey, defaultValue: dlDef.defaultToDeleteFiles);
    await prefs.safeMigrate<int>('DlSettingPrefs_downloadPagesTogether', _downloadPagesTogetherKey, defaultValue: dlDef.downloadPagesTogether);
    await prefs.safeMigrate<bool>('GlbSetting_usingDownloadedPage', _usingDownloadedPageKey, defaultValue: dlDef.usingDownloadedPage);

    var otherDef = OtherSetting.defaultSetting;
    await prefs.safeMigrate<int>('GlbSetting_timeoutBehavior', _timeoutBehaviorKey, defaultValue: otherDef.timeoutBehavior.toInt());
    await prefs.safeMigrate<int>('GlbSetting_dlTimeoutBehavior', _dlTimeoutBehaviorKey, defaultValue: otherDef.dlTimeoutBehavior.toInt());
    await prefs.safeMigrate<bool>('GlbSetting_enableLogger', _enableLoggerKey, defaultValue: otherDef.enableLogger);
  }
}
