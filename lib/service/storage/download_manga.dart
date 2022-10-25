import 'dart:io' show File, Directory;

import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/storage/download_file.dart';
import 'package:manhuagui_flutter/service/storage/queue_manager.dart';
import 'package:manhuagui_flutter/service/storage/storage.dart';
import 'package:queue/queue.dart';

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

Future<String> _getDownloadMangaDirectory([int? mangaId, int? chapterId]) async {
  if (mangaId == null) {
    return PathUtils.joinPath([await getPublicStorageDirectoryPath(), 'manhuagui_download']);
  }
  if (chapterId == null) {
    return PathUtils.joinPath([await getPublicStorageDirectoryPath(), 'manhuagui_download', mangaId.toString()]);
  }
  return PathUtils.joinPath([await getPublicStorageDirectoryPath(), 'manhuagui_download', mangaId.toString(), chapterId.toString()]);
}

Future<bool> _downloadChapterPage({required int mangaId, required int chapterId, required int pageIndex, required String url}) async {
  var basename = (pageIndex + 1).toString().padLeft(4, '0');
  var extension = PathUtils.getExtension(url.split('?')[0]);
  var filename = '$basename$extension';
  var filepath = PathUtils.joinPath([await _getDownloadMangaDirectory(mangaId, chapterId), filename]);
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

Future<void> deleteDownloadedManga(int mangaId) async {
  var mangaPath = await _getDownloadMangaDirectory(mangaId, null);
  var directory = Directory(mangaPath);
  try {
    await directory.delete(recursive: true);
  } catch (e) {
    print(e);
  }
}

class DownloadMangaQueueTask extends QueueTask<void> {
  DownloadMangaQueueTask({
    required this.mangaId,
    required this.chapterIds,
    int parallel = 4,
  })  : _canceled = false,
        _succeeded = false,
        _progress = DownloadMangaProgress.waiting(),
        _pageQueue = Queue(parallel: parallel);

  final int mangaId;
  final List<int> chapterIds;

  bool _canceled;

  @override
  bool get canceled => _canceled;

  @override
  void cancel() {
    super.cancel();
    _canceled = true;
    var ev = DownloadMangaProgressChangedEvent(task: this);
    EventBusManager.instance.fire(ev);
  }

  bool _succeeded;

  bool get succeeded => _succeeded;

  @override
  Future<void> doTask() async {
    _succeeded = await _coreDoTask();
    // var ev = DownloadMangaProgressChangedEvent(task: this);
    // EventBusManager.instance.fire(ev);
  }

  @override
  Future<void> doDefer() {
    var ev = DownloadMangaProgressChangedEvent(task: this);
    EventBusManager.instance.fire(ev);
    return Future.value(null);
  }

  DownloadMangaProgress _progress;

  DownloadMangaProgress get progress => _progress;

  void _updateProgress(DownloadMangaProgress progress) {
    _progress = progress;
    var ev = DownloadMangaProgressChangedEvent(task: this);
    EventBusManager.instance.fire(ev);
  }

  final Queue _pageQueue;

  void changeParallel(int parallel) {
    _pageQueue.parallel = parallel;
  }

  Future<bool> prepare({
    required String mangaTitle,
    required String mangaCover,
    required String mangaUrl,
    required Tuple3<String, String, int>? Function(int cid) getChapterTitleGroupPages,
  }) async {
    // 1. 检查下载任务是否存在，找到新增的章节
    List<int> needToAdd;
    var currentTasks = QueueManager.instance.tasks.whereType<DownloadMangaQueueTask>().toList();
    var previousTask = currentTasks.where((el) => el.mangaId == mangaId && !el.canceled).toList().firstOrNull;
    if (previousTask == null) {
      needToAdd = chapterIds.toList();
    } else {
      needToAdd = chapterIds.where((el) => !previousTask.chapterIds.contains(el)).toList();
    }
    if (needToAdd.isEmpty) {
      return false; // 没有新增章节，不需要入队
    }

    // 2. 更新漫画下载表
    var oldItem = await DownloadDao.getManga(mid: mangaId);
    await DownloadDao.addOrUpdateManga(
      manga: DownloadedManga.forDatabase(
        mangaId: mangaId,
        mangaTitle: mangaTitle,
        mangaCover: mangaCover,
        mangaUrl: mangaUrl,
        updatedAt: needToAdd.isEmpty ? (oldItem?.updatedAt ?? DateTime.now()) : DateTime.now(),
      ),
    );

    // 3. 更新章节下载表
    for (var chapterId in needToAdd.toList()) {
      var chapter = getChapterTitleGroupPages(chapterId);
      if (chapter == null) {
        needToAdd.remove(chapterId); // <<<
        continue;
      }
      await DownloadDao.addOrUpdateChapter(
        chapter: DownloadedChapter(
          mangaId: mangaId,
          chapterId: chapterId,
          chapterTitle: chapter.item1,
          chapterGroup: chapter.item2,
          totalPageCount: chapter.item3,
          startedPageCount: 0 /* <<< */,
          successPageCount: 0 /* <<< */,
        ),
      );
    }

    // 4. 判断是否入队
    if (previousTask != null) {
      previousTask.chapterIds.addAll(needToAdd); // <<<
      return false; // 漫画下载任务已存在，不需要入队
    }
    return true; // 新的漫画下载任务，入队
  }

  Future<bool> _coreDoTask() async {
    final client = RestClient(DioManager.instance.dio);
    _updateProgress(DownloadMangaProgress.beforeGettingManga());

    // 1. 创建必要文件
    var nomediaPath = PathUtils.joinPath([await _getDownloadMangaDirectory(), '.nomedia']);
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
      return false;
    }
    _updateProgress(DownloadMangaProgress.gotManga(
      manga: manga,
    ));

    // 3. 更新漫画下载表
    var oldItem = await DownloadDao.getManga(mid: mangaId);
    await DownloadDao.addOrUpdateManga(
      manga: DownloadedManga.forDatabase(
        mangaId: manga.mid,
        mangaTitle: manga.title,
        mangaCover: manga.cover,
        mangaUrl: manga.url,
        updatedAt: oldItem?.updatedAt ?? DateTime.now(),
      ),
    );

    // 4. 按顺序处理每一章节
    var startedChapters = <MangaChapter>[];
    var failedPageCountInAll = 0;
    for (var i = 0; i < chapterIds.length /* appendable */; i++) {
      // 4.1. 判断请求是否被取消
      if (canceled) {
        // 被取消 => 直接结束
        return false;
      }
      var chapterId = chapterIds[i];
      _updateProgress(DownloadMangaProgress.beforeGettingChapter(
        manga: manga,
        startedChapters: startedChapters,
        failedPageCountInAll: failedPageCountInAll,
      ));

      // 4.2. 获取章节数据
      MangaChapter chapter;
      try {
        chapter = (await client.getMangaChapter(mid: mangaId, cid: chapterId)).data;
      } catch (e, s) {
        print(wrapError(e, s).text);
        return false;
      }
      startedChapters.add(chapter);
      _updateProgress(DownloadMangaProgress.gotChapter(
        manga: manga,
        startedChapters: startedChapters,
        failedPageCountInAll: failedPageCountInAll,
        currentChapter: chapter,
      ));

      // 4.3. 更新章节信息表
      var chapterGroup = manga.chapterGroups.findChapterAndGroupName(chapterId)?.item2 ?? '';
      await DownloadDao.addOrUpdateChapter(
        chapter: DownloadedChapter(
          mangaId: chapter.mid,
          chapterId: chapter.cid,
          chapterTitle: chapter.title,
          chapterGroup: chapterGroup,
          totalPageCount: chapter.pageCount,
          startedPageCount: 0 /* <<< */,
          successPageCount: 0 /* <<< */,
        ),
      );

      // 4.4. 按顺序处理章节每一页
      var successPageCountInChapter = 0;
      var failedPageCountInChapter = 0;
      for (int i = 0; i < chapter.pages.length; i++) {
        int pageIndex = i;
        _pageQueue.add<void>(() async {
          // 4.4.1. 判断请求是否被取消
          if (canceled) {
            // 被取消 => 跳出当前页面处理逻辑
            return;
          }

          // 4.4.2. 下载页面
          var ok = await _downloadChapterPage(
            mangaId: chapter.mid,
            chapterId: chapter.cid,
            pageIndex: pageIndex,
            url: chapter.pages[pageIndex],
          );
          if (!ok) {
            failedPageCountInChapter++;
            failedPageCountInAll++;
          } else {
            successPageCountInChapter++;
          }

          // 4.4.3. 通知页面下载进度
          _updateProgress(DownloadMangaProgress.gotPage(
            manga: manga,
            startedChapters: startedChapters,
            failedPageCountInAll: failedPageCountInAll,
            currentChapter: chapter,
            successPageCountInChapter: successPageCountInChapter,
            failedPageCountInChapter: failedPageCountInChapter,
          ));
        }).onError((e, s) {
          // QueueCancelledException
          print(wrapError(e, s).text);
        });
      } // for in chapter.pages

      try {
        // 4.5. 判断请求是否被取消
        if (canceled) {
          // 被取消 => 直接取消页面下载队列
          _pageQueue.cancel();
          return false; // 在返回之前，会更新章节下载表
        } else {
          // 不被取消 => 等待章节中所有页面处理结束
          await _pageQueue.onComplete;
        }
      } catch (e, s) {
        print(wrapError(e, s).text);
      } finally {
        // 4.6. 更新章节下载表 (无论是否被取消，都需要更新)
        await DownloadDao.addOrUpdateChapter(
          chapter: DownloadedChapter(
            mangaId: chapter.mid,
            chapterId: chapter.cid,
            chapterTitle: chapter.title,
            chapterGroup: chapterGroup,
            totalPageCount: chapter.pages.length,
            startedPageCount: chapter.pages.length,
            successPageCount: successPageCountInChapter,
          ),
        );
      }
    } // for in chapterIds

    // 5. 返回下载结果
    if (failedPageCountInAll > 0) {
      return false;
    }
    return true;
  }
}

