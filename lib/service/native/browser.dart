import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

Future<void> launchInBrowser({
  required BuildContext context,
  required String url,
  bool useLaunch = false,
  LaunchMode launchMode = LaunchMode.externalApplication,
}) async {
  if (useLaunch) {
    try {
      await launchUrlString(url, mode: launchMode);
    } catch (_) {}
    return;
  }

  try {
    await FlutterWebBrowser.openWebPage(
      url: url,
      customTabsOptions: CustomTabsOptions(
        defaultColorSchemeParams: CustomTabsColorSchemeParams(
          toolbarColor: Theme.of(context).primaryColor,
        ),
        shareState: CustomTabsShareState.on,
        instantAppsEnabled: false,
        showTitle: true,
        urlBarHidingEnabled: true,
      ),
    );
  } catch (_) {}
}

Future<void> launchInEmail({
  required String email,
  String subject = '',
  String body = '',
}) async {
  email = Uri.encodeComponent(email);
  subject = Uri.encodeComponent(subject);
  body = Uri.encodeComponent(body);
  var url = Uri.parse('mailto:$email?subject=$subject&body=$body');
  try {
    await launchUrl(url);
  } catch (_) {}
}
