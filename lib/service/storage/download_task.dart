import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/storage/download.dart';
import 'package:manhuagui_flutter/service/storage/download_notification.dart';
import 'package:manhuagui_flutter/service/storage/queue_manager.dart';
import 'package:queue/queue.dart';

class DownloadMangaQueueTask extends QueueTask<void> {
  DownloadMangaQueueTask({
    required this.mangaId,
    required this.mangaTitle,
    required this.chapterIds,
    required this.invertOrder,
    required int parallel,
  })  : _doingTask = false,
        _succeeded = false,
        _canceled = false,
        _progress = DownloadMangaProgress.waiting(),
        _pageQueue = Queue(parallel: parallel);

  final int mangaId;
  final String mangaTitle;
  final List<int> chapterIds;
  final bool invertOrder;

  bool _doingTask;

  bool get doingTask => _doingTask;

  bool _succeeded;

  bool get succeeded => _succeeded;

  @override
  Future<void> doTask() async {
    _doingTask = true;
    try {
      _succeeded = await _coreDoTask();
    } catch (_) {}
    _doingTask = false;
    if (!_canceled) {
      DownloadNotificationHelper.showDoneNotification(mangaId, mangaTitle, _succeeded);
    } else {
      DownloadNotificationHelper.cancelNotification(mangaId);
    }
  }

  bool _canceled;

  @override
  bool get canceled => _canceled;

  @override
  void cancel() {
    super.cancel();
    _canceled = true;
    DownloadNotificationHelper.cancelNotification(mangaId);
    if (!_doingTask) {
      // if not running, call defer first
      QueueManager.instance.tasks.remove(this);
      doDefer();
    } else {
      var ev = DownloadMangaProgressChangedEvent(mangaId: mangaId, finished: false);
      EventBusManager.instance.fire(ev);
    }
  }

  @override
  Future<void> doDefer() {
    var ev = DownloadMangaProgressChangedEvent(mangaId: mangaId, finished: true); // finished means task is removed from queue
    EventBusManager.instance.fire(ev);
    var ev2 = DownloadedMangaEntityChangedEvent(mangaId: mangaId);
    EventBusManager.instance.fire(ev2);
    return Future.value(null);
  }

  DownloadMangaProgress _progress;

  DownloadMangaProgress get progress => _progress;

  void _updateProgress(DownloadMangaProgress progress, {bool alsoNotify = false}) {
    _progress = progress;
    if (alsoNotify && !_canceled) {
      DownloadNotificationHelper.showProgressNotification(mangaId, mangaTitle, _progress);
    }
    var ev = DownloadMangaProgressChangedEvent(mangaId: mangaId, finished: false);
    EventBusManager.instance.fire(ev);
  }

  final Queue _pageQueue;

  void changeParallel(int parallel) {
    _pageQueue.parallel = parallel;
  }

