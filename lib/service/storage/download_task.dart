import 'package:flutter/foundation.dart';
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
import 'package:synchronized/synchronized.dart';

class DownloadMangaQueueTask extends QueueTask<void> {
  DownloadMangaQueueTask({
    required this.mangaId,
    required this.mangaTitle,
    required this.chapterIds,
    required this.invertOrder,
    required int parallel,
  })  : _status = _TaskStatus.waiting,
        _canceled = false,
        _progress = DownloadMangaProgress.waiting(),
        _pageQueue = Queue(parallel: parallel);

  final int mangaId;
  final String mangaTitle;
  @protected
  final List<int> chapterIds; // 漫画下载任务内的章节列表，包括已被取消下载的章节
  final bool invertOrder;

  _TaskStatus _status;

  bool get startDoing => _status == _TaskStatus.doing || _status == _TaskStatus.done;

  @override
  Future<void> doTask() async {
    bool succeeded = false;
    _status = _TaskStatus.doing;
    try {
      succeeded = await _coreDoTask();
    } catch (_) {}
    _status = _TaskStatus.done;
    if (!_canceled) {
      await DownloadNotificationHelper.showDoneNotification(mangaId, mangaTitle, succeeded);
    } else {
      await DownloadNotificationHelper.cancelNotification(mangaId);
    }
  }

  bool _canceled;

  @override
  @protected
  bool get canceled => _canceled;

  bool get cancelRequested => _canceled;

