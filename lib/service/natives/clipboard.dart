import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

Future<void> copyText(
  String text, {
  bool showToast = true,
}) async {
  var data = ClipboardData(text: text);
  try {
    await Clipboard.setData(data);
    if (showToast) {
      Fluttertoast.showToast(msg: '$text 已经复制到剪贴板');
    }
  } catch (_) {}
}
