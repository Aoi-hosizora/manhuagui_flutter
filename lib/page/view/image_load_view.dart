import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';

class ImageLoadingView extends StatelessWidget {
  const ImageLoadingView({
    Key? key,
    required this.event,
    this.title,
    this.width,
    this.height,
  })  : assert(width == null || width > 0),
        assert(height == null || height > 0),
        super(key: key);

  final String title;
  final ImageChunkEvent event;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: width,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (title != null)
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
                value: (event?.expectedTotalBytes ?? 0 == 0) ? null : ((event?.cumulativeBytesLoaded ?? 0.0) / event.expectedTotalBytes),
              ),
            ),
          ),
          if (event?.cumulativeBytesLoaded != null)
            Text(
              event?.expectedTotalBytes == null ? '${filesize(event.cumulativeBytesLoaded)}' : '${filesize(event.cumulativeBytesLoaded)} / ${filesize(event.expectedTotalBytes)}',
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
    this.title,
    required this.width,
    required this.height,
  })  : assert(width == null || width > 0),
        assert(height == null || height > 0),
        super(key: key);

  final String title;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: width,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (title != null)
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
