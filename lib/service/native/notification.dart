import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:synchronized/synchronized.dart';

// @pragma('vm:entry-point')
// void onNotificationReceivedBackground(NotificationResponse nr) {
//   print('Receive Background ${nr.id} ${nr.actionId} ${nr.input} ${nr.notificationResponseType} ${nr.payload}');
// }

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
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        // onDidReceiveNotificationResponse: (NotificationResponse nr) async {
        //   print('Receive ${nr.id} ${nr.actionId} ${nr.input} ${nr.notificationResponseType} ${nr.payload}');
        // },
        // onDidReceiveBackgroundNotificationResponse: onNotificationReceivedBackground,
          onSelectNotification: (payload) {
            print('Receive $payload');
          },
      );
    }
    return _plugin!;
  }

  final _lock = Lock();
  var _latestId = 0;

  Future<int> generateId() {
    return _lock.synchronized<int>(() async {
      _latestId++;
      return _latestId;
    });
  }

  Future<bool> showDownloadNotification({
    /* data */
    required int id,
    required String title,
    String? body,
    String? subText,
    String? payload,
    // List<AndroidNotificationAction>? actions,
    /* progress */
    bool ongoing = false,
    bool showProgress = false,
    int maxProgress = 0,
    int progress = 0,
    bool indeterminate = false,
  }) async {
    var plugin = await getPlugin();
    var details = AndroidNotificationDetails(
      NTF_CHANNEL_ID,
      NTF_CHANNEL_NAME,
      channelDescription: NTF_CHANNEL_DESCRIPTION,
      /* data */
      subText: subText,
      ticker: null,
      // actions: actions,
      /* progress */
      ongoing: ongoing,
      showProgress: showProgress,
      maxProgress: maxProgress,
      progress: progress,
      indeterminate: indeterminate,
      /* setting */
      icon: null /* <<< */,
      largeIcon: null /* <<< */,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: false,
      enableVibration: false,
      autoCancel: true,
      onlyAlertOnce: true,
      showWhen: true,
      enableLights: false,
      channelShowBadge: false,
      channelAction: AndroidNotificationChannelAction.update,
      visibility: NotificationVisibility.secret,
      // category: AndroidNotificationCategory.progress,
    );

    try {
      await plugin.show(
        id,
        title,
        body,
        NotificationDetails(android: details),
        payload: payload,
      );
      return true;
    } catch (e, s) {
      print('===> exception when sendNotification:\n$e\n$s');
      return false;
    }
  }
}
