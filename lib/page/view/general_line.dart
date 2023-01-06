import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

/// 通用行，在 [TinyMangaLineView] / [SmallAuthorLineView] / [MangaRankLinkView] / [ShelfMangaLineView] / [MangaHistoryLineView] / [DownloadLineView] / [FavoriteMangaLineView] 使用
class GeneralLineView extends StatelessWidget {
  const GeneralLineView({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.icon1,
    required this.text1,
    required this.icon2,
    required this.text2,
    required this.icon3,
    required this.text3,
    this.cornerIcons,
    this.extrasInRow,
    this.extraWidthInRow,
    this.extraRightPaddingForTitle,
    this.extrasInStack,
    this.topExtrasInStack,
    required this.onPressed,
    this.onLongPressed,
  })  : customRows = null,
        super(key: key);

  const GeneralLineView.custom({
    Key? key,
    required this.imageUrl,
    required this.title,
    required List<Widget> this.customRows,
    this.extrasInRow,
    this.extraWidthInRow,
    this.extraRightPaddingForTitle,
    this.extrasInStack,
    this.topExtrasInStack,
    required this.onPressed,
    this.onLongPressed,
  })  : icon1 = null,
        text1 = null,
        icon2 = null,
        text2 = null,
        icon3 = null,
        text3 = null,
        cornerIcons = null,
        super(key: key);

  // required
  final String imageUrl;
  final String title;

  // basic rows
  final IconData? icon1;
  final String? text1;
  final IconData? icon2;
  final String? text2;
  final IconData? icon3;
  final String? text3;
  final List<IconData>? cornerIcons;

  // custom rows
  final List<Widget>? customRows; // 取代上面的 iconX 和 textX

  // optional
  final List<Widget>? extrasInRow;
  final double? extraWidthInRow;
  final double? extraRightPaddingForTitle;
  final List<Widget>? extrasInStack;
  final List<Widget>? topExtrasInStack;

  // callbacks
  final void Function() onPressed;
  final void Function()? onLongPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ****************************************************************
            // 左边图片
            // ****************************************************************
            Container(
              margin: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              child: NetworkImageView(
                url: imageUrl,
                height: 100,
                width: 75,
              ),
            ),

            // ****************************************************************
            // 右边信息
            // ****************************************************************
            Container(
              width: MediaQuery.of(context).size.width - 14 * 3 - 75 - (extraWidthInRow ?? 0), // | ▢ ▢▢ |
              margin: EdgeInsets.only(top: 5, bottom: 5, right: 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ****************************************************************
                  // 右上角标题
                  // ****************************************************************
                  Padding(
                    padding: EdgeInsets.only(bottom: 4, right: extraRightPaddingForTitle ?? 0),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.subtitle1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // ****************************************************************
                  // 右边预定义控件
                  // ****************************************************************
                  if (customRows == null) ...[
                    GeneralLineIconText(icon: icon1, text: text1),
                    GeneralLineIconText(icon: icon2, text: text2),
                    GeneralLineIconText(icon: icon3, text: text3, cornerIcons: cornerIcons),
                  ],

                  // ****************************************************************
                  // 右边自定义控件
                  // ****************************************************************
                  if (customRows != null) ...customRows!,
                ],
              ),
            ),

            // ****************************************************************
            // 最右边自定义控件
            // ****************************************************************
            if (extrasInRow != null) ...extrasInRow!,
          ],
        ),

        // ****************************************************************
        // Stack 自定义控件，Ripple 效果以内
        // ****************************************************************
        if (extrasInStack != null) ...extrasInStack!,

        // ****************************************************************
        // Ripple 效果
        // ****************************************************************
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              onLongPress: onLongPressed,
            ),
          ),
        ),

        // ****************************************************************
        // Stack 自定义控件，Ripple 效果以外
        // ****************************************************************
        if (topExtrasInStack != null) ...topExtrasInStack!,
      ],
    );
  }
}

class GeneralLineIconText extends StatelessWidget {
  const GeneralLineIconText({
    Key? key,
    required this.icon,
    required this.text,
    this.cornerIcons,
    this.padding,
    this.iconSize,
    this.cornerIconSize,
    this.textStyle,
    this.space,
    this.cornerSpace,
    this.textCornerSpace,
  }) : super(key: key);

  final IconData? icon;
  final String? text;
  final List<IconData>? cornerIcons;
  final EdgeInsets? padding;
  final double? iconSize;
  final double? cornerIconSize;
  final TextStyle? textStyle;
  final double? space;
  final double? cornerSpace;
  final double? textCornerSpace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.only(bottom: 3),
      child: IconText.texts(
        icon: Icon(
          icon,
          size: iconSize ?? 20,
          color: Colors.orange,
        ),
        texts: [
          Expanded(
            child: Text(
              text ?? '',
              style: textStyle ?? //
                  DefaultTextStyle.of(context).style.copyWith(color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: textCornerSpace ?? 6),
          for (var i = 0; i < (cornerIcons?.length ?? 0); i++)
            Padding(
              padding: EdgeInsets.only(
                left: i > 0 ? (cornerSpace ?? 4) : 0,
              ),
              child: Icon(
                cornerIcons![i],
                size: cornerIconSize ?? 18.5,
                color: Colors.grey[500],
              ),
            ),
        ],
        space: space ?? 8,
      ),
    );
  }
}
