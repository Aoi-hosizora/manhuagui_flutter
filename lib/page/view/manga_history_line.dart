import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

/// 漫画浏览历史行，在 [HistorySubPage] 使用
class MangaHistoryLineView extends StatefulWidget {
  const MangaHistoryLineView({
    Key? key,
    required this.history,
    required this.onLongPressed,
  }) : super(key: key);

  final MangaHistory history;
  final Function() onLongPressed;

  @override
  _MangaHistoryLineViewState createState() => _MangaHistoryLineViewState();
}

class _MangaHistoryLineViewState extends State<MangaHistoryLineView> {
  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: widget.history.mangaCover,
      title: widget.history.mangaTitle,
      icon1: widget.history.read ? Icons.subject : null,
      text1: widget.history.read ? '阅读至 ${widget.history.chapterTitle}' : null,
      icon2: widget.history.read ? Icons.import_contacts : Icons.subject,
      text2: widget.history.read ? '第${widget.history.chapterPage}页' : '未开始阅读',
      icon3: Icons.access_time,
      text3: DateFormat('yyyy-MM-dd HH:mm:ss').format(widget.history.lastTime),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (c) => MangaPage(
            id: widget.history.mangaId,
            title: widget.history.mangaTitle,
            url: widget.history.mangaUrl,
          ),
        ),
      ),
      onLongPressed: widget.onLongPressed,
    );
  }
}
