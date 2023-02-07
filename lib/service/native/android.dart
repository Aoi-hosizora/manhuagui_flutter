import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';

// =======
// version
// =======

int? _androidSDKVersion;

Future<bool> lowerThanAndroidQ() async {
  _androidSDKVersion ??= (await DeviceInfoPlugin().androidInfo).version.sdkInt!;
  return Platform.isAndroid && _androidSDKVersion! < 29; // SDK 29 => Android 10 (Q)
}

Future<bool> lowerThanAndroidR() async {
  _androidSDKVersion ??= (await DeviceInfoPlugin().androidInfo).version.sdkInt!;
  return Platform.isAndroid && _androidSDKVersion! < 30; // SDK 30 => Android 11 (R)
}

bool? isVersionNewer(String ver1, String ver2) {
  var re = RegExp('[vV]?(\\d+)\\.(\\d+)\\.(\\d+)(?:[\\.|\\+](\\d+))?'); // 0.0.0 / 0.0.0.0 / 0.0.0+0
  var match1 = re.firstMatch(ver1);
  var match2 = re.firstMatch(ver2);
  if (match1 == null || match2 == null) {
    return null;
  }

  var ver1P1 = int.tryParse(match1[1] ?? '0') ?? 0;
  var ver1P2 = int.tryParse(match1[2] ?? '0') ?? 0;
  var ver1P3 = int.tryParse(match1[3] ?? '0') ?? 0;
  var ver1P4 = int.tryParse(match1[4] ?? '0') ?? 0;

  var ver2P1 = int.tryParse(match2[1] ?? '0') ?? 0;
  var ver2P2 = int.tryParse(match2[2] ?? '0') ?? 0;
  var ver2P3 = int.tryParse(match2[3] ?? '0') ?? 0;
  var ver2P4 = int.tryParse(match2[4] ?? '0') ?? 0;

  if (ver1P1 > ver2P1) {
    return true;
  }
  if (ver1P1 == ver2P1 && ver1P2 > ver2P2) {
    return true;
  }
  if (ver1P1 == ver2P1 && ver1P2 == ver2P2 && ver1P3 > ver2P3) {
    return true;
  }
  if (ver1P1 == ver2P1 && ver1P2 == ver2P2 && ver1P3 == ver2P3 && ver1P4 > ver2P4) {
    return true;
  }
  return false;
}

// ==============
// native channel
// ==============

const _channelName = 'com.aoihosizora.manhuagui';
const _channel = MethodChannel(_channelName);
const _restartAppMethodName = 'restartApp';
const _insertMediaMethodName = 'insertMedia';
const _shareTextMethodName = 'shareText';
const _shareFileMethodName = 'shareFile';

Future<void> restartApp() async {
  if (Platform.isAndroid) {
    try {
      await _channel.invokeMethod(_restartAppMethodName);
    } catch (_) {}
  }
}

Future<void> addToGallery(File file) async {
  if (Platform.isAndroid) {
    try {
      // Intent.ACTION_MEDIA_SCANNER_SCAN_FILE
      await _channel.invokeMethod(_insertMediaMethodName, <String, dynamic>{
        'filepath': file.path,
      });
    } catch (_) {}
  }
}

Future<void> shareText({required String text, String? title}) async {
  if (Platform.isAndroid) {
    try {
      // Intent.ACTION_SEND, Intent.ACTION_CHOOSER
      await _channel.invokeMethod(_shareTextMethodName, <String, dynamic>{
        'shareText': text,
        'shareTitle': title,
        'chooserTitle': AppSetting.instance.other.useNativeShareSheet ? null : '',
      });
    } catch (_) {}
  }
}

Future<void> shareFile({required String filepath, String type = '*/*', String? text, String? title}) async {
  if (Platform.isAndroid) {
    try {
      // Intent.ACTION_SEND, Intent.ACTION_CHOOSER
      await _channel.invokeMethod(_shareFileMethodName, <String, dynamic>{
        'filepath': filepath,
        'fileType': type,
        'shareText': text,
        'shareTitle': title,
        'chooserTitle': AppSetting.instance.other.useNativeShareSheet ? null : '',
      });
    } catch (_) {}
  }
}
