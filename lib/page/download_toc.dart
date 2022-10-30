import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/manga_viewer.dart';
import 'package:manhuagui_flutter/page/page/dl_finished.dart';
import 'package:manhuagui_flutter/page/page/dl_setting.dart';
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
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/service/prefs/dl_setting.dart';
import 'package:manhuagui_flutter/service/storage/download_manga.dart';
import 'package:manhuagui_flutter/service/storage/queue_manager.dart';

/// 章节下载管理页，查询数据库并展示 [DownloadedManga] 信息，以及展示 [DownloadMangaProgressChangedEvent] 进度信息
class DownloadTocPage extends StatefulWidget {
  const DownloadTocPage({
    Key? key,
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
  }) : super(key: key);

  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;

  @override
  State<DownloadTocPage> createState() => _DownloadTocPageState();
}

class _DownloadTocPageState extends State<DownloadTocPage> with SingleTickerProviderStateMixin {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late final _tabController = TabController(length: 2, vsync: this);
  final _scrollController = ScrollController();
  final _cancelHandlers = <VoidCallback>[];

  var _setting = DlSetting.defaultSetting();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _refreshIndicatorKey.currentState?.show());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      // setting
      _setting = await DlSettingPrefs.getSetting();
      if (mounted) setState(() {});

      // progress related
      _cancelHandlers.add(EventBusManager.instance.listen<DownloadMangaProgressChangedEvent>((event) async {
        var mangaId = event.task.mangaId;
        if (mangaId != widget.mangaId) {
          return;
        }

        // <<<
        _task = !event.finished ? event.task : null;
        if (mounted) setState(() {});
        if (event.task.progress.stage == DownloadMangaProgressStage.waiting || event.task.progress.stage == DownloadMangaProgressStage.gotChapter) {
          // 只有在最开始等待、以及每次获得新章节数据时才遍历并获取文件大小
          getDownloadedMangaBytes(mangaId: mangaId).then((b) {
            _byte = b;
            if (mounted) setState(() {});
          });
        }
      }));

      // entity related
      _cancelHandlers.add(EventBusManager.instance.listen<DownloadedMangaEntityChangedEvent>((event) async {
        var mangaId = event.mangaId;
        if (mangaId != widget.mangaId) {
          return;
        }

        // <<<
        var newEntity = await DownloadDao.getManga(mid: mangaId);
        if (newEntity != null) {
          _data = newEntity;
          if (mounted) setState(() {});
          getDownloadedMangaBytes(mangaId: mangaId).then((b) {
            _byte = b;
            if (mounted) setState(() {});
          });
        } else {
          // ignore error
        }
      }));

      // history related
      _cancelHandlers.add(EventBusManager.instance.listen<HistoryUpdatedEvent>((_) async {
        try {
          _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);
          if (mounted) setState(() {});
        } catch (_) {}
      }));
    });
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  var _loading = true;
  DownloadedManga? _data;
  DownloadMangaQueueTask? _task;
  var _byte = 0;
  var _invertOrder = true;
  MangaHistory? _history;
  var _error = '';

  Future<void> _loadData() async {
    _loading = true;
    _data = null;
    _task = null;
    _byte = 0;
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
      _data = data;
      _task = QueueManager.instance.tasks.whereType<DownloadMangaQueueTask>().where((el) => el.mangaId == widget.mangaId).firstOrNull;
      _byte = await getDownloadedMangaBytes(mangaId: widget.mangaId); // TODO slow
      _invertOrder = true;
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
      print(wrapError(e, s).text);
      // ignore
    }
  }

  Future<void> _startOrPause({required bool start}) async {
    if (!start) {
      // => 暂停
      _task = QueueManager.instance.tasks.whereType<DownloadMangaQueueTask>().where((el) => el.mangaId == widget.mangaId).firstOrNull;
      _task?.cancel();
      return;
    }

    // => 开始
    // 1. 构造下载任务
    var newTask = DownloadMangaQueueTask(
      mangaId: _data!.mangaId,
      chapterIds: _data!.downloadedChapters.map((el) => el.chapterId).toList(),
      parallel: _setting.downloadPagesTogether,
    );

    // 2. 更新数据库
    var need = await newTask.prepare(
      mangaTitle: _data!.mangaTitle,
      mangaCover: _data!.mangaCover,
      mangaUrl: _data!.mangaUrl,
      getChapterTitleGroupPages: (cid) {
        var chapter = _data!.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull;
        if (chapter == null) {
          return null; // unreachable
        }
        var chapterTitle = chapter.chapterTitle;
        var groupName = chapter.chapterGroup;
        var chapterPageCount = chapter.totalPageCount;
        return Tuple3(chapterTitle, groupName, chapterPageCount);
      },
    );

    // 3. 入队等待执行，异步
    if (need) {
      QueueManager.instance.addTask(newTask);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('章节下载管理'),
        leading: AppBarActionButton.leading(context: context),
        actions: [
          AppBarActionButton(
            icon: Icon(Icons.open_in_browser),
            tooltip: '用浏览器打开',
            onPressed: () => launchInBrowser(
              context: context,
              url: widget.mangaUrl,
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
          isEmpty: _data == null,
          setting: PlaceholderSetting().copyWithChinese(),
          onRefresh: () => _loadData(),
          childBuilder: (c) => ExtendedNestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (c, o) => [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // ****************************************************************
                    // 漫画下载信息头部
                    // ****************************************************************
                    Container(
                      color: Colors.white,
                      child: LargeDownloadMangaLineView(
                        mangaEntity: _data!,
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
                            MaterialPageRoute(
                              builder: (c) => MangaPage(
                                id: widget.mangaId,
                                title: widget.mangaTitle,
                                url: widget.mangaUrl,
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
                          '全部开始',
                          Icons.play_arrow,
                          () => _startOrPause(start: true),
                        ),
                        action4: ActionItem.simple(
                          '全部暂停',
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
                handle: ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor(c),
                sliver: SliverPersistentHeader(
                  pinned: true,
                  floating: true,
                  delegate: SliverHeaderDelegate(
                    child: PreferredSize(
                      preferredSize: Size.fromHeight(Theme.of(context).appBarTheme.toolbarHeight!),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: Center(
                            child: TabBar(
                              controller: _tabController,
                              labelColor: Theme.of(context).primaryColor,
                              unselectedLabelColor: Colors.grey[600],
                              indicatorColor: Theme.of(context).primaryColor,
                              isScrollable: true,
                              indicatorSize: TabBarIndicatorSize.label,
                              tabs: const [
                                Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('已完成')),
                                Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('未完成')),
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
            bodyBuilder: (c, controllers) => Builder(
              builder: (c) => TabBarView(
                controller: _tabController,
                children: [
                  // ****************************************************************
                  // 已下载的章节
                  // ****************************************************************
                  DlFinishedSubPage(
                    innerController: controllers[0],
                    outerController: _scrollController,
                    injectorHandler: ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor(c),
                    mangaEntity: _data!,
                    downloadTask: _task,
                    invertOrder: _invertOrder,
                    history: _history,
                    onChapterPressed: (cid) {
                      _getChapterGroupsAsync(); // 异步请求章节目录，尽量避免 MangaViewer 做多次请求
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (c) => MangaViewerPage(
                            mangaId: widget.mangaId,
                            mangaTitle: widget.mangaTitle,
                            mangaCover: widget.mangaCover,
                            mangaUrl: widget.mangaUrl,
                            chapterGroups: _chapterGroups /* nullable */,
                            chapterId: cid,
                            initialPage: _history?.chapterId == cid
                                ? _history?.chapterPage ?? 1 // have read
                                : 1, // have not read
                          ),
                        ),
                      );
                    },
                  ),
                  // ****************************************************************
                  // 未完成下载（正在下载/下载失败）的章节
                  // ****************************************************************
                  DlUnfinishedSubPage(
                    innerController: controllers[1],
                    outerController: _scrollController,
                    injectorHandler: ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor(c),
                    mangaEntity: _data!,
                    downloadTask: _task,
                    invertOrder: _invertOrder,
                    history: _history,
                    onChapterPressed: (cid) {}, // TODO 单个漫画下载特定章节/按照特定顺序下载
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
