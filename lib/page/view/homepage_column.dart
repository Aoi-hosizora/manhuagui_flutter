import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

/// 用于主页推荐页面的分栏，在 [MangaGroupView] / [MangaCollectionView] / [MangaRankingListView] / [RecommendSubPage] 使用
class HomepageColumnView extends StatelessWidget {
  const HomepageColumnView({
    Key? key,
    required this.title,
    required this.icon,
    required this.child,
    this.onRefreshPressed,
    this.disableRefresh = false,
    this.onMorePressed,
    this.rightText,
    this.padding = const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    this.headerChildSpace,
  }) : super(key: key);

  final String title;
  final IconData icon;
  final Widget child;
  final void Function()? onRefreshPressed;
  final bool disableRefresh;
  final void Function()? onMorePressed;
  final String? rightText; // ignored when onMorePressed is not null
  final EdgeInsets padding;
  final double? headerChildSpace;

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
                padding: EdgeInsets.only(left: padding.left, top: padding.top, bottom: headerChildSpace ?? padding.top),
                child: Row(
                  children: [
                    IconText(
                      icon: Icon(icon, size: 24, color: Colors.orange),
                      text: Text(title, style: Theme.of(context).textTheme.subtitle1),
                      textPadding: EdgeInsets.only(bottom: 1),
                      space: 8,
                    ),
                    if (onRefreshPressed != null)
                      Padding(
                        padding: EdgeInsets.only(left: 3),
                        child: InkWell(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                            child: Icon(
                              Icons.refresh,
                              size: 24,
                              color: !disableRefresh ? Colors.orange : Colors.orange[100],
                            ),
                          ),
                          onTap: disableRefresh ? null : onRefreshPressed,
                        ),
                      ),
                  ],
                ),
              ),
              if (onMorePressed != null)
                Padding(
                  padding: EdgeInsets.only(right: padding.right - 5, top: (headerChildSpace ?? 0) / 2),
                  child: InkWell(
                    child: Padding(
                      padding: EdgeInsets.only(left: 8, right: 5, top: 3, bottom: 3),
                      child: IconText(
                        text: Text(
                          '查看更多',
                          style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 15, color: Colors.orange),
                        ),
                        icon: Icon(Icons.double_arrow, size: 21, color: Colors.orange),
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
                  padding: EdgeInsets.only(left: 8, right: padding.right, top: (headerChildSpace ?? 0) / 2),
                  child: Text(
                    rightText!,
                    style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
          child,
          SizedBox(height: padding.bottom),
        ],
      ),
    );
  }
}
