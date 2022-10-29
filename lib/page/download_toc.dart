import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/manga_viewer.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/download_manga_line.dart';
import 'package:manhuagui_flutter/page/view/manga_simple_toc.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/service/storage/download_manga.dart';
import 'package:manhuagui_flutter/service/storage/queue_manager.dart';

/// 已下载章节页，查询数据库并展示 [DownloadedManga] 信息，以及展示 [DownloadMangaProgressChangedEvent] 进度信息
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

class _DownloadTocPageState extends State<DownloadTocPage> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _refreshIndicatorKey.currentState?.show());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      // progress related
      _cancelHandlers.add(EventBusManager.instance.listen<DownloadMangaProgressChangedEvent>((event) async {
        var mangaId = event.task.mangaId;
        if (mangaId != widget.mangaId) {
          return;
        }

        // <<<
        _task = !event.finished ? event.task : null;
        if (event.task.progress.stage == DownloadMangaProgressStage.waiting || event.task.progress.stage == DownloadMangaProgressStage.gotChapter) {
          // 只有在最开始等待、以及每次获得新章节数据时才遍历并获取文件大小
          _byte = await getDownloadedMangaBytes(mangaId: mangaId);
        }
        if (mounted) setState(() {});
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
          _byte = await getDownloadedMangaBytes(mangaId: mangaId);
        } else {
          // ignore error
        }
        if (mounted) setState(() {});
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
    _cancelHandlers.forEach((c) => c.call);
    _controller.dispose();
    _fabController.dispose();
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

    var data = await DownloadDao.getManga(mid: widget.mangaId);
    if (data != null) {
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _data = data;
      _task = QueueManager.instance.tasks.whereType<DownloadMangaQueueTask>().where((el) => el.mangaId == widget.mangaId).firstOrNull;
      _byte = await getDownloadedMangaBytes(mangaId: widget.mangaId);
      _invertOrder = true;
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);

      // 异步请求章节目录
      _getChapterGroupsAsync(forceRefresh: true);
    } else {
      _error = '无法获取漫画下载信息';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('已下载章节'),
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
        onRefresh: _loadData,
        child: PlaceholderText.from(
          isLoading: _loading,
          errorText: _error,
          isEmpty: _data == null,
          setting: PlaceholderSetting().copyWithChinese(),
          onRefresh: () => _loadData(),
          onChanged: (_, __) => _fabController.hide(),
          childBuilder: (c) => ScrollbarWithMore(
            controller: _controller,
            interactive: true,
            crossAxisMargin: 2,
            child: ListView(
              controller: _controller,
              padding: EdgeInsets.zero,
              physics: AlwaysScrollableScrollPhysics(),
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
                // 漫画下载信息头部
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
                      () {
                        _invertOrder = !_invertOrder;
                        if (mounted) setState(() {});
                      },
                    ),
                    action3: ActionItem.simple('全部开始', Icons.play_arrow, () {}),
                    action4: ActionItem.simple('全部暂停', Icons.pause, () {}), // TODO 单个漫画下载特定章节/按照特定顺序下载
                  ),
                ),
                Container(height: 12),
                // ****************************************************************
                // 未完成下载（正在下载/下载失败）的章节
                // ****************************************************************
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '未完成下载的章节',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white,
                  child: Divider(height: 0, thickness: 1),
                ),
                Container(
                  color: Colors.white,
                  child: MangaSimpleTocView(
                    chapters: _data!.downloadedChapters //
                        .where((el) => !el.succeeded)
                        .map((el) => Tuple2(el.chapterGroup, el.toTiny()))
                        .toList(),
                    gridPadding: EdgeInsets.symmetric(horizontal: 12),
                    invertOrder: _invertOrder,
                    showNewBadge: false,
                    highlightedChapters: [_history?.chapterId ?? 0],
                    customBadgeBuilder: (cid) {
                      var oldChapter = _data!.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull;
                      if (oldChapter == null) {
                        return null;
                      }
                      return DownloadBadge(
                        state: !oldChapter.finished
                            ? DownloadBadgeState.downloading
                            : oldChapter.succeeded
                                ? DownloadBadgeState.succeeded
                                : DownloadBadgeState.failed,
                      );
                    },
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
                    onChapterLongPressed: (cid) => Fluttertoast.showToast(msg: 'TODO $cid'), // TODO
                  ),
                ),
                Container(height: 12),
                // ****************************************************************
                // 已下载的章节
                // ****************************************************************
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '已下载的章节',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white,
                  child: Divider(height: 0, thickness: 1),
                ),
                Container(
                  color: Colors.white,
                  // TODO Line，加进度条，长按弹出选项（目前与上面完全一样）
                  child: MangaSimpleTocView(
                    chapters: _data!.downloadedChapters //
                        .where((el) => el.succeeded)
                        .map((el) => Tuple2(el.chapterGroup, el.toTiny()))
                        .toList(),
                    gridPadding: EdgeInsets.symmetric(horizontal: 12),
                    invertOrder: _invertOrder,
                    showNewBadge: false,
                    highlightedChapters: [_history?.chapterId ?? 0],
                    customBadgeBuilder: (cid) {
                      var oldChapter = _data!.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull;
                      if (oldChapter == null) {
                        return null;
                      }
                      return DownloadBadge(
                        state: !oldChapter.finished
                            ? DownloadBadgeState.downloading
                            : oldChapter.succeeded
                                ? DownloadBadgeState.succeeded
                                : DownloadBadgeState.failed,
                      );
                    },
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
                    onChapterLongPressed: (cid) => Fluttertoast.showToast(msg: 'TODO $cid'), // TODO
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: ScrollAnimatedFab(
        controller: _fabController,
        scrollController: _controller,
        condition: ScrollAnimatedCondition.direction,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: null,
          onPressed: () => _controller.scrollToTop(),
        ),
      ),
    );
  }
}
