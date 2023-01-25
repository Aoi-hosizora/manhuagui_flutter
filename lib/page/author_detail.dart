import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';

/// 作者详情页，展示所给 [Author] 信息
class AuthorDetailPage extends StatefulWidget {
  const AuthorDetailPage({
    Key? key,
    required this.data,
  }) : super(key: key);

  final Author data;

  @override
  _AuthorDetailPageState createState() => _AuthorDetailPageState();
}

class _AuthorDetailPageState extends State<AuthorDetailPage> {
  final _controller = ScrollController();
  late final _details = [
    Tuple2('aid', widget.data.aid.toString()),
    Tuple2('作者名', widget.data.name),
    Tuple2('作者别名', widget.data.alias.trim().isNotEmpty ? widget.data.alias.trim() : '暂无'),
    Tuple2('所属地区', widget.data.zone),
    Tuple2('网页链接', widget.data.url),
    Tuple2('人气指数', widget.data.popularity.toString()),
    Tuple2('收录漫画数', widget.data.mangaCount.toString()),
    Tuple2('收录更新时间', widget.data.newestDate),
    Tuple2('最新收录漫画', '《${widget.data.newestMangaTitle}》mid: ${widget.data.newestMangaId}'),
    Tuple2('评分最高漫画', '《${widget.data.highestMangaTitle}》mid: ${widget.data.highestMangaId}'),
    Tuple2('最高评分', widget.data.highestScore.toString()),
    Tuple2('平均评分', widget.data.averageScore.toString()),
    Tuple2('作者介绍', widget.data.introduction.trim().isNotEmpty ? widget.data.introduction.trim() : '暂无'),
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
        title: Text('作者详情'),
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
                            onTap: () => copyText(_details[i].item2),
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
                            onTap: () => copyText(_details[i].item2),
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
