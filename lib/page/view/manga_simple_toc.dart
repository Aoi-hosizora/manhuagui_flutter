import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/page/view/chapter_grid.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';

/// 漫画章节列表（给定章节分组列表，不包括正逆序等按钮），在 [DlFinishedSubPage] 使用
class MangaSimpleTocView extends StatelessWidget {
  const MangaSimpleTocView({
    Key? key,
    required this.groups,
    this.showPageCount = false,
    this.columns = 4,
    this.gridPadding,
    this.invertOrder = true,
    this.highlightColor,
    this.highlightedChapters = const [],
    this.showNewBadge = true,
    this.customBadgeBuilder,
    this.itemBuilder,
    required this.onChapterPressed,
    this.onChapterLongPressed,
  }) : super(key: key);

  final List<MangaChapterGroup> groups;
  final bool showPageCount;
  final int columns;
  final EdgeInsets? gridPadding;
  final bool invertOrder;
  final Color? highlightColor;
  final List<int> highlightedChapters;
  final bool showNewBadge;
  final Widget? Function(int cid)? customBadgeBuilder;
  final Widget Function(BuildContext context, int? cid, Widget itemWidget)? itemBuilder;
  final void Function(int cid) onChapterPressed;
  final void Function(int cid)? onChapterLongPressed;

  Widget _buildGrid({required int idx, required List<TinyMangaChapter> chapters}) {
    return ChapterGridView(
      chapters: chapters,
      padding: gridPadding ?? EdgeInsets.symmetric(horizontal: 12),
      showPageCount: showPageCount,
      invertOrder: invertOrder /* true means desc */,
      maxLines: -1 /* show all chapters */,
      columns: columns,
      highlightColor: highlightColor,
      highlightedChapters: highlightedChapters,
      extrasInStack: (chapter) {
        if (chapter == null) {
          return [];
        }
        var newBadge = showNewBadge && chapter.isNew ? NewBadge() : null;
        var customBadge = customBadgeBuilder?.call(chapter.cid);
        return [
          if (newBadge != null) newBadge,
          if (customBadge != null) customBadge,
        ];
      },
      itemBuilder: itemBuilder == null
          ? null //
          : (ctx, chapter, itemWidget) => itemBuilder!.call(ctx, chapter?.cid, itemWidget),
      onChapterPressed: (chapter) {
        if (chapter != null) {
          onChapterPressed.call(chapter.cid);
        }
      },
      onChapterLongPressed: onChapterLongPressed == null
          ? null
          : (chapter) {
              if (chapter != null) {
                onChapterLongPressed!.call(chapter.cid);
              }
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    var isEmpty = this.groups.isEmpty || this.groups.allChapters.isEmpty;
    if (isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text('暂无章节', style: Theme.of(context).textTheme.subtitle1),
        ),
      );
    }

    var groups = this.groups.makeSureRegularGroupIsFirst(); // 保证【单话】为首个章节分组
    return Column(
      children: [
        SizedBox(height: 10),
        for (var i = 0; i < groups.length; i++) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '・${groups[i].title}・',
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: _buildGrid(
              idx: i,
              chapters: groups[i].chapters,
            ),
          ),
          SizedBox(height: 10),
        ],
      ],
    );
  }
}
