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
                  icon: Icon(icon, size: 25, color: Colors.orange),
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
