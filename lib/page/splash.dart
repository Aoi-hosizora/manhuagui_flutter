import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/message.dart';
import 'package:manhuagui_flutter/page/page/glb_setting.dart';
import 'package:manhuagui_flutter/page/view/message_dialog.dart';
import 'package:manhuagui_flutter/service/db/db_manager.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/native/android.dart';
import 'package:manhuagui_flutter/service/native/notification.dart';
import 'package:manhuagui_flutter/service/prefs/glb_setting.dart';
import 'package:manhuagui_flutter/service/prefs/message.dart';
import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:permission_handler/permission_handler.dart';

/// Splash 页 (flutter_native_splash)
class SplashPage extends StatefulWidget {
  const SplashPage({
    Key? key,
    required this.home,
  }) : super(key: key);

  final Widget home;

  @override
  State<SplashPage> createState() => _SplashPageState();

  static void preserve(WidgetsBinding widgetsBinding) => FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  static void remove() => FlutterNativeSplash.remove();

  static Future<void> prepare() async {
    // 1. check permission
    var ok = await _checkPermission();
    if (!ok) {
      Fluttertoast.showToast(msg: '权限授予失败，Manhuagui 即将退出');
      SystemNavigator.pop();
    }

    // 2. upgrade db and prefs
    await DBManager.instance.getDB();
    await PrefsManager.instance.loadPrefs();

    // 3. update global setting
    var setting = await GlbSettingPrefs.getSetting();
    GlbSetting.updateGlobalSetting(setting);
  }

  static Future<bool> _checkPermission() async {
    if (!(await Permission.storage.status).isGranted) {
      var r = await Permission.storage.request();
      return r.isGranted;
    }
    return true;
  }

  static void prepareWithContext(BuildContext context) async {
    // 1. register context for notification
    NotificationManager.instance.registerContext(context);

    // 2. check message asynchronously
    _checkLatestMessage(context);

    // 3. check auth asynchronously
    Future.microtask(() async {
      var r = await AuthManager.instance.check();
      if (!r.logined && r.error != null) {
        Fluttertoast.showToast(msg: '无法检查登录状态：${r.error!.text}');
      }
    });
  }

  static Future<void> _checkLatestMessage(BuildContext context) async {
    var readMessages = await MessagePrefs.getReadMessages();
    final client = RestClient(DioManager.instance.dio);
    LatestMessage lm;
    try {
      var result = await client.getLatestMessage();
      lm = result.data;
    } catch (e, s) {
      wrapError(e, s); // ignored
      return;
    }

    if (lm.mustUpgradeNewVersion != null && isVersionNewer(lm.mustUpgradeNewVersion!.newVersion!.version, APP_VERSION) == true) {
      await showNewVersionDialog(context: context, newVersion: lm.mustUpgradeNewVersion!);
    }
    if (lm.notDismissibleNotification != null && !readMessages.contains(lm.notDismissibleNotification!.mid)) {
      await showNotificationDialog(context: context, notification: lm.notDismissibleNotification!);
    }
    if (lm.newVersion != null && !readMessages.contains(lm.newVersion!.mid) && isVersionNewer(lm.newVersion!.newVersion!.version, APP_VERSION) == true) {
      await showNewVersionDialog(context: context, newVersion: lm.newVersion!);
    }
    if (lm.notification != null && !readMessages.contains(lm.notification!.mid)) {
      await showNotificationDialog(context: context, notification: lm.notification!);
    }
  }
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      // remove native splash page first
      SplashPage.remove();

      // prepare asynchronously
      SplashPage.prepareWithContext(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.home;
  }
}
