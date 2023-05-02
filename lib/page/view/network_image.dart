import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/config.dart';

class NetworkImageView extends StatelessWidget {
  const NetworkImageView({
    Key? key,
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.quality = FilterQuality.low,
    this.border,
    this.radius,
    this.errorBuilder,
  })  : fileFuture = null,
        super(key: key);

  const NetworkImageView.butForLocal({
    Key? key,
    required Future<File?> this.fileFuture,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.quality = FilterQuality.low,
    this.border,
    this.radius,
    this.errorBuilder,
  })  : url = '',
        super(key: key);

  final String url;
  final Future<File?>? fileFuture;
  final double width;
  final double height;
  final BoxFit fit;
  final FilterQuality quality;
  final BoxBorder? border;
  final BorderRadius? radius;
  final Widget Function(BuildContext, Object?)? errorBuilder;

  Widget _buildPlaceholderWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.orange[50],
      child: Center(
        child: Icon(
          Icons.more_horiz,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object? error) {
    return Container(
      width: width,
      height: height,
      color: Colors.orange[50],
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var url = this.url;
    if (url.startsWith('//')) {
      url = 'https:$url';
    }
    if (AppSetting.instance.other.useHttpForImage) {
      url = url.replaceAll('https://', 'http://');
    }

    return Container(
      decoration: border == null
          ? null
          : BoxDecoration(
              border: border,
              borderRadius: radius ?? BorderRadius.zero,
            ),
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: radius ?? BorderRadius.zero,
        child: fileFuture == null
            ? CachedNetworkImage(
                imageUrl: url,
                width: width,
                height: height,
                fit: fit,
                alignment: Alignment.center,
                filterQuality: quality,
                httpHeaders: const {
                  'User-Agent': USER_AGENT,
                  'Referer': REFERER,
                },
                cacheManager: DefaultCacheManager(),
                fadeOutDuration: Duration(milliseconds: 1000),
                fadeOutCurve: Curves.easeOut,
                fadeInDuration: Duration(milliseconds: 500),
                fadeInCurve: Curves.easeIn,
                placeholder: (c, _) => _buildPlaceholderWidget(c),
                errorWidget: (c, _, err) => errorBuilder?.call(c, err) ?? _buildErrorWidget(c, err),
              )
            : LocalOrCachedNetworkImage(
                provider: LocalOrCachedNetworkImageProvider.fromLocalWithFuture(
                  fileFuture: fileFuture!,
                  fileMustExist: true,
                ),
                width: width,
                height: height,
                fit: fit,
                alignment: Alignment.center,
                filterQuality: quality,
                fadeOutDuration: Duration(milliseconds: 1000),
                fadeOutCurve: Curves.easeOut,
                fadeInDuration: Duration(milliseconds: 500),
                fadeInCurve: Curves.easeIn,
                placeholderBuilder: (c) => _buildPlaceholderWidget(c),
                errorBuilder: (c, err, _) => errorBuilder?.call(c, err) ?? _buildErrorWidget(c, err),
              ),
      ),
    );
  }
}
