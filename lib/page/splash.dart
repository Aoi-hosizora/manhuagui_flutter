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

    // 2. update global setting
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
    // 1. check message asynchronously
    _checkMessage(context);

    // 2. check auth asynchronously
    Future.microtask(() async {
      var r = await AuthManager.instance.check();
      if (!r.logined && r.error != null) {
        Fluttertoast.showToast(msg: '无法检查登录状态：${r.error!.text}');
      }
    });
  }

  static Future<void> _checkMessage(BuildContext context) async {
    // TODO
    await showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text('TODO'),
        content: Text('TODO'),
        actions: [
          TextButton(
            child: Text('TODO'),
            onPressed: () => Navigator.of(c).pop(),
          ),
        ],
      ),
    );
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
