import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/dlg/manga_dialog.dart';
import 'package:manhuagui_flutter/page/dlg/setting_dl_dialog.dart';
import 'package:manhuagui_flutter/page/download.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/manga_viewer.dart';
import 'package:manhuagui_flutter/page/page/dl_finished.dart';
import 'package:manhuagui_flutter/page/page/dl_unfinished.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/download_chapter_line.dart';
import 'package:manhuagui_flutter/page/view/download_manga_line.dart';
import 'package:manhuagui_flutter/page/view/fit_system_screenshot.dart';
import 'package:manhuagui_flutter/page/view/later_manga_banner.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/db/later_manga.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/storage/download.dart';
import 'package:manhuagui_flutter/service/storage/download_task.dart';
import 'package:manhuagui_flutter/service/storage/queue_manager.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 下载管理页，查询数据库并展示 [DownloadedManga] 信息，以及展示 [DownloadProgressChangedEvent] 进度信息
class DownloadMangaPage extends StatefulWidget {
  const DownloadMangaPage({
    Key? key,
    required this.mangaId,
    this.gotoDownloading = false,
  }) : super(key: key);

  final int mangaId;
  final bool gotoDownloading;

  @override
  State<DownloadMangaPage> createState() => _DownloadMangaPageState();

  static RouteSettings buildRouteSetting({required int mangaId}) {
    return RouteSettings(
      name: '/DownloadedMangaPage',
      arguments: <String, Object>{'mangaId': mangaId},
    );
  }

  static bool isCurrentRoute(BuildContext context, int mangaId) {
    var setting = RouteSettings();
    Navigator.popUntil(context, (route) {
      setting = route.settings;
      return true;
    });

    if (setting.name != '/DownloadedMangaPage' || setting.arguments is! Map<String, Object>) {
      return false;
    }
    return (setting.arguments! as Map<String, Object>)['mangaId'] == mangaId;
  }
}

class _DownloadMangaPageState extends State<DownloadMangaPage> with SingleTickerProviderStateMixin, FitSystemScreenshotMixin {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _tabBarKey = GlobalKey<State<StatefulWidget>>();
  late final _tabController = TabController(length: 2, vsync: this);
  final _physicsController = CustomScrollPhysicsController();
  final _actionControllers = [ActionController(), ActionController()];
  final _scrollViewKey = GlobalKey();
  final _scrollController = ScrollController();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
    WidgetsBinding.instance?.addPostFrameCallback((_) => widget.gotoDownloading.ifTrue(() => _tabController.animateTo(1)));

