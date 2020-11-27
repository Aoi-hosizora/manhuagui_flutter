import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';

class ImageLoadingView extends StatefulWidget {
  const ImageLoadingView({
    Key key,
    this.title,
    @required this.event,
  }) : super(key: key);

  final String title;
  final ImageChunkEvent event;

  @override
  _ImageLoadingViewState createState() => _ImageLoadingViewState();
}

class _ImageLoadingViewState extends State<ImageLoadingView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        widget.title != null
            ? Text(
          widget.title,
          style: TextStyle(fontSize: 45, color: Colors.grey),
        )
            : SizedBox(height: 0),
        Padding(
          padding: EdgeInsets.all(30),
          child: Container(
            width: 50.0,
            height: 50.0,
            child: CircularProgressIndicator(
              value: widget.event?.expectedTotalBytes == null ? null : (widget.event?.cumulativeBytesLoaded ?? 0.0) / widget.event.expectedTotalBytes,
            ),
          ),
        ),
        widget.event?.expectedTotalBytes != null
            ? Text(
          '${filesize(widget.event.cumulativeBytesLoaded)} / ${filesize(widget.event.expectedTotalBytes)}',
          style: TextStyle(color: Colors.grey),
        )
            : SizedBox(height: 0),
      ],
    );
  }
}

class ImageLoadFailedView extends StatefulWidget {
  ImageLoadFailedView({
    Key key,
    this.title,
  }) : super(key: key);

  final String title;

  @override
  _ImageLoadFailedViewState createState() => _ImageLoadFailedViewState();
}

class _ImageLoadFailedViewState extends State<ImageLoadFailedView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        widget.title != null
            ? Text(
          widget.title,
          style: TextStyle(fontSize: 45, color: Colors.grey),
        )
            : SizedBox(height: 0),
        Padding(
          padding: EdgeInsets.all(30),
          child: Container(
            width: 50.0,
            height: 50.0,
            child: Icon(
              Icons.broken_image,
              color: Colors.grey[400],
              size: 50.0,
            ),
          ),
        ),
      ],
    );
  }
}