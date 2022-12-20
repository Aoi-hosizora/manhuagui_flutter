import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

/// 用于主页推荐页面的分栏，在 [MangaGroupView] / [MangaCollectionView] / [RecommendSubPage] 使用
class HomepageColumnView extends StatelessWidget {
  const HomepageColumnView({
    Key? key,
    required this.title,
    required this.icon,
    required this.child,
    this.onMorePressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    this.headerChildSpace,
  }) : super(key: key);

  final String title;
  final IconData icon;
  final Widget child;
  final void Function()? onMorePressed;
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
                child: IconText(
                  icon: Icon(icon, size: 25, color: Colors.orange),
                  text: Text(title, style: Theme.of(context).textTheme.subtitle1),
                  space: 8,
                ),
              ),
              if (onMorePressed != null)
                Padding(
                  padding: EdgeInsets.only(right: padding.right - 5, top: (headerChildSpace ?? 0) / 2),
                  child: InkWell(
                    child: Padding(
                      padding: EdgeInsets.only(left: 8, right: 5, top: 4, bottom: 4),
                      child: IconText(
                        text: Text(
                          '查看更多',
                          style: Theme.of(context).textTheme.bodyText2?.copyWith(color: Colors.orange),
                        ),
                        icon: Icon(
                          Icons.double_arrow,
                          size: 20,
                          color: Colors.orange,
                        ),
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
          SizedBox(height: padding.bottom),
        ],
      ),
    );
  }
}
