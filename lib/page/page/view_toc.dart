import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';

/// 漫画章节阅读页-章节目录
class ViewTocSubPage extends StatefulWidget {
  const ViewTocSubPage({
    Key? key,
    required this.mid,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.groups,
    required this.highlightedChapter,
    required this.predicate,
  }) : super(key: key);

  final int mid;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final List<MangaChapterGroup> groups;
  final int highlightedChapter;
  final bool Function(int cid) predicate;

  @override
  State<ViewTocSubPage> createState() => _ViewTocSubPageState();
}

class _ViewTocSubPageState extends State<ViewTocSubPage> {
  final _controller = ScrollController();
  var _loading = true; // fake loading flag

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 300), () {
        _loading = false;
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mangaTitle),
      ),
      body: PlaceholderText(
        state: _loading ? PlaceholderState.loading : PlaceholderState.normal,
        setting: PlaceholderSetting().copyWithChinese(),
        childBuilder: (c) => Container(
          color: Colors.white,
          child: ScrollbarWithMore(
            controller: _controller,
            interactive: true,
            crossAxisMargin: 2,
            child: SingleChildScrollView(
              controller: _controller,
              child: MangaTocView(
                groups: widget.groups,
                mangaId: widget.mid,
                mangaTitle: widget.mangaTitle,
                mangaCover: widget.mangaCover,
                mangaUrl: widget.mangaUrl,
                full: true,
                highlightedChapter: widget.highlightedChapter,
                lastChapterPage: 1,
                predicate: widget.predicate,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _loading
          ? null
          : ScrollAnimatedFab(
              scrollController: _controller,
              condition: ScrollAnimatedCondition.direction,
              fab: FloatingActionButton(
                child: Icon(Icons.vertical_align_top),
                heroTag: null,
                onPressed: () => _controller.scrollToTop(),
              ),
            ),
    );
  }
}
