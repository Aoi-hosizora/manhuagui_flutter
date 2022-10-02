import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/page/author.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

/// 作者行，[SmallAuthor]，在 [AuthorSubPage] 使用
class SmallAuthorLineView extends StatefulWidget {
  const SmallAuthorLineView({
    Key? key,
    required this.author,
  }) : super(key: key);

  final SmallAuthor author;

  @override
  _SmallAuthorLineViewState createState() => _SmallAuthorLineViewState();
}

class _SmallAuthorLineViewState extends State<SmallAuthorLineView> {
  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: widget.author.cover,
      title: widget.author.name,
      icon1: Icons.place,
      text1: widget.author.zone,
      icon2: Icons.edit,
      text2: '共 ${widget.author.mangaCount} 部漫画',
      icon3: Icons.access_time,
      text3: '更新于 ${widget.author.newestDate}',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (c) => AuthorPage(
            id: widget.author.aid,
            name: widget.author.name,
            url: widget.author.url,
          ),
        ),
      ),
    );
  }
}