  Future<bool> prepare({
    required String mangaCover,
    required String mangaUrl,
    required Tuple3<String, String, int>? Function(int cid) getChapterTitleGroupPages,
  }) async {
    // 1. 更新任务状态
    _updateProgress(
      DownloadMangaProgress.waiting(),
    );

    // 2. 合并请求下载的章节与数据库已有的章节，且保留请求下载章节的顺序
    var oldManga = await DownloadDao.getManga(mid: mangaId);
    var oldChapterIds = oldManga?.downloadedChapters.map((el) => el.chapterId).toList() ?? [];
    var dedupOldChapterIds = oldChapterIds.toList()..removeWhere((el) => chapterIds.contains(el));
    dedupOldChapterIds.sort((i, j) => !invertOrder ? i.compareTo(j) : j.compareTo(i));
    chapterIds.sort((i, j) => !invertOrder ? i.compareTo(j) : j.compareTo(i));
    chapterIds.addAll(dedupOldChapterIds);

    // 3. 检查漫画下载任务是否存在
    List<int> newChapterIds;
    var currentTasks = QueueManager.instance.getDownloadMangaQueueTasks(includingPreparing: false);
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
        error: false /* 恢复为无错误 */,
        updatedAt: (oldManga == null || chapterIds.length > oldChapterIds.length)
            ? DateTime.now() // 有新增下载章节 => 更新为当前时间
            : oldManga.updatedAt /* 没有新增下载章节 => 无需更新时间 */,
        downloadedChapters: [],
        needUpdate: oldManga?.needUpdate ?? true /* 存在则不变，不存在则设为需要更新 */,
      ),
    );

    // 5. 更新章节下载表，并通知数据库发生变化
    for (var chapterId in newChapterIds.toList()) {
      var chapterTuple = getChapterTitleGroupPages(chapterId);
      if (chapterTuple == null) {
        newChapterIds.remove(chapterId); // almost unreachable
        continue;
      }
      var oldChapter = oldManga?.downloadedChapters.where((el) => el.chapterId == chapterId).firstOrNull;
      await DownloadDao.addOrUpdateChapter(
        chapter: DownloadedChapter(
          mangaId: mangaId,
          chapterId: chapterId,
          chapterTitle: chapterTuple.item1,
          chapterGroup: chapterTuple.item2,
          totalPageCount: chapterTuple.item3,
          triedPageCount: oldChapter?.successPageCount ?? 0 /* 将尝试下载页数直接置为已成功下载页数 */,
          successPageCount: oldChapter?.successPageCount ?? 0,
          needUpdate: oldChapter?.needUpdate ?? true /* 存在则不变，不存在则设为需要更新 */,
        ),
      );
    }
    var ev = DownloadedMangaEntityChangedEvent(mangaId: mangaId);
    EventBusManager.instance.fire(ev);

    // 6. 判断是否入队
    if (previousTask != null) {
      // 漫画下载任务已存在 => 往后添加新漫画章节，标记为需要不需要入队
      previousTask.chapterIds.addAll(newChapterIds);
      return false;
    }
    // 新的漫画下载任务 => 整体更新漫画章节，标记为需要入队 (由 doTask 处理准备列表)
    chapterIds.clear();
    chapterIds.addAll(newChapterIds);
    return true;
  }

  Future<bool> _coreDoTask() async {
    final client = RestClient(DioManager.instance.dio);

    // 1. 创建必要文件，并更新状态
    try {
      await createNomediaFile();
    } catch (e, s) {
      // 唯一可能的原因，getPublicStorageDirectoryPath 出错
      globalLogger.e('DownloadMangaQueueTask_createNomediaFile', e, s);
      Fluttertoast.showToast(msg: '无法执行下载操作：$e');
      return false;
    }
    _updateProgress(
      DownloadMangaProgress.gettingManga(),
      alsoNotify: true,
    );

    // 2. 获取漫画数据
    var oldManga = await DownloadDao.getManga(mid: mangaId);
    Manga manga;
    try {
      manga = (await client.getManga(mid: mangaId)).data;
    } catch (e, s) {
      // 请求错误 => 更新漫画下载表为下载错误，然后直接返回
      var we = wrapError(e, s);
      globalLogger.e('DownloadMangaQueueTask_manga: ${we.text}', e, s);
      await Fluttertoast.cancel();
      Fluttertoast.showToast(msg: '获取《$mangaTitle》信息出错：${we.text}');
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
        downloadedChapters: [],
        needUpdate: false,
      ),
    );

    // 4. 先处理所有已下载完的章节
    _updateProgress(
      DownloadMangaProgress.gettingChapter(
        manga: manga,
        startedChapters: [],
        currentChapterId: chapterIds.first,
      ),
      alsoNotify: true,
    );
    var startedChapters = <MangaChapter?>[];
    for (var chapterId in chapterIds) {
      // 4.1. 判断请求是否被取消
      if (canceled) {
        return false; // 被取消 => 直接结束
      }

      // 4.2. 判断当前章节需要继续下载
      var oldChapter = oldManga?.downloadedChapters.where((el) => el.chapterId == chapterId).firstOrNull;
      if (oldChapter == null || !oldChapter.succeeded || oldChapter.needUpdate) {
        continue; // 未找到 / 未成功 / 需要更新 => 后续需要下载该章节
      }

      // 4.3. 根据请求获得的漫画数据更新章节下载表
      var chapterTuple = manga.chapterGroups.findChapterAndGroupName(chapterId);
      if (chapterTuple != null) {
        var totalPageCount = chapterTuple.item1.pageCount;
        await DownloadDao.addOrUpdateChapter(
          chapter: DownloadedChapter(
            mangaId: mangaId,
            chapterId: chapterId,
            chapterTitle: chapterTuple.item1.title,
            chapterGroup: chapterTuple.item2,
            totalPageCount: totalPageCount /* 已下载完的章节，total == tried == success */,
            triedPageCount: totalPageCount,
            successPageCount: totalPageCount,
            needUpdate: false,
          ),
        );
      }

      // 4.4. 往已开始的章节列表添加空占位，并发送通知
      startedChapters.add(null);
      _updateProgress(
        DownloadMangaProgress.gettingChapter(
          manga: manga,
          startedChapters: startedChapters,
          currentChapterId: chapterId,
        ),
      );
    }

    // 5. 再按顺序处理所有未下载完的章节
    var somePagesFailed = false;
    for (var i = 0; i < chapterIds.length /* appendable */; i++) {
      // 5.1. 判断请求是否被取消
      if (canceled) {
        return false; // 被取消 => 直接结束
      }

      // 5.2. 判断当前章节是否下载完
      var chapterId = chapterIds[i];
      var oldChapter = oldManga?.downloadedChapters.where((el) => el.chapterId == chapterId).firstOrNull;
      if (oldChapter != null && oldChapter.succeeded && !oldChapter.needUpdate) {
        continue; // 跳过已下载完且不需要更新的章节
      }

      // 5.3. 获取章节数据，并记录至已开始的章节列表
      startedChapters.add(null); // 占位
      _updateProgress(
        DownloadMangaProgress.gettingChapter(
          manga: manga,
          startedChapters: startedChapters,
          currentChapterId: chapterId,
        ),
        alsoNotify: true,
      );
      MangaChapter chapter;
      try {
        chapter = (await client.getMangaChapter(mid: mangaId, cid: chapterId)).data;
      } catch (e, s) {
        // 请求错误 => 更新章节下载表，并跳过当前章节
        var we = wrapError(e, s);
        globalLogger.e('DownloadMangaQueueTask_chapter: ${we.text}', e, s);
        if (oldChapter != null) {
          await DownloadDao.addOrUpdateChapter(
            chapter: oldChapter.copyWith(
              triedPageCount: oldChapter.totalPageCount /* 直接将漫画章节表的尝试下载页数置为所有页数，表示出错 */,
              successPageCount: oldChapter.successPageCount /* 已成功下载的页数不做变化 */,
            ),
          );
          var ev = DownloadedMangaEntityChangedEvent(mangaId: mangaId);
          EventBusManager.instance.fire(ev);
        }
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
        alsoNotify: true,
      );

      // 5.4. 更新章节信息表以及 metadata
      var chapterGroup = manga.chapterGroups.findChapterAndGroupName(chapterId)?.item2 ?? '';
      await DownloadDao.addOrUpdateChapter(
        chapter: DownloadedChapter(
          mangaId: chapter.mid,
          chapterId: chapter.cid,
          chapterTitle: chapter.title,
          chapterGroup: chapterGroup,
          totalPageCount: chapter.pageCount,
          triedPageCount: 0 /* 从零开始 */,
          successPageCount: 0 /* 从零开始 */,
          needUpdate: false,
        ),
      );
      await writeMetadataFile(mangaId: mangaId, chapterId: chapterId, manga: manga, chapter: chapter);

      // 5.5. 按顺序处理章节每一页
      var successChapterPageCount = 0;
      var failedChapterPageCount = 0;
      for (var i = 0; i < chapter.pages.length; i++) {
        // 5.5.1. 判断请求是否被取消
        if (canceled) {
          break; // 被取消 => 跳出当前页面处理逻辑，跳到 5.6
        }

        var pageIndex = i;
        _pageQueue.add(() async {
          // 5.5.2. 判断请求是否被取消
          if (canceled) {
            return; // 被取消 => 跳出当前页面处理逻辑，跳到 5.6
          }

          // 5.5.3. 下载页面，若文件已存在则跳过
          var pageUrl = chapter.pages[pageIndex];
          var ok = await downloadChapterPage(
            mangaId: chapter.mid,
            chapterId: chapter.cid,
            pageIndex: pageIndex,
            url: pageUrl,
          );
          if (!ok) {
            failedChapterPageCount++;
            somePagesFailed = true;
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
            alsoNotify: true,
          );
        }).onError((e, s) {
          if (e is! QueueCancelledException) {
            var we = wrapError(e, s);
            globalLogger.e('DownloadMangaQueueTask_queue: ${we.text}', e, s);
          } // 出错 => 跳到 5.7
        });
      } // for in chapter.pages

      try {
        // 5.6. 判断请求是否被取消
        if (canceled) {
          // 被取消 => 直接取消页面下载队列，在返回前会跳到 5.7 更新章节下载表
          _pageQueue.cancel();
          return false;
        } else {
          // 不被取消 => 等待章节中所有页面处理结束
          await _pageQueue.onComplete;
        }
      } catch (e, s) {
        if (e is! QueueCancelledException) {
          var we = wrapError(e, s);
          globalLogger.e('DownloadMangaQueueTask_queue: ${we.text}', e, s);
        }
      } finally {
        // 5.7. 无论是否被取消，都需要更新章节下载表
        await DownloadDao.addOrUpdateChapter(
          chapter: DownloadedChapter(
            mangaId: chapter.mid,
            chapterId: chapter.cid,
            chapterTitle: chapter.title,
            chapterGroup: chapterGroup,
            totalPageCount: chapter.pages.length,
            triedPageCount: successChapterPageCount + failedChapterPageCount /* 真实的尝试下载页数 */,
            successPageCount: successChapterPageCount,
            needUpdate: false,
          ),
        );
        var ev = DownloadedMangaEntityChangedEvent(mangaId: mangaId);
        EventBusManager.instance.fire(ev);
      }
    } // for in chapterIds

    // 6. 返回下载结果，用于更新下载任务的 succeeded 标志
    if (somePagesFailed) {
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

extension QueueManagerExtension on QueueManager {
  static final preparingTasks = <DownloadMangaQueueTask>[];

  List<DownloadMangaQueueTask> getDownloadMangaQueueTasks({bool includingPreparing = true}) {
    var prepared = tasks.whereType<DownloadMangaQueueTask>().toList();
    if (!includingPreparing) {
      return prepared;
    }

    var preparing = preparingTasks.toList();
    prepared.addAll(preparing.where((t1) => !prepared.any((t) => t.mangaId == t1.mangaId)));
    return prepared;
  }

  DownloadMangaQueueTask? getDownloadMangaQueueTask(int mangaId) {
    return tasks.whereType<DownloadMangaQueueTask>().where((t) => t.mangaId == mangaId).firstOrNull ?? // prepared
        preparingTasks.where((t) => t.mangaId == mangaId).firstOrNull; // preparing
  }
}

// !!!
Future<DownloadMangaQueueTask?> quickBuildDownloadMangaQueueTask({
  required int mangaId,
  required String mangaTitle,
  required String mangaCover,
  required String mangaUrl,
  required List<int> chapterIds,
  int? parallel,
  bool? invertOrder,
  required bool addToTask,
  //
  List<MangaChapterGroup>? throughGroupList,
  List<DownloadedChapter>? throughChapterList,
}) async {
  // 1. 构造漫画下载任务
  var newTask = DownloadMangaQueueTask(
    mangaId: mangaId,
    mangaTitle: mangaTitle,
    chapterIds: chapterIds,
    parallel: parallel ?? AppSetting.instance.dl.downloadPagesTogether,
    invertOrder: invertOrder ?? AppSetting.instance.dl.invertDownloadOrder,
  );

  // 2. 更新数据库
  QueueManagerExtension.preparingTasks.add(newTask); // 此时还未入队，先添加至"准备列表"中
  var need = await newTask.prepare(
    mangaCover: mangaCover,
    mangaUrl: mangaUrl,
    getChapterTitleGroupPages: (cid) {
      // => DownloadChoosePage
      if (throughGroupList != null) {
        var tuple = throughGroupList.findChapterAndGroupName(cid);
        if (tuple == null) {
          return null; // almost unreachable
        }
        var chapterTitle = tuple.item1.title;
        var groupName = tuple.item2;
        var pageCount = tuple.item1.pageCount;
        return Tuple3(chapterTitle, groupName, pageCount);
      }

      // => DownloadPage / DownloadMangaPage
      if (throughChapterList != null) {
        var chapter = throughChapterList.where((el) => el.chapterId == cid).firstOrNull;
        if (chapter == null) {
          return null; // almost unreachable
        }
        var chapterTitle = chapter.chapterTitle;
        var groupName = chapter.chapterGroup;
        var pageCount = chapter.totalPageCount;
        return Tuple3(chapterTitle, groupName, pageCount);
      }

      // almost unreachable
      assert(
        false,
        'Invalid using of quickBuildDownloadMangaQueueTask, '
        'throughGroupList and throughChapterList must have at least one noo-null value.',
      );
      return null;
    },
  );
  QueueManagerExtension.preparingTasks.removeWhere((el) => el.mangaId == mangaId); // 完成准备，直接从"准备列表"中移除

  // 3. 必要时入队，异步等待执行
  if (!need) {
    return null;
  }
  if (addToTask) {
    QueueManager.instance.addTask(newTask);
  }
  return newTask;
}
