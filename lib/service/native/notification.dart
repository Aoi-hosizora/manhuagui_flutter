import 'dart:convert';

import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/service/native/notification_handler.dart';

class NotificationManager with NotificationHandlerMixin {
  NotificationManager._();

  static NotificationManager? _instance;

  static NotificationManager get instance {
    _instance ??= NotificationManager._();
    return _instance!;
  }

  FlutterLocalNotificationsPlugin? _plugin; // global FlutterLocalNotificationsPlugin instance

  Future<FlutterLocalNotificationsPlugin> getPlugin() async {
    if (_plugin == null) {
      _plugin = FlutterLocalNotificationsPlugin();
      await _plugin!.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestPermission();
      await _plugin!.initialize(
        InitializationSettings(
          android: AndroidInitializationSettings('flutter_icon'),
        ),
        onSelectNotification: _onNotificationSelected,
      );
    }
    return _plugin!;
  }

  @pragma('vm:entry-point')
  static void _onNotificationSelected(String? payloadString) {
    var payload = NotificationPayload.fromString(payloadString ?? '{}');
    if (payload != null) {
      NotificationHandlerMixin.handleSelectedEvent(
        channelId: payload.channelId,
        messageId: payload.messageId,
        messageTag: payload.messageTag,
        arguments: payload.arguments,
      );
    }
  }

  static const progressCategory = 'progress';
  static const statusCategory = 'status';
  static const errCategory = 'err';

  static AndroidNotificationDetails _buildSilentNotificationDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
    String? icon,
    String? largeIcon,
    String? subText,
    String? ticker,
    String? tag,
    bool autoCancel = true,
    bool ongoing = false,
    bool showProgress = false,
    bool indeterminate = false,
    int maxProgress = 0,
    int progress = 0,
    String? category,
  }) {
    // https://pub.dev/packages/flutter_local_notifications#-usage
    // https://developer.android.com/reference/android/R.drawable#stat_sys_download
    // https://github.com/xiaojieonly/Ehviewer_CN_SXJ/blob/1.9.2/app/src/main/java/com/hippo/ehviewer/download/DownloadService.java#L218
    // https://github.com/MaikuB/flutter_local_notifications/blob/flutter_local_notifications-v12.0.3/flutter_local_notifications/lib/src/platform_specifics/android/categories.dart
    return AndroidNotificationDetails(
      /* channel */
      channelId,
      channelName,
      channelDescription: channelDescription,
      /* data */
      icon: icon,
      largeIcon: largeIcon == null ? null : DrawableResourceAndroidBitmap(largeIcon),
      subText: subText,
      ticker: ticker,
      tag: tag,
      autoCancel: autoCancel,
      ongoing: ongoing,
      showProgress: showProgress,
      indeterminate: indeterminate,
      maxProgress: maxProgress,
      progress: progress,
      category: category,
      /* silent setting */
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: false,
      showWhen: true,
      usesChronometer: false,
      channelShowBadge: false,
      enableLights: false,
      timeoutAfter: null,
      fullScreenIntent: false,
      colorized: false,
      channelAction: AndroidNotificationChannelAction.createIfNotExists,
      visibility: NotificationVisibility.secret,
    );
  }

  static const mipMapIcLaunch = '@mipmap/ic_launcher';
  static const drawableStatDownload = '@android:drawable/stat_sys_download';
  static const drawableStatDownloadDone = '@android:drawable/stat_sys_download_done';

  Future<bool> showDownloadChannelNotification({
    required int id,
    required String title,
    String? body,
    String? subText,
    String? ticker,
    String? tag,
    Object? payloadArguments,
    String? icon,
    String? largeIcon,
    bool autoCancel = true,
    bool ongoing = false,
    bool showProgress = false,
    bool indeterminate = false,
    int maxProgress = 0,
    int progress = 0,
    String? category,
  }) async {
    var plugin = await getPlugin();
    try {
      await plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: _buildSilentNotificationDetails(
            channelId: DL_NTFC_ID,
            channelName: DL_NTFC_NAME,
            channelDescription: DL_NTFC_DESCRIPTION,
            subText: subText,
            ticker: ticker,
            tag: tag,
            icon: icon,
            largeIcon: largeIcon,
            autoCancel: autoCancel,
            ongoing: ongoing,
            showProgress: showProgress,
            indeterminate: indeterminate,
            maxProgress: maxProgress,
            progress: progress,
            category: category,
          ),
        ),
        payload: NotificationPayload(
          channelId: DL_NTFC_ID,
          messageId: id,
          messageTag: tag,
          arguments: payloadArguments,
        ).buildString(),
      );
      return true;
    } catch (e, s) {
      globalLogger.e('showDownloadChannelNotification', e, s);
      return false;
    }
  }

  Future<bool> cancelNotification({required int id, String? tag}) async {
    var plugin = await getPlugin();
    try {
      await plugin.cancel(id, tag: tag);
      return true;
    } catch (e, s) {
      globalLogger.e('cancelNotification', e, s);
      return false;
    }
  }
}

class NotificationPayload {
  const NotificationPayload({
    required this.channelId,
    required this.messageId,
    this.messageTag,
    this.arguments,
  });

  final String channelId;
  final int messageId;
  final String? messageTag;
  final Object? arguments;

  String buildString() {
    var m = <String, dynamic>{
      'channelId': channelId,
      'messageId': messageId,
      'messageTag': messageTag,
      'arguments': arguments,
    };
    return json.encode(m);
  }

  static NotificationPayload? fromString(String payload) {
    try {
      var m = json.decode(payload) as Map<String, dynamic>;
      var channelId = m['channelId'];
      var messageId = m['messageId'];
      var messageTag = m['messageTag'];
      var arguments = m['arguments'];
      if (channelId == null || messageId == null) {
        return null;
      }
      return NotificationPayload(
        channelId: channelId,
        messageId: messageId,
        messageTag: messageTag,
        arguments: arguments,
      );
    } catch (_) {
      return null;
    }
  }
}
