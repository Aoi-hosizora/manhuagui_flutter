import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 稍后阅读提示栏，在 [MangaPage] / [DownloadMangaPage] / [ViewExtraSubPage] 使用
class LaterMangaBannerView extends StatelessWidget {
  const LaterMangaBannerView({
    Key? key,
    required this.manga,
    this.action,
  }) : super(key: key);

  final LaterManga manga;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.blueGrey,
      child: InkWell(
        onTap: action,
        onLongPress: action,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              right: 2,
              child: OverflowClipBox(
                useOverflowBox: true,
                useClipRect: true,
                direction: OverflowDirection.all,
                alignment: Alignment.center,
                height: 12 * 2 + 26,
                width: 110,
                child: Icon(Icons.schedule, size: 110, color: Colors.white.withOpacity(0.15)),
              ),
            ),
            IconText(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              space: 16, // this icon text layout is almost the same as the read button in MangaPage
              icon: Icon(MdiIcons.bookClock, size: 26, color: Colors.white),
              text: Flexible(
                child: Text(
                  '位于稍后阅读列表中 (添加于 ${manga.formattedCreatedAt})',
                  style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 16, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
