import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/download_chapter_line.dart';
import 'package:manhuagui_flutter/page/view/manga_simple_toc.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/service/storage/download_manga.dart';

/// 章节下载管理页-未完成
class DlUnfinishedSubPage extends StatefulWidget {
  const DlUnfinishedSubPage({
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
  State<DlUnfinishedSubPage> createState() => _DlUnfinishedSubPageState();
}

class _DlUnfinishedSubPageState extends State<DlUnfinishedSubPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var unfinishedChapters = widget.mangaEntity.downloadedChapters //
        .where((el) => !el.succeeded)
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
            // TODO xxx
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: MangaSimpleTocView(
                  chapters: unfinishedChapters.map((el) => Tuple2(el.chapterGroup, el.toTiny())).toList(),
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
              child: SizedBox(height: 100),
            ),
            if (unfinishedChapters.isEmpty)
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  child: Center(
                    child: Text(
                      '暂无章节',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                ),
              ),
            if (unfinishedChapters.isNotEmpty)
              SliverList(
                delegate: SliverChildListDelegate(
                  <Widget>[
                    for (var chapter in unfinishedChapters)
                      Material(
                        color: Colors.white,
                        child: DownloadChapterLineView(
                          chapterEntity: chapter,
                          downloadTask: widget.downloadTask,
                          onPressed: () => widget.onChapterPressed.call(chapter.chapterId),
                          onLongPressed: () => Fluttertoast.showToast(msg: 'TODO ${chapter.chapterId}'), // TODO
                        ),
                      )
                  ].separate(
                    Container(
                      color: Colors.white,
                      child: Divider(height: 0, thickness: 1),
                    ),
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
