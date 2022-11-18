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
