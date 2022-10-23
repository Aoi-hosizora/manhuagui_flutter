import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _downloadManga() async {
    // 1. 将漫画信息与所有需要下载的章节信息都更新至数据库
    await DownloadDao.addOrUpdateManga(
      manga: DownloadedManga(
        mangaId: widget.mangaId,
        mangaTitle: widget.mangaTitle,
        mangaCover: widget.mangaCover,
        totalChaptersCount: 0,
        startedChaptersCount: 0,
        successChaptersCount: 0,
        updatedAt: DateTime.now(),
      ),
    );
    for (var chapterId in _selected) {
      var tuple = widget.groups.findChapterAndGroupName(chapterId)!;
      var chapter = tuple.item1;
      await DownloadDao.addOrUpdateChapter(
        chapter: DownloadedChapter(
          mangaId: chapter.mid,
          chapterId: chapter.cid,
          chapterTitle: chapter.title,
          chapterGroup: tuple.item2,
          totalPagesCount: chapter.pageCount,
          successPagesCount: 0,
        ),
      );
    }

    // !!!
    unawaited(
      Future.microtask(() async {
        // 2. 构造下载任务
        var task = MangaDownloadQueueTask(
          mangaId: widget.mangaId,
          chapterIds: _selected,
          progressNotifier: (progress) {
            var ev = DownloadProgressChangedEvent(progress: progress, result: null);
            EventBusManager.instance.fire(ev);
          },
        );

        // 3. 入队
        var result = await QueueManager.instance.addTask(task) ?? MangaDownloadResult.canceled;

        // 4. 任务结束
        var ev = DownloadProgressChangedEvent(progress: null, result: result);
        EventBusManager.instance.fire(ev);
      }),
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
            onPressed: () {
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text('下载确认'),
                  content: Text('确定下载所选章节吗？'),
                  actions: [
                    TextButton(
                      child: Text('下载'),
                      onPressed: () async {
                        await _downloadManga();
                        Navigator.of(c).pop(); // 关闭对话框
                        Navigator.of(context).pop(); // 关闭该页
                      },
                    ),
                    TextButton(
                      child: Text('取消'),
                      onPressed: () => Navigator.of(c).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
          AppBarActionButton(
            icon: Icon(Icons.select_all),
            tooltip: '全选',
            onPressed: () {
              var allChapterIds = widget.groups.expand((group) => group.chapters.map((chapter) => chapter.cid)).toList();
              _selected.clear();
              _selected.addAll(allChapterIds);
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
              highlightedChapters: _selected,
              showNewBadge: false,
              predicate: (cid) {
                if (!_selected.contains(cid)) {
                  _selected.add(cid);
                  if (mounted) setState(() {});
                }
                return false;
              },
            ),
          ),
        ),
      ),
    );
  }
}
