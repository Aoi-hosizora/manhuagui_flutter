import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/manga_history_line.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';

/// 订阅浏览历史
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
  final _controller = ScrollController();
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _fabController = AnimatedFabController();
  CancelHandler? _cancelHandler;

  @override
  void initState() {
    super.initState();
    _cancelHandler = AuthManager.instance.listen(() {
      _pdvKey.currentState?.refresh();
    });
    widget.action?.addAction(() => _controller.scrollToTop());
  }

  @override
  void dispose() {
    _cancelHandler?.call();
    widget.action?.removeAction();
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  final _data = <MangaHistory>[];
  var _total = 0;
  var _removed = 0;

  Future<PagedList<MangaHistory>> _getData({required int page}) async {
    if (page == 1) {
      _removed = 0; // refresh
    }
    var data = await HistoryDao.getHistories(username: AuthManager.instance.username, page: page, offset: _removed);
    _total = await HistoryDao.getHistoryCount(username: AuthManager.instance.username);
    if (mounted) setState(() {});
    return PagedList(list: data, next: page + 1);
  }

  void _delete({required MangaHistory history}) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('删除历史记录'),
        content: Text('是否删除 ${history.mangaTitle}？'),
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
          padding: EdgeInsets.zero,
          placeholderSetting: PlaceholderSetting().copyWithChinese(),
          refreshFirst: true,
          clearWhenError: false,
          clearWhenRefresh: false,
          updateOnlyIfNotEmpty: false,
          onPlaceholderStateChanged: (_, __) => _fabController.hide(),
          onAppend: (l, _) {},
          onError: (e) => Fluttertoast.showToast(msg: e.toString()),
        ),
        separator: Divider(height: 1),
        itemBuilder: (c, _, item) => MangaHistoryLineView(
          history: item,
          onLongPressed: () => _delete(history: item),
        ),
        extra: UpdatableDataViewExtraWidgets(
          innerTopWidgets: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 26,
                    padding: EdgeInsets.only(left: 5),
                    child: Center(
                      child: Text(AuthManager.instance.logined ? '${AuthManager.instance.username} 的浏览历史' : '本地的浏览历史'),
                    ),
                  ),
                  Container(
                    height: 26,
                    padding: EdgeInsets.only(right: 5),
                    child: Center(
                      child: Text('共 $_total 部'),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1),
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
