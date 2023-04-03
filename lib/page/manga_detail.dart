import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/detail_table.dart';

/// 漫画详情页，展示所给 [Manga] 信息
class MangaDetailPage extends StatefulWidget {
  const MangaDetailPage({
    Key? key,
    required this.data,
  }) : super(key: key);

  final Manga data;

  @override
  _MangaDetailPageState createState() => _MangaDetailPageState();
}

class _MangaDetailPageState extends State<MangaDetailPage> {
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
        title: Text('漫画详情'),
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
                DetailRow('mid', widget.data.mid.toString()),
                DetailRow('标题', '《${widget.data.title}》', textForCopy: widget.data.title),
                DetailRow(
                  '标题别名',
                  widget.data.aliases.isEmpty ? '暂无' : widget.data.aliases.map((a) => '《$a》').join('\n'),
                  textForCopy: widget.data.aliases.join('\n'),
                  canCopy: widget.data.aliases.isNotEmpty,
                ),
                DetailRow('封面链接', widget.data.cover),
                DetailRow('网页链接', widget.data.url),
                DetailRow('状态', widget.data.finished ? '已完结' : '连载中'),
                DetailRow('出版年份', widget.data.publishYear),
                DetailRow('漫画地区', widget.data.mangaZone),
                DetailRow('漫画类别', widget.data.genres.map((g) => g.title).join(', ')),
                DetailRow('漫画作者', widget.data.authors.map((a) => a.name).join(', ')),
                DetailRow('最新章节', widget.data.newestChapter),
                DetailRow('更新时间', widget.data.formattedNewestDate),
                DetailRow('总章节数', widget.data.chapterGroups.expand((g) => g.chapters).length.toString()),
                DetailRow('章节分组数', widget.data.chapterGroups.length.toString()),
                for (var group in widget.data.chapterGroups) //
                  DetailRow('【${group.title}】章节数', group.chapters.length.toString()),
                DetailRow('包含色情暴力', widget.data.banned ? '是' : '否', canCopy: false),
                DetailRow('拥有版权', widget.data.copyright ? '是' : '否', canCopy: false),
                DetailRow('漫画排名', widget.data.mangaRank),
                DetailRow('平均得分', widget.data.averageScore.toStringAsFixed(1)),
                DetailRow('评分人数', widget.data.scoreCount.toString()),
                for (var num in [5, 4, 3, 2, 1]) //
                  DetailRow('评 $num 星比例', widget.data.perScores[num]),
                DetailRow('简要介绍', widget.data.briefIntroduction),
                DetailRow('详细介绍', widget.data.introduction),
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
