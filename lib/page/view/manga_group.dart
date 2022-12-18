import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/manga_group.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

enum MangaGroupViewStyle {
  normalFull,
  normalTruncate,
  smallTruncate,
  smallOneLine,
}

/// 漫画分组，仅针对推荐列表，在 [RecommendSubPage] / [MangaGroupPage] 使用
class MangaGroupView extends StatelessWidget {
  const MangaGroupView({
    Key? key,
    required this.group,
    required this.type,
    required this.style,
    this.onMorePressed,
  }) : super(key: key);

  final MangaGroup group;
  final MangaGroupType type;
  final MangaGroupViewStyle style;
  final void Function()? onMorePressed;

  Widget _buildItem({required BuildContext context, required TinyBlockManga manga, required double width, required double height}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FullRippleWidget(
          child: Stack(
            children: [
              Container(
                width: width,
                height: height,
                child: NetworkImageView(
                  url: manga.cover,
                  width: width,
                  height: height,
                  radius: BorderRadius.circular(5),
                  border: Border.all(width: 0.7, color: Colors.grey[400]!),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  width: width,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, 0.2, 1],
                      colors: [
                        Colors.grey[900]!.withOpacity(0),
                        Colors.grey[900]!.withOpacity(0.2),
                        Colors.grey[900]!.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      manga.finished ? '${manga.newestChapter} 全' : '更新至 ${manga.newestChapter}',
                      style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 12, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          radius: BorderRadius.circular(5),
          splashColor: null,
          highlightColor: null,
          onTap: () => Navigator.of(context).push(
            CustomPageRoute(
              context: context,
              builder: (c) => MangaPage(
                id: manga.mid,
                title: manga.title,
                url: manga.url,
              ),
            ),
          ),
        ),
        Container(
          width: width,
          padding: EdgeInsets.only(top: 2),
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
    const hSpace = 15.0;
    const vSpace = 10.0;

    List<TinyBlockManga> mangas = group.mangas;
    switch (style) {
      case MangaGroupViewStyle.normalFull:
        break;
      case MangaGroupViewStyle.normalTruncate:
        if (mangas.length > 6) {
          mangas = mangas.sublist(0, 6); // X X X | X X X
        }
        break;
      case MangaGroupViewStyle.smallTruncate:
        if (mangas.length > 8) {
          mangas = mangas.sublist(0, 8); // X X X X | X X X X
        }
        break;
      case MangaGroupViewStyle.smallOneLine:
        if (mangas.length > 4) {
          mangas = mangas.sublist(0, 4); // X X X X
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

    return MangaGroupFrameworkView(
      title: title,
      icon: icon,
      onMorePressed: onMorePressed,
      child: _buildGroupItems(context: context),
    );
  }
}

/// 漫画分组的统一框架，在 [MangaGroupView] / [MangaCollectionView] 使用
class MangaGroupFrameworkView extends StatelessWidget {
  const MangaGroupFrameworkView({
    Key? key,
    required this.title,
    required this.icon,
    required this.child,
    this.onMorePressed,
    this.hPadding = 15,
    this.vPadding = 10,
  }) : super(key: key);

  final String title;
  final IconData icon;
  final Widget child;
  final void Function()? onMorePressed;
  final double hPadding;
  final double vPadding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.only(left: hPadding, top: vPadding, bottom: vPadding),
                child: IconText(
                  icon: Icon(icon, size: 24, color: Colors.orange),
                  text: Text(title, style: Theme.of(context).textTheme.subtitle1),
                  space: 8,
                ),
              ),
              if (onMorePressed != null)
                Padding(
                  padding: EdgeInsets.only(right: hPadding - 4, top: vPadding - 3, bottom: vPadding - 3),
                  child: InkWell(
                    child: Padding(
                      padding: EdgeInsets.only(left: 6, right: 4, top: 3, bottom: 3),
                      child: IconText(
                        text: Text('查看更多', style: Theme.of(context).textTheme.bodyText2?.copyWith(color: Colors.orange)),
                        icon: Icon(Icons.double_arrow, size: 20, color: Colors.orange),
                        alignment: IconTextAlignment.r2l,
                        space: 2,
                      ),
                    ),
                    onTap: onMorePressed,
                  ),
                ),
            ],
          ),
          child,
          SizedBox(height: vPadding),
        ],
      ),
    );
  }
}
