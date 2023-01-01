import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/page/view/manga_corner_icons.dart';

/// 收藏漫画行，在 [FavoriteSubPage] 使用
class FavoriteMangaLineView extends StatelessWidget {
  const FavoriteMangaLineView({
    Key? key,
    required this.manga,
    required this.index,
    required this.history,
    required this.onLongPressed,
    this.inDownload = false,
    this.inShelf = false,
    this.inHistory = false,
  }) : super(key: key);

  final FavoriteManga manga;
  final int index;
  final MangaHistory? history;
  final Function()? onLongPressed;
  final bool inDownload;
  final bool inShelf;
  final bool inHistory;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: manga.mangaCover,
      title: manga.mangaTitle,
      icon1: Icons.label_outline,
      text1: '${manga.checkedGroupName}${manga.remark.trim().isEmpty ? '' : '・备注 ${manga.remark.trim()}'}',
      icon2: history == null || !history!.read ? Icons.web_asset : Icons.import_contacts,
      text2: history == null ? '尚未浏览' : (!history!.read ? '未开始阅读' : '最近阅读至 ${history!.chapterTitle} 第${history!.chapterPage}页'),
      icon3: Icons.access_time,
      text3: '添加于 ${manga.formattedCreatedAt}',
      cornerIcons: buildMangaCornerIcons(inDownload: inDownload, inShelf: inShelf, inFavorite: true, inHistory: inHistory),
      extraRightPaddingForTitle: 28 - 14 + 5 /* badge width - line horizontal padding + extra space */,
      extrasInStack: [
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28)),
            ),
            alignment: Alignment.topRight,
            child: SizedBox(
              width: 28 * 0.8,
              height: 28 * 0.85,
              child: Center(
                child: Text(
                  index.toString(),
                  // manga.order.toString(),
                  style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: index < 100 ? null : 12.5, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
      onPressed: () => Navigator.of(context).push(
        CustomPageRoute(
          context: context,
          builder: (c) => MangaPage(
            id: manga.mangaId,
            title: manga.mangaTitle,
            url: manga.mangaUrl,
          ),
        ),
      ),
      onLongPressed: onLongPressed,
    );
  }
}
