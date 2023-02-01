import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/download_chapter_line.dart';
import 'package:manhuagui_flutter/page/view/multi_selection_fab.dart';
import 'package:manhuagui_flutter/service/storage/download_task.dart';

/// 下载管理页-未完成/所有章节
class DlUnfinishedSubPage extends StatefulWidget {
  const DlUnfinishedSubPage({
    Key? key,
    required this.innerController,
    required this.outerController,
    required this.actionController,
    required this.injectorHandler,
    required this.mangaEntity,
    required this.downloadTask,
    required this.showAllChapters,
    required this.invertOrder,
    required this.toReadChapter,
    required this.toDeleteChapters,
    required this.toControlChapter,
    required this.toAdjustChapter,
  }) : super(key: key);

  final ScrollController innerController;
  final ScrollController outerController;
  final ActionController actionController;
  final SliverOverlapAbsorberHandle injectorHandler;
  final DownloadedManga mangaEntity;
  final DownloadMangaQueueTask? downloadTask;
  final bool showAllChapters;
  final bool invertOrder;
  final void Function(int cid) toReadChapter;
  final void Function({required List<int> chapterIds}) toDeleteChapters;
  final void Function(int cid, {required bool start}) toControlChapter;
  final void Function(int cid) toAdjustChapter;

  @override
  State<DlUnfinishedSubPage> createState() => _DlUnfinishedSubPageState();
}

class _DlUnfinishedSubPageState extends State<DlUnfinishedSubPage> with AutomaticKeepAliveClientMixin {
  final _msController = MultiSelectableController<ValueKey<int>>();

  @override
  void initState() {
    super.initState();
    widget.actionController.addAction('exitMultiSelectionMode', () => _msController.exitMultiSelectionMode());
  }

  @override
  void dispose() {
    widget.actionController.removeAction('exitMultiSelectionMode');
    _msController.dispose();
    super.dispose();
  }

  List<DownloadedChapter> _getData() {
    List<DownloadedChapter> chapters;
    if (!widget.showAllChapters) {
      chapters = widget.mangaEntity.downloadedChapters
          .where((el) => !el.succeeded || el.needUpdate) // 仅包括未下载成功或需要更新的章节
          .toList();
    } else {
      chapters = widget.mangaEntity.downloadedChapters // 包括所有章节
          .toList();
    }

    // sort in this sub page
    if (!widget.invertOrder) {
      chapters.sort((i, j) => i.chapterId.compareTo(j.chapterId)); // compare through chapterId
    } else {
      chapters.sort((i, j) => j.chapterId.compareTo(i.chapterId));
    }
    return chapters;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var chapters = _getData();

    return WillPopScope(
      onWillPop: () async {
        if (_msController.multiSelecting) {
          _msController.exitMultiSelectionMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
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
              if (chapters.isEmpty)
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
              if (chapters.isNotEmpty)
                MultiSelectable<ValueKey<int>>(
                  controller: _msController,
                  stateSetter: () => mountedSetState(() {}),
                  onModeChanged: (_) => mountedSetState(() {}),
                  child: SliverList(
                    delegate: SliverChildListDelegate(
                      <Widget>[
                        for (var chapter in chapters)
                          SelectableCheckboxItem<ValueKey<int>>(
                            key: ValueKey<int>(chapter.chapterId),
                            checkboxPosition: PositionArgument.fromLTRB(null, 0, 11, 0),
                            checkboxBuilder: (_, __, tip) => CheckboxForSelectableItem(tip: tip, backgroundColor: Colors.white),
                            itemBuilder: (_, key, tip) => Material(
                              color: Colors.white,
                              child: DownloadChapterLineView(
                                chapterEntity: chapter,
                                downloadTask: widget.downloadTask,
                                onPressed: () => widget.toReadChapter.call(chapter.chapterId),
                                onLongPressed: !tip.isNormal ? null : () => _msController.enterMultiSelectionMode(alsoSelect: [key]),
                                onPauseIconPressed: () => widget.toControlChapter.call(chapter.chapterId, start: false),
                                onStartIconPressed: () => widget.toControlChapter.call(chapter.chapterId, start: true),
                                onIconLongPressed: () => widget.toAdjustChapter.call(chapter.chapterId),
                              ),
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
                ),
            ],
          ),
        ),
        floatingActionButton: MultiSelectionFabContainer(
          multiSelectableController: _msController,
          onCounterPressed: () {
            var chapterIds = _msController.selectedItems.map((e) => e.value).toList();
            var allEntities = widget.invertOrder ? widget.mangaEntity.downloadedChapters.reversed : widget.mangaEntity.downloadedChapters; // chapters are in cid asc order
            var titles = allEntities.where((el) => chapterIds.contains(el.chapterId)).map((m) => '《${m.chapterTitle}》').toList();
            MultiSelectionFabContainer.showSelectedItemsDialogForCounter(context, titles);
          },
          fabForMultiSelection: [
            MultiSelectionFabOption(
              child: Icon(Icons.more_horiz),
              show: _msController.selectedItems.length == 1,
              onPressed: () => chapters.where((el) => el.chapterId == _msController.selectedItems.first.value).firstOrNull?.let((chapter) {
                _msController.exitMultiSelectionMode();
                widget.toAdjustChapter(chapter.chapterId);
              }),
            ),
            MultiSelectionFabOption(
              child: Icon(Icons.delete),
              onPressed: () => widget.toDeleteChapters.call(chapterIds: _msController.selectedItems.map((k) => k.value).toList()),
            ),
          ],
          fabForNormal: ScrollAnimatedFab(
            scrollController: widget.innerController,
            condition: !_msController.multiSelecting ? ScrollAnimatedCondition.direction : ScrollAnimatedCondition.custom,
            customBehavior: (_) => false,
            fab: FloatingActionButton(
              child: Icon(Icons.vertical_align_top),
              heroTag: null,
              onPressed: () => widget.outerController.scrollToTop(),
            ),
          ),
        ),
      ),
    );
  }
}