  @override
  void cancel() {
    super.cancel();
    _canceled = true;
    DownloadNotificationHelper.cancelNotification(mangaId);
    if (_status == _TaskStatus.waiting) {
      QueueManager.instance.tasks.remove(this); // if task is not running, remove it and call defer immediately
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
    if (alsoNotify) {
      if (!_canceled) {
        DownloadNotificationHelper.showProgressNotification(mangaId, mangaTitle, _progress);
      } else {
        DownloadNotificationHelper.cancelNotification(mangaId);
      }
    }
    var ev = DownloadMangaProgressChangedEvent(mangaId: mangaId, finished: false);
    EventBusManager.instance.fire(ev);
  }

  Queue _pageQueue; // 用于下载章节页面的队列

  void changeParallel(int parallel) {
    _pageQueue.parallel = parallel;
  }

  final _canceledChapters = <int>{}; // 已被取消下载的章节集合

  // 章节是否被请求取消下载
  bool isChapterCancelRequested(int chapterId) => _canceledChapters.contains(chapterId);

  // 在任务中且不被取消下载的章节数量
  int get chaptersLength => chapterIds.where((cid) => !isChapterCancelRequested(cid) || progress.currentChapterId == cid).toSet().length;

  // 章节是否在任务中且不被取消下载
  bool isChapterInTask(int chapterId) => chapterIds.any((cid) => chapterId == cid && (!isChapterCancelRequested(cid) || progress.currentChapterId == cid));

  void cancelChapter(int chapterId) {
    _canceledChapters.add(chapterId); // 不对 chapterIds 做任何修改，仅添加到集合
    var ev = DownloadMangaProgressChangedEvent(mangaId: mangaId, finished: false);
    EventBusManager.instance.fire(ev);
  }

  // 章节是否在任务中且下载已结束
  bool isChapterFinished(int chapterId) {
    return isChapterInTask(chapterId) && // 在任务中
        progress.startedChapterIds != null && // 漫画数据已获取
        progress.startedChapterIds!.contains(chapterId) && // 该章节已经开始下载
        progress.currentChapterId != chapterId; // 当前未在下载该章节
  }

  Future<bool> prepare({
    required String mangaCover,
    required String mangaUrl,
    required Tuple3<String, String, int>? Function(int cid) getChapterTitleGroupPages,
  }) async {
    // 1. 更新任务状态
    _status = _TaskStatus.waiting;
    _updateProgress(
      DownloadMangaProgress.waiting(),
    );

    // 2. 获取数据库已有的漫画数据和章节数据，判断该下载任务中是否有新章节
    var oldManga = await DownloadDao.getManga(mid: mangaId);
    var oldChapterIds = oldManga?.downloadedChapters.map((el) => el.chapterId).toList() ?? [];
    assert(_canceledChapters.isEmpty); // 此时任务刚构建，_canceledChapters 肯定为空
    var containNewChapter = chapterIds.any((el) => !oldChapterIds.contains(el));

    // 3. 检查漫画下载任务是否存在，并获得到新增的章节
    List<int> newChapterIds;
    var currentTasks = QueueManager.instance.getDownloadMangaQueueTasks(includingPreparing: false); // 从已准备好的下载任务中找出当前漫画中新增的章节
    var previousTask = currentTasks.where((el) => el.mangaId == mangaId && !el.canceled).firstOrNull;
    if (previousTask != null) {
      // 下载任务已存在 => 找到新增的章节、下载已结束的章节
      newChapterIds = chapterIds.where((cid) => !previousTask.isChapterInTask(cid) || previousTask.isChapterFinished(cid)).toList();
    } else {
      // 下载任务不存在 => 保持原样，拷贝列表
      newChapterIds = chapterIds.toList();
    }
    print('newChapterIds $newChapterIds');
    if (newChapterIds.isEmpty) {
      // 没有新增章节 => 无需做任何变更，不需要入队
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
        updatedAt: (oldManga == null || containNewChapter)
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
      // 漫画下载任务已存在 => 更新任务进度等，往后添加新章节，不需要入队
      print('漫画下载任务已存在 $newChapterIds');
      for (var cid in newChapterIds) {
        previousTask.progress.startedChapterIds?.remove(cid); // 从"下载进度"中删除新章节
        previousTask._canceledChapters.remove(cid); // 从"取消集合"中删除新章节
        previousTask.chapterIds.add(cid); // 往旧任务后添加新章节
      }
      return false;
    } else {
      // 新的漫画下载任务 => 整体替换当前漫画章节，需要入队
      print('新的漫画下载任务 $newChapterIds');
      chapterIds.clear();
      chapterIds.addAll(newChapterIds);
      return true;
    }
  }

  Future<bool> _coreDoTask() async {
    final client = RestClient(DioManager.instance.dio);

    // 1. 创建必要文件，并更新状态
    print('1. 创建必要文件，并更新状态');
    try {
      await createNomediaFile();
    } catch (e, s) {
      // 唯一可能的原因，在 PublicStorageDirectory 中创建文件时出错
      globalLogger.e('DownloadMangaQueueTask_createNomediaFile', e, s);
      Fluttertoast.showToast(msg: '无法执行下载操作：$e');
      return false;
    }
    _updateProgress(
      DownloadMangaProgress.gettingManga(),
      alsoNotify: true, // 同时更新系统通知栏
    );

    // 2. 获取漫画数据
    print('2. 获取漫画数据');
    var chaptersWhenInit = chapterIds.toList(); // 先记录下载任务刚创建时的待下载章节
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
          manga: oldManga.copyWith(error: true), // 漫画数据获取失败
        );
      }
      return false;
    }

    // 3. 更新漫画下载表
    print('3. 更新漫画下载表');
    await DownloadDao.addOrUpdateManga(
      manga: DownloadedManga(
        mangaId: manga.mid,
        mangaTitle: manga.title,
        mangaCover: manga.cover,
        mangaUrl: manga.url,
        error: false,
        updatedAt: oldManga?.updatedAt ?? DateTime.now(),
        downloadedChapters: [],
        needUpdate: false /* 已被更新，无需更新 */,
      ),
    );

    // 4. 先一次性找出所有无需下载的章节
    print('4. 先一次性找出所有无需下载的章节');
    var startedChapters = <MangaChapter?>[]; // 已开始下载的章节，包括无需下载的章节
    var startedChapterIds = <int>[];
    for (var chapterId in chaptersWhenInit /* 使用最开头记录的章节列表，防止在漫画数据下载途中被新增的章节也在此处被处理 */) {
      // 4.1. 判断请求是否被取消
      print('4.1. 判断请求是否被取消 $chapterId');
      if (canceled) {
        print('(4.1) canceled $chapterId');
        return false; // 被取消 => 直接结束
      }

      // 4.2. 判断当前章节是否需要继续下载
      print('4.2. 判断当前章节是否需要继续下载 $chapterId');
      var oldChapter = oldManga?.downloadedChapters.where((el) => el.chapterId == chapterId).firstOrNull;
      if (oldChapter == null || !oldChapter.succeeded || oldChapter.needUpdate) {
        continue; // 未找到 / 未成功 / 需要更新 => 后续需要下载该章节
      }
      print('(4.2) 跳过 $chapterId');

      // 4.3. 根据最新获得的漫画数据更新章节下载表
      print('4.3. 根据最新获得的漫画数据更新章节下载表 $chapterId');
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

      // 4.4. 更新完章节下载表后，再更新"已开始下载的章节"列表，并发送通知
      print('4.4. 更新完章节下载表后，再更新"已开始下载的章节"列表，并发送通知 $chapterId');
      startedChapters.add(null); // 空占位，章节已完成下载
      startedChapterIds.add(chapterId);
      _updateProgress(
        DownloadMangaProgress.gettingChapter(
          manga: manga,
          startedChapterIds: startedChapterIds,
          currentChapterId: chapterId,
        ),
        alsoNotify: true,
      );
    }

    // 5. 再按顺序处理所有未下载完的章节，此处还会处理中途被新添加的章节
    print('5. 再按顺序处理所有未下载完的章节');
    var somePagesFailed = false;
    for (var i = 0; i < chapterIds.length /* 允许被动态添加 */; i++) {
      // TODO 章节取消后重新开始，调整顺序，需要对 cancel 做手脚

      // 5.1. 判断请求是否被取消
      var chapterId = chapterIds[i];
      print('5.1. 判断请求是否被取消 $chapterId');
      if (canceled) {
        print('(5.1) canceled $chapterId');
        return false; // 漫画下载被取消 => 直接结束
      }
      if (isChapterCancelRequested(chapterId)) {
        print('(5.1) chapter_canceled $chapterId');
        continue; // 章节下载被取消 => 跳过当前章节
      }

      // 5.2. 判断当前章节是否已完成下载
      print('5.2. 判断当前章节是否已完成下载 $chapterId');
      if (progress.startedChapterIds?.contains(chapterId) == true) {
        print('(5.2) 忽略 $chapterId');
        continue; // 当前章节已经被下载过且未被取消后重新开始，忽略
      }
      var oldChapter = oldManga?.downloadedChapters.where((el) => el.chapterId == chapterId).firstOrNull;
      if (oldChapter != null && oldChapter.succeeded && !oldChapter.needUpdate) {
        print('(5.2) 跳过 $chapterId');
        if (!startedChapterIds.contains(chapterId)) {
          startedChapters.add(null); // 占位，新入队的章节已完成下载
          startedChapterIds.add(chapterId);
        }
        continue; // 跳过已下载完且不需要更新的章节
      }

      // 5.3. 获取章节数据，并记录至"已开始下载的章节"列表
      print('5.3. 获取章节数据，并记录至"已开始下载的章节"列表 $chapterId');
      print('(5.3) 下载 $chapterId');
      startedChapters.add(null); // 占位，章节已开始下载
      startedChapterIds.add(chapterId);
      _updateProgress(
        DownloadMangaProgress.gettingChapter(
          manga: manga,
          startedChapterIds: startedChapterIds,
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
              triedPageCount: oldChapter.totalPageCount /* 直接将漫画章节表的尝试下载页数置为所有页数 */,
              successPageCount: oldChapter.successPageCount /* 已成功下载的页数不做变化 */,
            ),
          );
          var ev = DownloadedMangaEntityChangedEvent(mangaId: mangaId);
          EventBusManager.instance.fire(ev);
        }
        continue;
      }
      startedChapters[startedChapters.length - 1] = chapter; // 更新占位的章节数据
      _updateProgress(
        DownloadMangaProgress.gotChapter(
          manga: manga,
          startedChapterIds: startedChapterIds,
          currentChapterId: chapterId,
          currentChapter: chapter,
        ),
        alsoNotify: true,
      );

      // 5.4. 更新章节下载表并写入 metadata 文件
      print('5.4. 更新章节下载表并写入 metadata 文件 $chapterId');
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
          needUpdate: false /* 已被更新，无需更新 */,
        ),
      );
      await writeMetadataFile(
        mangaId: mangaId,
        chapterId: chapterId,
        manga: manga /* 暂不写入漫画数据 */,
        chapter: chapter /* 目前仅写入跳转章节数据和所有页面链接 */,
      ); // 忽略错误

      // 5.5. 按顺序处理章节每一页
      print('5.5. 按顺序处理章节每一页 $chapterId');
      var successChapterPageCount = 0;
      var failedChapterPageCount = 0;
      for (var i = 0; i < chapter.pages.length; i++) {
        // 5.5.1. 判断请求是否被取消
        print('5.5.1. 判断请求是否被取消 $chapterId $i');
        if (canceled || isChapterCancelRequested(chapterId)) {
          print('(5.5.1) canceled || chapter_canceled');
          break; // 漫画下载或章节下载被取消 => 跳出当前页面处理逻辑，跳到 5.6
        }

        var pageIndex = i;
        if (_pageQueue.isCancelled) {
          _pageQueue = Queue(parallel: _pageQueue.parallel); // 若有章节被取消，此时 queue 也会被取消，需要重新初始化
        }
        _pageQueue.add(() async {
          // 5.5.2. 判断请求是否被取消
          print('5.5.2. 判断请求是否被取消 $chapterId $i');
          if (canceled || isChapterCancelRequested(chapterId)) {
            print('(5.5.2) canceled || chapter_canceled');
            return; // 漫画下载或章节下载被取消 => 跳出当前页面处理逻辑，跳到 5.6
          }

          // 5.5.3. 下载页面，若文件已存在则会跳过
          print('5.5.3. 下载页面，若文件已存在则会跳过 $chapterId $i');
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
          print('5.5.4. 通知页面下载进度 $chapterId $i');
          _updateProgress(
            DownloadMangaProgress.gotPage(
              manga: manga,
              startedChapterIds: startedChapterIds,
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
          } // 出错 => 跳到 5.6 与 5.7
        }); // _pageQueue.add().onError
      } // for in chapter.pages

      try {
        // 5.6. 判断请求是否被取消
        print('5.6. 判断请求是否被取消 $chapterId');
        if (canceled) {
          // 漫画下载被取消 => 直接取消页面下载队列，结束漫画下载
          print('(5.6) canceled');
          _pageQueue.cancel();
          return false; // return 前会跳到 5.7 更新章节下载表
        }
        if (isChapterCancelRequested(chapterId)) {
          // 章节下载被取消 => 直接取消页面下载队列，跳过当前章节
          print('(5.6) chapter_canceled');
          _pageQueue.cancel();
          continue; // continue 前会跳到 5.7 更新章节下载表
        }
        // 不被取消 => 等待章节中所有页面处理结束
        await _pageQueue.onComplete;
      } catch (e, s) {
        if (e is! QueueCancelledException) {
          var we = wrapError(e, s);
          globalLogger.e('DownloadMangaQueueTask_queue: ${we.text}', e, s);
        }
      } finally {
        // 5.7. 无论是否被取消，都需要更新章节下载表
        print('5.7. 无论是否被取消，都需要更新章节下载表 $chapterId');
        await DownloadDao.addOrUpdateChapter(
          chapter: DownloadedChapter(
            mangaId: chapter.mid,
            chapterId: chapter.cid,
            chapterTitle: chapter.title,
            chapterGroup: chapterGroup,
            totalPageCount: chapter.pages.length,
            triedPageCount: successChapterPageCount + failedChapterPageCount /* 真实的尝试下载页数 */,
            successPageCount: successChapterPageCount,
            needUpdate: false /* 已被更新，无需更新 */,
          ),
        );
        var ev = DownloadedMangaEntityChangedEvent(mangaId: mangaId);
        EventBusManager.instance.fire(ev);
      } // try-catch-finally
    } // for in chapterIds

    // 6. 返回下载结果，仅用于发送系统通知
    print('6. 返回下载结果');
    if (somePagesFailed) {
      return false;
    }
    return true;
  }
}

