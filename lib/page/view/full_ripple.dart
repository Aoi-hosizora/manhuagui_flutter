import 'package:flutter/material.dart';

/// 点击图像时的 Ripple 效果，在 [MineSubPage] / [MangaPage] / [AuthorPage] / [LargeDownloadLineView] 使用
class FullRippleWidget extends StatelessWidget {
  const FullRippleWidget({
    Key? key,
    required this.child,
    this.radius,
    required this.onTap,
    this.onLongPress,
    this.highlightColor = Colors.black26,
    this.splashColor = Colors.black26,
    this.backgroundDecoration,
  }) : super(key: key);

  final Widget child;
  final BorderRadius? radius;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final Color? highlightColor;
  final Color? splashColor;
  final Decoration? backgroundDecoration;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.zero,
      child: Stack(
        children: [
          if (backgroundDecoration != null)
            Positioned.fill(
              child: Container(
                decoration: backgroundDecoration!,
              ),
            ),
          child,
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                highlightColor: highlightColor,
                splashColor: splashColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
