import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/download.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/storage/download_manga.dart';
import 'package:manhuagui_flutter/service/storage/queue_manager.dart';

/// 选择下载章节页，展示所给 [MangaChapterGroup] 列表信息，并提供章节选择
class DownloadSelectPage extends StatefulWidget {
  const DownloadSelectPage({
    Key? key,
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.groups,
  }) : super(key: key);

  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final List<MangaChapterGroup> groups;

  @override
  State<DownloadSelectPage> createState() => _DownloadSelectPageState();
}

class _DownloadSelectPageState extends State<DownloadSelectPage> {
  final _controller = ScrollController();
  VoidCallback? _cancelHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async => await _getChapters());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandler = EventBusManager.instance.listen<DownloadedMangaEntityChangedEvent>((event) async {
        if (event.mid == widget.mangaId) {
          await _getChapters();
        }
      });
    });
  }

  @override
  void dispose() {
    _cancelHandler?.call();
    _controller.dispose();
    super.dispose();
  }

  final _selected = <int>[];
  final _downloadedChapters = <DownloadedChapter>[];

  Future<void> _getChapters() async {
    var chapters = (await DownloadDao.getManga(mid: widget.mangaId))?.downloadedChapters ?? [];
    _downloadedChapters.clear();
    _downloadedChapters.addAll(chapters);
    if (mounted) setState(() {});
  }

  Future<void> _downloadManga() async {
    // 1. 获取需要下载的章节
    if (_selected.isEmpty) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('下载'),
          content: Text('请选择需要下载的章节。'),
          actions: [
            TextButton(
              child: Text('确定'),
              onPressed: () => Navigator.of(c).pop(),
            ),
          ],
        ),
      );
      return;
    }
    var chapterIds = <int>[];
    for (var cid in _selected) {
      var oldChapter = _downloadedChapters.where((el) => el.chapterId == cid).firstOrNull;
      if (oldChapter != null && oldChapter.succeeded) {
        continue; // 过滤掉已下载成功的章节
      }
      chapterIds.add(cid);
    }
    if (chapterIds.isEmpty) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('下载'),
          content: Text('所选章节均已下载完毕。'),
          actions: [
            TextButton(
              child: Text('确定'),
              onPressed: () => Navigator.of(c).pop(),
            ),
          ],
        ),
      );
      return;
    }

    // 2. 显示下载确认
    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('下载确认'),
        content: Text('确定下载所选的 ${chapterIds.length} 个章节吗？'),
        actions: [
          TextButton(
            child: Text('下载'),
            onPressed: () => Navigator.of(c).pop(true),
          ),
          TextButton(
            child: Text('取消'),
            onPressed: () => Navigator.of(c).pop(false),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }

    // 3. 构造下载任务
    var task = DownloadMangaQueueTask(
      mangaId: widget.mangaId,
      chapterIds: chapterIds.toList(),
    );

    // 4. 更新数据库，并更新界面
    var need = await task.prepare(
      mangaTitle: widget.mangaTitle,
      mangaCover: widget.mangaCover,
      mangaUrl: widget.mangaUrl,
      getChapterTitleGroupPages: (cid) {
        var tuple = widget.groups.findChapterAndGroupName(cid);
        if (tuple == null) {
          return null;
        }
        var chapterTitle = tuple.item1.title;
        var groupName = tuple.item2;
        var chapterPageCount = tuple.item1.pageCount;
        return Tuple3(chapterTitle, groupName, chapterPageCount);
      },
    );
    await _getChapters();

    // 5. 入队等待执行，异步
    if (need) {
      QueueManager.instance.addTask(task);
    }

    // 6. 显示提示
    _selected.clear();
    if (mounted) setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已添加 ${chapterIds.length} 个章节至下载任务'),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: '查看下载列表',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (c) => DownloadPage(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('下载 ${widget.mangaTitle}'),
        leading: AppBarActionButton.leading(context: context),
        actions: [
          AppBarActionButton(
            icon: Icon(Icons.download),
            tooltip: '下载',
            onPressed: () => _downloadManga(),
          ),
          AppBarActionButton(
            icon: Icon(Icons.select_all),
            tooltip: '全选',
            onPressed: () {
              var allChapterIds = widget.groups.expand((group) => group.chapters.map((chapter) => chapter.cid)).toList();
              if (_selected.length == allChapterIds.length) {
                _selected.clear();
              } else {
                _selected.clear();
                _selected.addAll(allChapterIds);
              }
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: ScrollbarWithMore(
          controller: _controller,
          interactive: true,
          crossAxisMargin: 2,
          child: SingleChildScrollView(
            controller: _controller,
            child: MangaTocView(
              groups: widget.groups,
              mangaId: widget.mangaId,
              mangaTitle: widget.mangaTitle,
              mangaCover: widget.mangaCover,
              mangaUrl: widget.mangaUrl,
              full: true,
              highlightColor: Theme.of(context).primaryColor.withOpacity(0.4),
              highlightedChapters: _selected,
              showNewBadge: true,
              customBadgeBuilder: (cid) {
                var oldChapter = _downloadedChapters.where((el) => el.chapterId == cid).firstOrNull;
                if (oldChapter == null) {
                  return null;
                }
                return Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 1.2, horizontal: 1.2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: oldChapter.succeeded ? Colors.green : Colors.blue,
                    ),
                    child: Icon(
                      oldChapter.succeeded ? Icons.check : Icons.arrow_downward,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                );
              },
              predicate: (cid) {
                if (!_selected.contains(cid)) {
                  _selected.add(cid);
                } else {
                  _selected.remove(cid);
                }
                if (mounted) setState(() {});
                return false;
              },
            ),
          ),
        ),
      ),
      floatingActionButton: ScrollAnimatedFab(
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
