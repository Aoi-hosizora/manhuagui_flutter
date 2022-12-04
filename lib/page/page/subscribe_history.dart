import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/manga_history_line.dart';
import 'package:manhuagui_flutter/page/view/setting_dialog.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 订阅-浏览历史
class HistorySubPage extends StatefulWidget {
  const HistorySubPage({
    Key? key,
    this.action,
  }) : super(key: key);

  final ActionController? action;

  @override
  _HistorySubPageState createState() => _HistorySubPageState();
}

class _HistorySubPageState extends State<HistorySubPage> with AutomaticKeepAliveClientMixin {
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  final _cancelHandlers = <VoidCallback>[];
  var _historyUpdated = false;
  AuthData? _oldAuthData;

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _controller.scrollToTop());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandlers.add(AuthManager.instance.listen(() => _oldAuthData, (_) {
        _oldAuthData = AuthManager.instance.authData;
        _pdvKey.currentState?.refresh();
      }));
      await AuthManager.instance.check();
    });
    _cancelHandlers.add(EventBusManager.instance.listen<HistoryUpdatedEvent>((_) {
      _historyUpdated = true;
      if (mounted) setState(() {});
    }));
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    _cancelHandlers.forEach((c) => c.call());
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  final _data = <MangaHistory>[];
  var _total = 0;
  var _removed = 0;

  Future<PagedList<MangaHistory>> _getData({required int page}) async {
    if (page == 1) {
      // refresh
      _removed = 0;
      _historyUpdated = false;
    }
    var username = AuthManager.instance.username; // maybe empty, which represents local history
    var data = await HistoryDao.getHistories(username: username, page: page, offset: _removed) ?? [];
    _total = await HistoryDao.getHistoryCount(username: username) ?? 0;
    if (mounted) setState(() {});
    return PagedList(list: data, next: page + 1);
  }

  void _delete({required MangaHistory history}) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('历史记录刪除确认'),
        content: Text('是否删除阅读历史《${history.mangaTitle}》？'),
        actions: [
          TextButton(
            child: Text('删除'),
            onPressed: () async {
              _data.remove(history);
              _removed++;
              _total--;
              await HistoryDao.deleteHistory(username: AuthManager.instance.username, mid: history.mangaId);
              if (mounted) setState(() {});
              Navigator.of(c).pop();
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
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: PaginationListView<MangaHistory>(
        key: _pdvKey,
        data: _data,
        getData: ({indicator}) => _getData(page: indicator),
        scrollController: _controller,
        paginationSetting: PaginationSetting(
          initialIndicator: 1,
          nothingIndicator: 0,
        ),
        setting: UpdatableDataViewSetting(
          padding: EdgeInsets.symmetric(vertical: 0),
          interactiveScrollbar: true,
          scrollbarCrossAxisMargin: 2,
          placeholderSetting: PlaceholderSetting().copyWithChinese(),
          onPlaceholderStateChanged: (_, __) => _fabController.hide(),
          refreshFirst: true,
          clearWhenRefresh: false,
          clearWhenError: false,
          updateOnlyIfNotEmpty: false,
        ),
        separator: Divider(height: 0, thickness: 1),
        itemBuilder: (c, _, item) => MangaHistoryLineView(
          history: item,
          onLongPressed: () => _delete(history: item),
        ),
        extra: UpdatableDataViewExtraWidgets(
          innerTopWidgets: [
            ListHintView.textWidget(
              leftText: (AuthManager.instance.logined ? '${AuthManager.instance.username} 的浏览历史' : '本地浏览历史') + (_historyUpdated ? ' (有更新)' : ''),
              rightWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('共 $_total 部'),
                  SizedBox(width: 5),
                  HelpIconView(
                    title: '浏览历史',
                    hint: '注意：由于漫画柜官方并未提供漫画浏览历史记录的功能，所以本应用的浏览历史仅被记录在移动端本地，且不同账号的浏览历史互不影响。',
                    useRectangle: true,
                    padding: EdgeInsets.all(3),
                  ),
                ],
              ),
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