enum _TaskStatus {
  waiting,
  doing,
  done,
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
        startedChapterIds = null,
        currentChapterId = null,
        currentChapter = null,
        triedChapterPageCount = null,
        successChapterPageCount = null;

  const DownloadMangaProgress.gettingManga()
      : stage = DownloadMangaProgressStage.gettingManga,
        manga = null,
        startedChapterIds = null,
        currentChapterId = null,
        currentChapter = null,
        triedChapterPageCount = null,
        successChapterPageCount = null;

  const DownloadMangaProgress.gettingChapter({
    required Manga this.manga,
    required List<int> this.startedChapterIds,
    required int this.currentChapterId,
  })  : stage = DownloadMangaProgressStage.gettingChapter,
        currentChapter = null,
        triedChapterPageCount = null,
        successChapterPageCount = null;

  const DownloadMangaProgress.gotChapter({
    required Manga this.manga,
    required List<int> this.startedChapterIds,
    required int this.currentChapterId,
    required MangaChapter this.currentChapter,
  })  : stage = DownloadMangaProgressStage.gotChapter,
        triedChapterPageCount = null,
        successChapterPageCount = null;

  const DownloadMangaProgress.gotPage({
    required Manga this.manga,
    required List<int> this.startedChapterIds,
    required int this.currentChapterId,
    required MangaChapter this.currentChapter,
    required int this.triedChapterPageCount,
    required int this.successChapterPageCount,
  }) : stage = DownloadMangaProgressStage.gotPage;

