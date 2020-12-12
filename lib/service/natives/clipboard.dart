import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void copyText({
  @required String text,
  void Function() onSuccess,
  void Function(dynamic) onError,
}) async {
  var data = ClipboardData(text: text);
  await Clipboard.setData(data).then((_) {
    onSuccess?.call();
  }).catchError((err) {
    onError?.call(err);
  });
}
