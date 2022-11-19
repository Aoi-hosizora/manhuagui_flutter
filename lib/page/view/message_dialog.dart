import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/message.dart';
import 'package:manhuagui_flutter/service/native/android.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/service/prefs/message.dart';

Future<void> showNewVersionDialog({required BuildContext context, required Message newVersion}) async {
  var msg = newVersion;
  var cnt = newVersion.newVersion!;
  var needUpgrade = isVersionNewer(cnt.version, APP_VERSION) == true;

  await showDialog(
    context: context,
    barrierDismissible: !needUpgrade || !cnt.mustUpgrade,
    builder: (c) => AlertDialog(
      title: Text('${cnt.version} 版本可用，是否更新？'),
      content: Text(cnt.changeLogs),
      actions: !needUpgrade
          ? [
              TextButton(
                child: Text('已阅读'),
                onPressed: () async {
                  await MessagePrefs.addReadMessage(msg.mid);
                  Navigator.of(c).pop();
                },
              ),
            ]
          : [
              TextButton(
                child: Text('去更新'),
                onPressed: () async {
                  await MessagePrefs.addReadMessage(msg.mid);
                  launchInBrowser(context: context, url: cnt.releasePage);
                },
              ),
              if (!cnt.mustUpgrade) ...[
                TextButton(
                  child: Text('忽略该版本'),
                  onPressed: () async {
                    await MessagePrefs.addReadMessage(msg.mid);
                    Navigator.of(c).pop();
                  },
                ),
                TextButton(
                  child: Text('下次提醒我'),
                  onPressed: () => Navigator.of(c).pop(),
                ),
              ],
              if (cnt.mustUpgrade)
                TextButton(
                  child: Text('退出应用'),
                  onPressed: () => SystemNavigator.pop(),
                ),
            ],
    ),
  );
}

Future<void> showNotificationDialog({required BuildContext context, required Message notification}) async {
  var msg = notification;
  var cnt = notification.notification!;
  var hasRead = (await MessagePrefs.getReadMessages()).contains(msg.mid);

  await showDialog(
    context: context,
    barrierDismissible: hasRead || cnt.dismissible,
    builder: (c) => AlertDialog(
      title: Text(msg.title),
      content: Text(cnt.content),
      actions: [
        TextButton(
          child: Text('已阅读'),
          onPressed: () async {
            await MessagePrefs.addReadMessage(msg.mid);
            Navigator.of(c).pop();
          },
        ),
        if (cnt.link.isNotEmpty)
          TextButton(
            child: Text('查看详情'),
            onPressed: () async {
              await MessagePrefs.addReadMessage(msg.mid);
              launchInBrowser(context: context, url: cnt.link);
            },
          ),
        if (!hasRead && cnt.dismissible)
          TextButton(
            child: Text('下次提醒我'),
            onPressed: () => Navigator.of(c).pop(),
          ),
        if (!hasRead && !cnt.dismissible)
          TextButton(
            child: Text('退出应用'),
            onPressed: () => SystemNavigator.pop(),
          ),
      ],
    ),
  );
}
