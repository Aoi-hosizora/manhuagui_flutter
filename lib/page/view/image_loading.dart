import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';

class ImageLoadingView extends StatefulWidget {
  const ImageLoadingView({
    Key key,
    this.title,
    @required this.event,
    this.color = Colors.black,
    @required this.height,
    @required this.width,
  })  : assert(height != null),
        assert(width != null),
        super(key: key);

  final String title;
  final ImageChunkEvent event;
  final Color color;
  final double height;
  final double width;

  @override
  _ImageLoadingViewState createState() => _ImageLoadingViewState();
}

class _ImageLoadingViewState extends State<ImageLoadingView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      color: widget.color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.title != null)
            Text(
              widget.title,
              style: TextStyle(fontSize: 45, color: Colors.grey),
            ),
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
          if (widget.event?.expectedTotalBytes != null)
            Text(
              '${filesize(widget.event.cumulativeBytesLoaded)} / ${filesize(widget.event.expectedTotalBytes)}',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }
}

class ImageLoadFailedView extends StatefulWidget {
  ImageLoadFailedView({
    Key key,
    this.title,
    this.color = Colors.black,
    @required this.height,
    @required this.width,
  })  : assert(height != null),
        assert(width != null),
        super(key: key);

  final String title;
  final Color color;
  final double height;
  final double width;

  @override
  _ImageLoadFailedViewState createState() => _ImageLoadFailedViewState();
}

class _ImageLoadFailedViewState extends State<ImageLoadFailedView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      color: widget.color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.title != null)
            Text(
              widget.title,
              style: TextStyle(fontSize: 45, color: Colors.grey),
            ),
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
      ),
    );
  }
}
