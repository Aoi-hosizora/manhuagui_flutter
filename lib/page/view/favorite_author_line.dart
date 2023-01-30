import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/author.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 收藏作者行，在 [FavoriteAuthorPage] 使用
class FavoriteAuthorLineView extends StatelessWidget {
  const FavoriteAuthorLineView({
    Key? key,
    required this.author,
    this.flags,
    required this.onLongPressed,
  }) : super(key: key);

  final FavoriteAuthor author;
  final AuthorCornerFlags? flags;
  final void Function()? onLongPressed;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: author.authorCover,
      title: author.authorName,
      icon1: MdiIcons.commentBookmark,
      text1: '备注 ${author.remark.trim().isEmpty ? '暂无' : author.remark.trim()}',
      icon2: Icons.place,
      text2: author.authorZone,
      icon3: Icons.access_time,
      text3: '添加于 ${author.formattedCreatedAt}',
      cornerIcons: flags?.buildIcons(),
      onPressed: () => Navigator.of(context).push(
        CustomPageRoute(
          context: context,
          builder: (c) => AuthorPage(
            id: author.authorId,
            name: author.authorName,
            url: author.authorUrl,
          ),
        ),
      ),
      onLongPressed: onLongPressed,
    );
  }
}
