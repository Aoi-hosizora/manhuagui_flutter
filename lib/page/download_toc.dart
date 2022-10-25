import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/storage/download_manga.dart';
import 'package:manhuagui_flutter/service/storage/queue_manager.dart';

class DownloadTocPage extends StatefulWidget {
  const DownloadTocPage({
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
  State<DownloadTocPage> createState() => _DownloadTocPageState();
}

class _DownloadTocPageState extends State<DownloadTocPage> {
  final _controller = ScrollController();
  final _selected = <int>[];

  final _chapters = <DownloadedChapter>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _chapters.clear();
      _chapters.addAll(await DownloadDao.getChapters(mid: widget.mangaId) ?? []);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _downloadManga() async {
    // 1. 获取需要下载的章节
    var chapterIds = <int>[];
    for (var cid in _selected) {
      var oldChapter = _chapters.where((el) => el.chapterId == cid).toList().firstOrNull;
      if (oldChapter != null && oldChapter.success) {
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
              child: Text('取消'),
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
        content: Text('确定下载所选章节吗？'),
        actions: [
          TextButton(
            child: Text('下载'),
            onPressed: () async {
              Navigator.of(c).pop(true); // 关闭对话框
            },
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
      chapterIds: chapterIds,
    );

    // !!!
    unawaited(
      Future.microtask(() async {
        // 4. 更新数据库
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

        if (need) {
          // 5. 入队等待执行结束
          await QueueManager.instance.addTask(task);
        }
      }),
    );

    // 6. 关闭窗口
    Navigator.of(context).pop();
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
              customBadgeBuilder: (cid) {
                var oldChapter = _chapters.where((el) => el.chapterId == cid).toList().firstOrNull;
                if (oldChapter == null) {
                  return null;
                }
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 0, horizontal: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(3),
                      topRight: Radius.circular(1),
                    ),
                  ),
                  child: Icon(
                    oldChapter.success ? Icons.check : Icons.arrow_downward,
                    size: 13,
                    color: Colors.white,
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
    );
  }
}
