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

Future<String> getDownloadedMangaPageFilepath({required int mangaId, required int chapterId, required int pageIndex, required String url}) async {
  var basename = (pageIndex + 1).toString().padLeft(4, '0');
  var extension = PathUtils.getExtension(url.split('?')[0]);
  var filename = '$basename$extension';
  return PathUtils.joinPath([await _getDownloadMangaDirectory(mangaId, chapterId), filename]);
}

Future<bool> _downloadChapterPage({required int mangaId, required int chapterId, required int pageIndex, required String url}) async {
  var filepath = await getDownloadedMangaPageFilepath(
    mangaId: mangaId,
    chapterId: chapterId,
    pageIndex: pageIndex,
    url: url,
  );
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

Future<int> getDownloadedMangaBytes({required int mangaId}) async {
  var mangaPath = await _getDownloadMangaDirectory(mangaId, null);
  var directory = Directory(mangaPath);
  if (!(await directory.exists())) {
    return 0;
  }

  var totalBytes = 0;
  await for (var entity in directory.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      totalBytes += await entity.length();
    }
  }
  return totalBytes;
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
    int parallel = 5,
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
    var ev = DownloadMangaProgressChangedEvent(task: this, finished: false);
    EventBusManager.instance.fire(ev);
  }

  bool _succeeded;

  bool get succeeded => _succeeded;

  @override
  Future<void> doTask() async {
    _succeeded = await _coreDoTask();
  }

  @override
  Future<void> doDefer() {
    var ev = DownloadMangaProgressChangedEvent(task: this, finished: true);
    EventBusManager.instance.fire(ev);
    var ev2 = DownloadedMangaEntityChangedEvent(mangaId: mangaId);
    EventBusManager.instance.fire(ev2);
    return Future.value(null);
  }

  DownloadMangaProgress _progress;

  DownloadMangaProgress get progress => _progress;

  void _updateProgress(DownloadMangaProgress progress) {
    _progress = progress;
    var ev = DownloadMangaProgressChangedEvent(task: this, finished: false);
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
    // 1. 更新任务状态
    _updateProgress(
      DownloadMangaProgress.waiting(),
    );

    // 2. 合并请求下载的章节与数据库已有的章节
    var oldManga = await DownloadDao.getManga(mid: mangaId);
    var oldChapterIds = oldManga?.downloadedChapters.map((el) => el.chapterId) ?? [];
    var mergedChapterIds = {...oldChapterIds, ...chapterIds}.toList()..sort();
    chapterIds.clear();
    chapterIds.addAll(mergedChapterIds);

    // 3. 检查漫画下载任务是否存在
    List<int> newChapterIds;
    var currentTasks = QueueManager.instance.tasks.whereType<DownloadMangaQueueTask>().toList();
    var previousTask = currentTasks.where((el) => el.mangaId == mangaId && !el.canceled).firstOrNull;
    if (previousTask != null) {
      // 下载任务已存在 => 找到新增的章节
      newChapterIds = chapterIds.where((el) => !previousTask.chapterIds.contains(el)).toList();
    } else {
      // 下载任务不存在 => 保留原样
      newChapterIds = chapterIds.toList();
    }
    if (newChapterIds.isEmpty) {
      // 没有新增章节 => 无需任何变更，不需要入队
      return false;
    }

    // 4. 更新漫画下载表
    await DownloadDao.addOrUpdateManga(
      manga: DownloadedManga(
        mangaId: mangaId,
        mangaTitle: mangaTitle,
        mangaCover: mangaCover,
        mangaUrl: mangaUrl,
        error: false,
        updatedAt: (oldManga == null || chapterIds.length > oldChapterIds.length)
            ? DateTime.now() // 新增下载章节 => 更新时间
            : oldManga.updatedAt /* 没有新增下载章节 => 无需更新时间 */,
        downloadedChapters: [] /* ignored */,
      ),
    );

    // 5. 更新章节下载表，并通知漫画下载表发生变化
    for (var chapterId in newChapterIds.toList()) {
      var oldChapter = oldManga?.downloadedChapters.where((el) => el.chapterId == chapterId).firstOrNull;
      var chapterTuple = getChapterTitleGroupPages(chapterId);
      if (chapterTuple == null) {
        newChapterIds.remove(chapterId); // <<<
        continue;
      }
      await DownloadDao.addOrUpdateChapter(
        chapter: DownloadedChapter(
          mangaId: mangaId,
          chapterId: chapterId,
          chapterTitle: chapterTuple.item1,
          chapterGroup: chapterTuple.item2,
          totalPageCount: chapterTuple.item3,
          triedPageCount: oldChapter?.triedPageCount ?? 0,
          successPageCount: oldChapter?.successPageCount ?? 0,
        ),
      );
    }
    var ev = DownloadedMangaEntityChangedEvent(mangaId: mangaId);
    EventBusManager.instance.fire(ev);

    // 6. 判断是否入队
    if (previousTask != null) {
      // 漫画下载任务已存在 => 往后添加任务章节信息，不需要入队
      previousTask.chapterIds.addAll(newChapterIds);
      return false;
    }
    // 新的漫画下载任务 => 更新任务章节信息，入队
    chapterIds.clear();
    chapterIds.addAll(newChapterIds);
    return true;
  }

  Future<bool> _coreDoTask() async {
    final client = RestClient(DioManager.instance.dio);

    // 1. 创建必要文件
    var nomediaPath = PathUtils.joinPath([await _getDownloadMangaDirectory(), '.nomedia']);
    var nomediaFile = File(nomediaPath);
    if (!(await nomediaFile.exists())) {
      await nomediaFile.create(recursive: true);
    }

    // 2. 获取漫画数据
    _updateProgress(
      DownloadMangaProgress.gettingManga(),
    );
    var oldManga = await DownloadDao.getManga(mid: mangaId);
    Manga manga;
    try {
      manga = (await client.getManga(mid: mangaId)).data;
    } catch (e, s) {
      // 请求错误 => 更新漫画下载表为下载错误，然后直接返回
      print(wrapError(e, s).text);
      if (oldManga != null) {
        await DownloadDao.addOrUpdateManga(
          manga: oldManga.copyWith(error: true),
        );
      }
      return false;
    }

    // 3. 更新漫画下载表
    await DownloadDao.addOrUpdateManga(
      manga: DownloadedManga(
        mangaId: manga.mid,
        mangaTitle: manga.title,
        mangaCover: manga.cover,
        mangaUrl: manga.url,
        error: false,
        updatedAt: oldManga?.updatedAt ?? DateTime.now(),
        downloadedChapters: [] /* ignored */,
      ),
    );

    // 4. 先处理所有已下载完的章节
    var alreadyDownloadedChapterIds = <int>[];
    var startedChapters = <MangaChapter?>[];
    for (var chapterId in chapterIds) {
      // 4.1. 判断请求是否被取消
      if (canceled) {
        // 被取消 => 直接结束
        return false;
      }

      // 4.2. 判断当前章节是否下载完
      var oldChapter = oldManga?.downloadedChapters.where((el) => el.chapterId == chapterId).firstOrNull;
      if (oldChapter == null || !oldChapter.succeeded) {
        continue;
      }

      // 4.3. 根据请求获得的漫画数据更新章节下载表
      var chapterTuple = manga.chapterGroups.findChapterAndGroupName(chapterId);
      if (chapterTuple != null) {
        await DownloadDao.addOrUpdateChapter(
          chapter: DownloadedChapter(
            mangaId: mangaId,
            chapterId: chapterId,
            chapterTitle: chapterTuple.item1.title,
            chapterGroup: chapterTuple.item2,
            totalPageCount: chapterTuple.item1.pageCount,
            triedPageCount: oldChapter.triedPageCount,
            successPageCount: oldChapter.successPageCount,
          ),
        );
      }

      // 4.4. 记录该章节已下载完
      alreadyDownloadedChapterIds.add(chapterId);
      startedChapters.add(null); // 添加占位
      _updateProgress(
        DownloadMangaProgress.gettingChapter(
          manga: manga,
          startedChapters: startedChapters,
          currentChapterId: chapterId,
        ),
      );
    }

    // 5. 再按顺序处理每一个未下载完的章节
    var somePagedFailed = false;
    for (var i = 0; i < chapterIds.length /* appendable */; i++) {
      // 5.1. 判断请求是否被取消
      if (canceled) {
        // 被取消 => 直接结束
        return false;
      }

      // 5.2. 判断当前章节是否下载完
      var chapterId = chapterIds[i];
      if (alreadyDownloadedChapterIds.contains(chapterId)) {
        continue; // 跳过已下载完的章节
      }
      startedChapters.add(null); // 占位
      _updateProgress(
        DownloadMangaProgress.gettingChapter(
          manga: manga,
          startedChapters: startedChapters,
          currentChapterId: chapterId,
        ),
      );

      // 5.3. 获取章节数据
      MangaChapter chapter;
      try {
        chapter = (await client.getMangaChapter(mid: mangaId, cid: chapterId)).data;
      } catch (e, s) {
        // 请求错误 => 无需更新章节下载表，直接返回
        print(wrapError(e, s).text);
        continue;
      }
      startedChapters[startedChapters.length - 1] = chapter; // 更新占位
      _updateProgress(
        DownloadMangaProgress.gotChapter(
          manga: manga,
          startedChapters: startedChapters,
          currentChapterId: chapterId,
          currentChapter: chapter,
        ),
      );

      // 5.4. 更新章节信息表
      var chapterGroup = manga.chapterGroups.findChapterAndGroupName(chapterId)?.item2 ?? '';
      await DownloadDao.addOrUpdateChapter(
        chapter: DownloadedChapter(
          mangaId: chapter.mid,
          chapterId: chapter.cid,
          chapterTitle: chapter.title,
          chapterGroup: chapterGroup,
          totalPageCount: chapter.pageCount,
          triedPageCount: 0 /* 从零开始 */,
          successPageCount: 0,
        ),
      );

      // 5.5. 按顺序处理章节每一页
      var successChapterPageCount = 0;
      var failedChapterPageCount = 0;
      for (var i = 0; i < chapter.pages.length; i++) {
        // 5.5.1. 判断请求是否被取消
        if (canceled) {
          // 被取消 => 跳出当前页面处理逻辑
          break; // 跳到 5.6
        }

        var pageIndex = i;
        _pageQueue.add(() async {
          // 5.5.2. 判断请求是否被取消
          if (canceled) {
            // 被取消 => 跳出当前页面处理逻辑
            return; // 跳到 5.6
          }

          // 5.5.3. 下载页面（文件已存在则跳过下载）
          var pageUrl = chapter.pages[pageIndex];
          var ok = await _downloadChapterPage(
            mangaId: chapter.mid,
            chapterId: chapter.cid,
            pageIndex: pageIndex,
            url: pageUrl,
          );
          if (!ok) {
            failedChapterPageCount++;
            somePagedFailed = true;
          } else {
            successChapterPageCount++;
          }

          // 5.5.4. 通知页面下载进度
          _updateProgress(
            DownloadMangaProgress.gotPage(
              manga: manga,
              startedChapters: startedChapters,
              currentChapterId: chapterId,
              currentChapter: chapter,
              triedChapterPageCount: successChapterPageCount + failedChapterPageCount,
              successChapterPageCount: successChapterPageCount,
            ),
          );
        }).onError((e, _) {
          if (e is! QueueCancelledException) {
            print(e);
          } // 跳到 5.7
        });
      } // for in chapter.pages

      try {
        // 5.6. 判断请求是否被取消
        if (canceled) {
          // 被取消 => 直接取消页面下载队列，在返回前会更新章节下载表
          _pageQueue.cancel();
          return false;
        } else {
          // 不被取消 => 等待章节中所有页面处理结束
          await _pageQueue.onComplete;
        }
      } catch (e, _) {
        if (e is! QueueCancelledException) {
          print(e);
        }
      } finally {
        // 5.7. 更新章节下载表 (无论是否被取消，都需要更新)
        await DownloadDao.addOrUpdateChapter(
          chapter: DownloadedChapter(
            mangaId: chapter.mid,
            chapterId: chapter.cid,
            chapterTitle: chapter.title,
            chapterGroup: chapterGroup,
            totalPageCount: chapter.pages.length,
            triedPageCount: successChapterPageCount + failedChapterPageCount,
            successPageCount: successChapterPageCount,
          ),
        );
        var ev = DownloadedMangaEntityChangedEvent(mangaId: mangaId);
        EventBusManager.instance.fire(ev);
      }
    } // for in chapterIds

    // 6. 返回下载结果
    if (somePagedFailed) {
      return false;
    }
    return true;
  }
}

