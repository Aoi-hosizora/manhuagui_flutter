import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/page/view/chapter_grid.dart';
import 'package:manhuagui_flutter/page/view/manga_toc_badge.dart';

/// 漫画章节列表（给定章节分组列表，包括正逆序等按钮），在 [MangaPage] / [MangaTocPage] / [ViewTocSubPage] / [DownloadChoosePage] 使用
class MangaTocView extends StatefulWidget {
  const MangaTocView({
    Key? key,
    required this.groups,
    required this.full,
    this.tocTitle,
    this.firstGroupRowsIfNotFull = 3,
    this.otherGroupsRowsIfNotFull = 1,
    this.columns = 4,
    this.gridPadding,
    this.highlightColor,
    this.highlightedChapters = const [],
    this.highlight2Color,
    this.highlighted2Chapters = const [],
    this.faintTextColor,
    this.faintedChapters = const [],
    this.showHighlight = true,
    this.showHighlight2 = true,
    this.showFaintColor = true,
    this.showTriText = false,
    this.getTriText,
    this.showNewBadge = true,
    this.customBadgeBuilder,
    this.itemBuilder,
    required this.onChapterPressed,
    this.onMoreChaptersPressed,
    this.onChapterLongPressed,
    this.onMoreChaptersLongPressed,
  }) : super(key: key);

  final List<MangaChapterGroup> groups;
  final bool full;
  final String? tocTitle;
  final int firstGroupRowsIfNotFull;
  final int otherGroupsRowsIfNotFull;
  final int columns;
  final EdgeInsets? gridPadding;
  final Color? highlightColor;
  final List<int> highlightedChapters;
  final Color? highlight2Color;
  final List<int> highlighted2Chapters;
  final Color? faintTextColor;
  final List<int> faintedChapters;
  final bool showHighlight;
  final bool showHighlight2;
  final bool showFaintColor;
  final bool showTriText;
  final String Function(TinyMangaChapter)? getTriText;
  final bool showNewBadge;
  final Widget? Function(int cid)? customBadgeBuilder;
  final Widget Function(BuildContext context, int? cid, Widget itemWidget)? itemBuilder;
  final void Function(int cid) onChapterPressed;
  final void Function()? onMoreChaptersPressed;
  final void Function(int cid)? onChapterLongPressed;
  final void Function()? onMoreChaptersLongPressed;

  @override
  _MangaTocViewState createState() => _MangaTocViewState();
}

class _MangaTocViewState extends State<MangaTocView> {
  var _invertOrder = true;

  Widget _buildHeader() {
    Widget button({required IconData icon, required String text, required bool selected, required EdgeInsets padding, required void Function() onPressed}) {
      Color color = selected ? Theme.of(context).primaryColor : Colors.black;
      return InkWell(
        onTap: onPressed,
        child: Padding(
          padding: padding,
          child: IconText(
            icon: Icon(icon, size: 18, color: color),
            text: Text(text, style: Theme.of(context).textTheme.bodyText1?.copyWith(color: color)),
            space: 0,
          ),
        ),
      );
    }

    // padding: EdgeInsets.fromLTRB(12, 6, 6, 6)
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.tocTitle ?? '章节列表',
          style: Theme.of(context).textTheme.subtitle1,
        ),
        Material(
          color: Colors.transparent,
          child: Row(
            children: [
              if (widget.onMoreChaptersPressed != null) ...[
                InkWell(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      '查看全部',
                      style: Theme.of(context).textTheme.bodyText1?.copyWith(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  onTap: widget.onMoreChaptersPressed!,
                  onLongPress: widget.onMoreChaptersLongPressed,
                ),
                Container(
                  margin: EdgeInsets.only(left: 5, right: 5),
                  color: Theme.of(context).dividerColor,
                  width: 1,
                  height: TextSpan(text: '　', style: Theme.of(context).textTheme.subtitle1).layoutSize(context).height,
                ),
              ],
              button(
                icon: Icons.keyboard_arrow_up,
                text: '正序',
                selected: !_invertOrder,
                padding: EdgeInsets.fromLTRB(5, 4, 8, 4),
                onPressed: () => mountedSetState(() => _invertOrder = false),
              ),
              button(
                icon: Icons.keyboard_arrow_down,
                text: '逆序',
                selected: _invertOrder,
                padding: EdgeInsets.fromLTRB(5, 4, 8, 4),
                onPressed: () => mountedSetState(() => _invertOrder = true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGrid({required int idx, required List<TinyMangaChapter> chapters}) {
    return ChapterGridView(
      chapters: chapters,
      padding: widget.gridPadding ?? EdgeInsets.symmetric(horizontal: 12),
      showPageCount: true,
      invertOrder: _invertOrder,
      maxLines: widget.full
          ? -1 // show all chapters
          : idx == 0
              ? widget.firstGroupRowsIfNotFull // first line => show the first three lines in default
              : widget.otherGroupsRowsIfNotFull /* following lines => show the first line in default */,
      columns: widget.columns,
      highlightColor: widget.highlightColor,
      highlightedChapters: widget.highlightedChapters,
      highlight2Color: widget.highlight2Color,
      highlighted2Chapters: widget.highlighted2Chapters,
      faintTextColor: widget.faintTextColor,
      faintedChapters: widget.faintedChapters,
      showHighlight: widget.showHighlight,
      showHighlight2: widget.showHighlight2,
      showFaintColor: widget.showFaintColor,
      showTriText: widget.showTriText,
      getTriText: widget.getTriText,
      extrasInStack: (chapter) {
        if (chapter == null) {
          return [];
        }
        var newBadge = widget.showNewBadge && chapter.isNew ? NewBadge() : null;
        var customBadge = widget.customBadgeBuilder?.call(chapter.cid);
        return [
          if (newBadge != null) newBadge,
          if (customBadge != null) customBadge,
        ];
      },
      itemBuilder: widget.itemBuilder == null
          ? null //
          : (ctx, chapter, itemWidget) => widget.itemBuilder!.call(ctx, chapter?.cid, itemWidget),
      onChapterPressed: (chapter) {
        if (chapter == null) {
          widget.onMoreChaptersPressed?.call();
        } else {
          widget.onChapterPressed.call(chapter.cid);
        }
      },
      onChapterLongPressed: widget.onChapterLongPressed == null
          ? null
          : (chapter) {
              if (chapter == null) {
                widget.onMoreChaptersLongPressed?.call();
              } else {
                widget.onChapterLongPressed!.call(chapter.cid);
              }
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    var isEmpty = widget.groups.isEmpty || widget.groups.allChapters.isEmpty;
    var groups = widget.groups.makeSureRegularGroupIsFirst(); // 保证【单话】为首个章节分组
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(12, 6, 6, 6),
          child: _buildHeader(),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          color: Colors.white,
          child: Divider(height: 0, thickness: 1),
        ),
        if (isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text('暂无章节', style: Theme.of(context).textTheme.subtitle1),
            ),
          ),
        if (!isEmpty) SizedBox(height: 10),
        if (!isEmpty)
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
