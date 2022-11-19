import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/message.dart';
import 'package:manhuagui_flutter/service/native/android.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/service/prefs/message.dart';

Future<void> showNewVersionDialog({
  required BuildContext context,
  required Message newVersion,
  void Function()? onChanged,
}) async {
  var msg = newVersion;
  var cnt = newVersion.newVersion!;
  var needUpgrade = isVersionNewer(cnt.version, APP_VERSION) == true;
  var hasRead = (await MessagePrefs.getReadMessages()).contains(msg.mid);

  var canceled = await showDialog<bool>(
    context: context,
    barrierDismissible: !needUpgrade || !cnt.mustUpgrade,
    builder: (c) => WillPopScope(
      onWillPop: () async => !needUpgrade || !cnt.mustUpgrade,
      child: AlertDialog(
        title: Text('${cnt.version} 版本可用'),
        scrollable: true,
        content: SizedBox(
          width: MediaQuery.of(context).size.width - (MediaQuery.of(context).padding + kDialogDefaultInsetPadding + kAlertDialogDefaultContentPadding).horizontal,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '发布于：${msg.createdAtString}',
                style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 13, color: Colors.grey),
              ),
              if (msg.createdAt != msg.updatedAt)
                Text(
                  '更新于：${msg.updatedAtString}',
                  style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 13, color: Colors.grey),
                ),
              SizedBox(height: kDividerDefaultHeight),
              Text(
                cnt.changeLogs.isEmpty ? '无版本更新日志' : cnt.changeLogs,
              ),
            ],
          ),
        ),
        actions: [
          if (!needUpgrade) ...[
            TextButton(
              child: Text('无需更新'),
              onPressed: () => Navigator.of(c).pop(false),
            ),
            TextButton(
              child: Text('查看详情'),
              onPressed: () => launchInBrowser(context: context, url: cnt.releasePage),
            ),
          ],
          if (needUpgrade) ...[
            TextButton(
              child: Text('去更新'),
              onPressed: () async {
                launchInBrowser(context: context, url: cnt.releasePage);
                await MessagePrefs.addReadMessage(msg.mid); // <<< set to read first
                onChanged?.call();
              },
            ),
            if (!cnt.mustUpgrade)
              TextButton(
                child: Text('忽略该版本'),
                onPressed: () => Navigator.of(c).pop(false),
              ),
            if (!hasRead && !cnt.mustUpgrade)
              TextButton(
                child: Text('下次提醒我'),
                onPressed: () => Navigator.of(c).pop(true),
              ),
            if (cnt.mustUpgrade)
              TextButton(
                child: Text('退出应用'),
                onPressed: () => SystemNavigator.pop(),
              ),
          ],
        ],
      ),
    ),
  );

  if (canceled != true) {
    await MessagePrefs.addReadMessage(msg.mid);
    onChanged?.call();
  }
}

Future<void> showNotificationDialog({
  required BuildContext context,
  required Message notification,
  void Function()? onChanged,
}) async {
  var msg = notification;
  var cnt = notification.notification!;
  var hasRead = (await MessagePrefs.getReadMessages()).contains(msg.mid);

  var canceled = await showDialog<bool>(
    context: context,
    barrierDismissible: hasRead || cnt.dismissible,
    builder: (c) => WillPopScope(
      onWillPop: () async => hasRead || cnt.dismissible,
      child: AlertDialog(
        title: Text(msg.title),
        scrollable: true,
        content: SizedBox(
          width: MediaQuery.of(context).size.width - (MediaQuery.of(context).padding + kDialogDefaultInsetPadding + kAlertDialogDefaultContentPadding).horizontal,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '发布于：${msg.createdAtString}',
                style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 13, color: Colors.grey),
              ),
              if (msg.createdAt != msg.updatedAt)
                Text(
                  '更新于：${msg.updatedAtString}',
                  style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 13, color: Colors.grey),
                ),
              SizedBox(height: kDividerDefaultHeight),
              Text(cnt.content),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('已阅读'),
            onPressed: () => Navigator.of(c).pop(false),
          ),
          if (cnt.link.trim().isNotEmpty)
            TextButton(
              child: Text('查看详情'),
              onPressed: () => launchInBrowser(context: context, url: cnt.link.trim()),
            ),
          if (!hasRead && cnt.dismissible)
            TextButton(
              child: Text('下次提醒我'),
              onPressed: () => Navigator.of(c).pop(true),
            ),
          if (!hasRead && !cnt.dismissible)
            TextButton(
              child: Text('退出应用'),
              onPressed: () => SystemNavigator.pop(),
            ),
        ],
      ),
    ),
  );

  if (canceled != true) {
    await MessagePrefs.addReadMessage(msg.mid);
    onChanged?.call();
  }
}
