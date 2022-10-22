import 'package:flutter/material.dart';

class FullRippleWidget extends StatelessWidget {
  const FullRippleWidget({
    Key? key,
    required this.child,
    this.radius,
    required this.onTap,
    this.onLongPress,
    this.highlightColor = Colors.black26,
    this.splashColor = Colors.black26,
  }) : super(key: key);

  final Widget child;
  final BorderRadius? radius;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final Color? highlightColor;
  final Color? splashColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.zero,
      child: Stack(
        children: [
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
