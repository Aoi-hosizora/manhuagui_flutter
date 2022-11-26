import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/download_toc.dart';
import 'package:manhuagui_flutter/service/native/notification.dart';
import 'package:manhuagui_flutter/service/storage/download_task.dart';

class DownloadNotificationHelper {
  static Future<void> showDoneNotification(int mangaId, String mangaTitle, bool success) async {
    await _showNotification(
      id: mangaId,
      title: mangaTitle,
      body: success ? '下载已完成' : '下载失败',
      icon: NotificationManager.drawableStatSysDownloadDone,
      largeIcon: NotificationManager.mipMapIcLaunch,
      autoCancel: true,
      ongoing: false,
      showProgress: false,
      category: success ? NotificationManager.statusCategory : NotificationManager.errCategory,
    );
  }

  static Future<void> showProgressNotification(int mangaId, String mangaTitle, DownloadMangaProgress progress) async {
    Future<void> show(String body, [int? triedPageCount, int? totalPageCount]) async {
      await _showNotification(
        id: mangaId,
        title: mangaTitle,
        body: body,
        icon: NotificationManager.drawableStatSysDownload,
        largeIcon: NotificationManager.mipMapIcLaunch,
        autoCancel: false,
        ongoing: true,
        showProgress: true,
        indeterminate: triedPageCount == null,
        progress: triedPageCount ?? 0,
        maxProgress: totalPageCount ?? 1,
        category: NotificationManager.progressCategory,
      );
    }

    switch (progress.stage) {
      case DownloadMangaProgressStage.gettingManga:
        show('获取漫画信息中');
        break;
      case DownloadMangaProgressStage.gettingChapter:
        show('获取章节信息中');
        break;
      case DownloadMangaProgressStage.gotChapter:
      case DownloadMangaProgressStage.gotPage:
        var chapter = progress.currentChapter!;
        var tried = progress.triedChapterPageCount ?? 0;
        show('${chapter.title} $tried/${chapter.pageCount}', tried, chapter.pageCount);
        break;
      default:
      // skip
    }
  }

  static Future<void> cancelNotification({required int mangaId}) async {
    await NotificationManager.instance.cancelNotification(id: mangaId);
  }

  static Future<bool> _showNotification({
    required int id,
    required String title,
    String? body,
    String? subText,
    String? ticker,
    String? tag,
    Object? arguments,
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
    return await NotificationManager.instance.showNotification(
      id: id,
      title: title,
      body: body,
      arguments: arguments,
      details: NotificationManager.buildSilentDetails(
        channel: NotificationManager.downloadChannel,
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
    );
  }
}

class DownloadNotificationHandler extends NotificationHandler {
  @override
  bool check(BuildContext? context, String channelId, int messageId, String? messageTag, Object? arguments) {
    return channelId == NotificationManager.downloadChannel.id;
  }

  @override
  void select(BuildContext? context, String channelId, int messageId, String? messageTag, Object? arguments) {
    var mangaId = messageId;
    if (context != null && !DownloadTocPage.isCurrentRoute(context, mangaId)) {
      Navigator.of(context).push(
        CustomPageRoute(
          context: context,
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
