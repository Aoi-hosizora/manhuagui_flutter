import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/service/native/system_ui.dart';

class SplashPage {
  static void preserve(WidgetsBinding widgetsBinding) {
    setDefaultSystemUIOverlayStyle();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  static void remove() {
    FlutterNativeSplash.remove();
  }

  static Future<void> prepare() async {
    // TODO
    await Future.delayed(Duration(seconds: 1));
    Fluttertoast.cancel();
    Fluttertoast.showToast(msg: '3');
    
    await Future.delayed(Duration(seconds: 1));
    Fluttertoast.cancel();
    Fluttertoast.showToast(msg: '2');
    
    await Future.delayed(Duration(seconds: 1));
    Fluttertoast.cancel();
    Fluttertoast.showToast(msg: '1');
    
    await Future.delayed(Duration(seconds: 1));
    Fluttertoast.cancel();
    Fluttertoast.showToast(msg: 'Done!');
  }
}