  // 当前阶段
  final DownloadMangaProgressStage stage;

  // 已获得/已开始的数据
  final Manga? manga;
  final List<int>? startedChapterIds;

  // 当前正在下载的章节
  final int? currentChapterId;
  final MangaChapter? currentChapter;
  final int? triedChapterPageCount;
  final int? successChapterPageCount;
}

extension QueueManagerExtension on QueueManager {
  static final preparingTasks = <DownloadMangaQueueTask>[]; // 正在准备的任务列表

  List<DownloadMangaQueueTask> getDownloadMangaQueueTasks({bool includingPreparing = true}) {
    var prepared = tasks.whereType<DownloadMangaQueueTask>().toList();
    if (!includingPreparing) {
      return prepared; // 仅返回已完成准备的任务列表，只用于下载任务的准备阶段
    }

    var preparing = preparingTasks.toList();
    prepared.addAll(preparing.where((t1) => !prepared.any((t) => t.mangaId == t1.mangaId)));
    return prepared;
  }

  DownloadMangaQueueTask? getDownloadMangaQueueTask(int mangaId, {bool includingPreparing = true}) {
    return tasks.whereType<DownloadMangaQueueTask>().where((t) => t.mangaId == mangaId).firstOrNull ?? // prepared
        (includingPreparing ? preparingTasks.where((t) => t.mangaId == mangaId).firstOrNull : null); // preparing
  }
}

