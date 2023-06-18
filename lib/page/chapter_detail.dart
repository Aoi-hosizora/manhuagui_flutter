import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/page/view/detail_table.dart';

/// 漫画章节详情页，展示所给 [TinyMangaChapter] 信息
class ChapterDetailPage extends StatefulWidget {
  const ChapterDetailPage({
    Key? key,
    required this.data,
    required this.chapterCover,
    required this.groupLength,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.mangaAuthors,
    required this.isTocLoaded,
  }) : super(key: key);

  final TinyMangaChapter data;
  final String? chapterCover;
  final int? groupLength;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final List<String> mangaAuthors;
  final bool isTocLoaded;

  @override
  _ChapterDetailPageState createState() => _ChapterDetailPageState();
}

class _ChapterDetailPageState extends State<ChapterDetailPage> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('漫画章节详情'),
        leading: AppBarActionButton.leading(context: context),
      ),
      body: ExtendedScrollbar(
        controller: _controller,
        interactive: true,
        mainAxisMargin: 2,
        crossAxisMargin: 2,
        child: ListView(
          controller: _controller,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          physics: AlwaysScrollableScrollPhysics(),
          children: [
            DetailTableView(
              rows: [
                DetailRow('cid', widget.data.cid.toString()),
                DetailRow('章节标题', '《${widget.data.title}》', textForCopy: widget.data.title),
                DetailRow('章节封面', widget.chapterCover == null ? '未知' : widget.chapterCover!, canCopy: widget.chapterCover != null),
                DetailRow('章节网页链接', widget.data.url),
                DetailRow('章节页数', widget.data.pageCount.toString()),
                DetailRow('(mid)', widget.data.mid.toString()),
                DetailRow('(漫画标题)', '《${widget.mangaTitle}》', textForCopy: widget.mangaTitle),
                DetailRow('(漫画封面)', widget.mangaCover),
                DetailRow('(漫画网页链接)', widget.mangaUrl),
                DetailRow('(漫画作者)', widget.mangaAuthors.join('/')),
                if (widget.isTocLoaded) ...[
                  DetailRow('最近上传', widget.data.isNew ? '是' : '否', canCopy: false),
                  DetailRow('章节所属分组', widget.data.group.isEmpty ? '未知' : widget.data.group, canCopy: widget.data.group.isNotEmpty),
                  DetailRow('分组内顺序', '正序 ${widget.data.number <= 0 ? '未知' : widget.data.number} (总数 ${widget.groupLength ?? '未知'})'),
                ],
                if (!widget.isTocLoaded) ...[
                  DetailRow('最近上传', '未知', canCopy: false),
                  DetailRow('章节所属分组', '未知', canCopy: false),
                  DetailRow('分组内顺序', '未知', canCopy: false),
                ],
              ],
              tableWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal - 40,
            ),
          ],
        ),
      ),
      floatingActionButton: ScrollAnimatedFab(
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
