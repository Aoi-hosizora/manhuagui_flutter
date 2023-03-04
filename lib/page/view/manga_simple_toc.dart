import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/page/view/chapter_grid.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';

/// 漫画章节列表（给定章节列表），在 [DlFinishedSubPage] 使用
class MangaSimpleTocView extends StatelessWidget {
  const MangaSimpleTocView({
    Key? key,
    required this.chapters,
    this.showPageCount = false,
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

  final List<Tuple2<String, TinyMangaChapter>> chapters;
  final bool showPageCount;
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
    if (chapters.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        child: Center(
          child: Text(
            '暂无章节',
            style: Theme.of(context).textTheme.subtitle1,
          ),
        ),
      );
    }

    var groupMap = <String, List<TinyMangaChapter>>{};
    for (var chapter in chapters) {
      var groupName = chapter.item1;
      var group = groupMap[groupName] ?? [];
      group.add(chapter.item2);
      groupMap[groupName] = group;
    }
    var groups = <MangaChapterGroup>[];
    for (var kv in groupMap.entries) {
      groups.add(MangaChapterGroup(title: kv.key, chapters: kv.value));
    }
    groups = groups.makeSureRegularGroupIsFirst(); // 保证【单话】为首个章节分组

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
