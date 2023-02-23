import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/page/view/detail_table.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            DetailTableView(
              rows: [
                DetailRow('aid', widget.data.aid.toString()),
                DetailRow('作者名', widget.data.name),
                DetailRow('作者别名', widget.data.alias.trim().isNotEmpty ? widget.data.alias.trim() : '暂无'),
                DetailRow('所属地区', widget.data.zone),
                DetailRow('网页链接', widget.data.url),
                DetailRow('人气指数', widget.data.popularity.toString()),
                DetailRow('收录漫画数', widget.data.mangaCount.toString()),
                DetailRow('收录更新时间', widget.data.formattedNewestDate),
                DetailRow('最新收录漫画', '《${widget.data.newestMangaTitle}》mid: ${widget.data.newestMangaId}'),
                DetailRow('评分最高漫画', '《${widget.data.highestMangaTitle}》mid: ${widget.data.highestMangaId}'),
                DetailRow('最高评分', widget.data.highestScore.toString()),
                DetailRow('平均评分', widget.data.averageScore.toString()),
                DetailRow('作者介绍', widget.data.introduction.trim().isNotEmpty ? widget.data.introduction.trim() : '暂无'),
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
