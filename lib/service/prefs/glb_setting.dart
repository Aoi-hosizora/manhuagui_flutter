import 'package:manhuagui_flutter/page/page/glb_setting.dart';
import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlbSettingPrefs {
  GlbSettingPrefs._();

  static const _timeoutBehaviorKey = 'GlbSetting_timeoutBehavior'; // int
  static const _dlTimeoutBehaviorKey = 'GlbSetting_dlTimeoutBehavior'; // int
  static const _enableLoggerKey = 'GlbSetting_enableLogger'; // bool

  static Future<GlbSetting> getSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var def = GlbSetting.defaultSetting();
    return GlbSetting(
      timeoutBehavior: TimeoutBehaviorExtension.fromInt(prefs.safeGetInt(_timeoutBehaviorKey) ?? def.timeoutBehavior.toInt()),
      dlTimeoutBehavior: TimeoutBehaviorExtension.fromInt(prefs.safeGetInt(_dlTimeoutBehaviorKey) ?? def.dlTimeoutBehavior.toInt()),
      enableLogger: prefs.safeGetBool(_enableLoggerKey) ?? def.enableLogger,
    );
  }

  static Future<void> setSetting(GlbSetting setting) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    await prefs.setInt(_timeoutBehaviorKey, setting.timeoutBehavior.toInt());
    await prefs.setInt(_dlTimeoutBehaviorKey, setting.dlTimeoutBehavior.toInt());
    await prefs.setBool(_enableLoggerKey, setting.enableLogger);
  }

  static Future<void> upgradeFromVer1To2(SharedPreferences prefs) async {
    // pass
  }
}
