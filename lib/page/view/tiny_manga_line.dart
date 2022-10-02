import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

/// 漫画行，[TinyManga]，在 [RecentSubPage] / [OverallSubPage] / [GenreSubPage] / [AuthorPage] / [SearchPage] 使用
class TinyMangaLineView extends StatefulWidget {
  const TinyMangaLineView({
    Key? key,
    required this.manga,
  }) : super(key: key);

  final TinyManga manga;

  @override
  _TinyMangaLineViewState createState() => _TinyMangaLineViewState();
}

class _TinyMangaLineViewState extends State<TinyMangaLineView> {
  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: widget.manga.cover,
      title: widget.manga.title,
      icon1: Icons.edit,
      text1: widget.manga.finished ? '已完结' : '连载中',
      icon2: Icons.subject,
      text2: (widget.manga.finished ? '共 ' : '更新至 ') + widget.manga.newestChapter,
      icon3: Icons.access_time,
      text3: '更新于 ${widget.manga.newestDate}',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (c) => MangaPage(
            id: widget.manga.mid,
            title: widget.manga.title,
            url: widget.manga.url,
          ),
        ),
      ),
    );
  }
}
