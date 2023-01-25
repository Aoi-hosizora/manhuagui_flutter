import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/message.dart';
import 'package:manhuagui_flutter/page/page/message_dialog.dart';
import 'package:manhuagui_flutter/service/prefs/read_message.dart';

/// 历史消息行，在 [MessagePage] 使用
class MessageLineView extends StatelessWidget {
  const MessageLineView({
    Key? key,
    required this.message,
    required this.hasRead,
    this.onChanged,
  }) : super(key: key);

  final Message message;
  final bool hasRead;
  final void Function()? onChanged;

  Future<void> _showDetail(BuildContext context) async {
    if (message.notification != null) {
      await showNotificationDialog(
        context: context,
        notification: message,
        onChanged: onChanged,
      );
    }
    if (message.newVersion != null) {
      await showNewVersionDialog(
        context: context,
        newVersion: message,
        onChanged: onChanged,
      );
    }
  }

  Future<void> _showOptions(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('消息选项'),
        children: [
          IconTextDialogOption(
            icon: Icon(Icons.arrow_forward),
            text: Text('查看详情'),
            onPressed: () async {
              Navigator.of(c).pop();
              await _showDetail(context);
            },
          ),
          if (hasRead)
            IconTextDialogOption(
              icon: Icon(Icons.notification_add),
              text: Text('标记为未阅读'),
              onPressed: () async {
                Navigator.of(c).pop();
                await ReadMessagePrefs.removeReadMessage(message.mid);
                onChanged?.call();
              },
            ),
          if (!hasRead)
            IconTextDialogOption(
              icon: Icon(Icons.notifications_none),
              text: Text('标记为已阅读'),
              onPressed: () async {
                Navigator.of(c).pop();
                await ReadMessagePrefs.addReadMessage(message.mid);
                onChanged?.call();
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDetail(context),
      onLongPress: () => _showOptions(context),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Stack(
              children: [
                Icon(
                  Icons.notifications,
                  color: Colors.grey[700],
                  size: 28,
                ),
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
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '【${message.title}】' + //
                        (message.notification != null ? message.notification!.content : '') +
                        (message.newVersion != null ? message.newVersion!.version : ''),
                    style: Theme.of(context).textTheme.subtitle1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Text(
                    '发布于：${message.createdAtString}',
                    style: Theme.of(context).textTheme.bodyText2?.copyWith(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
