import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/message.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/message_line.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/prefs/message.dart';

/// 历史消息页
class MessagePage extends StatefulWidget {
  const MessagePage({Key? key}) : super(key: key);

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final _data = <Message>[];
  var _total = 0;
  final _readMessages = <int>[];

  Future<List<Message>> _getData() async {
    final client = RestClient(DioManager.instance.dio);
    var result = await client.getMessages().onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });

    _total = result.data.data.length;
    var messages = await MessagePrefs.getReadMessages();
    _readMessages.clear();
    _readMessages.addAll(messages);
    if (mounted) setState(() {});

    return result.data.data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('历史消息'),
        leading: AppBarActionButton.leading(context: context),
      ),
      body: RefreshableListView<Message>(
        data: _data,
        getData: () => _getData(),
        setting: UpdatableDataViewSetting(
          padding: EdgeInsets.symmetric(vertical: 0),
          interactiveScrollbar: true,
          scrollbarCrossAxisMargin: 2,
          placeholderSetting: PlaceholderSetting().copyWithChinese(),
          refreshFirst: true,
          clearWhenRefresh: false,
          clearWhenError: false,
        ),
        separator: Divider(height: 0, thickness: 1),
        itemBuilder: (c, _, item) => MessageLineView(
          message: item,
          hasRead: _readMessages.contains(item.mid),
        ),
        extra: UpdatableDataViewExtraWidgets(
          outerTopWidgets: [
            ListHintView.textText(
              leftText: '本应用的信息',
              rightText: '共 $_total 条',
            ),
          ],
        ),
      ),
    );
  }
}
