import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';

/// 图片加载和错误控件，在 [MangaGalleryView] / [ImageViewerPage] 使用

class ImageLoadingView extends StatelessWidget {
  const ImageLoadingView({
    Key? key,
    required this.title,
    required this.event,
  }) : super(key: key);

  final String title;
  final ImageChunkEvent? event;

  @override
  Widget build(BuildContext context) {
    var event = this.event;
    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(vertical: 40),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 45, color: Colors.grey),
            ),
          Padding(
            padding: EdgeInsets.all(30),
            child: SizedBox(
              height: 50,
              width: 50,
              child: Padding(
                padding: EdgeInsets.all(4.5 / 2),
                child: CircularProgressIndicator(
                  strokeWidth: 4.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              event == null
                  ? '　'
                  : (event.expectedTotalBytes ?? 0) == 0
                      ? '　${filesize(event.cumulativeBytesLoaded)}　'
                      : '　${filesize(event.cumulativeBytesLoaded)} / ${filesize(event.expectedTotalBytes!)}　',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class ImageLoadFailedView extends StatelessWidget {
  const ImageLoadFailedView({
    Key? key,
    required this.title,
    this.error,
    this.errorFormatter,
  }) : super(key: key);

  final String title;
  final dynamic error;
  final String? Function(dynamic error)? errorFormatter;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(vertical: 40),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 45, color: Colors.grey),
            ),
          Padding(
            padding: EdgeInsets.all(30),
            child: Container(
              width: 50,
              height: 50,
              child: Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 50,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              errorFormatter?.call(error) ??
                  (error == null //
                      ? '未知错误'
                      : wrapError(error, StackTrace.empty).text),
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
