import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

/// 书架漫画行，在 [ShelfSubPage] 使用
class ShelfMangaLineView extends StatefulWidget {
  const ShelfMangaLineView({
    Key? key,
    required this.manga,
  }) : super(key: key);

  final ShelfManga manga;

  @override
  _ShelfMangaLineViewState createState() => _ShelfMangaLineViewState();
}

class _ShelfMangaLineViewState extends State<ShelfMangaLineView> {
  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: widget.manga.cover,
      title: widget.manga.title,
      icon1: Icons.subject,
      text1: '更新至 ' + widget.manga.newestChapter,
      icon2: Icons.access_time,
      text2: '更新于 ${widget.manga.newestDuration}',
      icon3: Icons.import_contacts,
      text3: '最近阅读至 ${widget.manga.lastChapter.isEmpty ? '未知话' : widget.manga.lastChapter} (${widget.manga.lastDuration})',
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
