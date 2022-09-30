import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/service/natives/clipboard.dart';

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
  var _details = <Tuple2<String, String>>[];

  @override
  void initState() {
    super.initState();
    _details = [
      Tuple2('mid', widget.data.mid.toString()),
      Tuple2('标题', widget.data.title),
      Tuple2('标题别名', widget.data.aliasTitle ?? '暂无'), // TODO nullable ???
      Tuple2('别名', widget.data.alias),
      Tuple2('封面链接', widget.data.cover),
      Tuple2('网页链接', widget.data.url),
      Tuple2('状态', widget.data.finished ? '已完结' : '连载中'),
      Tuple2('出版年份', widget.data.publishYear),
      Tuple2('漫画地区', widget.data.mangaZone),
      Tuple2('漫画类别', widget.data.genres.map((g) => g.title).join(', ')),
      Tuple2('漫画作者', widget.data.authors.map((a) => a.name).join(', ')),
      Tuple2('最新章节', widget.data.newestChapter),
      Tuple2('更新时间', widget.data.newestDate),
      Tuple2('总章节数', widget.data.chapterGroups.expand((g) => g.chapters).length.toString()),
      Tuple2('章节分组数', widget.data.chapterGroups.length.toString()),
      for (var group in widget.data.chapterGroups) Tuple2('《${group.title}》章节数', group.chapters.length.toString()),
      Tuple2('包含色情暴力', widget.data.banned ? '是' : '否'),
      Tuple2('拥有版权', widget.data.copyright ? '是' : '否'),
      Tuple2('漫画排名', widget.data.mangaRank),
      Tuple2('平均得分', widget.data.averageScore.toStringAsFixed(1)),
      Tuple2('评分人数', widget.data.scoreCount.toString()),
      for (var num in [1, 2, 3, 4, 5]) Tuple2('评 $num 星比例', widget.data.perScores[num]),
      Tuple2('简要介绍', widget.data.briefIntroduction),
      Tuple2('详细介绍', widget.data.introduction),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('漫画详情'),
      ),
      body: ScrollbarWithMore(
        interactive: true,
        crossAxisMargin: 2,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            Table(
              columnWidths: const {
                0: FractionColumnWidth(0.3),
              },
              border: TableBorder(
                horizontalInside: BorderSide(
                  width: 1,
                  color: Colors.grey,
                  style: BorderStyle.solid,
                ),
              ),
              children: [
                TableRow(
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text('键', style: TextStyle(color: Colors.grey)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text('值', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
                for (var data in _details)
                  TableRow(
                    children: [
                      TableRowInkWell(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: Text('${data.item1}　'),
                        ),
                        onTap: () => copyText(data.item2),
                      ),
                      TableRowInkWell(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: Text('${data.item2}　'),
                        ),
                        onTap: () => copyText(data.item2),
                      ),
                    ],
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
