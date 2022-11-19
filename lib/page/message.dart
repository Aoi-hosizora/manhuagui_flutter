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
  final _rdvKey = GlobalKey<RefreshableDataViewState>();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();

  @override
  void dispose() {
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  final _data = <Message>[];
  var _total = 0;
  final _readMessages = <int>[];
  var _unreadCount = 0;

  Future<List<Message>> _getData() async {
    final client = RestClient(DioManager.instance.dio);
    var result = await client.getMessages().onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });

    _total = result.data.data.length;
    if (mounted) setState(() {});
    await _loadReadMangas();

    return result.data.data;
  }

  Future<void> _loadReadMangas() async {
    var messages = await MessagePrefs.getReadMessages();
    _readMessages.clear();
    _readMessages.addAll(messages);
    _unreadCount = _data.length - _data.where((el) => _readMessages.contains(el.mid)).length;
    if (mounted) setState(() {});
  }

  Future<void> _markAllAsHasRead(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('操作确认'),
        content: Text('是否标记所有消息为已阅读？'),
        actions: [
          TextButton(
            child: Text('标记'),
            onPressed: () async {
              Navigator.of(c).pop();
              var r = await MessagePrefs.addReadMessages(_data.map((m) => m.mid).toList());
              _readMessages.clear();
              _readMessages.addAll(r);
              if (mounted) setState(() {});
            },
          ),
          TextButton(
            child: Text('取消'),
            onPressed: () => Navigator.of(c).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllAsUnread(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('操作确认'),
        content: Text('是否标记所有消息为未阅读？'),
        actions: [
          TextButton(
            child: Text('标记'),
            onPressed: () async {
              Navigator.of(c).pop();
              await MessagePrefs.clearReadMessages();
              _readMessages.clear();
              if (mounted) setState(() {});
            },
          ),
          TextButton(
            child: Text('取消'),
            onPressed: () => Navigator.of(c).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('历史消息'),
        leading: AppBarActionButton.leading(context: context),
        actions: [
          AppBarActionButton(
            icon: Icon(Icons.notifications_none),
            tooltip: '全部标记为已阅读',
            onPressed: () => _markAllAsHasRead(context),
          ),
          AppBarActionButton(
            icon: Icon(Icons.notification_add),
            tooltip: '全部标记为未阅读',
            onPressed: () => _markAllAsUnread(context),
          ),
        ],
      ),
      body: RefreshableListView<Message>(
        key: _rdvKey,
        data: _data,
        getData: () => _getData(),
        scrollController: _controller,
        setting: UpdatableDataViewSetting(
          padding: EdgeInsets.symmetric(vertical: 0),
          interactiveScrollbar: true,
          scrollbarCrossAxisMargin: 2,
          placeholderSetting: PlaceholderSetting().copyWithChinese(),
          onPlaceholderStateChanged: (_, __) => _fabController.hide(),
          refreshFirst: true,
          clearWhenRefresh: false,
          clearWhenError: false,
          onError: (e) {
            if (_data.isNotEmpty) {
              Fluttertoast.showToast(msg: e.toString());
            }
          },
        ),
        separator: Divider(height: 0, thickness: 1),
        itemBuilder: (c, _, item) => MessageLineView(
          message: item,
          hasRead: _readMessages.contains(item.mid),
          onChanged: () => _loadReadMangas(),
        ),
        extra: UpdatableDataViewExtraWidgets(
          outerTopWidgets: [
            ListHintView.textText(
              leftText: '本应用的所有历史信息',
              rightText: '共 $_total 条 / $_unreadCount 条未读',
            ),
          ],
        ),
      ),
      floatingActionButton: ScrollAnimatedFab(
        controller: _fabController,
        scrollController: _controller,
        condition: ScrollAnimatedCondition.direction,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: null,
          onPressed: () => _controller.scrollToTop(),
        ),
      ),
    );
  }
}
