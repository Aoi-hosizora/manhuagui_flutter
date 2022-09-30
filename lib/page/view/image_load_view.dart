import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

class ImageLoadingView extends StatelessWidget {
  const ImageLoadingView({
    Key? key,
    required this.title,
    required this.event,
    this.width,
    this.height,
  })  : assert(width == null || width > 0),
        assert(height == null || height > 0),
        super(key: key);

  final String title;
  final ImageChunkEvent? event;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: width,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
              child: CircularProgressIndicator(
                value: (event?.expectedTotalBytes ?? 0) == 0 ? null : event!.cumulativeBytesLoaded / event!.expectedTotalBytes!,
              ),
            ),
          ),
          Text(
            event?.expectedTotalBytes == null ? filesize(event!.cumulativeBytesLoaded) : '${filesize(event!.cumulativeBytesLoaded)} / ${filesize(event!.expectedTotalBytes ?? 0)}',
            style: TextStyle(color: Colors.grey),
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
    this.width,
    this.height,
  })  : assert(width == null || width > 0),
        assert(height == null || height > 0),
        super(key: key);

  final String title;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: width,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
        ],
      ),
    );
  }
}
