import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';

/// 章节列表展示，在 [MangaTocView] / [MangaSimpleTocView] 使用
class ChapterGridView extends StatelessWidget {
  const ChapterGridView({
    Key? key,
    required this.chapters,
    required this.padding,
    required this.showPageCount,
    this.invertOrder = true,
    this.maxLines = -1,
    this.columns = 4,
    this.highlightColor,
    this.highlightedChapters = const [],
    this.highlight2Color,
    this.highlighted2Chapters = const [],
    this.faintTextColor,
    this.faintedChapters = const [],
    this.showHighlight = true,
    this.showHighlight2 = true,
    this.showFaintColor = true,
    this.extrasInStack,
    this.itemBuilder,
    required this.onChapterPressed,
    this.onChapterLongPressed,
  }) : super(key: key);

  final List<TinyMangaChapter> chapters;
  final EdgeInsets padding;
  final bool showPageCount;
  final bool invertOrder; // true means desc
  final int maxLines; // -1 means full
  final int columns;
  final Color? highlightColor;
  final List<int> highlightedChapters;
  final Color? highlight2Color;
  final List<int> highlighted2Chapters;
  final Color? faintTextColor;
  final List<int> faintedChapters;
  final bool showHighlight;
  final bool showHighlight2;
  final bool showFaintColor;
  final List<Widget> Function(TinyMangaChapter? chapter)? extrasInStack;
  final Widget Function(BuildContext context, TinyMangaChapter? chapter, Widget itemWidget)? itemBuilder;
  final void Function(TinyMangaChapter? chapter) onChapterPressed;
  final void Function(TinyMangaChapter? chapter)? onChapterLongPressed;

  Widget _buildItem({required BuildContext context, required TinyMangaChapter? chapter}) {
    return Stack(
      children: [
        Positioned.fill(
          child: OutlinedButton(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chapter?.title ?? '...',
                  style: Theme.of(context).textTheme.button?.copyWith(
                        color: !faintedChapters.contains(chapter?.cid) //
                            ? Colors.black
                            : (faintTextColor ?? Colors.grey[600]!.withOpacity(0.7)),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (chapter != null && showPageCount)
                  Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Text(
                      '共${chapter.pageCount}页',
                      style: Theme.of(context).textTheme.overline?.copyWith(
                            color: showFaintColor && faintedChapters.contains(chapter.cid) //
                                ? (faintTextColor ?? Colors.grey[600]!.withOpacity(0.7))
                                : Colors.grey[800],
                          ),
                    ),
                  ),
              ],
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              backgroundColor: showHighlight && highlightedChapters.contains(chapter?.cid)
                  ? (highlightColor ?? Colors.deepOrange.withOpacity(0.3)) //
                  : showHighlight2 && highlighted2Chapters.contains(chapter?.cid)
                      ? (highlight2Color ?? Colors.deepOrange.withOpacity(0.08)) //
                      : null,
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

    final width = (MediaQuery.of(context).size.width - 2 * padding.left - (columns - 1) * hSpace) / columns; // |   ▢ ▢ ▢ ▢   |
    const height = 36.0; // button's default height

    List<TinyMangaChapter?> shown = chapters.toList();
    if (!invertOrder) {
      shown.sort((i, j) => i!.number.compareTo(j!.number)); // sort through comparing with number
    } else {
      shown.sort((i, j) => j!.number.compareTo(i!.number));
    }

    if (maxLines > 0) {
      var count = maxLines * columns;
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
              height: height +
                  (!showPageCount //
                      ? 0
                      : TextSpan(text: '　', style: Theme.of(context).textTheme.overline).layoutSize(context).height + 1),
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