    _cancelHandlers.add(EventBusManager.instance.listen<DownloadProgressChangedEvent>((ev) => _updateByEvent(progressEvent: ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadUpdatedEvent>((ev) => _updateByEvent(entityEvent: ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<HistoryUpdatedEvent>((ev) => _updateByEvent(historyEvent: ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<FootprintUpdatedEvent>((ev) => _updateByEvent(footprintEvent: ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<LaterUpdatedEvent>((ev) => _updateByEvent(laterEvent: ev)));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  var _loading = true; // initialize to true
  DownloadedManga? _data;
  var _error = '';

  DownloadMangaQueueTask? _task;
  var _byte = 0;
  MangaHistory? _history;
  Map<int, ChapterFootprint>? _footprints;
  LaterManga? _later;
  Manga? _mangaData; // loaded in background
  var _onlineMode = AppSetting.instance.dl.defaultToOnlineMode;
  var _showAllChapters = false;
  var _invertOrder = true;

  Future<void> _loadData() async {
    _loading = true;
    _data = null;
    _task = null;
    _byte = 0;
    _history = null;
    _footprints = null;
    _later = null;
    _mangaData = null;
    if (mounted) setState(() {});

    // 若为同步模式，则在最初加载时同时异步请求漫画数据
    if (_onlineMode) {
      // 同步模式会使得 MangaViewerPage 阻塞请求漫画数据，所以需要提前加载
      _loadMangaDataAsync(forceRefresh: false);
    }

    // 获取漫画下载记录，并更新下载任务等数据
    var data = await DownloadDao.getManga(mid: widget.mangaId);
    if (data != null) {
      _data = null;
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(kFlashListDuration);
      _data = data;
      _task = QueueManager.instance.getDownloadMangaQueueTask(widget.mangaId);
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);
      _footprints = await HistoryDao.getMangaFootprintsSet(username: AuthManager.instance.username, mid: widget.mangaId) ?? {};
      _later = await LaterMangaDao.getLaterManga(username: AuthManager.instance.username, mid: widget.mangaId);
      getDownloadedMangaBytes(mangaId: widget.mangaId).then((b) => mountedSetState(() => _byte = b)); // 在每次刷新时都重新统计文件大小
    } else {
      _error = '暂无漫画下载记录';
    }
    _loading = false;
    if (mounted) setState(() {});
  }

  Future<void> _updateByEvent({
    DownloadProgressChangedEvent? progressEvent,
    DownloadUpdatedEvent? entityEvent,
    HistoryUpdatedEvent? historyEvent,
    FootprintUpdatedEvent? footprintEvent,
    LaterUpdatedEvent? laterEvent,
  }) async {
    if (progressEvent != null && progressEvent.mangaId == widget.mangaId) {
      var task = QueueManager.instance.getDownloadMangaQueueTask(widget.mangaId);
      if (progressEvent.finished) {
        mountedSetState(() => _task = null);
      } else if (task != null) {
        mountedSetState(() => _task = task);
        if (task.progress.stage == DownloadMangaProgressStage.waiting || task.progress.stage == DownloadMangaProgressStage.gotChapter) {
          getDownloadedMangaBytes(mangaId: widget.mangaId).then((b) => mountedSetState(() => _byte = b)); // 仅在最开始等待、以及每次获得新章节时才统计文件大小
        }
      }
    }

    if (entityEvent != null && entityEvent.mangaId == widget.mangaId && !entityEvent.fromDownloadMangaPage) {
      var entity = await DownloadDao.getManga(mid: widget.mangaId);
      if (entity != null) {
        mountedSetState(() => _data = entity);
        getDownloadedMangaBytes(mangaId: widget.mangaId).then((b) => mountedSetState(() => _byte = b)); // 在每次数据库发生变化时都统计文件大小
      }
    }

    if (historyEvent != null && historyEvent.mangaId == widget.mangaId) {
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);
      if (mounted) setState(() {});
    }

    if (footprintEvent != null && footprintEvent.mangaId == widget.mangaId) {
      _footprints = await HistoryDao.getMangaFootprintsSet(username: AuthManager.instance.username, mid: widget.mangaId) ?? {};
      if (mounted) setState(() {});
    }

    if (laterEvent != null && laterEvent.mangaId == widget.mangaId) {
      _later = await LaterMangaDao.getLaterManga(username: AuthManager.instance.username, mid: widget.mangaId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadMangaDataAsync({bool forceRefresh = false}) async {
    if (_mangaData != null && !forceRefresh) {
      return;
    }

    final client = RestClient(DioManager.instance.dio);
    try {
      var result = await client.getManga(mid: widget.mangaId);
      if (result.data.title != '' /* 确保获取的漫画数据没有问题 */) {
        _mangaData = result.data;
      }
    } catch (e, s) {
      wrapError(e, s); // ignored
    }
  }

  Future<void> _startOrPauseManga({required bool start}) async {
    if (!start) {
      // 暂停 => 获取最新的任务，并取消
      _task = QueueManager.instance.getDownloadMangaQueueTask(widget.mangaId);
      if (_task != null && !_task!.cancelRequested) {
        _task?.cancel();
      }
      return;
    }

    // 开始 => 构造任务、同步准备、入队
    await quickBuildDownloadMangaQueueTask(
      mangaId: _data!.mangaId,
      mangaTitle: _data!.mangaTitle,
      mangaCover: _data!.mangaCover,
      mangaUrl: _data!.mangaUrl,
      chapterIds: _data!.downloadedChapters.map((el) => el.chapterId).toList(),
      alsoAddTask: true,
      throughGroupList: null,
      throughChapterList: _data!.downloadedChapters,
    );
  }

  Future<void> _startOrPauseChapter(int chapterId, {required bool start}) async {
    if (!start) {
      // 暂停 => 获取最新的任务，并取消
      _task = QueueManager.instance.getDownloadMangaQueueTask(widget.mangaId);
      _task?.cancelChapter(chapterId);
      return;
    }

    // 开始 => 构造任务、同步准备、入队
    await quickBuildDownloadMangaQueueTask(
      mangaId: _data!.mangaId,
      mangaTitle: _data!.mangaTitle,
      mangaCover: _data!.mangaCover,
      mangaUrl: _data!.mangaUrl,
      chapterIds: [chapterId],
      alsoAddTask: true,
      throughGroupList: null,
      throughChapterList: _data!.downloadedChapters,
    );
  }

  Future<void> _adjustChapterDetails(int chapterId) async {
    var entity = _data?.downloadedChapters.where((el) => el.chapterId == chapterId).firstOrNull;
    if (entity == null) {
      return;
    }

    var progress = DownloadChapterLineProgress.fromEntityAndTask(entity: entity, task: _task);
    var status = progress.status;
    var canStart = status == DownloadChapterLineStatus.paused || status == DownloadChapterLineStatus.succeeded || status == DownloadChapterLineStatus.nupdate || status == DownloadChapterLineStatus.failed;
    var canPause = status == DownloadChapterLineStatus.waiting || status == DownloadChapterLineStatus.preparing || status == DownloadChapterLineStatus.downloading;
    var allFinished = status == DownloadChapterLineStatus.succeeded || status == DownloadChapterLineStatus.nupdate;

    void popAndCall(BuildContext context, Function callback) {
      Navigator.of(context).pop();
      callback();
    }

    Future<void> updateNeedUpdate(bool needUpdate) async {
      // 更新数据库、更新列表显示、发送通知
      var newChapter = entity.copyWith(needUpdate: needUpdate);
      await DownloadDao.addOrUpdateChapter(chapter: newChapter);
      _data?.downloadedChapters.replaceWhere((item) => item.chapterId == chapterId, (_) => newChapter);
      if (mounted) setState(() {});
      EventBusManager.instance.fire(DownloadUpdatedEvent(mangaId: widget.mangaId, fromDownloadMangaPage: true));
    }

    await showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(entity.chapterTitle),
        children: [
          IconTextDialogOption(
            icon: Icon(Icons.import_contacts),
            text: Text('阅读该章节'),
            onPressed: () => popAndCall(c, () => _readChapter(chapterId)),
          ),
          IconTextDialogOption(
            icon: Icon(Icons.delete),
            text: Text('删除该章节'),
            onPressed: () => popAndCall(c, () => _deleteChapters(chapterIds: [chapterId])),
          ),
          if (canStart)
            IconTextDialogOption(
              icon: Icon(Icons.play_arrow),
              text: Text('开始下载'),
              onPressed: () => popAndCall(c, () => _startOrPauseChapter(chapterId, start: true)),
            ),
          if (canPause)
            IconTextDialogOption(
              icon: Icon(Icons.pause),
              text: Text('暂停下载'),
              onPressed: () => popAndCall(c, () => _startOrPauseChapter(chapterId, start: false)),
            ),
          if (allFinished && !entity.needUpdate)
            IconTextDialogOption(
              icon: Icon(Icons.update),
              text: Text('标记为需要更新数据'),
              onPressed: () => popAndCall(c, () => updateNeedUpdate(true)),
            ),
          if (allFinished && entity.needUpdate)
            IconTextDialogOption(
              icon: Icon(Icons.update_disabled),
              text: Text('标记为不需要更新数据'),
              onPressed: () => popAndCall(c, () => updateNeedUpdate(false)),
            ),
        ],
      ),
    );
  }

  void _readChapter(int chapterId) {
    // 此处不异步请求漫画数据，由 MangaViewerPage 请求并回传更新 _mangaData，从而避免重复请求
    // _loadMangaDataAsync(forceRefresh: false);

    void __gotoViewerPage({required int cid, required int page}) {
      Navigator.of(context).push(
        CustomPageRoute(
          context: context,
          builder: (c) => MangaViewerPage(
            mangaId: widget.mangaId,
            chapterId: cid /* <<< */,
            mangaTitle: _data!.mangaTitle,
            mangaCover: _data!.mangaCover,
            mangaUrl: _data!.mangaUrl,
            neededData: MangaChapterNeededData.fromNullableMangaData(_mangaData) /* nullable */,
            initialPage: page /* <<< */,
            onlineMode: _onlineMode,
            onMangaGot: (manga) => _mangaData = manga,
          ),
        ),
      );
    }

    if (_history == null || (_history!.chapterId != chapterId && _history!.lastChapterId != chapterId)) {
      // (1) 所选章节不是上次/上上次阅读的章节 => 直接从第一页阅读
      __gotoViewerPage(cid: chapterId, page: 1);
      return;
    }

    // (2) 所选章节在上次/上上次被阅读 => 弹出选项判断是否需要阅读
    var historyTitle = _history!.chapterId == chapterId ? _history!.chapterTitle : _history!.lastChapterTitle;
    var historyPage = _history!.chapterId == chapterId ? _history!.chapterPage : _history!.lastChapterPage;
    var chapter = _data!.downloadedChapters.where((c) => c.chapterId == chapterId).firstOrNull;
    if (chapter == null) {
      showYesNoAlertDialog(context: context, title: Text('章节阅读'), content: Text('未找到所选章节，无法阅读。'), yesText: Text('确定'), noText: null);
      return; // actually unreachable
    }
    var checkNotfin = AppSetting.instance.ui.readGroupBehavior.needCheckNotfin(currentPage: historyPage, totalPage: chapter.totalPageCount); // 是否检查"未阅读完"
    var checkFinish = AppSetting.instance.ui.readGroupBehavior.needCheckFinish(currentPage: historyPage, totalPage: chapter.totalPageCount); // 是否检查"已阅读完"
    if (!checkNotfin && !checkFinish) {
      // (2.1) 所选章节无需弹出提示 => 继续阅读
      __gotoViewerPage(cid: chapterId, page: historyPage);
    } else {
      // (2.2) 所选章节需要弹出提示 (未阅读完/已阅读完) => 根据所选选项来确定阅读行为
      showDialog(
        context: context,
        builder: (c) => SimpleDialog(
          title: Text('章节阅读'),
          children: [
            SubtitleDialogOption(
              text: checkNotfin //
                  ? Text('所选章节 ($historyTitle) 已阅读至第$historyPage页 (共${chapter.totalPageCount}页)，是否继续阅读该页？') // 未阅读完
                  : Text('所选章节 ($historyTitle) 已阅读至最后一页 (第$historyPage页)，是否选择其他章节阅读？'), // 已阅读完
            ),
            ...([
              IconTextDialogOption(
                icon: Icon(CustomIcons.opened_book_arrow_right),
                text: Text('继续阅读所选章节 ($historyTitle 第$historyPage页)'),
                popWhenPress: c,
                onPressed: () => __gotoViewerPage(cid: chapterId, page: historyPage),
              ),
              if (historyPage > 1)
                IconTextDialogOption(
                  icon: Icon(CustomIcons.opened_book_replay),
                  text: Text('从头阅读所选章节 ($historyTitle 第1页)'),
                  popWhenPress: c,
                  onPressed: () => __gotoViewerPage(cid: chapterId, page: 1),
                ),
            ].let(
              (opt) => checkNotfin ? opt /* 未阅读完 */ : opt.reversed /* 已阅读完 */,
            )),
            IconTextDialogOption(
              icon: Icon(Icons.menu),
              text: Text('选择其他章节'),
              popWhenPress: c,
              onPressed: () {}, // <<< 此处不提供新章节供选择阅读
            ),
          ],
        ),
      );
    }
  }

  Future<void> _deleteChapters({required List<int> chapterIds}) async {
    var allEntities = _invertOrder ? _data!.downloadedChapters.reversed : _data!.downloadedChapters; // chapters are in cid asc order
    var entities = allEntities.where((el) => chapterIds.contains(el.chapterId)).toList();
    if (entities.isEmpty) {
      return;
    }
    _task = QueueManager.instance.getDownloadMangaQueueTask(widget.mangaId);
    if (_task != null) {
      Fluttertoast.showToast(msg: '请先暂停下载，然后再删除章节');
      return;
    }

    var alsoDeleteFile = AppSetting.instance.dl.defaultToDeleteFiles;
    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, _setState) => AlertDialog(
          title: Text('删除确认'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entities.length == 1) Text('是否删除《${entities.first.chapterTitle}》章节？\n'),
              if (entities.length > 1)
                Text(
                  '是否删除以下 ${entities.length} 个章节？\n\n' + //
                      ([for (int i = 0; i < entities.length; i++) '${i + 1}. 《${entities[i].chapterTitle}》'].join('\n') + '\n'),
                ),
              CheckboxListTile(
                title: Text('同时删除已下载的文件'),
                value: alsoDeleteFile,
                onChanged: (v) => _setState(() => alsoDeleteFile = v ?? false),
                visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(child: Text('删除'), onPressed: () => Navigator.of(c).pop(true)),
            TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
          ],
        ),
      ),
    );
    if (ok != true) {
      return;
    }

    // 退出多选模式、保存设置
    _actionControllers.forEach((action) => action.invoke('exitMultiSelectionMode'));
    await updateDlSettingDefaultToDeleteFiles(alsoDeleteFile);

    // 更新数据库、更新列表显示
    for (var chapterId in chapterIds) {
      await DownloadDao.deleteChapter(mid: widget.mangaId, cid: chapterId);
      _data!.downloadedChapters.removeWhere((chapter) => chapter.chapterId == chapterId);
    }
    if (mounted) setState(() {});

    // 删除文件并统计大小、最后再发送通知
    if (alsoDeleteFile) {
      for (var chapterId in chapterIds) {
        await deleteDownloadedChapter(mangaId: widget.mangaId, chapterId: chapterId);
      }
      getDownloadedMangaBytes(mangaId: widget.mangaId).then((b) => mountedSetState(() => _byte = b)); // 删除文件后遍历统计文件大小
    }
    EventBusManager.instance.fire(DownloadUpdatedEvent(mangaId: widget.mangaId, fromDownloadMangaPage: true));
  }

  @override
  FitSystemScreenshotData get fitSystemScreenshotData => FitSystemScreenshotData(
    scrollViewKey: _scrollViewKey,
    scrollController: _scrollController,
  );

  @override
  Widget build(BuildContext context) {
    return DrawerScaffold(
      appBar: AppBar(
        title: Text('漫画下载管理'),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: false),
        actions: [
          PopupMenuButton(
            child: Builder(
              builder: (c) => AppBarActionButton(
                icon: Icon(Icons.more_vert),
                tooltip: '更多选项',
                onPressed: () => c.findAncestorStateOfType<PopupMenuButtonState>()?.showButtonMenu(),
              ),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                child: IconTextMenuItem(Icons.settings, '漫画下载设置'),
                onTap: () => WidgetsBinding.instance?.addPostFrameCallback(
                  (_) => showDlSettingDialog(context: context),
                ),
              ),
              PopupMenuItem(
                child: IconTextMenuItem(Icons.format_list_bulleted, '查看漫画下载列表'),
                onTap: () => WidgetsBinding.instance?.addPostFrameCallback(
                  (_) => Navigator.of(context).push(
                    CustomPageRoute(
                      context: context,
                      builder: (c) => DownloadPage(),
                    ),
                  ),
                ),
              ),
              PopupMenuItem(
                child: IconTextMenuItem(
                  _showAllChapters ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                  '显示所有章节的下载状态',
                ),
                onTap: () => mountedSetState(() => _showAllChapters = !_showAllChapters),
              ),
              if (_data != null && !_data!.error && _data!.allChaptersEitherSucceededOrNeedUpdate)
                PopupMenuItem(
                  child: IconTextMenuItem(
                    !_data!.needUpdate ? Icons.update : Icons.update_disabled,
                    !_data!.needUpdate ? '标记为需要更新数据' : '标记为不需要更新数据',
                  ),
                  onTap: () async {
                    // 更新数据库、更新数据、发送通知
                    var newEntity = _data!.copyWith(needUpdate: !_data!.needUpdate);
                    await DownloadDao.addOrUpdateManga(manga: newEntity);
                    _data = newEntity;
                    if (mounted) setState(() {});
                    EventBusManager.instance.fire(DownloadUpdatedEvent(mangaId: widget.mangaId, fromDownloadMangaPage: true));
                  },
                ),
            ],
          ),
        ],
      ),
      drawer: AppDrawer(
        currentSelection: DrawerSelection.none,
      ),
      drawerEdgeDragWidth: null,
      physicsController: _physicsController,
      implicitlyOverscrollableScaffold: true,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        notificationPredicate: (n) => n.depth <= 2,
        onRefresh: _loadData,
        child: PlaceholderText.from(
          isLoading: _loading,
          errorText: _error,
          isEmpty: _data == null,
          setting: PlaceholderSetting().copyWithChinese(),
          onRefresh: () => _loadData(),
          childBuilder: (c) => ExtendedNestedScrollView(
            key: _scrollViewKey,
            controller: _scrollController,
            headerSliverBuilder: (context, _) => [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // ****************************************************************
                    // 漫画下载信息头部
                    // ****************************************************************
                    Container(
                      color: Colors.white,
                      child: DownloadMangaBlockView(
                        mangaEntity: _data!,
                        downloadTask: _task,
                        downloadedBytes: _byte,
                      ),
                    ),
                    // ****************************************************************
                    // 稍后阅读
                    // ****************************************************************
                    if (_later != null)
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LaterMangaBannerView(
                          manga: _later!,
                          currentNewestChapter: _mangaData?.newestChapter,
                          currentNewestDate: _mangaData?.formattedNewestDate,
                          action: () => showPopupMenuForLaterManga(
                            context: context,
                            mangaId: _data!.mangaId,
                            mangaTitle: _data!.mangaTitle,
                            mangaCover: _data!.mangaCover,
                            mangaUrl: _data!.mangaUrl,
                            extraData: _mangaData == null ? null : MangaExtraDataForDialog.fromManga(_mangaData!),
                            fromMangaPage: false,
                            laterManga: _later!,
                            inLaterSetter: (l) {
                              // (更新数据库)、更新界面[↴]、(弹出提示)、(发送通知)
                              _later = l;
                              if (mounted) setState(() {});
                            },
                          ),
                        ),
                      ),
                    Container(height: 12),
                    // ****************************************************************
                    // 五个按钮
                    // ****************************************************************
                    Container(
                      color: Colors.white,
                      child: ActionRowView.five(
                        action1: ActionItem.simple(
                          '查看漫画',
                          MdiIcons.bookOutline,
                          () => Navigator.of(context).push(
                            CustomPageRoute(
                              context: context,
                              builder: (c) => MangaPage(
                                id: widget.mangaId,
                                title: _data!.mangaTitle,
                                url: _data!.mangaUrl,
                              ),
                            ),
                          ),
                          longPress: () => showPopupMenuForMangaList(
                            context: context,
                            mangaId: widget.mangaId,
                            mangaTitle: _data!.mangaTitle,
                            mangaCover: _data!.mangaCover,
                            mangaUrl: _data!.mangaUrl,
                            extraData: _mangaData == null ? null : MangaExtraDataForDialog.fromManga(_mangaData!),
                            fromDownloadPage: true,
                          ),
                        ),
                        action2: ActionItem.simple(
                          _onlineMode ? '在线模式' : '离线模式',
                          _onlineMode ? Icons.travel_explore : Icons.public_off,
                          () async {
                            _onlineMode = !_onlineMode;
                            if (mounted) setState(() {});
                            await updateDlSettingDefaultToOnlineMode(_onlineMode);
                          },
                          longPress: () => showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: Text('在线模式与离线模式'),
                              content: Text('从下载列表中阅读章节时，若使用"在线模式"则会通过网络在线获取最新的章节数据，若使用"离线模式"则会使用下载时保存的章节数据。'),
                              actions: [TextButton(child: Text('确定'), onPressed: () => Navigator.of(c).pop())],
                            ),
                          ),
                        ),
                        action3: ActionItem.simple(
                          _invertOrder ? '逆序显示' : '正序显示',
                          _invertOrder ? MdiIcons.sortDescending : MdiIcons.sortAscending,
                          () => mountedSetState(() => _invertOrder = !_invertOrder),
                        ),
                        action4: ActionItem.simple(
                          '开始下载',
                          Icons.play_arrow,
                          () => _startOrPauseManga(start: true),
                        ),
                        action5: ActionItem.simple(
                          '暂停下载',
                          Icons.pause,
                          () => _startOrPauseManga(start: false),
                        ),
                      ),
                    ),
                    Container(height: 12),
                  ],
                ),
              ),
              SliverOverlapAbsorber(
                handle: ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverPersistentHeader(
                  pinned: true,
                  floating: true,
                  delegate: SliverHeaderDelegate(
                    child: PreferredSize(
                      preferredSize: Size.fromHeight(36.0),
                      child: Material(
                        color: Colors.white,
                        elevation: 2,
                        child: Center(
                          child: TabBar(
                            key: _tabBarKey,
                            controller: _tabController,
                            labelColor: Theme.of(context).primaryColor,
                            unselectedLabelColor: Colors.grey[600],
                            indicatorColor: Theme.of(context).primaryColor,
                            isScrollable: true,
                            indicatorSize: TabBarIndicatorSize.label,
                            tabs: [
                              const SizedBox(height: 36.0, child: Center(child: Text('已完成'))),
                              SizedBox(height: 36.0, child: Center(child: Text(!_showAllChapters ? '未完成' : '所有章节'))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            innerControllerCount: _tabController.length,
            activeControllerIndex: _tabController.index,
            bodyBuilder: (c, controllers) => TabBarView(
              controller: _tabController,
              physics: CustomScrollPhysics(controller: _physicsController),
              children: [
                // ****************************************************************
                // 已完成下载的章节
                // ****************************************************************
                DlFinishedSubPage(
                  innerController: controllers[0],
                  outerController: _scrollController,
                  actionController: _actionControllers[0],
                  injectorHandler: ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor(c),
                  mangaEntity: _data!,
                  invertOrder: _invertOrder,
                  history: _history,
                  footprints: _footprints,
                  toReadChapter: _readChapter,
                  toDeleteChapters: _deleteChapters,
                  toAdjustChapter: _adjustChapterDetails,
                ),
                // ****************************************************************
                // 未完成下载的章节 => 等待下载/正在下载/下载失败
                // ****************************************************************
                DlUnfinishedSubPage(
                  innerController: controllers[1],
                  outerController: _scrollController,
                  actionController: _actionControllers[1],
                  injectorHandler: ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor(c),
                  mangaEntity: _data!,
                  downloadTask: _task,
                  showAllChapters: _showAllChapters,
                  invertOrder: _invertOrder,
                  toReadChapter: _readChapter,
                  toDeleteChapters: _deleteChapters,
                  toControlChapter: _startOrPauseChapter,
                  toAdjustChapter: _adjustChapterDetails,
                ),
              ],
            ),
          ).fitSystemScreenshot(this),
        ),
      ),
    );
  }
}
