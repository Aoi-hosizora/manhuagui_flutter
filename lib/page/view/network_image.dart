import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class NetworkImageView extends StatelessWidget {
  const NetworkImageView({
    Key? key,
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.radius,
  }) : super(key: key);

  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    var url =this.url;
    if (url.startsWith('//')) {
      url = 'https:$url';
    }
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.zero,
      child: SizedBox(
        width: width,
        height: height,
        child: CachedNetworkImage(
          imageUrl: url,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => Container(
            width: width,
            height: height,
            color: Colors.orange[50],
            child: Center(
              child: Icon(
                Icons.more_horiz,
                color: Colors.grey,
              ),
            ),
          ),
          errorWidget: (_, url, __) => Container(
            width: width,
            height: height,
            color: Colors.orange[50],
            child: Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.grey,
              ),
            ),
          ),
          cacheManager: DefaultCacheManager(),
          fadeOutDuration: Duration(milliseconds: 1000),
          fadeOutCurve: Curves.easeOut,
          fadeInDuration: Duration(milliseconds: 500),
          fadeInCurve: Curves.easeIn,
        ),
      ),
    );
  }
}
