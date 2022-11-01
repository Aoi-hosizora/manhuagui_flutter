import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:manhuagui_flutter/page/download.dart';
import 'package:manhuagui_flutter/page/download_toc.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/native/notification.dart';
import 'package:manhuagui_flutter/service/storage/download_manga_task.dart';
import 'package:manhuagui_flutter/service/storage/queue_manager.dart';

class NotificationSelectedEvent {
  const NotificationSelectedEvent({required this.id, required this.payload});

  final int id;
  final String? payload;
}

class NotificationActionSelectedEvent {
  const NotificationActionSelectedEvent({required this.id, required this.actionId, required this.payload});

  final int id;
  final String actionId;
  final String? payload;
}

@pragma('vm:entry-point')
void fireNotificationSelectedEvent(NotificationResponse nr) {
  if (nr.id != null) {
    var ev = NotificationSelectedEvent(id: nr.id!, payload: nr.payload);
    EventBusManager.instance.fire(ev);
  }
}

@pragma('vm:entry-point')
void fireNotificationActionSelectedEvent(NotificationResponse nr) {
  if (nr.id != null && nr.actionId != null) {
    // TODO ???
    var ev = NotificationActionSelectedEvent(id: nr.id!, actionId: nr.actionId!, payload: nr.payload);
    EventBusManager.instance.fire(ev);
  }
}

void listenNotificationSelectedEvent(BuildContext context) {
  EventBusManager.instance.listen<NotificationSelectedEvent>((ev) {
    print('>>> notify ${ev.id} ${ev.payload}');
    if (ev.payload == NotificationManager.downloadChannelPayload) {
      Navigator.of(context).push(
        CustomMaterialPageRoute(
          context: context,
          builder: (c) => DownloadTocPage(
            mangaId: ev.id,
            gotoDownloading: true,
          ),
        ),
      );
    }
  });
}

void listenNotificationActionSelectedEvent(BuildContext context) {
  // TODO ???
  EventBusManager.instance.listen<NotificationActionSelectedEvent>((ev) async {
    print('>>> action ${ev.id} ${ev.payload} ${ev.actionId}');
    if (ev.payload == NotificationManager.downloadChannelPayload) {
      if (ev.actionId == NotificationManager.downloadChannelAction1Id) {
        print('>>> downloadChannelAction1Id');
        await Navigator.of(context).push(
          CustomMaterialPageRoute(
            context: context,
            builder: (c) => DownloadPage(),
          ),
        );
        for (var t in QueueManager.instance.getDownloadMangaQueueTasks()) {
          print('1 ${t.mangaId}');
          if (!t.canceled) {
            t.cancel();
          }
        }
      } else if (ev.actionId == NotificationManager.downloadChannelAction2Id) {
        print('>>> downloadChannelAction2Id');
        await Navigator.of(context).push(
          CustomMaterialPageRoute(
            context: context,
            builder: (c) => DownloadTocPage(
              mangaId: ev.id,
              gotoDownloading: false,
            ),
          ),
        );
        var task = QueueManager.instance.getDownloadMangaQueueTask(ev.id);
        if (task != null && !task.canceled) {
          print('2 ${task.mangaId}');
          task.cancel();
        }
      }
    }
  });
}
