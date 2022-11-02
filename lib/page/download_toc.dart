import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/download.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/manga_viewer.dart';
import 'package:manhuagui_flutter/page/page/dl_finished.dart';
import 'package:manhuagui_flutter/page/page/dl_unfinished.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/download_manga_line.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/prefs/dl_setting.dart';
import 'package:manhuagui_flutter/service/storage/download_image.dart';
import 'package:manhuagui_flutter/service/storage/download_manga_task.dart';
import 'package:manhuagui_flutter/service/storage/queue_manager.dart';

/// 章节下载管理页，查询数据库并展示 [DownloadedManga] 信息，以及展示 [DownloadMangaProgressChangedEvent] 进度信息
class DownloadTocPage extends StatefulWidget {
  const DownloadTocPage({
    Key? key,
    required this.mangaId,
    this.gotoDownloading = false,
  }) : super(key: key);

  final int mangaId;
  final bool gotoDownloading;

  @override
  State<DownloadTocPage> createState() => _DownloadTocPageState();

  static RouteSettings buildRouteSetting({required int mangaId}) {
    return RouteSettings(
      name: '/DownloadTocPage',
      arguments: <String, Object>{'mangaId': mangaId},
    );
  }

  static bool isCurrentRoute(BuildContext context, int mangaId) {
    var setting = RouteSettings();
    Navigator.popUntil(context, (route) {
      setting = route.settings;
      return true;
    });

    if (setting.name != '/DownloadTocPage' || setting.arguments is! Map<String, Object>) {
      return false;
    }
    return (setting.arguments! as Map<String, Object>)['mangaId'] == mangaId;
  }
}