enum DownloadMangaProgressStage {
  waiting,
  beforeGettingManga,
  gotManga,
  beforeGettingChapter,
  gotChapter,
  gotPage,
}

class DownloadMangaProgress {
  const DownloadMangaProgress.waiting()
      : stage = DownloadMangaProgressStage.waiting,
        manga = null,
        startedChapters = null,
        failedPageCountInAll = 0,
        currentChapter = null,
        successPageCountInChapter = null,
        failedPageCountInChapter = null;

  const DownloadMangaProgress.beforeGettingManga()
      : stage = DownloadMangaProgressStage.beforeGettingManga,
        manga = null,
        startedChapters = null,
        failedPageCountInAll = 0,
        currentChapter = null,
        successPageCountInChapter = null,
        failedPageCountInChapter = null;

  const DownloadMangaProgress.gotManga({
    required Manga this.manga,
  })  : stage = DownloadMangaProgressStage.gotManga,
        startedChapters = null,
        failedPageCountInAll = 0,
        currentChapter = null,
        successPageCountInChapter = null,
        failedPageCountInChapter = null;

  const DownloadMangaProgress.beforeGettingChapter({
    required Manga this.manga,
    required List<MangaChapter> this.startedChapters,
    required this.failedPageCountInAll,
  })  : stage = DownloadMangaProgressStage.beforeGettingChapter,
        currentChapter = null,
        successPageCountInChapter = null,
        failedPageCountInChapter = null;

  const DownloadMangaProgress.gotChapter({
    required Manga this.manga,
    required List<MangaChapter> this.startedChapters,
    required this.failedPageCountInAll,
    required MangaChapter this.currentChapter,
  })  : stage = DownloadMangaProgressStage.gotChapter,
        successPageCountInChapter = null,
        failedPageCountInChapter = null;

  const DownloadMangaProgress.gotPage({
    required Manga this.manga,
    required List<MangaChapter> this.startedChapters,
    required this.failedPageCountInAll,
    required MangaChapter this.currentChapter,
    required int this.successPageCountInChapter,
    required int this.failedPageCountInChapter,
  }) : stage = DownloadMangaProgressStage.gotPage;

  // 当前阶段
  final DownloadMangaProgressStage stage;

  // 已获得的数据
  final Manga? manga;
  final List<MangaChapter>? startedChapters;
  final int failedPageCountInAll;

  // 当前下载
  final MangaChapter? currentChapter;
  final int? successPageCountInChapter;
  final int? failedPageCountInChapter;
}
