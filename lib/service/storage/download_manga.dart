import 'dart:io' show File;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
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

    // 3. 更新漫画下载表和章节下载表
    await DownloadDao.addOrUpdateManga(
      manga: DownloadedManga(
        mangaId: manga.mid,
        mangaTitle: manga.title,
        mangaCover: manga.cover,
        totalChaptersCount: 0,
        successChaptersCount: 0,
        updatedAt: DateTime.now(),
      ),
    );
    var chapterGroupMap = <int, String>{};
    for (var chapterId in chapterIds) {
      var tuple = manga.chapterGroups.findChapterAndGroupName(chapterId);
      if (tuple == null) {
        continue; // unreachable
      }
      var chapter = tuple.item1;
      chapterGroupMap[chapterId] = tuple.item2;
      await DownloadDao.addOrUpdateChapter(
        chapter: DownloadedChapter(
          mangaId: chapter.mid,
          chapterId: chapter.cid,
          chapterTitle: chapter.title,
          chapterGroup: tuple.item2,
          totalPagesCount: null,
          successPagesCount: null,
        ),
      );
    }

    // 4. 按顺序处理每一章节
    var downloadedChapters = <MangaChapter>[];
    var successCount = 0;
    var failedCount = 0;
    for (var chapterId in chapterIds) {
      // 4.1. 判断请求是否被取消，若被取消则直接结束，否则通知当前正在下载的章节
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

      // 4.2. 获取章节数据
      MangaChapter chapter;
      try {
        chapter = (await client.getMangaChapter(mid: mangaId, cid: chapterId)).data;
      } catch (e, s) {
        throw wrapError(e, s).text;
      }
      downloadedChapters.add(chapter);

      // 4.3. 更新章节下载表
      await DownloadDao.addOrUpdateChapter(
        chapter: DownloadedChapter(
          mangaId: chapter.mid,
          chapterId: chapter.cid,
          chapterTitle: chapter.title,
          chapterGroup: chapterGroupMap[chapter.cid] ?? '',
          totalPagesCount: chapter.pages.length,
          successPagesCount: 0,
        ),
      );

      // 4.4. 按顺序下载章节每一页
      for (int i = 0; i < chapter.pages.length; i++) {
        // 4.4.1. 判断请求是否被取消，若被取消则更新章节下载表，否则通知当前正在下载的页面
        if (super.canceled) {
          await DownloadDao.addOrUpdateChapter(
            chapter: DownloadedChapter(
              mangaId: chapter.mid,
              chapterId: chapter.cid,
              chapterTitle: chapter.title,
              chapterGroup: chapterGroupMap[chapter.cid] ?? '',
              totalPagesCount: chapter.pages.length,
              successPagesCount: successCount,
            ),
          );
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

        // 4.4.2. 下载章节页面
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

      // 5. 更新章节下载表
      await DownloadDao.addOrUpdateChapter(
        chapter: DownloadedChapter(
          mangaId: chapter.mid,
          chapterId: chapter.cid,
          chapterTitle: chapter.title,
          chapterGroup: chapterGroupMap[chapter.cid] ?? '',
          totalPagesCount: chapter.pages.length,
          successPagesCount: successCount,
        ),
      );
    }

    // 8. 返回下载结果
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
