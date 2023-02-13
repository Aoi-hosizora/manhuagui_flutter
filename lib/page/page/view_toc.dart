import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 漫画章节阅读页-章节目录
class ViewTocSubPage extends StatefulWidget {
  const ViewTocSubPage({
    Key? key,
    required this.mangaId,
    required this.mangaTitle,
    required this.groups,
    required this.highlightedChapter,
    required this.onChapterPressed,
    this.onChapterLongPressed,
  }) : super(key: key);

  final int mangaId;
  final String mangaTitle;
  final List<MangaChapterGroup> groups;
  final int highlightedChapter;
  final void Function(int cid) onChapterPressed;
  final void Function(int cid)? onChapterLongPressed;

  @override
  State<ViewTocSubPage> createState() => _ViewTocSubPageState();
}

class _ViewTocSubPageState extends State<ViewTocSubPage> {
  final _controller = ScrollController();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadUpdatedEvent>((ev) => _updateByEvent(ev)));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _controller.dispose();
    super.dispose();
  }

  var _loading = true; // initialize to true, fake loading flag
  DownloadedManga? _downloadEntity;

  Future<void> _loadData() async {
    _loading = true;
    if (mounted) setState(() {});

    try {
      await Future.delayed(Duration(milliseconds: 400)); // fake loading
      _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId);
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _updateByEvent(DownloadUpdatedEvent ev) async {
    if (ev.mangaId == widget.mangaId) {
      _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId);
      if (mounted) setState(() {});
    }
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
          child: ExtendedScrollbar(
            controller: _controller,
            interactive: true,
            mainAxisMargin: 2,
            crossAxisMargin: 2,
            child: ListView(
              controller: _controller,
              padding: EdgeInsets.zero,
              physics: AlwaysScrollableScrollPhysics(),
              children: [
                MangaTocView(
                  groups: widget.groups,
                  full: true,
                  highlightedChapters: [widget.highlightedChapter],
                  customBadgeBuilder: (cid) => DownloadBadge.fromEntity(
                    entity: _downloadEntity?.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull,
                  ),
                  onChapterPressed: widget.onChapterPressed,
                  onChapterLongPressed: widget.onChapterLongPressed,
                ),
              ],
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
