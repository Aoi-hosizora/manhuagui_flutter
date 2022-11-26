import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:manhuagui_flutter/config.dart';

class NotificationManager {
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
        InitializationSettings(android: AndroidInitializationSettings('flutter_icon')),
        onSelectNotification: _onNotificationSelected,
      );
    }
    return _plugin!;
  }

  // ===============
  // handler related
  // ===============

  static BuildContext? _hackedContext; // global BuildContext instance

  void registerContext(BuildContext context) {
    _hackedContext = context;
  }

  static final _registeredHandlers = <NotificationHandler>[]; // global handlers list instance

  void registerHandler(NotificationHandler handler) {
    _registeredHandlers.add(handler);
  }

  @pragma('vm:entry-point')
  static void _onNotificationSelected(String? payloadString) {
    var payload = _NotificationPayload.fromJson(payloadString);
    if (payload != null) {
      for (var handler in _registeredHandlers) {
        if (handler.check(_hackedContext, payload.channelId, payload.messageId, payload.messageTag, payload.arguments)) {
          handler.select(_hackedContext, payload.channelId, payload.messageId, payload.messageTag, payload.arguments);
          break;
        }
      }
    }
  }

  // =======================
  // show and cancel related
  // =======================

  Future<bool> showNotification({required int id, String? title, String? body, required AndroidNotificationDetails details, Object? arguments}) async {
    try {
      var plugin = await getPlugin();
      var payload = _NotificationPayload(details.channelId, id, details.tag, arguments).toJson();
      await plugin.show(id, title, body, NotificationDetails(android: details), payload: payload);
      return true;
    } catch (e, s) {
      globalLogger.e('showNotification', e, s);
      return false;
    }
  }

  Future<bool> cancelNotification({required int id, String? tag}) async {
    try {
      var plugin = await getPlugin();
      await plugin.cancel(id, tag: tag);
      return true;
    } catch (e, s) {
      globalLogger.e('cancelNotification', e, s);
      return false;
    }
  }

  // =======
  // helpers
  // =======

  static const downloadChannel = NotificationChannel._(DL_NTFC_ID, DL_NTFC_NAME, DL_NTFC_DESCRIPTION);

  static const progressCategory = 'progress';
  static const statusCategory = 'status';
  static const errCategory = 'err';

  static const mipMapIcLaunch = '@mipmap/ic_launcher';
  static const drawableStatSysDownload = '@android:drawable/stat_sys_download';
  static const drawableStatSysDownloadDone = '@android:drawable/stat_sys_download_done';

  static AndroidNotificationDetails buildSilentDetails({
    required NotificationChannel channel,
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
      channel.id,
      channel.name,
      channelDescription: channel.description,
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
}

abstract class NotificationHandler {
  NotificationHandler();

  bool check(BuildContext? context, String channelId, int messageId, String? messageTag, Object? arguments);

  void select(BuildContext? context, String channelId, int messageId, String? messageTag, Object? arguments);
}

class NotificationChannel {
  const NotificationChannel._(this.id, this.name, this.description);

  final String id;
  final String name;
  final String description;
}

class _NotificationPayload {
  const _NotificationPayload(this.channelId, this.messageId, this.messageTag, this.arguments);

  final String channelId;
  final int messageId;
  final String? messageTag;
  final Object? arguments;

  String toJson() {
    var m = <String, dynamic>{'channel_id': channelId, 'message_id': messageId, 'message_tag': messageTag, 'arguments': arguments};
    return json.encode(m);
  }

  static _NotificationPayload? fromJson(String? s) {
    try {
      var m = json.decode(s ?? '{}') as Map<String, dynamic>;
      var channelId = m['channel_id'];
      var messageId = m['message_id'];
      var messageTag = m['message_tag'];
      var arguments = m['arguments'];
      if (channelId == null || messageId == null) {
        return null;
      }
      return _NotificationPayload(channelId, messageId, messageTag, arguments);
    } catch (e, s) {
      globalLogger.w('_NotificationPayload.fromJson', e, s);
      return null;
    }
  }
}
