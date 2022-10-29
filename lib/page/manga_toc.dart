import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 漫画章节目录页，展示所给 [MangaChapterGroup] 信息
class MangaTocPage extends StatefulWidget {
  const MangaTocPage({
    Key? key,
    required this.mangaId,
    required this.mangaTitle,
    required this.groups,
    required this.onChapterPressed,
  }) : super(key: key);

  final int mangaId;
  final String mangaTitle;
  final List<MangaChapterGroup> groups;
  final void Function(int cid) onChapterPressed;

  @override
  _MangaTocPageState createState() => _MangaTocPageState();
}

class _MangaTocPageState extends State<MangaTocPage> {
  final _controller = ScrollController();
  var _loading = true; // fake loading flag
  VoidCallback? _cancelHandler;
  MangaHistory? _history;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 300), () {
        _loading = false;
        if (mounted) setState(() {});
      });
    });
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
      ),
      body: PlaceholderText(
        state: _loading ? PlaceholderState.loading : PlaceholderState.normal,
        setting: PlaceholderSetting().copyWithChinese(),
        childBuilder: (c) => Container(
          color: Colors.white,
          child: ScrollbarWithMore(
            controller: _controller,
            interactive: true,
            crossAxisMargin: 2,
            child: SingleChildScrollView(
              controller: _controller,
              child: MangaTocView(
                mangaId: widget.mangaId,
                mangaTitle: widget.mangaTitle,
                groups: widget.groups,
                full: true,
                highlightedChapters: [_history?.chapterId ?? 0],
                onPressed: widget.onChapterPressed,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _loading
          ? null
          : ScrollAnimatedFab(
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
