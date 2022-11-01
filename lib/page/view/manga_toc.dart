import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/page/manga_toc.dart';
import 'package:manhuagui_flutter/page/view/chapter_grid.dart';

/// 漫画章节目录（给定章节分组列表），在 [MangaPage] / [MangaTocPage] / [ViewTocSubPage] / [DownloadSelectPage] 使用
class MangaTocView extends StatefulWidget {
  const MangaTocView({
    Key? key,
    required this.mangaId,
    required this.mangaTitle,
    required this.groups,
    required this.full,
    this.gridPadding,
    this.highlightColor,
    this.highlightedChapters = const [],
    this.showNewBadge = true,
    this.customBadgeBuilder,
    required this.onChapterPressed,
    this.onChapterLongPressed,
  }) : super(key: key);

  final int mangaId;
  final String mangaTitle;
  final List<MangaChapterGroup> groups;
  final bool full;
  final EdgeInsets? gridPadding;
  final Color? highlightColor;
  final List<int> highlightedChapters;
  final bool showNewBadge;
  final Widget? Function(int cid)? customBadgeBuilder;
  final void Function(int cid) onChapterPressed;
  final void Function(int cid)? onChapterLongPressed;

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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '章节列表',
          style: Theme.of(context).textTheme.subtitle1,
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 3),
          child: Material(
            color: Colors.transparent,
            child: Row(
              children: [
                button(
                  icon: Icons.keyboard_arrow_up,
                  text: '正序',
                  selected: !_invertOrder,
                  padding: EdgeInsets.only(top: 3, bottom: 3, left: 5, right: 10),
                  onPressed: () => mountedSetState(() => _invertOrder = false),
                ),
                button(
                  icon: Icons.keyboard_arrow_down,
                  text: '倒序',
                  selected: _invertOrder,
                  padding: EdgeInsets.only(top: 3, bottom: 3, left: 5, right: 10),
                  onPressed: () => mountedSetState(() => _invertOrder = true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid({required int idx, required List<TinyMangaChapter> chapters}) {
    return ChapterGridView(
      chapters: chapters,
      padding: widget.gridPadding ?? EdgeInsets.symmetric(horizontal: 12),
      invertOrder: _invertOrder,
      maxLines: widget.full
          ? -1 // show all chapters
          : idx == 0
              ? 3 // first line => show the first three lines
              : 1 /* following lines => show the first line */,
      highlightColor: widget.highlightColor,
      highlightedChapters: widget.highlightedChapters,
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
      onChapterPressed: (chapter) {
        if (chapter == null) {
          Navigator.of(context).push(
            CustomMaterialPageRoute(
              context: context,
              builder: (c) => MangaTocPage(
                mangaId: widget.mangaId,
                mangaTitle: widget.mangaTitle,
                groups: widget.groups,
                onChapterPressed: widget.onChapterPressed,
              ),
            ),
          );
        } else {
          widget.onChapterPressed.call(chapter.cid);
        }
      },
      onChapterLongPressed: widget.onChapterLongPressed == null
          ? null
          : (chapter) {
              if (chapter != null) {
                widget.onChapterLongPressed!.call(chapter.cid);
              }
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) {
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

    var groups = widget.groups.makeSureRegularGroupIsFirst(); // 保证【单话】为首个章节分组
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.only(left: 12, right: 4, top: 2, bottom: 2),
          child: _buildHeader(),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          color: Colors.white,
          child: Divider(height: 0, thickness: 1),
        ),
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

class NewBadge extends StatelessWidget {
  const NewBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1, horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.all(Radius.circular(2.0)),
        ),
        child: Text(
          'NEW',
          style: TextStyle(
            fontSize: 9,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

enum DownloadBadgeState {
  downloading,
  succeeded,
  failed,
}

class DownloadBadge extends StatelessWidget {
  const DownloadBadge({
    Key? key,
    required this.state,
  }) : super(key: key);

  final DownloadBadgeState state;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 1,
      right: 1,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.25, horizontal: 1.25),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: state == DownloadBadgeState.downloading
              ? Colors.blue
              : state == DownloadBadgeState.succeeded
                  ? Colors.green
                  : Colors.red,
        ),
        child: Icon(
          state == DownloadBadgeState.downloading
              ? Icons.download
              : state == DownloadBadgeState.succeeded
                  ? Icons.file_download_done
                  : Icons.priority_high,
          size: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}
