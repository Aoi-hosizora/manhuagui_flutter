import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/manga_simple_toc.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/service/storage/download_manga.dart';

/// 章节下载管理页-已完成

class DlFinishedSubPage extends StatefulWidget {
  const DlFinishedSubPage({
    Key? key,
    required this.innerController,
    required this.outerController,
    required this.injectorHandler,
    required this.mangaEntity,
    required this.downloadTask,
    required this.invertOrder,
    required this.history,
    required this.onChapterPressed,
  }) : super(key: key);

  final ScrollController innerController;
  final ScrollController outerController;
  final SliverOverlapAbsorberHandle injectorHandler;
  final DownloadedManga mangaEntity;
  final DownloadMangaQueueTask? downloadTask;
  final bool invertOrder;
  final MangaHistory? history;
  final void Function(int cid) onChapterPressed;

  @override
  State<DlFinishedSubPage> createState() => _DlFinishedSubPageState();
}

class _DlFinishedSubPageState extends State<DlFinishedSubPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var succeededChapters = widget.mangaEntity.downloadedChapters //
        .where((el) => el.succeeded)
        .map((el) => Tuple2(el.chapterGroup, el.toTiny()))
        .toList();

    return Scaffold(
      body: ScrollbarWithMore(
        controller: widget.innerController,
        interactive: true,
        crossAxisMargin: 2,
        child: CustomScrollView(
          controller: widget.innerController,
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverOverlapInjector(
              handle: widget.injectorHandler,
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: MangaSimpleTocView(
                  chapters: succeededChapters,
                  invertOrder: widget.invertOrder,
                  showNewBadge: false,
                  highlightedChapters: [widget.history?.chapterId ?? 0],
                  customBadgeBuilder: (cid) {
                    var oldChapter = widget.mangaEntity.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull;
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
                  onChapterPressed: widget.onChapterPressed,
                  onChapterLongPressed: (cid) => Fluttertoast.showToast(msg: 'TODO $cid'), // TODO
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: MangaSimpleTocView(
                  chapters: succeededChapters,
                  invertOrder: widget.invertOrder,
                  showNewBadge: false,
                  highlightedChapters: [widget.history?.chapterId ?? 0],
                  customBadgeBuilder: (cid) {
                    var oldChapter = widget.mangaEntity.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull;
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
                  onChapterPressed: widget.onChapterPressed,
                  onChapterLongPressed: (cid) => Fluttertoast.showToast(msg: 'TODO $cid'), // TODO
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: MangaSimpleTocView(
                  chapters: succeededChapters,
                  invertOrder: widget.invertOrder,
                  showNewBadge: false,
                  highlightedChapters: [widget.history?.chapterId ?? 0],
                  customBadgeBuilder: (cid) {
                    var oldChapter = widget.mangaEntity.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull;
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
                  onChapterPressed: widget.onChapterPressed,
                  onChapterLongPressed: (cid) => Fluttertoast.showToast(msg: 'TODO $cid'), // TODO
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: MangaSimpleTocView(
                  chapters: succeededChapters,
                  invertOrder: widget.invertOrder,
                  showNewBadge: false,
                  highlightedChapters: [widget.history?.chapterId ?? 0],
                  customBadgeBuilder: (cid) {
                    var oldChapter = widget.mangaEntity.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull;
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
                  onChapterPressed: widget.onChapterPressed,
                  onChapterLongPressed: (cid) => Fluttertoast.showToast(msg: 'TODO $cid'), // TODO
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScrollAnimatedFab(
        scrollController: widget.innerController,
        condition: ScrollAnimatedCondition.direction,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: null,
          onPressed: () => widget.outerController.scrollToTop(),
        ),
      ),
    );
  }
}
