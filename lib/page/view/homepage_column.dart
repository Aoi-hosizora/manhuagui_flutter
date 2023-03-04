import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

/// 用于首页推荐页面的分栏，在 [RecommendSubPage] / [MangaGroupView] / [MangaCollectionView] / [MangaRankingListView] / [MangaAudRankingPage] 使用
class HomepageColumnView extends StatelessWidget {
  const HomepageColumnView({
    Key? key,
    required this.title,
    required this.icon,
    required this.child,
    this.onRefreshPressed,
    this.disableRefresh = false,
    this.onHintPressed,
    this.onMorePressed,
    this.rightText,
    this.padding = const EdgeInsets.only(bottom: 12),
    this.headerPadding = const EdgeInsets.only(left: 15, right: 15, top: 12, bottom: 12),
  }) : super(key: key);

  final String title;
  final IconData icon;
  final Widget child;
  final void Function()? onRefreshPressed;
  final bool disableRefresh;
  final void Function()? onHintPressed;
  final void Function()? onMorePressed;
  final String? rightText; // ignored when onMorePressed is not null
  final EdgeInsets padding;
  final EdgeInsets headerPadding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // left
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Padding(
                          padding: EdgeInsets.only(left: headerPadding.left, top: headerPadding.top, bottom: headerPadding.bottom), // <= headerPadding left & vertical
                          child: IconText(
                            icon: Icon(icon, size: 26, color: Colors.orange),
                            text: Flexible(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 1),
                                child: Text(title, style: Theme.of(context).textTheme.subtitle1, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                            mainAxisSize: MainAxisSize.min,
                            space: 8,
                          ),
                        ),
                      ),
                      if (onRefreshPressed != null)
                        Padding(
                          padding: EdgeInsets.only(left: 2, top: headerPadding.top - 3, bottom: headerPadding.bottom - 3), // <= headerPadding vertical
                          child: InkWell(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                              child: Icon(Icons.refresh, size: 23, color: !disableRefresh ? Colors.orange : Colors.orange[100]),
                            ),
                            onTap: disableRefresh ? null : onRefreshPressed,
                          ),
                        ),
                      if (onHintPressed != null)
                        Padding(
                          padding: EdgeInsets.only(left: 2, top: headerPadding.top - 3, bottom: headerPadding.bottom - 3), // <= headerPadding vertical
                          child: InkWell(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                              child: Icon(Icons.help_outline, size: 23, color: Colors.orange),
                            ),
                            onTap: onHintPressed,
                          ),
                        ),
                    ],
                  ),
                ),

                // right
                if (onMorePressed != null)
                  Padding(
                    padding: EdgeInsets.only(top: headerPadding.top - 4.5, bottom: headerPadding.bottom - 4.5, right: headerPadding.right - 6), // <= headerPadding right & vertical
                    child: InkWell(
                      child: Padding(
                        padding: EdgeInsets.only(left: 8, right: 6, top: 4.5, bottom: 4.5),
                        child: IconText(
                          text: Text(
                            '查看更多',
                            style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 15, color: Colors.orange),
                          ),
                          icon: Icon(Icons.double_arrow, size: 19, color: Colors.orange),
                          textPadding: EdgeInsets.only(bottom: 1),
                          alignment: IconTextAlignment.r2l,
                          space: 2,
                        ),
                      ),
                      onTap: onMorePressed,
                    ),
                  ),
                if (onMorePressed == null && rightText != null)
                  Padding(
                    padding: EdgeInsets.only(left: 12, top: headerPadding.top, bottom: headerPadding.bottom, right: headerPadding.right), // <= headerPadding right & vertical
                    child: Text(
                      rightText!,
                      style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                if (onMorePressed == null && rightText == null) //
                  SizedBox(width: headerPadding.right), // <= headerPadding right
              ],
            ),

            // child
            child,
          ],
        ),
      ),
    );
  }
}
