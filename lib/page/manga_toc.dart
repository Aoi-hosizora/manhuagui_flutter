import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';

/// 漫画章节目录页，展示所给 [MangaChapterGroup] 信息
class MangaTocPage extends StatefulWidget {
  const MangaTocPage({
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
  _MangaTocPageState createState() => _MangaTocPageState();
}

class _MangaTocPageState extends State<MangaTocPage> {
  final _controller = ScrollController();
  VoidCallback? _cancelHandler;
  MangaHistory? _history;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      try {
        _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);
        if (mounted) setState(() {});
      } catch (_) {}
    });
    _cancelHandler = EventBusManager.instance.listen<HistoryUpdatedEvent>((_) async {
      try {
        _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mangaId);
        if (mounted) setState(() {});
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _cancelHandler?.call();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mangaTitle),
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
              highlightedChapters: [_history?.chapterId ?? 0],
              lastChapterPage: _history?.chapterPage ?? 1,
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
