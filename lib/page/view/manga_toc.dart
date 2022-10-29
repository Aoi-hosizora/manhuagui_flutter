import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/page/manga_toc.dart';
import 'package:manhuagui_flutter/page/view/chapter_grid.dart';

/// 漫画章节目录，在 [MangaPage] / [MangaTocPage] / [ViewTocSubPage] / [DownloadSelectPage] 使用
class MangaTocView extends StatefulWidget {
  const MangaTocView({
    Key? key,
    required this.mangaId,
    required this.mangaTitle,
    required this.groups,
    required this.full,
    this.highlightColor,
    this.highlightedChapters = const [],
    this.showNewBadge = true,
    this.customBadgeBuilder,
    required this.onPressed,
  }) : super(key: key);

  final int mangaId;
  final String mangaTitle;
  final List<MangaChapterGroup> groups;
  final bool full;
  final Color? highlightColor;
  final List<int> highlightedChapters;
  final bool showNewBadge;
  final Widget? Function(int cid)? customBadgeBuilder;
  final void Function(int cid) onPressed;

  @override
  _MangaTocViewState createState() => _MangaTocViewState();
}

class _MangaTocViewState extends State<MangaTocView> {
  var _invertedOrder = true;

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
                  selected: !_invertedOrder,
                  padding: EdgeInsets.only(top: 3, bottom: 3, left: 5, right: 10),
                  onPressed: () => mountedSetState(() => _invertedOrder = false),
                ),
                button(
                  icon: Icons.keyboard_arrow_down,
                  text: '倒序',
                  selected: _invertedOrder,
                  padding: EdgeInsets.only(top: 3, bottom: 3, left: 5, right: 10),
                  onPressed: () => mountedSetState(() => _invertedOrder = true),
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
      padding: EdgeInsets.symmetric(horizontal: 12),
      invertOrder: _invertedOrder,
      maxLines: widget.full
          ? -1 // show all chapters
          : idx == 0
              ? 3 // first line => show the first three lines
              : 1 /* following lines => show the first line */,
      highlightColor: widget.highlightColor,
      highlightedChapters: widget.highlightedChapters,
      onPressed: (chapter) {
        if (chapter == null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (c) => MangaTocPage(
                mangaId: widget.mangaId,
                mangaTitle: widget.mangaTitle,
                groups: widget.groups,
                onChapterPressed: widget.onPressed,
              ),
            ),
          );
        } else {
          widget.onPressed.call(chapter.cid);
        }
      },
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) {
      return SizedBox(height: 0);
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
        for (var i = 0; i < groups.length; i++) ...[
          SizedBox(height: 10),
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
        ],
        SizedBox(height: 10),
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

class DownloadBadge extends StatelessWidget {
  const DownloadBadge({
    Key? key,
    required this.downloading,
  }) : super(key: key);

  final bool downloading;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 1,
      right: 1,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.25, horizontal: 1.25),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: downloading ? Colors.blue : Colors.green,
        ),
        child: Icon(
          downloading ? Icons.download : Icons.file_download_done,
          size: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}
