import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/download_chapter_line.dart';
import 'package:manhuagui_flutter/service/storage/download_manga_task.dart';

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
    required this.toControlChapter,
    required this.toReadChapter,
    required this.toDeleteChapter,
  }) : super(key: key);

  final ScrollController innerController;
  final ScrollController outerController;
  final SliverOverlapAbsorberHandle injectorHandler;
  final DownloadedManga mangaEntity;
  final DownloadMangaQueueTask? downloadTask;
  final bool invertOrder;
  final void Function(int cid) toControlChapter;
  final void Function(int cid) toReadChapter;
  final void Function(int cid) toDeleteChapter;

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
    if (!widget.invertOrder) {
      unfinishedChapters.sort((i, j) => i.chapterId.compareTo(j.chapterId));
    } else {
      unfinishedChapters.sort((i, j) => j.chapterId.compareTo(i.chapterId));
    }

    return Scaffold(
      body: ExtendedScrollbar(
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
                          onPressedWhenEnabled: () => widget.toControlChapter.call(chapter.chapterId),
                          onPressedWhenDisabled: () => widget.toReadChapter.call(chapter.chapterId),
                          onLongPressed: () => widget.toDeleteChapter.call(chapter.chapterId),
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
