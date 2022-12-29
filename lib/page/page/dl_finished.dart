import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/manga_simple_toc.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/page/view/multi_selection_fab.dart';

/// 下载管理页-已完成
class DlFinishedSubPage extends StatefulWidget {
  const DlFinishedSubPage({
    Key? key,
    required this.innerController,
    required this.outerController,
    required this.actionController,
    required this.injectorHandler,
    required this.mangaEntity,
    required this.invertOrder,
    required this.history,
    required this.toReadChapter,
    required this.toDeleteChapters,
  }) : super(key: key);

  final ScrollController innerController;
  final ScrollController outerController;
  final ActionController actionController;
  final SliverOverlapAbsorberHandle injectorHandler;
  final DownloadedManga mangaEntity;
  final bool invertOrder;
  final MangaHistory? history;
  final void Function(int cid) toReadChapter;
  final void Function({required List<int> chapterIds}) toDeleteChapters;

  @override
  State<DlFinishedSubPage> createState() => _DlFinishedSubPageState();
}

class _DlFinishedSubPageState extends State<DlFinishedSubPage> with AutomaticKeepAliveClientMixin {
  final _msController = MultiSelectableController<ValueKey<int>>();

  @override
  void initState() {
    super.initState();
    widget.actionController.addAction(() => _msController.exitMultiSelectionMode());
  }

  @override
  void dispose() {
    widget.actionController.removeAction();
    _msController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var succeededChapters = widget.mangaEntity.downloadedChapters
        .where((el) => el.succeeded && !el.needUpdate) // 仅包括下载成功且不需要更新的章节
        .map((el) => Tuple2(el.chapterGroup, el.toTiny()))
        .toList();

    return WillPopScope(
      onWillPop: () async {
        if (!_msController.multiSelecting) {
          return true;
        }
        _msController.exitMultiSelectionMode();
        return false;
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
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: MultiSelectable<ValueKey<int>>(
                    controller: _msController,
                    stateSetter: () => mountedSetState(() {}),
                    onModeChanged: (_) => mountedSetState(() {}),
                    child: MangaSimpleTocView(
                      chapters: succeededChapters,
                      invertOrder: widget.invertOrder,
                      showNewBadge: false,
                      highlightedChapters: [widget.history?.chapterId ?? 0],
                      customBadgeBuilder: (cid) => DownloadBadge.fromEntity(
                        entity: widget.mangaEntity.downloadedChapters.where((el) => el.chapterId == cid).firstOrNull,
                      ),
                      itemBuilder: (_, chapterId, itemWidget) => chapterId == null
                          ? itemWidget
                          : SelectableCheckboxItem<ValueKey<int>>(
                              key: ValueKey<int>(chapterId),
                              checkboxPosition: PositionArgument.fromLTRB(null, null, 1, 1),
                              checkboxBuilder: (_, __, tip) => CheckboxForSelectableItem(
                                tip: tip,
                                backgroundColor: Colors.white,
                                scale: 0.7,
                                scaleAlignment: Alignment.bottomRight,
                              ),
                              itemBuilder: (_, key, tip) => itemWidget /* single grid */,
                            ),
                      onChapterPressed: widget.toReadChapter,
                      onChapterLongPressed: _msController.multiSelecting ? null : (chapterId) => _msController.enterMultiSelectionMode(alsoSelect: [ValueKey<int>(chapterId)]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: MultiSelectionFabContainer(
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
          multiSelectableController: _msController,
          onCounterPressed: () {
            var chapterIds = _msController.selectedItems.map((e) => e.value).toList();
            var allEntities = widget.invertOrder ? widget.mangaEntity.downloadedChapters.reversed : widget.mangaEntity.downloadedChapters;
            var titles = allEntities.where((el) => chapterIds.contains(el.chapterId)).map((m) => '《${m.chapterTitle}》').toList();
            MultiSelectionFabContainer.showSelectedItemsDialogForCounter(context, titles);
          },
          fabForMultiSelection: [
            MultiSelectionFabOption(
              child: Icon(Icons.delete),
              onPressed: () => widget.toDeleteChapters.call(chapterIds: _msController.selectedItems.map((k) => k.value).toList()),
            ),
          ],
        ),
      ),
    );
  }
}
