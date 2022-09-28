import 'package:flutter/material.dart';
import 'package:flutter_ahlib/list.dart';
import 'package:flutter_ahlib/widget.dart';
import 'package:flutter_ahlib/util.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/manga_history_line.dart';
import 'package:manhuagui_flutter/service/database/history.dart';
import 'package:manhuagui_flutter/service/state/auth.dart';

/// 订阅浏览历史
class HistorySubPage extends StatefulWidget {
  const HistorySubPage({
    Key key,
    this.action,
  }) : super(key: key);

  final ActionController action;

  @override
  _HistorySubPageState createState() => _HistorySubPageState();
}

class _HistorySubPageState extends State<HistorySubPage> with AutomaticKeepAliveClientMixin, NotifyReceiverMixin {
  final _controller = ScrollController();
  final _udvController = UpdatableDataViewController();
  final _fabController = AnimatedFabController();
  var _data = <MangaHistory>[];
  int _total;
  var _removed = 0;

  @override
  String get receiverKey => "HistorySubPage";

  @override
  void initState() {
    super.initState();
    AuthState.instance.registerDefault(this, () => _udvController.refresh());
    widget.action?.addAction('', () => _controller.scrollToTop());
  }

  @override
  void dispose() {
    AuthState.instance.unregisterDefault(this);
    widget.action?.removeAction('');
    _controller.dispose();
    _udvController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _delete({required MangaHistory history}) {
    assert(history != null);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('删除历史记录'),
        content: Text('是否删除 ${history.mangaTitle}？'),
        actions: [
          FlatButton(
            child: Text('删除'),
            onPressed: () async {
              _data.remove(history);
              _removed++;
              _total--;
              await deleteHistory(username: AuthState.instance.username, mid: history.mangaId);
              if (mounted) setState(() {});
              Navigator.of(c).pop();
            },
          ),
          FlatButton(
            child: Text('取消'),
            onPressed: () => Navigator.of(c).pop(),
          ),
        ],
      ),
    );
  }

  Future<PagedList<MangaHistory>> _getData({int page}) async {
    if (page == 1) {
      _removed = 0; // refresh
    }
    var data = await getHistories(username: AuthState.instance.username, page: page, offset: _removed);
    _total = await getHistoryCount(username: AuthState.instance.username);
    if (mounted) setState(() {});
    return PagedList(list: data, next: page + 1);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: PaginationListView<MangaHistory>(
        data: _data,
        getData: ({indicator}) => _getData(page: indicator),
        controller: _udvController,
        scrollController: _controller,
        paginationSetting: PaginationSetting(
          initialIndicator: 1,
          nothingIndicator: 0,
        ),
        setting: UpdatableDataViewSetting(
          padding: EdgeInsets.zero,
          placeholderSetting: PlaceholderSetting().toChinese(),
          refreshFirst: true,
          clearWhenError: false,
          clearWhenRefresh: false,
          updateOnlyIfNotEmpty: false,
          onStateChanged: (_, __) => _fabController.hide(),
          onAppend: (l) {},
          onError: (e) => Fluttertoast.showToast(msg: e.toString()),
        ),
        separator: Divider(height: 1),
        itemBuilder: (c, item) => MangaHistoryLineView(
          history: item,
          onLongPressed: () => _delete(history: item),
        ),
        extra: UpdatableDataViewExtraWidgets(
          innerTopWidget: Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 26,
                  padding: EdgeInsets.only(left: 5),
                  child: Center(
                    child: Text(AuthState.instance.logined ? '${AuthState.instance.username} 的浏览历史' : '本地的浏览历史'),
                  ),
                ),
                Container(
                  height: 26,
                  padding: EdgeInsets.only(right: 5),
                  child: Center(
                    child: Text('共 ${_total == null ? '?' : _total.toString()} 部'),
                  ),
                ),
              ],
            ),
          ),
          innerTopDivider: Divider(height: 1, thickness: 1),
        ),
      ),
      floatingActionButton: ScrollAnimatedFab(
        controller: _fabController,
        scrollController: _controller,
        condition: ScrollAnimatedCondition.direction,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: 'HistorySubPage',
          onPressed: () => _controller.scrollToTop(),
        ),
      ),
    );
  }
}
