import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

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
    this.extraInRow,
    this.extraWidthInRow,
    this.extraInStack,
    this.extraInStack2,
    required this.onPressed,
    this.onLongPressed,
  })  : rowsExceptTitle = null,
        super(key: key);

  const GeneralLineView.custom({
    Key? key,
    required this.imageUrl,
    required this.title,
    required List<Widget> this.rowsExceptTitle,
    this.extraInRow,
    this.extraWidthInRow,
    this.extraInStack,
    this.extraInStack2,
    required this.onPressed,
    this.onLongPressed,
  })  : icon1 = null,
        text1 = null,
        icon2 = null,
        text2 = null,
        icon3 = null,
        text3 = null,
        super(key: key);

  final String imageUrl;
  final String title;
  final IconData? icon1;
  final String? text1;
  final IconData? icon2;
  final String? text2;
  final IconData? icon3;
  final String? text3;
  final List<Widget>? rowsExceptTitle;
  final Widget? extraInRow;
  final double? extraWidthInRow;
  final Widget? extraInStack;
  final Widget? extraInStack2;
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
            Container(
              width: MediaQuery.of(context).size.width - 14 * 3 - 75 - (extraWidthInRow ?? 0), // | ▢ ▢▢ |
              margin: EdgeInsets.only(top: 5, bottom: 5, right: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ****************************************************************
                  // 右上角标题
                  // ****************************************************************
                  Padding(
                    padding: EdgeInsets.only(bottom: 4),
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
                  if (rowsExceptTitle == null) ...[
                    GeneralLineIconText(icon: icon1, text: text1),
                    GeneralLineIconText(icon: icon2, text: text2),
                    GeneralLineIconText(icon: icon3, text: text3),
                  ],
                  // ****************************************************************
                  // 右边自定义控件
                  // ****************************************************************
                  if (rowsExceptTitle != null) ...rowsExceptTitle!,
                ],
              ),
            ),
            // ****************************************************************
            // 最右边自定义控件
            // ****************************************************************
            if (extraInRow != null) extraInRow!,
          ],
        ),
        if (extraInStack != null) extraInStack!,
        // ****************************************************************
        // 点击效果
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
        if (extraInStack2 != null) extraInStack2!,
      ],
    );
  }
}

class GeneralLineIconText extends StatelessWidget {
  const GeneralLineIconText({
    Key? key,
    required this.icon,
    required this.text,
    this.padding,
    this.iconSize,
    this.textStyle,
    this.space,
  }) : super(key: key);

  final IconData? icon;
  final String? text;
  final EdgeInsets? padding;
  final double? iconSize;
  final TextStyle? textStyle;
  final double? space;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.only(bottom: 2),
      child: IconText(
        icon: Icon(
          icon,
          size: iconSize ?? 20,
          color: Colors.orange,
        ),
        text: Text(
          text ?? '',
          style: (textStyle ?? DefaultTextStyle.of(context).style).copyWith(
            color: Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        space: space ?? 8,
      ),
    );
  }
}
