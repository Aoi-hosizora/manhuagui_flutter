import 'package:flutter_share/flutter_share.dart';

Future<bool> shareText({
  String? title,
  String? text,
}) async {
  var shared = await FlutterShare.share(
    title: title ?? '无标题',
    text: text,
    linkUrl: null,
    chooserTitle: null,
  );
  return shared ?? false;
}
