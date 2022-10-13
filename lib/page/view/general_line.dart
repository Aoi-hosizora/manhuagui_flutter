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
    this.extraInStack,
    this.extraInRow,
    this.extraWidthInRow,
    required this.onPressed,
    this.onLongPressed,
  }) : super(key: key);

  final String imageUrl;
  final String title;
  final IconData? icon1;
  final String? text1;
  final IconData? icon2;
  final String? text2;
  final IconData? icon3;
  final String? text3;
  final Widget? extraInStack;
  final Widget? extraInRow;
  final double? extraWidthInRow;
  final void Function() onPressed;
  final void Function()? onLongPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.subtitle1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: IconText(
                      icon: Icon(
                        icon1,
                        size: 20,
                        color: Colors.orange,
                      ),
                      text: Text(
                        text1 ?? '',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      space: 8,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: IconText(
                      icon: Icon(
                        icon2,
                        size: 20,
                        color: Colors.orange,
                      ),
                      text: Text(
                        text2 ?? '',
                        style: TextStyle(color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      space: 8,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: IconText(
                      icon: Icon(
                        icon3,
                        size: 20,
                        color: Colors.orange,
                      ),
                      text: Text(
                        text3 ?? '',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      space: 8,
                    ),
                  ),
                ],
              ),
            ),
            if (extraInRow != null) extraInRow!,
          ],
        ),
        if (extraInStack != null) extraInStack!,
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              onLongPress: onLongPressed,
            ),
          ),
        ),
      ],
    );
  }
}