class _DownloadTocPageState extends State<DownloadTocPage> with SingleTickerProviderStateMixin {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late final _tabController = TabController(length: 2, vsync: this);
  final _scrollController = ScrollController();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _refreshIndicatorKey.currentState?.show());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      if (widget.gotoDownloading) {
        _tabController.animateTo(1);
      }
    });

    // progress related
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadMangaProgressChangedEvent>((event) async {
      if (event.mangaId != widget.mangaId) {
        return;
      }
      if (event.finished) {
        _task = null;
        if (mounted) setState(() {});
      } else {
        _task = QueueManager.instance.getDownloadMangaQueueTask(event.mangaId);
        if (mounted) setState(() {});
        if (_task != null && (_task!.progress.stage == DownloadMangaProgressStage.waiting || _task!.progress.stage == DownloadMangaProgressStage.gotChapter)) {
          getDownloadedMangaBytes(mangaId: event.mangaId).then((b) {
            _byte = b; // 只有在最开始等待、以及每次获得新章节时才遍历统计文件大小
            if (mounted) setState(() {});
          });
        }
      }
    }));

    // entity related
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadedMangaEntityChangedEvent>((event) async {
      if (event.mangaId != widget.mangaId) {
        return;
      }
      var newEntity = await DownloadDao.getManga(mid: event.mangaId);
      if (newEntity != null) {
        _entity = newEntity;
        if (mounted) setState(() {});
        getDownloadedMangaBytes(mangaId: event.mangaId).then((b) {
          _byte = b; // 在每次数据库发生变化时都遍历统计文件大小
          if (mounted) setState(() {});
        });
      }
    }));

    // history related
    _cancelHandlers.add(EventBusManager.instance.listen<HistoryUpdatedEvent>((_) async {
      try {
        _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);
        if (mounted) setState(() {});
      } catch (_) {}
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
  var _invertOrder = true;
  MangaHistory? _history;
  var _error = '';

  Future<void> _loadData() async {
    _loading = true;
    _entity = null;
    _task = null;
    _history = null;
    if (mounted) setState(() {});

    // 异步请求章节目录
    _getChapterGroupsAsync(forceRefresh: true);

    // 获取漫画下载记录，并更新下载任务等数据
    var data = await DownloadDao.getManga(mid: widget.mangaId);
    if (data != null) {
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _entity = data;
      _task = QueueManager.instance.getDownloadMangaQueueTask(widget.mangaId);
      getDownloadedMangaBytes(mangaId: widget.mangaId).then((b) {
        _byte = b;
        if (mounted) setState(() {});
      });
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);
    } else {
      _error = '无法获取漫画下载记录';
    }
    _loading = false;
    if (mounted) setState(() {});
  }

  List<MangaChapterGroup>? _chapterGroups;

  Future<void> _getChapterGroupsAsync({bool forceRefresh = false}) async {
    if (_chapterGroups != null && !forceRefresh) {
      return;
    }

    final client = RestClient(DioManager.instance.dio);
    try {
      var result = await client.getManga(mid: widget.mangaId);
      _chapterGroups = result.data.chapterGroups;
    } catch (e, s) {
      // ignored
      print('===> exception when _getChapterGroupsAsync:\n${wrapError(e, s).text}');
    }
  }

  Future<void> _startOrPause({required bool start}) async {
    if (!start) {
      // 暂停 => 获取最新的任务，并取消
      _task = QueueManager.instance.getDownloadMangaQueueTask(widget.mangaId);
      _task?.cancel();
      return;
    }

    // 开始 => 快速构造下载任务，同步更新数据库，并入队异步等待执行
    var setting = await DlSettingPrefs.getSetting();
    await quickBuildDownloadMangaQueueTask(
      mangaId: _entity!.mangaId,
      mangaTitle: _entity!.mangaTitle,
      mangaCover: _entity!.mangaCover,
      mangaUrl: _entity!.mangaUrl,
      chapterIds: _entity!.downloadedChapters.map((el) => el.chapterId).toList(),
      parallel: setting.downloadPagesTogether,
      invertOrder: setting.invertDownloadOrder,
      addToTask: true,
      throughChapterList: _entity!.downloadedChapters,
    );
  }

  void _readChapter(int chapterId) {
    // TODO 离线阅读功能，跳过请求章节信息
    _getChapterGroupsAsync(); // 异步请求章节目录，尽量避免 MangaViewer 做多次请求
    Navigator.of(context).push(
      CustomMaterialPageRoute(
        context: context,
        builder: (c) => MangaViewerPage(
          mangaId: widget.mangaId,
          mangaTitle: _entity!.mangaTitle,
          mangaCover: _entity!.mangaCover,
          mangaUrl: _entity!.mangaUrl,
          chapterGroups: _chapterGroups /* nullable */,
          chapterId: chapterId,
          initialPage: _history?.chapterId == chapterId
              ? _history?.chapterPage ?? 1 // have read
              : 1, // have not read
        ),
      ),
    );
  }

  Future<void> _deleteChapter(DownloadedChapter entity) async {
    _task = QueueManager.instance.getDownloadMangaQueueTask(widget.mangaId);
    if (_task != null) {
      Fluttertoast.showToast(msg: '当前仅支持在漫画暂停下载时删除章节');
      return;
    }

    var setting = await DlSettingPrefs.getSetting();
    var alsoDeleteFile = setting.defaultToDeleteFiles;
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, _setState) => AlertDialog(
          title: Text('章节删除确认'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('是否删除漫画章节《${_entity!.mangaTitle}》${entity.chapterTitle}？'),
              SizedBox(height: 5),
              CheckboxListTile(
                title: Text('同时删除已下载的文件'),
                value: alsoDeleteFile,
                onChanged: (v) {
                  alsoDeleteFile = v ?? false;
                  _setState(() {});
                },
                dense: false,
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

                var setting = await DlSettingPrefs.getSetting();
                setting = setting.copyWith(defaultToDeleteFiles: alsoDeleteFile);
                await DlSettingPrefs.setSetting(setting);
                if (alsoDeleteFile) {
                  await deleteDownloadedChapter(mangaId: entity.mangaId, chapterId: entity.chapterId);
                  getDownloadedMangaBytes(mangaId: entity.mangaId).then((b) {
                    _byte = b;
                    if (mounted) setState(() {});
                  });
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
    return Scaffold(
      appBar: AppBar(
        title: Text('章节下载管理'),
        leading: AppBarActionButton.leading(context: context),
        actions: [
          AppBarActionButton(
            icon: Icon(Icons.list),
            tooltip: '查看下载列表',
            onPressed: () => Navigator.of(context).push(
              CustomMaterialPageRoute(
                context: context,
                builder: (c) => DownloadPage(),
              ),
            ),
          ),
        ],
      ),
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
            headerSliverBuilder: (context, _) => [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // ****************************************************************
                    // 漫画下载信息头部
                    // ****************************************************************
                    Container(
                      color: Colors.white,
                      child: LargeDownloadMangaLineView(
                        mangaEntity: _entity!,
                        downloadTask: _task,
                        downloadedBytes: _byte,
                      ),
                    ),
                    Container(height: 12),
                    // ****************************************************************
                    // 四个按钮
                    // ****************************************************************
                    Container(
                      color: Colors.white,
                      child: ActionRowView.four(
                        action1: ActionItem.simple(
                          '查看漫画',
                          Icons.description,
                          () => Navigator.of(context).push(
                            CustomMaterialPageRoute(
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
                          _invertOrder ? '倒序显示' : '正序显示',
                          _invertOrder ? Icons.arrow_downward : Icons.arrow_upward,
                          () => mountedSetState(() => _invertOrder = !_invertOrder),
                        ),
                        action3: ActionItem.simple(
                          '开始下载',
                          Icons.play_arrow,
                          () => _startOrPause(start: true),
                        ),
                        action4: ActionItem.simple(
                          '暂停下载',
                          Icons.pause,
                          () => _startOrPause(start: false),
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
                            controller: _tabController,
                            labelColor: Theme.of(context).primaryColor,
                            unselectedLabelColor: Colors.grey[600],
                            indicatorColor: Theme.of(context).primaryColor,
                            isScrollable: true,
                            indicatorSize: TabBarIndicatorSize.label,
                            tabs: const [
                              SizedBox(height: 36.0, child: Center(child: Text('已完成'))),
                              SizedBox(height: 36.0, child: Center(child: Text('未完成'))),
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
              children: [
                // ****************************************************************
                // 已下载的章节
                // ****************************************************************
                DlFinishedSubPage(
                  innerController: controllers[0],
                  outerController: _scrollController,
                  injectorHandler: ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor(c),
                  mangaEntity: _entity!,
                  invertOrder: _invertOrder,
                  history: _history,
                  toReadChapter: _readChapter,
                  toDeleteChapter: (cid) async {
                    var chapterEntity = _entity!.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull;
                    if (chapterEntity != null) {
                      await _deleteChapter(chapterEntity);
                    }
                  },
                ),
                // ****************************************************************
                // 未完成下载（正在下载/下载失败）的章节
                // ****************************************************************
                DlUnfinishedSubPage(
                  innerController: controllers[1],
                  outerController: _scrollController,
                  injectorHandler: ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor(c),
                  mangaEntity: _entity!,
                  downloadTask: _task,
                  invertOrder: _invertOrder,
                  toControlChapter: (cid) {
                    Fluttertoast.showToast(msg: '目前暂不支持单独下载或暂停某一章节'); // TODO 单个漫画下载特定章节/按照特定顺序下载
                  },
                  toReadChapter: _readChapter,
                  toDeleteChapter: (cid) async {
                    var chapterEntity = _entity!.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull;
                    if (chapterEntity != null) {
                      await _deleteChapter(chapterEntity);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
