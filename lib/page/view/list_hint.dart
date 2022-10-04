import 'package:flutter/material.dart';

enum ListHintViewStyle {
  textText,
  textWidget,
  widgets,
}

class ListHintView extends StatelessWidget {
  const ListHintView.textText({
    Key? key,
    required String this.leftText,
    required String this.rightText,
  })  : rightWidget = null,
        widgets = null,
        style = ListHintViewStyle.textText,
        super(key: key);

  const ListHintView.textWidget({
    Key? key,
    required String this.leftText,
    required Widget this.rightWidget,
  })  : rightText = null,
        widgets = null,
        style = ListHintViewStyle.textWidget,
        super(key: key);

  const ListHintView.widgets({
    Key? key,
    required List<Widget> this.widgets,
  })  : leftText = null,
        rightText = null,
        rightWidget = null,
        style = ListHintViewStyle.widgets,
        super(key: key);

  final String? leftText;
  final String? rightText;
  final Widget? rightWidget;
  final List<Widget>? widgets;
  final ListHintViewStyle style;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisAlignment: style == ListHintViewStyle.widgets
                ? MainAxisAlignment.spaceAround /* | 　 　 　 | */
                : MainAxisAlignment.spaceBetween /* | 　   　 | */,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: style == ListHintViewStyle.textText
                ? [
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Text(
                          leftText!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    SizedBox(height: 26, width: 20),
                    Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: Text(rightText!),
                    ),
                  ]
                : style == ListHintViewStyle.textWidget
                    ? [
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Text(
                              leftText!,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        SizedBox(height: 26, width: 15),
                        rightWidget!,
                      ]
                    : widgets!,
          ),
        ),
        Divider(height: 0, thickness: 1),
      ],
    );
  }
}
