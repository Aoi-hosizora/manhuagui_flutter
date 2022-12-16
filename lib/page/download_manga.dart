import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/download.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/manga_viewer.dart';
import 'package:manhuagui_flutter/page/page/dl_finished.dart';
import 'package:manhuagui_flutter/page/page/dl_setting.dart';
import 'package:manhuagui_flutter/page/page/dl_unfinished.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/download_chapter_line.dart';
import 'package:manhuagui_flutter/page/view/download_manga_line.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/storage/download.dart';
import 'package:manhuagui_flutter/service/storage/download_task.dart';
import 'package:manhuagui_flutter/service/storage/queue_manager.dart';

/// 下载管理页，查询数据库并展示 [DownloadedManga] 信息，以及展示 [DownloadMangaProgressChangedEvent] 进度信息
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

class _DownloadMangaPageState extends State<DownloadMangaPage> with SingleTickerProviderStateMixin {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _tabBarKey = GlobalKey<State<StatefulWidget>>();
  late final _tabController = TabController(length: 2, vsync: this);
  final _physicsController = CustomScrollPhysicsController();
  final _scrollController = ScrollController();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _refreshIndicatorKey.currentState?.show());
    WidgetsBinding.instance?.addPostFrameCallback((_) => widget.gotoDownloading.ifTrue(() => _tabController.animateTo(1)));

    var updater = _updateData();
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadMangaProgressChangedEvent>((ev) => updater.item1(ev.mangaId, ev.finished)));
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadedMangaEntityChangedEvent>((ev) => updater.item2(ev.mangaId)));
    _cancelHandlers.add(EventBusManager.instance.listen<HistoryUpdatedEvent>((_) async {
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);
      if (mounted) setState(() {});
    }));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  var _loading = true;
  DownloadedManga? _entity;
  DownloadMangaQueueTask? _task;
  var _byte = 0;
  var _onlineMode = AppSetting.instance.dl.defaultToOnlineMode;
  var _onlyUnfinished = true;
  var _invertOrder = true;
  MangaHistory? _history;
  Manga? _mangaData; // loaded in background
  var _error = '';

  Future<void> _loadData() async {
    _loading = true;
    _entity = null;
    _task = null;
    _history = null;
    if (mounted) setState(() {});

    // 异步请求章节目录
    _loadMangaDataAsync(forceRefresh: true);

    // 获取漫画下载记录，并更新下载任务等数据
    var data = await DownloadDao.getManga(mid: widget.mangaId);
    if (data != null) {
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(kFlashListDuration);
      _entity = data;
      _task = QueueManager.instance.getDownloadMangaQueueTask(widget.mangaId);
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);
      getDownloadedMangaBytes(mangaId: widget.mangaId).then((b) => mountedSetState(() => _byte = b)); // 在每次刷新时都重新统计文件大小
    } else {
      _error = '无法获取漫画下载记录';
    }
    _loading = false;
    if (mounted) setState(() {});
  }

  Tuple2<void Function(int, bool), void Function(int)> _updateData() {
    void throughProgress(final int mangaId, final bool finished) async {
      if (mangaId != widget.mangaId) return;
      var task = QueueManager.instance.getDownloadMangaQueueTask(mangaId);
      if (finished) {
        mountedSetState(() => _task = null);
      } else if (task != null) {
        mountedSetState(() => _task = task);
        if (task.progress.stage == DownloadMangaProgressStage.waiting || task.progress.stage == DownloadMangaProgressStage.gotChapter) {
          getDownloadedMangaBytes(mangaId: mangaId).then((b) => mountedSetState(() => _byte = b)); // 仅在最开始等待、以及每次获得新章节时才统计文件大小
        }
      }
    }

    void throughEntity(final int mangaId) async {
      if (mangaId != widget.mangaId) return;
      var entity = await DownloadDao.getManga(mid: mangaId);
      if (entity != null) {
        mountedSetState(() => _entity = entity);
        getDownloadedMangaBytes(mangaId: mangaId).then((b) => mountedSetState(() => _byte = b)); // 在每次数据库发生变化时都统计文件大小
      }
    }

    return Tuple2(throughProgress, throughEntity);
  }

  Future<void> _loadMangaDataAsync({bool forceRefresh = false}) async {
    if (_mangaData != null && !forceRefresh) {
      return;
    }

    final client = RestClient(DioManager.instance.dio);
    try {
      var result = await client.getManga(mid: widget.mangaId);
      _mangaData = result.data;
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
      mangaId: _entity!.mangaId,
      mangaTitle: _entity!.mangaTitle,
      mangaCover: _entity!.mangaCover,
      mangaUrl: _entity!.mangaUrl,
      chapterIds: _entity!.downloadedChapters.map((el) => el.chapterId).toList(),
      alsoAddTask: true,
      throughGroupList: null,
      throughChapterList: _entity!.downloadedChapters,
    );
  }

  Future<void> _startOrPauseChapter(int chapterId, {required bool start}) async {
    if (!start) {
      // 暂停 => 获取最新的任务，并取消
      print('_startOrPauseChapter 暂停下载章节 $chapterId');
      _task = QueueManager.instance.getDownloadMangaQueueTask(widget.mangaId);
      _task?.cancelChapter(chapterId);
      return;
    }

    // 开始 => 构造任务、同步准备、入队
    print('_startOrPauseChapter 下载章节 $chapterId');
    await quickBuildDownloadMangaQueueTask(
      mangaId: _entity!.mangaId,
      mangaTitle: _entity!.mangaTitle,
      mangaCover: _entity!.mangaCover,
      mangaUrl: _entity!.mangaUrl,
      chapterIds: [chapterId],
      alsoAddTask: true,
      throughGroupList: null,
      throughChapterList: _entity!.downloadedChapters,
    );
  }

  Future<void> _adjustChapterDetails(int chapterId) async {
    var entity = _entity?.downloadedChapters.where((el) => el.chapterId == chapterId).firstOrNull;
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
      await DownloadDao.addOrUpdateChapter(chapter: entity.copyWith(needUpdate: needUpdate));
      var ev = DownloadedMangaEntityChangedEvent(mangaId: widget.mangaId);
      EventBusManager.instance.fire(ev);
    }

    await showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(entity.chapterTitle),
        children: [
          IconTextDialogOption(
            icon: Icon(Icons.import_contacts),
            text: Text('阅读章节'),
            onPressed: () => popAndCall(c, () => _readChapter(chapterId)),
          ),
          IconTextDialogOption(
            icon: Icon(Icons.delete),
            text: Text('删除章节'),
            onPressed: () => popAndCall(c, () => _deleteChapter(chapterId)),
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
              text: Text('设置为需要更新数据'),
              onPressed: () => popAndCall(c, () => updateNeedUpdate(true)),
            ),
          if (allFinished && entity.needUpdate)
            IconTextDialogOption(
              icon: Icon(Icons.update_disabled),
              text: Text('设置为不需要更新数据'),
              onPressed: () => popAndCall(c, () => updateNeedUpdate(false)),
            ),
        ],
      ),
    );
  }

  void _readChapter(int chapterId) {
    _loadMangaDataAsync(forceRefresh: false); // 异步请求章节目录，尽量避免 MangaViewerPage 反复请求
    Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => MangaViewerPage(
          parentContext: context,
          mangaId: widget.mangaId,
          chapterId: chapterId,
          mangaCover: _entity!.mangaCover,
          chapterGroups: _mangaData?.chapterGroups /* nullable */,
          initialPage: _history?.chapterId == chapterId
              ? _history?.chapterPage ?? 1 // have read
              : 1 /* have not read */,
          onlineMode: _onlineMode,
        ),
      ),
    );
  }

  Future<void> _deleteChapter(int chapterId) async {
    var entity = _entity!.downloadedChapters.where((el) => el.chapterId == chapterId).firstOrNull;
    if (entity == null) {
      return;
    }
    _task = QueueManager.instance.getDownloadMangaQueueTask(widget.mangaId);
    if (_task != null) {
      Fluttertoast.showToast(msg: '请先暂停下载，然后再删除该章节');
      return;
    }

    var alsoDeleteFile = AppSetting.instance.dl.defaultToDeleteFiles;
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, _setState) => AlertDialog(
          title: Text('章节删除确认'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('是否删除《${_entity!.mangaTitle}》${entity.chapterTitle}？'),
              SizedBox(height: 5),
              CheckboxListTile(
                title: Text('同时删除已下载的文件'),
                value: alsoDeleteFile,
                onChanged: (v) {
                  alsoDeleteFile = v ?? false;
                  _setState(() {});
                },
                visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('删除'),
              onPressed: () async {
                Navigator.of(c).pop();
                _entity!.downloadedChapters.remove(entity);
                await DownloadDao.deleteChapter(mid: entity.mangaId, cid: entity.chapterId);
                if (mounted) setState(() {});
                await updateDlSettingDefaultToDeleteFiles(alsoDeleteFile);
                if (alsoDeleteFile) {
                  await deleteDownloadedChapter(mangaId: entity.mangaId, chapterId: entity.chapterId);
                  getDownloadedMangaBytes(mangaId: entity.mangaId).then((b) => mountedSetState(() => _byte = b)); // 删除文件后遍历统计文件大小
                }
              },
            ),
            TextButton(
              child: Text('取消'),
              onPressed: () => Navigator.of(c).pop(),
            ),
          ],
        ),
      ),
    );
  }

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
                child: Text('漫画下载设置'),
                onTap: () => WidgetsBinding.instance?.addPostFrameCallback(
                  (_) => showDlSettingDialog(context: context),
                ),
              ),
              PopupMenuItem(
                child: Text('查看下载列表'),
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
                child: Text(_onlyUnfinished ? '显示所有章节的下载情况' : '仅显示未完成的下载情况'),
                onTap: () => mountedSetState(() => _onlyUnfinished = !_onlyUnfinished),
              ),
              if (_entity != null && !_entity!.error && _entity!.successChapterIds.length == _entity!.totalChapterIds.length)
                PopupMenuItem(
                  child: Text(!_entity!.needUpdate ? '设置为需要更新数据' : '设置为不需要更新数据'),
                  onTap: () async {
                    await DownloadDao.addOrUpdateManga(manga: _entity!.copyWith(needUpdate: !_entity!.needUpdate));
                    var ev = DownloadedMangaEntityChangedEvent(mangaId: widget.mangaId);
                    EventBusManager.instance.fire(ev);
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
      drawerExtraDragTriggers: [
        DrawerDragTrigger(
          top: 0,
          height: _tabBarKey.currentContext?.findRenderObject()?.getBoundInAncestorCoordinate(context.findRenderObject()).let((rect) => rect.top + rect.height) ?? 0,
          dragWidth: MediaQuery.of(context).size.width,
        ),
      ],
      physicsController: _physicsController,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        notificationPredicate: (n) => n.depth <= 2,
        onRefresh: _loadData,
        child: PlaceholderText.from(
          isLoading: _loading,
          errorText: _error,
          isEmpty: _entity == null,
          setting: PlaceholderSetting().copyWithChinese(),
          onRefresh: () => _loadData(),
          childBuilder: (c) => ExtendedNestedScrollView(
            controller: _scrollController,
            onNotification: (e) {
              if (e is ScrollEndNotification) {
                WidgetsBinding.instance?.addPostFrameCallback((_) {
                  if (mounted) setState(() {}); // <<< for updating DrawerDragTrigger
                });
              }
              return false;
            },
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
                        mangaEntity: _entity!,
                        downloadTask: _task,
                        downloadedBytes: _byte,
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
                          Icons.description,
                          () => Navigator.of(context).push(
                            CustomPageRoute(
                              context: context,
                              builder: (c) => MangaPage(
                                id: widget.mangaId,
                                title: _entity!.mangaTitle,
                                url: _entity!.mangaUrl,
                              ),
                            ),
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
                        ),
                        action3: ActionItem.simple(
                          _invertOrder ? '倒序显示' : '正序显示',
                          _invertOrder ? Icons.arrow_downward : Icons.arrow_upward,
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
                          child: StatefulWidgetWithCallback(
                            postFrameCallbackForInitState: (_) {
                              if (mounted) setState(() {}); // <<< for updating DrawerDragTrigger
                            },
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
                                SizedBox(height: 36.0, child: Center(child: Text(_onlyUnfinished ? '未完成' : '所有章节'))),
                              ],
                            ),
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
                  injectorHandler: ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor(c),
                  mangaEntity: _entity!,
                  invertOrder: _invertOrder,
                  history: _history,
                  toReadChapter: _readChapter,
                  toDeleteChapter: _deleteChapter,
                ),
                // ****************************************************************
                // 未完成下载的章节 => 等待下载/正在下载/下载失败
                // ****************************************************************
                DlUnfinishedSubPage(
                  innerController: controllers[1],
                  outerController: _scrollController,
                  injectorHandler: ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor(c),
                  mangaEntity: _entity!,
                  downloadTask: _task,
                  showAllChapters: !_onlyUnfinished,
                  invertOrder: _invertOrder,
                  toReadChapter: _readChapter,
                  toDeleteChapter: _deleteChapter,
                  toControlChapter: _startOrPauseChapter,
                  toAdjustChapter: _adjustChapterDetails,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
