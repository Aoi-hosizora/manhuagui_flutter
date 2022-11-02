import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/download_toc.dart';

mixin NotificationHandlerMixin {
  static BuildContext? _hackedContext; // global BuildContext instance

  void registerContext(BuildContext context) {
    _hackedContext = context;
  }

  @pragma('vm:entry-point')
  static Future<void> handleSelectedEvent({
    required String channelId,
    required int messageId,
    String? messageTag,
    Object? arguments,
  }) async {
    switch (channelId) {
      case DL_NTFC_ID:
        var mangaId = messageId;
        if (_hackedContext != null && !DownloadTocPage.isCurrentRoute(_hackedContext!, mangaId)) {
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
        break;

      default:
        break;
    }
  }
}
