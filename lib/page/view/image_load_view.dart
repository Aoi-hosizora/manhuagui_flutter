import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

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
    return Container(
      color: Colors.black,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
        maxWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal,
      ),
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
                value: (event == null || (event!.expectedTotalBytes ?? 0) == 0) ? null : event!.cumulativeBytesLoaded / event!.expectedTotalBytes!,
              ),
            ),
          ),
          Text(
            event == null
                ? ''
                : (event!.expectedTotalBytes ?? 0) == 0
                    ? filesize(event!.cumulativeBytesLoaded)
                    : '${filesize(event!.cumulativeBytesLoaded)} / ${filesize(event!.expectedTotalBytes!)}',
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
  }) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
        maxWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal,
      ),
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
