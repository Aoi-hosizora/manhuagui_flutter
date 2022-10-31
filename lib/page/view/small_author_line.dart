import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/page/author.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

/// 作者行，[SmallAuthor]，在 [AuthorSubPage] 使用
class SmallAuthorLineView extends StatelessWidget {
  const SmallAuthorLineView({
    Key? key,
    required this.author,
  }) : super(key: key);

  final SmallAuthor author;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: author.cover,
      title: author.name,
      icon1: Icons.place,
      text1: author.zone,
      icon2: Icons.edit,
      text2: '共 ${author.mangaCount} 部漫画',
      icon3: Icons.access_time,
      text3: '更新于 ${author.newestDate}',
      onPressed: () => Navigator.of(context).push(
        CustomMaterialPageRoute(
          builder: (c) => AuthorPage(
            id: author.aid,
            name: author.name,
            url: author.url,
          ),
        ),
      ),
    );
  }
}
