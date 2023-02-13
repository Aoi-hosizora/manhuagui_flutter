import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';

/// 漫画章节详情页，展示所给 [TinyMangaChapter] 信息
class ChapterDetailsPage extends StatefulWidget {
  const ChapterDetailsPage({
    Key? key,
    required this.data,
    required this.group,
    required this.groupLength,
    required this.mangaTitle,
    required this.mangaUrl,
    this.tocLoaded = true,
  }) : super(key: key);

  final TinyMangaChapter data;
  final String? group;
  final int? groupLength;
  final String mangaTitle;
  final String mangaUrl;
  final bool tocLoaded;

  @override
  _ChapterDetailsPageState createState() => _ChapterDetailsPageState();
}

class _ChapterDetailsPageState extends State<ChapterDetailsPage> {
  final _controller = ScrollController();
  late final _details = [
    Tuple2('cid', widget.data.cid.toString()),
    Tuple2('章节标题', '《${widget.data.title}》'),
    Tuple2('章节网页链接', widget.data.url),
    Tuple2('mid', widget.data.mid.toString()),
    Tuple2('漫画标题', '《${widget.mangaTitle}》'),
    Tuple2('漫画网页链接', widget.mangaUrl),
    Tuple2('章节页数', widget.data.pageCount.toString()),
    if (widget.tocLoaded) ...[
      Tuple2('最近上传', widget.data.isNew ? '是' : '否'),
      Tuple2('章节所属分组', widget.group ?? '未知'),
      Tuple2('分组内顺序', '正序 ${widget.data.number} (总数 ${widget.groupLength ?? '未知'})'),
    ],
    if (!widget.tocLoaded) ...[
      Tuple2('最近上传', '未知'),
      Tuple2('章节所属分组', '未知'),
      Tuple2('分组内顺序', '未知'),
    ],
  ];
  late final _helper = TableCellHelper(_details.length, 2);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var tableWidth = MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal - 40;

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
            StatefulWidgetWithCallback(
              postFrameCallbackForBuild: _helper.hasSearched()
                  ? null
                  : (_, __) {
                      if (_helper.searchForHighestCells()) {
                        if (mounted) setState(() {});
                      }
                    },
              child: Table(
                columnWidths: const {
                  0: FractionColumnWidth(0.3),
                },
                border: TableBorder(
                  horizontalInside: BorderSide(width: 1, color: Colors.grey),
                ),
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Text('键', style: Theme.of(context).textTheme.bodyText2?.copyWith(color: Colors.grey)),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Text('值', style: Theme.of(context).textTheme.bodyText2?.copyWith(color: Colors.grey)),
                      ),
                    ],
                  ),
                  for (var i = 0; i < _details.length; i++)
                    TableRow(
                      children: [
                        TableCell(
                          key: _helper.getCellKey(i, 0),
                          verticalAlignment: _helper.determineCellAlignment(i, 0, TableCellVerticalAlignment.top),
                          child: TableWholeRowInkWell.preferred(
                            child: Text('${_details[i].item1}　', style: Theme.of(context).textTheme.bodyText2),
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            onTap: () => copyText(_details[i].item2, showToast: true),
                            tableWidth: tableWidth,
                            accumulativeWidthRatio: 0,
                          ),
                        ),
                        TableCell(
                          key: _helper.getCellKey(i, 1),
                          verticalAlignment: _helper.determineCellAlignment(i, 1, TableCellVerticalAlignment.top),
                          child: TableWholeRowInkWell.preferred(
                            child: Text('${_details[i].item2}　', style: Theme.of(context).textTheme.bodyText2),
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            onTap: () => copyText(_details[i].item2, showToast: true),
                            tableWidth: tableWidth,
                            accumulativeWidthRatio: 0.3,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
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
