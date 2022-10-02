import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/chapter_group.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/natives/browser.dart';

/// 漫画章节目录
/// Page for [MangaChapterGroup].
class MangaTocPage extends StatefulWidget {
  const MangaTocPage({
    Key? key,
    required this.mid,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.groups,
    required this.highlightedChapter,
  }) : super(key: key);

  final int mid;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final List<MangaChapterGroup> groups;
  final int highlightedChapter;

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
    HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mid).then((r) {
      _history = r;
      if (mounted) setState(() {});
    }).catchError((_) {});
    _cancelHandler = EventBusManager.instance.listen<HistoryUpdatedEvent>((_) async {
      _history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: widget.mid).catchError((_) {});
      if (mounted) setState(() {});
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
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_browser),
            tooltip: '打开浏览器',
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
            child: ChapterGroupView(
              groups: widget.groups,
              full: true,
              highlightedChapter: _history?.chapterId ?? widget.highlightedChapter,
              mangaId: widget.mid,
              mangaTitle: widget.mangaTitle,
              mangaCover: widget.mangaCover,
              mangaUrl: widget.mangaUrl,
            ),
          ),
        ),
      ),
    );
  }
}
