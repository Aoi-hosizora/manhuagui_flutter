import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/download_toc.dart';
import 'package:manhuagui_flutter/service/native/notification.dart';

mixin NotificationHandlerMixin {
  static BuildContext? _hackedContext; // global BuildContext instance

  void registerContext(BuildContext context) {
    _hackedContext = context;
  }

  @pragma('vm:entry-point')
  static Future<void> handleSelectedEvent(int id, String? payload) async {
    if (payload == NotificationManager.downloadChannelPayload && _hackedContext != null) {
      var mangaId = id;
      if (!DownloadTocPage.isCurrentRoute(_hackedContext!, mangaId)) {
        Navigator.of(_hackedContext!).push(
          CustomMaterialPageRoute(
            context: _hackedContext!,
            builder: (c) => DownloadTocPage(
              mangaId: mangaId,
              gotoDownloading: true,
            ),
            settings: DownloadTocPage.buildRouteSetting(
              mangaId: mangaId,
            ),
          ),
        );
      }
    }
  }
}
