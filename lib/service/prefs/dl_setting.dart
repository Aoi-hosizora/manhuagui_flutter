import 'package:manhuagui_flutter/page/page/dl_setting.dart';
import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DlSettingPrefs {
  DlSettingPrefs._();

  static const _invertDownloadOrderKey = 'DlSettingPrefs_invertDownloadOrder'; // int
  static const _defaultToDeleteFilesKey = 'DlSettingPrefs_defaultToDeleteFiles'; // bool
  static const _downloadPagesTogetherKey = 'DlSettingPrefs_downloadPagesTogether'; // int

  static Future<DlSetting> getSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var def = DlSetting.defaultSetting();
    return DlSetting(
      invertDownloadOrder: prefs.safeGetBool(_invertDownloadOrderKey) ?? def.invertDownloadOrder,
      defaultToDeleteFiles: prefs.safeGetBool(_defaultToDeleteFilesKey) ?? def.defaultToDeleteFiles,
      downloadPagesTogether: prefs.safeGetInt(_downloadPagesTogetherKey) ?? def.downloadPagesTogether,
    );
  }

  static Future<void> setSetting(DlSetting setting) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    await prefs.setBool(_invertDownloadOrderKey, setting.invertDownloadOrder);
    await prefs.setBool(_defaultToDeleteFilesKey, setting.defaultToDeleteFiles);
    await prefs.setInt(_downloadPagesTogetherKey, setting.downloadPagesTogether);
  }

  static Future<void> upgradeFromVer1To2(SharedPreferences prefs) async {
    // pass
  }

  static Future<void> upgradeFromVer2To3(SharedPreferences prefs) async {
    // pass
  }
}
