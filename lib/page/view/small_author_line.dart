import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/page/author.dart';
import 'package:manhuagui_flutter/page/dlg/author_dialog.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

/// 作者行，[SmallAuthor]，在 [AuthorSubPage] 使用
class SmallAuthorLineView extends StatelessWidget {
  const SmallAuthorLineView({
    Key? key,
    required this.author,
    this.flags,
    this.twoColumns = false,
  }) : super(key: key);

  final SmallAuthor author;
  final AuthorCornerFlags? flags;
  final bool twoColumns;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: author.cover,
      title: author.name,
      icon1: Icons.place,
      text1: author.zone,
      icon2: Icons.edit,
      text2: '共收录 ${author.mangaCount} 部漫画',
      icon3: Icons.update,
      text3: '更新于 ${author.formattedNewestDateWithDuration}',
      cornerIcons: flags?.buildIcons(),
      twoColumns: twoColumns,
      onPressed: () => Navigator.of(context).push(
        CustomPageRoute(
          context: context,
          builder: (c) => AuthorPage(
            id: author.aid,
            name: author.name,
            url: author.url,
          ),
        ),
      ),
      onLongPressed: () => showPopupMenuForAuthorList(
        context: context,
        authorId: author.aid,
        authorName: author.name,
        authorCover: author.cover,
        authorUrl: author.url,
        authorZone: author.zone,
      ),
    );
  }
}
