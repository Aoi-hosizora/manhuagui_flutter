import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/message.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/fit_system_screenshot.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/message_line.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/prefs/read_message.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 应用消息页，网络请求并展示 [Message] 信息
class MessagePage extends StatefulWidget {
  const MessagePage({Key? key}) : super(key: key);

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> with FitSystemScreenshotMixin {
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
    await _loadReadMangas(data: result.data.data);

    return result.data.data;
  }

  Future<void> _loadReadMangas({List<Message>? data}) async {
    var messages = await ReadMessagePrefs.getReadMessages();
    _readMessages.clear();
    _readMessages.addAll(messages);

    data ??= _data;
    _unreadCount = data.length - data.where((msg) => _readMessages.contains(msg.mid)).length;
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
              var r = await ReadMessagePrefs.addReadMessages(_data.map((m) => m.mid).toList());
              _readMessages.clear();
              _readMessages.addAll(r);
              _unreadCount = 0;
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
              await ReadMessagePrefs.clearReadMessages();
              _readMessages.clear();
              _unreadCount = _data.length;
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
  FitSystemScreenshotData get fitSystemScreenshotData => FitSystemScreenshotData(
        scrollViewKey: _rdvKey,
        scrollController: _controller,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('应用消息'),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: false),
        actions: [
          AppBarActionButton(
            icon: Icon(MdiIcons.bellCheck),
            tooltip: '全部标记为已阅读',
            onPressed: () => _markAllAsHasRead(context),
          ),
          AppBarActionButton(
            icon: Icon(MdiIcons.bellPlus),
            tooltip: '全部标记为未阅读',
            onPressed: () => _markAllAsUnread(context),
          ),
        ],
      ),
      drawer: AppDrawer(
        currentSelection: DrawerSelection.none,
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: RefreshableListView<Message>(
        key: _rdvKey,
        data: _data,
        getData: () => _getData(),
        scrollController: _controller,
        setting: UpdatableDataViewSetting(
          padding: EdgeInsets.symmetric(vertical: 0),
          interactiveScrollbar: true,
          scrollbarMainAxisMargin: 2,
          scrollbarCrossAxisMargin: 2,
          placeholderSetting: PlaceholderSetting().copyWithChinese(),
          onPlaceholderStateChanged: (_, __) => _fabController.hide(),
          refreshFirst: true /* <<< refresh first */,
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
      ).fitSystemScreenshot(this),
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
