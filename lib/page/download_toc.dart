import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
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
    // TODO 检查 _selected 中已经在下载列表中的章节

    // 1. 构造下载任务
    var task = MangaDownloadQueueTask(
      mangaId: widget.mangaId,
      chapterIds: _selected,
    );

    // !!!
    unawaited(
      Future.microtask(() async {
        // 2. 更新数据库
        await task.prepare(
          mangaTitle: widget.mangaTitle,
          mangaCover: widget.mangaCover,
          mangaUrl: widget.mangaUrl,
          getChapter: (cid) {
            var tuple = widget.groups.findChapterAndGroupName(cid)!;
            var chapter = tuple.item1;
            var groupName = tuple.item2;
            return DownloadedChapter(
              mangaId: chapter.mid,
              chapterId: chapter.cid,
              chapterTitle: chapter.title,
              chapterGroup: groupName,
              totalPagesCount: chapter.pageCount,
              successPagesCount: 0,
            );
          },
        );

        // 3. 入队等待执行结束
        await QueueManager.instance.addTask(task) ?? MangaDownloadTaskResult.canceled;
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
