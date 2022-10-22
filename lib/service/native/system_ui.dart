import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void setDefaultSystemUIOverlayStyle() async {
  setSystemUIOverlayStyle();
}

void setSystemUIOverlayStyle({
  // status bar
  Color? statusBarColor,
  Brightness? statusBarBrightness,
  Brightness? statusBarIconBrightness,
  // navigation bar
  Color? navigationBarColor,
  Brightness? navigationBarIconBrightness,
  Color? navigationBarDividerColor,
}) async {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: statusBarColor /* Colors.transparent */,
      statusBarBrightness: statusBarBrightness ?? Brightness.dark,
      statusBarIconBrightness: statusBarIconBrightness ?? Brightness.light,
      systemNavigationBarColor: navigationBarColor ?? Color.fromRGBO(250, 250, 250, 1.0),
      systemNavigationBarIconBrightness: navigationBarIconBrightness ?? Brightness.dark,
      systemNavigationBarDividerColor: navigationBarDividerColor ?? Color.fromRGBO(250, 250, 250, 1.0),
    ),
  );
}

Future<void> setEdgeToEdgeSystemUIMode() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: SystemUiOverlay.values);
}

Future<void> setManualSystemUIMode(List<SystemUiOverlay> overlays) async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: overlays);
}
