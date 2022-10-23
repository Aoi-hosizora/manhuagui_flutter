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
  }) : _progress = MangaDownloadProgress.beforeGettingManga(
          mangaId: mangaId,
          chapterIds: chapterIds,
        );

  final int mangaId;
  final List<int> chapterIds;
  final void Function(MangaDownloadProgress) progressNotifier;

  MangaDownloadProgress _progress;

  MangaDownloadProgress get progress => _progress;

  void _setProgress(MangaDownloadProgress progress) {
    _progress = progress;
    progressNotifier.call(progress);
  }

  @override
  Future<MangaDownloadResult> doTask() async {
    final client = RestClient(DioManager.instance.dio);

    // TODO old duplicate download task ??? need to merge chapters and cancel the new task

    // 1. 创建必要文件
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
      print(wrapError(e, s).text);
      return MangaDownloadResult.failed;
    }
    _setProgress(
      MangaDownloadProgress.gotManga(
        mangaId: mangaId,
        chapterIds: chapterIds,
        manga: manga,
      ),
    );

    // 3. 更新漫画下载表和章节下载表
    await DownloadDao.addOrUpdateManga(
      manga: DownloadedManga(
        mangaId: manga.mid,
        mangaTitle: manga.title,
        mangaCover: manga.cover,
        totalChaptersCount: 0,
        startedChaptersCount: 0,
        successChaptersCount: 0,
        updatedAt: DateTime.now(),
      ),
    );
    var chapterGroupMap = <int, String>{};
    for (var chapterId in chapterIds) {
      var tuple = manga.chapterGroups.findChapterAndGroupName(chapterId)!;
      var chapter = tuple.item1;
      chapterGroupMap[chapterId] = tuple.item2;
      await DownloadDao.addOrUpdateChapter(
        chapter: DownloadedChapter(
          mangaId: chapter.mid,
          chapterId: chapter.cid,
          chapterTitle: chapter.title,
          chapterGroup: tuple.item2,
          totalPagesCount: chapter.pageCount,
          successPagesCount: 0, // <<< starts from zero
        ),
      );
    }

    // 4. 按顺序处理每一章节
    var startedChapters = <MangaChapter>[];
    var successPagesInAll = 0;
    var failedPagesInAll = 0;
    for (var chapterId in chapterIds) {
      // 4.1. 判断请求是否被取消，若被取消则直接结束
      if (super.canceled) {
        return MangaDownloadResult.canceled;
      }
      _setProgress(
        MangaDownloadProgress.beforeGettingChapter(
          mangaId: mangaId,
          chapterIds: chapterIds,
          manga: manga,
          startedChapters: startedChapters,
          successPagesCount: successPagesInAll,
          failedPagesCount: failedPagesInAll,
          currentChapterId: chapterId,
        ),
      );

      // 4.2. 获取章节数据
      MangaChapter chapter;
      try {
        chapter = (await client.getMangaChapter(mid: mangaId, cid: chapterId)).data;
      } catch (e, s) {
        print(wrapError(e, s).text);
        return MangaDownloadResult.failed;
      }
      startedChapters.add(chapter);
      _setProgress(
        MangaDownloadProgress.gotChapter(
          mangaId: mangaId,
          chapterIds: chapterIds,
          manga: manga,
          startedChapters: startedChapters,
          successPagesCount: successPagesInAll,
          failedPagesCount: failedPagesInAll,
          currentChapterId: chapterId,
          currentChapter: chapter,
        ),
      );

      // 4.3. 按顺序下载章节每一页
      var successPagesInChapter = 0;
      for (int pageIndex = 0; pageIndex < chapter.pages.length; pageIndex++) {
        // 4.3.1. 判断请求是否被取消，若被取消则更新章节下载表并结束
        if (super.canceled) {
          await DownloadDao.addOrUpdateChapter(
            chapter: DownloadedChapter(
              mangaId: chapter.mid,
              chapterId: chapter.cid,
              chapterTitle: chapter.title,
              chapterGroup: chapterGroupMap[chapter.cid] ?? '',
              totalPagesCount: chapter.pages.length,
              successPagesCount: successPagesInChapter,
            ),
          );
          return MangaDownloadResult.canceled;
        }

        // 4.3.2. 下载章节页面
        var url = chapter.pages[pageIndex];
        var ok = await _downloadChapterPage(
          mangaId: chapter.mid,
          chapterId: chapter.cid,
          pageIndex: pageIndex,
          url: url,
        );
        if (ok) {
          successPagesInChapter++;
          successPagesInAll++;
        } else {
          failedPagesInAll++;
        }

        // 4.3.3 通知章节页面下载进度
        _setProgress(
          MangaDownloadProgress.gotPage(
            mangaId: mangaId,
            chapterIds: chapterIds,
            manga: manga,
            startedChapters: startedChapters,
            successPagesCount: successPagesInAll,
            failedPagesCount: failedPagesInAll,
            currentChapterId: chapterId,
            currentChapter: chapter,
            currentChapterPage: pageIndex + 1,
          ),
        );
      }

      // 4.4. 更新章节下载表
      await DownloadDao.addOrUpdateChapter(
        chapter: DownloadedChapter(
          mangaId: chapter.mid,
          chapterId: chapter.cid,
          chapterTitle: chapter.title,
          chapterGroup: chapterGroupMap[chapter.cid] ?? '',
          totalPagesCount: chapter.pages.length,
          successPagesCount: successPagesInChapter,
        ),
      );
    }

    // 5. 返回下载结果
    if (failedPagesInAll > 0) {
      return MangaDownloadResult.failed;
    }
    return MangaDownloadResult.success;
  }
}

