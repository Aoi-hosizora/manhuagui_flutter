import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/download_chapter_line.dart';
import 'package:manhuagui_flutter/service/storage/download_task.dart';

/// 下载管理页-未完成/所有章节
class DlUnfinishedSubPage extends StatefulWidget {
  const DlUnfinishedSubPage({
    Key? key,
    required this.innerController,
    required this.outerController,
    required this.injectorHandler,
    required this.mangaEntity,
    required this.downloadTask,
    required this.showAllChapters,
    required this.invertOrder,
    required this.toReadChapter,
    required this.toDeleteChapter,
    required this.toControlChapter,
    required this.toAdjustChapter,
  }) : super(key: key);

  final ScrollController innerController;
  final ScrollController outerController;
  final SliverOverlapAbsorberHandle injectorHandler;
  final DownloadedManga mangaEntity;
  final DownloadMangaQueueTask? downloadTask;
  final bool showAllChapters;
  final bool invertOrder;
  final void Function(int cid) toReadChapter;
  final void Function(int cid) toDeleteChapter;
  final void Function(int cid, {required bool start}) toControlChapter;
  final void Function(int cid) toAdjustChapter;

  @override
  State<DlUnfinishedSubPage> createState() => _DlUnfinishedSubPageState();
}

class _DlUnfinishedSubPageState extends State<DlUnfinishedSubPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    List<DownloadedChapter> unfinishedChapters;
    if (!widget.showAllChapters) {
      unfinishedChapters = widget.mangaEntity.downloadedChapters
          .where((el) => !el.succeeded || el.needUpdate) // 仅包括未下载成功或需要更新的章节
          .toList();
    } else {
      unfinishedChapters = widget.mangaEntity.downloadedChapters // 包括所有章节
          .toList();
    }
    if (!widget.invertOrder) {
      unfinishedChapters.sort((i, j) => i.chapterId.compareTo(j.chapterId));
    } else {
      unfinishedChapters.sort((i, j) => j.chapterId.compareTo(i.chapterId));
    }

    return Scaffold(
      body: ExtendedScrollbar(
        controller: widget.innerController,
        interactive: true,
        mainAxisMargin: 2,
        crossAxisMargin: 2,
        extraMargin: EdgeInsets.only(top: widget.injectorHandler.layoutExtent ?? 0),
        child: CustomScrollView(
          controller: widget.innerController,
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverOverlapInjector(
              handle: widget.injectorHandler,
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
                          onPressed: () => widget.toReadChapter.call(chapter.chapterId),
                          onLongPressed: () => widget.toDeleteChapter.call(chapter.chapterId),
                          onPauseIconPressed: () => widget.toControlChapter.call(chapter.chapterId, start: false),
                          onStartIconPressed: () => widget.toControlChapter.call(chapter.chapterId, start: true),
                          onIconLongPressed: () => widget.toAdjustChapter.call(chapter.chapterId),
                        ),
                      ),
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
