import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 漫画章节阅读页-章节列表
class ViewTocSubPage extends StatefulWidget {
  const ViewTocSubPage({
    Key? key,
    required this.mangaId,
    required this.mangaTitle,
    required this.groups,
    required this.currReadChapterId,
    this.lastReadChapterId,
    this.footprintChapterIds,
    required this.onChapterPressed,
    this.onChapterLongPressed,
  }) : super(key: key);

  final int mangaId;
  final String mangaTitle;
  final List<MangaChapterGroup> groups;
  final int currReadChapterId;
  final int? lastReadChapterId;
  final List<int>? footprintChapterIds;
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
  List<MangaChapterGroup>? _downloadedChapters;
  var _downloadOnly = false;
  var _columns = 4; // default to four columns

  Future<void> _loadData() async {
    _loading = true;
    if (mounted) setState(() {});

    try {
      await Future.delayed(Duration(milliseconds: 400)); // fake loading
      _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId);
      _downloadedChapters = _downloadEntity?.downloadedChapters.toChapterGroup(origin: widget.groups);
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _updateByEvent(DownloadUpdatedEvent ev) async {
    if (ev.mangaId == widget.mangaId) {
      _downloadEntity = await DownloadDao.getManga(mid: widget.mangaId);
      _downloadedChapters = _downloadEntity?.downloadedChapters.toChapterGroup(origin: widget.groups);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mangaTitle),
        leading: AppBarActionButton.leading(context: context),
        actions: [
          AppBarActionButton(
            icon: Icon(_downloadOnly ? CustomIcons.eye_download : CustomIcons.eye_menu),
            tooltip: _downloadOnly ? '当前仅显示下载章节' : '当前显示着全部章节',
            onPressed: () => mountedSetState(() => _downloadOnly = !_downloadOnly),
          ),
          PopupMenuButton(
            child: Builder(
              builder: (c) => AppBarActionButton(
                icon: Icon(Icons.more_vert),
                tooltip: '更多选项',
                onPressed: () => c.findAncestorStateOfType<PopupMenuButtonState>()?.showButtonMenu(),
              ),
            ),
            itemBuilder: (_) => [
              for (var column in [2, 3, 4])
                PopupMenuItem(
                  child: IconTextMenuItem(
                    _columns == column ? Icons.radio_button_on : Icons.radio_button_off,
                    '显示$column列',
                  ),
                  onTap: () => mountedSetState(() => _columns = column),
                ),
            ],
          ),
        ],
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
                  groups: !_downloadOnly ? widget.groups : (_downloadedChapters ?? []),
                  full: true,
                  tocTitle: !_downloadOnly ? '章节列表' : '章节列表 (仅下载)',
                  columns: _columns,
                  highlightedChapters: [widget.currReadChapterId],
                  highlighted2Chapters: [widget.lastReadChapterId ?? 0],
                  faintedChapters: widget.footprintChapterIds ?? [],
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