enum MangaDownloadProgressStage {
  beforeGettingManga,
  gotManga,
  beforeGettingChapter,
  gotChapter,
  gotPage,
}

class MangaDownloadProgress {
  const MangaDownloadProgress.beforeGettingManga({
    required this.mangaId,
    required this.chapterIds,
  })  : stage = MangaDownloadProgressStage.beforeGettingManga,
        preparingManga = true,
        preparingChapter = true,
        manga = null,
        startedChapters = null,
        successPagesCount = 0,
        failedPagesCount = 0,
        currentChapterId = null,
        currentChapter = null,
        currentChapterPage = null;

  const MangaDownloadProgress.gotManga({
    required this.mangaId,
    required this.chapterIds,
    required Manga this.manga,
  })  : stage = MangaDownloadProgressStage.gotManga,
        preparingManga = false,
        preparingChapter = true,
        startedChapters = null,
        successPagesCount = 0,
        failedPagesCount = 0,
        currentChapterId = null,
        currentChapter = null,
        currentChapterPage = null;

  const MangaDownloadProgress.beforeGettingChapter({
    required this.mangaId,
    required this.chapterIds,
    required Manga this.manga,
    required List<MangaChapter> this.startedChapters,
    required this.successPagesCount,
    required this.failedPagesCount,
    required int this.currentChapterId,
  })  : stage = MangaDownloadProgressStage.beforeGettingChapter,
        preparingManga = false,
        preparingChapter = true,
        currentChapter = null,
        currentChapterPage = null;

  const MangaDownloadProgress.gotChapter({
    required this.mangaId,
    required this.chapterIds,
    required Manga this.manga,
    required List<MangaChapter> this.startedChapters,
    required this.successPagesCount,
    required this.failedPagesCount,
    required int this.currentChapterId,
    required MangaChapter this.currentChapter,
  })  : stage = MangaDownloadProgressStage.gotChapter,
        preparingManga = false,
        preparingChapter = false,
        currentChapterPage = null;

  const MangaDownloadProgress.gotPage({
    required this.mangaId,
    required this.chapterIds,
    required Manga this.manga,
    required List<MangaChapter> this.startedChapters,
    required this.successPagesCount,
    required this.failedPagesCount,
    required int this.currentChapterId,
    required MangaChapter this.currentChapter,
    required int this.currentChapterPage,
  })  : stage = MangaDownloadProgressStage.gotPage,
        preparingManga = false,
        preparingChapter = false;

  // 原始请求
  final int mangaId;
  final List<int> chapterIds;

  // 已获得的数据
  final MangaDownloadProgressStage stage;
  final bool preparingManga;
  final bool preparingChapter;
  final Manga? manga;
  final List<MangaChapter>? startedChapters;

  // 页面汇总
  final int successPagesCount;
  final int failedPagesCount;

  // 当前下载
  final int? currentChapterId;
  final MangaChapter? currentChapter;
  final int? currentChapterPage;
}

Future<String> _getMangaDownloadDirectory([int? mangaId, int? chapterId]) async {
  var download = PathUtils.joinPath([await getPublicStorageDirectoryPath(), 'manhuagui_download']);
  if (mangaId == null || chapterId == null) {
    return download;
  }
  return PathUtils.joinPath([download, mangaId.toString(), chapterId.toString()]);
}

Future<bool> _downloadChapterPage({required int mangaId, required int chapterId, required int pageIndex, required String url}) async {
  var basename = (pageIndex + 1).toString().padLeft(4, '0');
  var extension = PathUtils.getExtension(url.split('?')[0]);
  var filename = '$basename$extension';
  var filepath = PathUtils.joinPath([await _getMangaDownloadDirectory(mangaId, chapterId), filename]);
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
    print(e);
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
    await addToGallery(f); // <<<
    return f;
  } catch (e) {
    print(e);
    return null;
  }
}
