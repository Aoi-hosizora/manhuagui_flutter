import 'package:flutter_share/flutter_share.dart';

Future<bool> shareText({
  required String title,
  String? text,
  String? link,
}) async {
  var shared = await FlutterShare.share(
    title: title,
    linkUrl: link,
    text: text,
    chooserTitle: null,
  );
  return shared ?? false;
}
