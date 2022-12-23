import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';

/// 章节列表展示，在 [MangaTocView] / [MangaSimpleTocView] 使用
class ChapterGridView extends StatelessWidget {
  const ChapterGridView({
    Key? key,
    required this.chapters,
    required this.padding,
    this.invertOrder = true,
    this.maxLines = -1,
    this.highlightColor,
    this.highlightedChapters = const [],
    this.extrasInStack,
    this.itemBuilder,
    required this.onChapterPressed,
    this.onChapterLongPressed,
  }) : super(key: key);

  final List<TinyMangaChapter> chapters;
  final EdgeInsets padding;
  final bool invertOrder; // true means desc
  final int maxLines; // -1 means full
  final Color? highlightColor;
  final List<int> highlightedChapters;
  final List<Widget> Function(TinyMangaChapter? chapter)? extrasInStack;
  final Widget Function(BuildContext context, TinyMangaChapter? chapter, Widget itemWidget)? itemBuilder;
  final void Function(TinyMangaChapter? chapter) onChapterPressed;
  final void Function(TinyMangaChapter? chapter)? onChapterLongPressed;

  Widget _buildItem({required BuildContext context, required TinyMangaChapter? chapter}) {
    return Stack(
      children: [
        Positioned.fill(
          child: OutlinedButton(
            child: Text(
              chapter?.title ?? '...',
              style: TextStyle(color: Colors.black),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              backgroundColor: !highlightedChapters.contains(chapter?.cid)
                  ? null //
                  : (highlightColor ?? Theme.of(context).primaryColorLight.withOpacity(0.6)),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => onChapterPressed(chapter),
            onLongPress: onChapterLongPressed == null ? null : () => onChapterLongPressed!.call(chapter),
          ),
        ),
        if (extrasInStack != null) //
          ...extrasInStack!.call(chapter),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const hSpace = 8.0;
    const vSpace = 8.0;

    final width = (MediaQuery.of(context).size.width - 2 * padding.left - 3 * hSpace) / 4; // |   ▢ ▢ ▢ ▢   |
    const height = 36.0;

    List<TinyMangaChapter?> shown = chapters.toList();
    if (!invertOrder) {
      shown.sort((i, j) => i!.cid.compareTo(j!.cid));
    } else {
      shown.sort((i, j) => j!.cid.compareTo(i!.cid));
    }

    if (maxLines > 0) {
      var count = maxLines * 4;
      if (shown.length > count) {
        shown = [...shown.sublist(0, count - 1), null];
        // for example:
        // maxLines: 3 => X X X X | X X X X | X X X O
        // maxLines: 1 => X X X O
      }
    }

    return Padding(
      padding: padding,
      child: Wrap(
        spacing: hSpace,
        runSpacing: vSpace,
        children: [
          for (var chapter in shown)
            SizedBox(
              width: width,
              height: height,
              child: _buildItem(
                context: context,
                chapter: chapter,
              ).let(
                (itemWidget) => itemBuilder?.call(context, chapter, itemWidget) ?? itemWidget,
              ),
            ),
        ],
      ),
    );
  }
}
