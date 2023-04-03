import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
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

  static double getChildAspectRatioForTwoColumns(BuildContext context) {
    // note: customRows (DownloadLineView) will never be used when calling getHeight
    var imageHeight = 48.0 + 10 * 2;
    var titleHeight = TextSpan(text: '　', style: Theme.of(context).textTheme.subtitle1).layoutSize(context).height;
    var lineHeight = TextSpan(text: '　', style: Theme.of(context).textTheme.bodyText2).layoutSize(context).height;
    var textHeight = titleHeight + lineHeight + 10 * 2;

    var height = imageHeight > textHeight ? imageHeight : textHeight;
    var width = MediaQuery.of(context).size.width / 2;
    return width / height;
  }

  @override
  Widget build(BuildContext context) {
    return FullRippleWidget(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            NetworkImageView(
              url: manga.mangaCover,
              height: 48,
              width: 48,
              radius: BorderRadius.circular(10),
            ),
            SizedBox(width: 16),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manga.mangaTitle,
                    style: Theme.of(context).textTheme.subtitle1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '同步于 ${manga.formattedCachedAt}',
                    style: Theme.of(context).textTheme.bodyText2?.copyWith(color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