List<int> filterNeedDownloadChapterIds({required List<int> chapterIds, required List<DownloadedChapter> downloadedChapters}) {
  var out = <int>[];
  for (var cid in chapterIds) {
    var oldChapter = downloadedChapters.where((el) => el.chapterId == cid).firstOrNull;
    if (oldChapter != null && oldChapter.succeeded && oldChapter.needUpdate) {
      continue; // 过滤被记录过、且已下载成功、且不需要更新的章节
    }
    out.add(cid);
  }
  return out;
}

var _lockForPrepare = Lock();

// !!!
Future<DownloadMangaQueueTask?> quickBuildDownloadMangaQueueTask({
  required int mangaId,
  required String mangaTitle,
  required String mangaCover,
  required String mangaUrl,
  required List<int> chapterIds,
  required bool alsoAddTask,
  List<MangaChapterGroup>? throughGroupList,
  List<DownloadedChapter>? throughChapterList,
}) async {
  // 1. 构造漫画下载任务
  var newTask = DownloadMangaQueueTask(
    mangaId: mangaId,
    mangaTitle: mangaTitle,
    chapterIds: chapterIds,
    invertOrder: AppSetting.instance.dl.invertDownloadOrder,
    parallel: AppSetting.instance.dl.downloadPagesTogether,
  );

  // 2. 准备该任务，即更新数据库，需要全局同步
  QueueManagerExtension.preparingTasks.add(newTask); // 此时还未入队，先添加至"准备列表"中，再准备任务
  var needEnqueue = await _lockForPrepare.synchronized(() async {
    return await newTask.prepare(
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
          'throughGroupList and throughChapterList must have at least one not-null value.',
        );
        return null;
      },
    );
  });
  QueueManagerExtension.preparingTasks.removeWhere((el) => el.mangaId == mangaId); // 完成准备，直接从"准备列表"中移除

  // 3. 必要时入队，异步等待执行
  if (!needEnqueue) {
    return null;
  }
  if (alsoAddTask) {
    QueueManager.instance.addTask(newTask);
  }
  return newTask;
}
