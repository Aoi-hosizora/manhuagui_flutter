import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class NetworkImageView extends StatelessWidget {
  const NetworkImageView({
    Key? key,
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  final String url;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          child: Icon(
            Icons.more_horiz,
            color: Colors.grey,
          ),
          width: width,
          height: height,
          color: Colors.orange[50],
        ),
        errorWidget: (context, url, error) => Container(
          child: Icon(
            Icons.broken_image,
            color: Colors.grey,
          ),
          width: width,
          height: height,
          color: Colors.orange[50],
        ),
        fadeOutDuration: Duration(milliseconds: 1000),
        fadeOutCurve: Curves.easeOut,
        fadeInDuration: Duration(milliseconds: 500),
        fadeInCurve: Curves.easeIn,
      ),
    );
  }
}
