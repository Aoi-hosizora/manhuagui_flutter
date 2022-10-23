import 'dart:io' show File;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/storage/download_file.dart';
import 'package:manhuagui_flutter/service/storage/queue_manager.dart';
import 'package:manhuagui_flutter/service/storage/storage.dart';

enum MangaDownloadResult {
  success,
  failed,
  canceled, // canceled when downloading
}

class MangaDownloadQueueTask extends QueueTask<MangaDownloadResult> {
  MangaDownloadQueueTask({
    required this.mangaId,
    required this.chapterIds,
    required this.progressNotifier,
  });

  final int mangaId;
  final List<int> chapterIds;
  final void Function(MangaDownloadProgress) progressNotifier;

  @override
  Future<MangaDownloadResult> doTask() async {
    final client = RestClient(DioManager.instance.dio);

    // 1. 创建 nomedia 文件
    var nomediaPath = PathUtils.joinPath([await _getMangaDownloadDirectory(), '.nomedia']);
    var nomediaFile = File(nomediaPath);
    if (!(await nomediaFile.exists())) {
      await nomediaFile.create(recursive: true);
    }

    // 2. 获取漫画数据
    Manga manga;
    try {
      manga = (await client.getManga(mid: mangaId)).data;
    } catch (e, s) {
      throw wrapError(e, s).text;
    }
    if (super.canceled) {
      return MangaDownloadResult.canceled;
    }

    // 3. 更新漫画下载表
    // TODO

    var downloadedChapters = <MangaChapter>[];
    var successCount = 0;
    var failedCount = 0;
    for (var chapterId in chapterIds) {
      if (super.canceled) {
        return MangaDownloadResult.canceled;
      }
      progressNotifier.call(
        MangaDownloadProgress(
          mangaId: mangaId,
          chapterIds: chapterIds,
          manga: manga,
          downloadedChapters: downloadedChapters,
          currentChapterId: chapterId,
          preparing: true,
          currentChapter: null,
          currentChapterPage: null,
          finishedPagesCount: successCount + failedCount,
          failedPagesCount: failedCount,
        ),
      );

      // 4. 获取章节数据
      MangaChapter chapter;
      try {
        chapter = (await client.getMangaChapter(mid: mangaId, cid: chapterId)).data;
      } catch (e, s) {
        throw wrapError(e, s).text;
      }
      if (super.canceled) {
        return MangaDownloadResult.canceled;
      }
      downloadedChapters.add(chapter);

      // 5. 更新章节下载表
      // TODO

      // 6. 按顺序下载每一页
      for (int i = 0; i < chapter.pages.length; i++) {
        if (super.canceled) {
          return MangaDownloadResult.canceled;
        }
        progressNotifier.call(
          MangaDownloadProgress(
            mangaId: mangaId,
            chapterIds: chapterIds,
            manga: manga,
            downloadedChapters: downloadedChapters,
            currentChapterId: chapterId,
            preparing: false,
            currentChapter: chapter,
            currentChapterPage: i + 1,
            finishedPagesCount: successCount + failedCount,
            failedPagesCount: failedCount,
          ),
        );

        var url = chapter.pages[i];
        var ok = await _downloadPage(
          mangaId: chapter.mid,
          chapterId: chapter.cid,
          pageIndex: i,
          url: url,
        );
        if (ok) {
          successCount++;
        } else {
          failedCount++;
        }
      }

      // 7. 更新章节下载表
      // TODO
    }

    // 8. 更新漫画下载表
    // TODO

    if (failedCount > 0) {
      return MangaDownloadResult.failed;
    }
    return MangaDownloadResult.success;
  }
}

class MangaDownloadProgress {
  const MangaDownloadProgress({
    required this.mangaId,
    required this.chapterIds,
    required this.manga,
    required this.downloadedChapters,
    required this.currentChapterId,
    required this.preparing,
    required this.currentChapter,
    required this.currentChapterPage,
    required this.finishedPagesCount,
    required this.failedPagesCount,
  });

  // 原请求
  final int mangaId;
  final List<int> chapterIds;

  // 已结束
  final Manga? manga;
  final List<MangaChapter>? downloadedChapters;

  // 当前下载
  final int? currentChapterId;
  final bool preparing;
  final MangaChapter? currentChapter;
  final int? currentChapterPage;

  // 汇总
  final int finishedPagesCount;
  final int failedPagesCount;
}

Future<String> _getMangaDownloadDirectory([int? mangaId, int? chapterId]) async {
  var download = PathUtils.joinPath([await getPublicStorageDirectoryPath(), 'manhuagui_download']);
  if (mangaId == null || chapterId == null) {
    return download;
  }
  return PathUtils.joinPath([download, mangaId.toString(), chapterId.toString()]);
}

Future<bool> _downloadPage({
  required int mangaId,
  required int chapterId,
  required int pageIndex,
  required String url,
}) async {
  var basename = (pageIndex + 1).toString().padLeft(4, '0');
  var extension = PathUtils.getExtension(url.split('?')[0]);
  var filename = '$basename$extension';
  var filepath = PathUtils.joinPath([
    await getPublicStorageDirectoryPath(),
    'manhuagui_download',
    mangaId.toString(),
    chapterId.toString(),
    filename,
  ]);
  if (await File(filepath).exists()) {
    return true;
  }

  try {
    await downloadFile(
      url: url,
      filepath: filepath,
      headers: {
        'User-Agent': USER_AGENT,
        'Referer': REFERER,
      },
      cacheManager: DefaultCacheManager(),
      option: DownloadOption(
        behavior: DownloadBehavior.preferUsingCache,
        whenOverwrite: (_) async => OverwriteBehavior.overwrite,
      ),
    );
    return true;
  } catch (e) {
    return false;
  }
}

Future<File?> downloadImageToGallery(String url) async {
  var basename = getTimestampTokenForFilename();
  var extension = PathUtils.getExtension(url.split('?')[0]);
  var filename = '$basename$extension';
  var filepath = PathUtils.joinPath([await getPublicStorageDirectoryPath(), 'manhuagui_image', 'IMG_$filename']);
  try {
    var f = await downloadFile(
      url: url,
      filepath: filepath,
      headers: {
        'User-Agent': USER_AGENT,
        'Referer': REFERER,
      },
      cacheManager: DefaultCacheManager(),
      option: DownloadOption(
        behavior: DownloadBehavior.preferUsingCache,
        whenOverwrite: (_) async => OverwriteBehavior.addSuffix,
      ),
    ); // IMG_20220917_131013_206.jpg
    await addToGallery(f);
    return f;
  } catch (e) {
    print(e);
    return null;
  }
}
