import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

bool? _lowerThanAndroidQ;

Future<bool> lowerThanAndroidQ() async {
  _lowerThanAndroidQ ??= Platform.isAndroid && (await DeviceInfoPlugin().androidInfo).version.sdkInt! < 29; // SDK 29 => Android 10
  return _lowerThanAndroidQ!;
}

bool? _lowerThanAndroidR;

Future<bool> lowerThanAndroidR() async {
  _lowerThanAndroidR ??= Platform.isAndroid && (await DeviceInfoPlugin().androidInfo).version.sdkInt! < 30; // SDK 30 => Android 11
  return _lowerThanAndroidR!;
}

bool? isVersionNewer(String ver1, String ver2) {
  var re = RegExp('v?(\\d+)\\.(\\d+)\\.(\\d+)(?:[\\.|\\+](\\d+))?'); // 0.0.0 / 0.0.0.0 / 0.0.0+0
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
