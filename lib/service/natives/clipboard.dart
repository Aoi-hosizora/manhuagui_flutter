import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

Future<void> copyText(
  String text, {
  bool showToast = true,
  Function()? callback,
}) {
  var data = ClipboardData(text: text);
  return Clipboard.setData(data).then((_) {
    if (showToast) {
      Fluttertoast.showToast(msg: '$text 已经复制到剪贴板');
    }
    callback?.call();
  }).onError((_, __) {});
}
