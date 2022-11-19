import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/message.dart';

class MessageLineView extends StatelessWidget {
  const MessageLineView({
    Key? key,
    required this.message,
    required this.hasRead,
  }) : super(key: key);

  final Message message;
  final bool hasRead;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {}, // TODO
      title: Text(
        '【${message.title}】' + (message.notification != null ? message.notification!.content : '') + (message.newVersion != null ? message.newVersion!.version : ''),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(message.createdAt.toString()),
      leading: Stack(
        children: [
          Icon(Icons.notifications),
          if (!hasRead)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
