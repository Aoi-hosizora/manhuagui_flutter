import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/manga_history_line.dart';
import 'package:manhuagui_flutter/service/database/history.dart';
import 'package:manhuagui_flutter/service/state/auth.dart';
import 'package:manhuagui_flutter/service/state/notifiable.dart';

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

class _HistorySubPageState extends State<HistorySubPage> with AutomaticKeepAliveClientMixin, NotifiableMixin {
  ScrollMoreController _controller;
  ScrollFabController _fabController;
  var _data = <MangaHistory>[];
  int _total;
  var _removed = 0;

  @override
  void initState() {
    super.initState();
    _controller = ScrollMoreController();
    _fabController = ScrollFabController();
    AuthState.instance.registerListener(this, () => _controller.refresh());
    widget.action?.addAction('', () => _controller.scrollTop());
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabController.dispose();
    AuthState.instance.unregisterListener(this);
    super.dispose();
  }

  Future<List<MangaHistory>> _getData({int page}) async {
    if (page == 1) {
      _removed = 0; // refresh
    }
    var data = await getHistories(username: AuthState.instance.username, page: page, offset: _removed);
    _total = await getHistoryCount(username: AuthState.instance.username);
    if (mounted) setState(() {});
    return data;
  }

  void _delete({@required MangaHistory history}) {
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

  @override
  String get key => 'HistorySubPage';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: PaginationListView<MangaHistory>(
        controller: _controller,
        data: _data,
        strategy: PaginationStrategy.offsetBased,
        getDataByOffset: _getData,
        initialPage: 1,
        onAppend: (l) {},
        onError: (e) => Fluttertoast.showToast(msg: e.toString()),
        clearWhenRefreshing: false,
        clearWhenError: false,
        updateOnlyIfNotEmpty: false,
        refreshFirst: true,
        placeholderSetting: PlaceholderSetting().toChinese(),
        onStateChanged: (_, __) => _fabController.hide(),
        padding: EdgeInsets.zero,
        separator: Divider(height: 1),
        physics: AlwaysScrollableScrollPhysics(),
        itemBuilder: (c, item) => MangaHistoryLineView(
          history: item,
          onLongPressed: () => _delete(history: item),
        ),
        topWidget: Container(
          color: Colors.white,
          child: Column(
            children: [
              Padding(
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
              Divider(height: 1, thickness: 1),
            ],
          ),
        ),
      ),
      floatingActionButton: ScrollFloatingActionButton(
        scrollController: _controller,
        fabController: _fabController,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: 'HistorySubPage',
          onPressed: () => _controller.scrollTop(),
        ),
      ),
    );
  }
}
