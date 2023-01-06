import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

/// 缓存书架漫画行，在 [ShelfCacheSubPage] 使用
class ShelfCacheLineView extends StatelessWidget {
  const ShelfCacheLineView({
    Key? key,
    required this.manga,
    required this.onPressed,
    this.onLongPressed,
  }) : super(key: key);

  final ShelfCache manga;
  final VoidCallback onPressed;
  final VoidCallback? onLongPressed;

  @override
  Widget build(BuildContext context) {
    return FullRippleWidget(
      child: ListTile(
        title: Text(manga.mangaTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('同步于 ${manga.formattedCachedAt}', maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NetworkImageView(
              url: manga.mangaCover,
              height: 48,
              width: 48,
              radius: BorderRadius.circular(12),
            ),
          ],
        ),
      ),
      highlightColor: null,
      splashColor: null,
      onTap: onPressed,
      onLongPress: onLongPressed,
    );
  }
}
