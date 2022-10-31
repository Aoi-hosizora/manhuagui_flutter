import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/manga_group.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

enum MangaGroupViewStyle {
  normalFull,
  normalTruncate,
  smallTruncate,
  smallOneLine,
}

/// 单个漫画分组，在 [RecommendSubPage] / [MangaGroupPage] 使用
class MangaGroupView extends StatelessWidget {
  const MangaGroupView({
    Key? key,
    required this.group,
    required this.type,
    this.controller,
    required this.style,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  final MangaGroup group;
  final MangaGroupType type;
  final ScrollController? controller;
  final MangaGroupViewStyle style;
  final EdgeInsets margin;
  final EdgeInsets padding;

  Widget _buildItem({required BuildContext context, required TinyBlockManga? manga, required double width, required double height, void Function()? onMorePressed}) {
    if (manga == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0, 0.5, 1],
            colors: [
              Colors.blue[100]!,
              Colors.orange[200]!,
              Colors.purple[100]!,
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            child: Center(
              child: Text('查看更多...'),
            ),
            onTap: onMorePressed,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              width: width,
              height: height,
              child: NetworkImageView(
                url: manga.cover,
                width: width,
                height: height,
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                width: width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 1],
                    colors: [
                      Colors.grey[800]!.withOpacity(0),
                      Colors.grey[800]!.withOpacity(0.9),
                    ],
                  ),
                ),
                child: Text(
                  manga.finished ? '${manga.newestChapter} 全' : '更新至 ${manga.newestChapter}',
                  style: TextStyle(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    CustomMaterialPageRoute(
                      builder: (c) => MangaPage(
                        id: manga.mid,
                        title: manga.title,
                        url: manga.url,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Container(
          width: width,
          padding: EdgeInsets.only(top: 1.5),
          child: Text(
            manga.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupItems({required BuildContext context}) {
    const hSpace = 10.0;
    const vSpace = 8.0;

    List<TinyBlockManga?> mangas = group.mangas;
    switch (style) {
      case MangaGroupViewStyle.normalFull:
        break;
      case MangaGroupViewStyle.normalTruncate:
        if (mangas.length > 6) {
          mangas = [...mangas.sublist(0, 5), null]; // X X X | X X O
        }
        break;
      case MangaGroupViewStyle.smallTruncate:
        if (mangas.length > 8) {
          mangas = [...mangas.sublist(0, 7), null]; // X X X X | X X X O
        }
        break;
      case MangaGroupViewStyle.smallOneLine:
        if (mangas.length > 4) {
          mangas = [...mangas.sublist(0, 3), null]; // X X X O
        }
        break;
    }

    final largerWidth = (MediaQuery.of(context).size.width - hSpace * 4) / 3; // | ▢ ▢ ▢ |
    final smallerWidth = (MediaQuery.of(context).size.width - hSpace * 5) / 4; // | ▢ ▢ ▢ ▢ |
    var widgets = <Widget>[];
    for (var manga in mangas) {
      var width = style == MangaGroupViewStyle.smallTruncate || style == MangaGroupViewStyle.smallOneLine ? smallerWidth : largerWidth;
      widgets.add(
        _buildItem(
          context: context,
          manga: manga,
          width: width,
          height: width / 3 * 4,
          onMorePressed: () => Navigator.of(context).push(
            CustomMaterialPageRoute(
              builder: (c) => MangaGroupPage(
                group: group,
                type: type,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hSpace),
      child: Wrap(
        spacing: hSpace,
        runSpacing: vSpace,
        children: widgets,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var title = group.title.isEmpty ? type.toTitle() : (type.toTitle() + '・' + group.title);
    var icon = type == MangaGroupType.serial
        ? Icons.whatshot
        : type == MangaGroupType.finish
            ? Icons.check_circle_outline
            : Icons.fiber_new;

    return Container(
      color: Colors.white,
      margin: margin,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: IconText(
              icon: Icon(icon, size: 20, color: Colors.orange),
              text: Text(title, style: Theme.of(context).textTheme.subtitle1),
              space: 6,
            ),
          ),
          _buildGroupItems(context: context),
        ],
      ),
    );
  }
}
