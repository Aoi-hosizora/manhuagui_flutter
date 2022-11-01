import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/service/evb/ntf_events.dart';

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
        InitializationSettings(
          android: AndroidInitializationSettings('flutter_icon'),
        ),
        onDidReceiveNotificationResponse: _onNotificationReceived,
        onDidReceiveBackgroundNotificationResponse: _onNotificationReceived,
      );
    }
    return _plugin!;
  }

  @pragma('vm:entry-point')
  static void _onNotificationReceived(NotificationResponse nr) {
    if (nr.notificationResponseType == NotificationResponseType.selectedNotification) {
      print('notify ${nr.id} ${nr.payload}');
      fireNotificationSelectedEvent(nr);
    } else {
      print('action ${nr.id} ${nr.actionId} ${nr.input} ${nr.payload}');
      fireNotificationActionSelectedEvent(nr);
    }
  }

  AndroidNotificationDetails buildSilentNotificationDetails({
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
    AndroidNotificationCategory? category,
    List<AndroidNotificationAction>? actions,
  }) {
    // https://pub.dev/packages/flutter_local_notifications#-usage
    // https://developer.android.com/reference/android/R.drawable#stat_sys_download
    // https://github.com/xiaojieonly/Ehviewer_CN_SXJ/blob/1.9.2/app/src/main/java/com/hippo/ehviewer/download/DownloadService.java#L218
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
      category: category /* progress or error */,
      actions: actions,
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

  Future<bool> cancelNotification({required int id, String? tag}) async {
    var plugin = await getPlugin();
    try {
      await plugin.cancel(id, tag: tag);
      return true;
    } catch (e, s) {
      print('===> exception when cancelNotification:\n$e\n$s');
      return false;
    }
  }

  static const mipMapIcLaunch = '@mipmap/ic_launcher';
  static const drawableStatDownload = '@android:drawable/stat_sys_download';
  static const drawableStatDownloadDone = '@android:drawable/stat_sys_download_done';

  static const downloadChannelPayload = DL_NTFC_ID;
  static const downloadChannelAction1Id = DL_NTFC_ID + ':action1';
  static const downloadChannelAction2Id = DL_NTFC_ID + ':action2';

  Future<bool> showDownloadChannelNotification({
    required int id,
    required String title,
    String? body,
    String? subText,
    String? ticker,
    String? tag,
    String? payload,
    String? icon,
    String? largeIcon,
    bool autoCancel = true,
    bool ongoing = false,
    bool showProgress = false,
    bool indeterminate = false,
    int maxProgress = 0,
    int progress = 0,
    AndroidNotificationCategory? category,
    List<AndroidNotificationAction>? actions,
  }) async {
    var plugin = await getPlugin();
    try {
      await plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: buildSilentNotificationDetails(
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
            actions: actions,
          ),
        ),
        payload: payload,
      );
      return true;
    } catch (e, s) {
      print('===> exception when showDownloadChannelNotification:\n$e\n$s');
      return false;
    }
  }
}
