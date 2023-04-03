import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
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
    required this.toAdjustChapter,
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
  final void Function(int cid) toAdjustChapter;

  @override
  State<DlFinishedSubPage> createState() => _DlFinishedSubPageState();
}

class _DlFinishedSubPageState extends State<DlFinishedSubPage> with AutomaticKeepAliveClientMixin {
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

  Tuple2<List<TinyMangaChapter>, List<MangaChapterGroup>> _getData() {
    var dlChapters = widget.mangaEntity.downloadedChapters
        .where((el) => el.succeeded && !el.needUpdate) // 仅包括下载成功且不需要更新的章节
        .toList(); // no need to sort in this sub page, it will be sorted in chapter grid view

    var chapters = dlChapters.map((el) => el.toTiny()).toList();
    var groups = dlChapters.toChapterGroup();
    return Tuple2(chapters, groups);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var tuple = _getData();
    var chapters = tuple.item1;
    var groups = tuple.item2;

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
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: MultiSelectable<ValueKey<int>>(
                    controller: _msController,
                    stateSetter: () => mountedSetState(() {}),
                    onModeChanged: (_) => mountedSetState(() {}),
                    child: MangaSimpleTocView(
                      groups: groups,
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
                              checkboxPosition: PositionArgument.fromLTRB(null, null, 0.9, 1),
                              checkboxBuilder: (_, __, tip) => CheckboxForSelectableItem(
                                tip: tip,
                                backgroundColor: chapterId != widget.history?.chapterId //
                                    ? Colors.white
                                    : Theme.of(context).primaryColorLight.applyOpacity(0.6),
                                scale: 0.7,
                                scaleAlignment: Alignment.bottomRight,
                              ),
                              itemBuilder: (_, key, tip) => itemWidget /* single grid */,
                            ),
                      onChapterPressed: widget.toReadChapter,
                      onChapterLongPressed: _msController.multiSelecting
                          ? null //
                          : (chapterId) => _msController.enterMultiSelectionMode(alsoSelect: [ValueKey<int>(chapterId)]),
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
            var allEntities = widget.invertOrder ? widget.mangaEntity.downloadedChapters.reversed : widget.mangaEntity.downloadedChapters; // chapters are in cid asc order
            var chapterIds = _msController.selectedItems.map((e) => e.value).toList();
            var titles = allEntities.where((el) => chapterIds.contains(el.chapterId)).map((m) => '《${m.chapterTitle}》').toList();
            var allKeys = chapters.map((el) => ValueKey(el.cid)).toList();
            MultiSelectionFabContainer.showCounterDialog(context, controller: _msController, selected: titles, allKeys: allKeys);
          },
          fabForMultiSelection: [
            MultiSelectionFabOption(
              child: Icon(Icons.more_horiz),
              tooltip: '查看更多选项',
              show: _msController.selectedItems.length == 1,
              onPressed: () => chapters.where((el) => el.cid == _msController.selectedItems.first.value).firstOrNull?.let((chapter) {
                _msController.exitMultiSelectionMode();
                widget.toAdjustChapter(chapter.cid);
              }),
            ),
            MultiSelectionFabOption(
              child: Icon(Icons.delete),
              tooltip: '删除下载章节',
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
