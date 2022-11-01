import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/image_viewer.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

/// 通用的漫画下载行（小），在 [DownloadMangaLineView] 使用
class DownloadLineView extends StatelessWidget {
  const DownloadLineView({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.icon1,
    required this.text1,
    required this.icon2,
    required this.text2,
    required this.icon3,
    required this.text3,
    required this.showProgressBar,
    required this.progressBarValue,
    required this.disableAction,
    required this.actionIcon,
    required this.onActionPressed,
    required this.onLinePressed,
    required this.onLineLongPressed,
  }) : super(key: key);

  final String imageUrl;
  final String title;
  final IconData icon1;
  final String text1;
  final IconData icon2;
  final String text2;
  final IconData? icon3;
  final String? text3;
  final bool showProgressBar;
  final double? progressBarValue;
  final bool disableAction;
  final IconData actionIcon;
  final void Function() onActionPressed;
  final void Function() onLinePressed;
  final void Function()? onLineLongPressed;

  @override
  Widget build(BuildContext context) {
    return GeneralLineView.custom(
      imageUrl: imageUrl,
      title: title,
      customRows: [
        GeneralLineIconText(
          icon: icon1,
          text: text1,
        ),
        GeneralLineIconText(
          icon: icon2,
          text: text2,
        ),
        GeneralLineIconText(
          icon: icon3,
          text: text3,
        ),
      ],
      extrasInStack: [
        if (showProgressBar)
          Positioned(
            bottom: 8 + 24 / 2 - (Theme.of(context).progressIndicatorTheme.linearMinHeight ?? 4) / 2 - 2,
            left: 75 + 14 * 2,
            right: 24 + 8 * 2 + 14,
            child: LinearProgressIndicator(
              value: progressBarValue,
            ),
          ),
      ],
      topExtrasInStack: [
        Positioned(
          right: 0,
          bottom: 0,
          child: InkWell(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                actionIcon,
                size: 24,
                color: !disableAction ? Theme.of(context).iconTheme.color : Colors.grey,
              ),
            ),
            onTap: !disableAction ? onActionPressed : null,
          ),
        ),
      ],
      onPressed: onLinePressed,
      onLongPressed: onLineLongPressed,
    );
  }
}

/// 通用的漫画下载行（大），在 [DownloadMangaBlockView] 使用
class LargeDownloadLineView extends StatelessWidget {
  const LargeDownloadLineView({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.icon1,
    required this.text1,
    required this.icon2,
    required this.text2,
    required this.icon3,
    required this.text3,
  }) : super(key: key);

  final String imageUrl;
  final String title;
  final IconData icon1;
  final String text1;
  final IconData icon2;
  final String text2;
  final IconData icon3;
  final String text3;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ****************************************************************
        // 封面
        // ****************************************************************
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: FullRippleWidget(
            child: NetworkImageView(
              url: imageUrl,
              height: 160,
              width: 120,
            ),
            onTap: () => Navigator.of(context).push(
              CustomMaterialPageRoute(
                context: context,
                builder: (c) => ImageViewerPage(
                  url: imageUrl,
                  title: '漫画封面',
                ),
              ),
            ),
          ),
        ),
        // ****************************************************************
        // 信息
        // ****************************************************************
        Container(
          width: MediaQuery.of(context).size.width - 14 * 3 - 120, // | ▢ ▢▢ |
          padding: EdgeInsets.only(top: 10, bottom: 10, right: 0),
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headline6?.copyWith(fontWeight: FontWeight.normal),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Divider(height: 20, thickness: 1.5),
              GeneralLineIconText(
                icon: icon1,
                text: text1,
                iconSize: 22,
                textStyle: Theme.of(context).textTheme.subtitle2?.copyWith(fontSize: 16, fontWeight: FontWeight.normal),
                padding: EdgeInsets.only(bottom: 4),
              ),
              GeneralLineIconText(
                icon: icon2,
                text: text2,
                iconSize: 22,
                textStyle: Theme.of(context).textTheme.subtitle2?.copyWith(fontSize: 16, fontWeight: FontWeight.normal),
                padding: EdgeInsets.only(bottom: 4),
              ),
              GeneralLineIconText(
                icon: icon3,
                text: text3,
                iconSize: 22,
                textStyle: Theme.of(context).textTheme.subtitle2?.copyWith(fontSize: 16, fontWeight: FontWeight.normal),
                padding: EdgeInsets.only(bottom: 4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
