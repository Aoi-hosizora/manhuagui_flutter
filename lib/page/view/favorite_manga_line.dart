import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

/// 收藏漫画行，在 [FavoriteSubPage] 使用
class FavoriteMangaLineView extends StatelessWidget {
  const FavoriteMangaLineView({
    Key? key,
    required this.manga,
    required this.index,
    required this.history,
    this.flags,
    required this.onLongPressed,
  }) : super(key: key);

  final FavoriteManga manga;
  final int? index;
  final MangaHistory? history;
  final MangaCornerFlags? flags;
  final void Function()? onLongPressed;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView(
      imageUrl: manga.mangaCover,
      title: manga.mangaTitle,
      icon1: Icons.folder_open,
      text1: '${manga.checkedGroupName}${manga.remark.trim().isEmpty ? '' : '・备注 ${manga.remark.trim()}'}',
      icon2: history == null || !history!.read ? CustomIcons.opened_left_star_book : Icons.import_contacts,
      text2: (history == null || !history!.read ? '未开始阅读' : '最近阅读至 ${history!.chapterTitle}') + ' (${history?.formattedLastTimeOrDuration ?? '未知时间'})',
      icon3: Icons.access_time,
      text3: '收藏于 ${manga.formattedCreatedAtWithDuration}',
      cornerIcons: flags?.buildIcons(),
      extraRightPaddingForTitle: index != null
          ? 28 - 14 + 5 // badge width - line horizontal padding + extra space
          : null /* no extra padding */,
      extrasInStack: [
        if (index != null)
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
                    index!.toString(),
                    // manga.order.toString(),
                    style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: index! < 100 ? null : 12.5, color: Colors.white),
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
