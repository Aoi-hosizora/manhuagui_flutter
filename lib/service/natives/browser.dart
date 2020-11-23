import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';

Future<void> launchInBrowser({
  @required BuildContext context,
  @required String url,
}) async {
  try {
    return await FlutterWebBrowser.openWebPage(
      url: url,
      customTabsOptions: CustomTabsOptions(
        toolbarColor: Theme.of(context).primaryColor,
      ),
    );
  } catch (ex) {
    return Future.error(ex);
  }
}