enum DownloadMangaProgressStage {
  waiting,
  gettingManga,
  gettingChapter,
  gotChapter,
  gotPage,
}

class DownloadMangaProgress {
  const DownloadMangaProgress.waiting()
      : stage = DownloadMangaProgressStage.waiting,
        manga = null,
        startedChapters = null,
        currentChapterId = null,
        currentChapter = null,
        triedChapterPageCount = null,
        successChapterPageCount = null;

  const DownloadMangaProgress.gettingManga()
      : stage = DownloadMangaProgressStage.gettingManga,
        manga = null,
        currentChapterId = null,
        startedChapters = null,
        currentChapter = null,
        triedChapterPageCount = null,
        successChapterPageCount = null;

  const DownloadMangaProgress.gettingChapter({
    required Manga this.manga,
    required List<MangaChapter?> this.startedChapters,
    required int this.currentChapterId,
  })  : stage = DownloadMangaProgressStage.gettingChapter,
        currentChapter = null,
        triedChapterPageCount = null,
        successChapterPageCount = null;

  const DownloadMangaProgress.gotChapter({
    required Manga this.manga,
    required List<MangaChapter?> this.startedChapters,
    required int this.currentChapterId,
    required MangaChapter this.currentChapter,
  })  : stage = DownloadMangaProgressStage.gotChapter,
        triedChapterPageCount = null,
        successChapterPageCount = null;

  const DownloadMangaProgress.gotPage({
    required Manga this.manga,
    required List<MangaChapter?> this.startedChapters,
    required int this.currentChapterId,
    required MangaChapter this.currentChapter,
    required int this.triedChapterPageCount,
    required int this.successChapterPageCount,
  }) : stage = DownloadMangaProgressStage.gotPage;

  // 当前阶段
  final DownloadMangaProgressStage stage;

  // 已获得/已开始的数据
  final Manga? manga;
  final List<MangaChapter?>? startedChapters;

  // 当前下载的章节
  final int? currentChapterId;
  final MangaChapter? currentChapter;
  final int? triedChapterPageCount;
  final int? successChapterPageCount;
}
