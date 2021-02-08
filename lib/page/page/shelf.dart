import 'package:flutter/material.dart';
import 'package:flutter_ahlib/list.dart';
import 'package:flutter_ahlib/widget.dart';
import 'package:flutter_ahlib/util.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/login_first.dart';
import 'package:manhuagui_flutter/page/view/shelf_manga_line.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';
import 'package:manhuagui_flutter/service/state/auth.dart';

/// 订阅书架
class ShelfSubPage extends StatefulWidget {
  const ShelfSubPage({
    Key key,
    this.action,
  }) : super(key: key);

  final ActionController action;

  @override
  _ShelfSubPageState createState() => _ShelfSubPageState();
}

class _ShelfSubPageState extends State<ShelfSubPage> with AutomaticKeepAliveClientMixin, NotifyReceiverMixin {
  final _controller = ScrollController();
  final _udvController = UpdatableDataViewController();
  final _fabController = AnimatedFabController();
  var _data = <ShelfManga>[];
  int _total;

  @override
  String get receiverKey => 'ShelfSubPage';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthState.instance.logined) {
        if (mounted) setState(() {});
      }
    });
    AuthState.instance.registerDefault(this, () {
      if (mounted) setState(() {});
    });
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

  Future<PagedList<ShelfManga>> _getData({int page}) async {
    var dio = DioManager.instance.dio;
    var client = RestClient(dio);
    ErrorMessage err;
    var result = await client.getShelfMangas(token: AuthState.instance.token, page: page).catchError((e) {
      err = wrapError(e);
    });
    if (err != null) {
      return Future.error(err.text);
    }
    _total = result.data.total;
    if (mounted) setState(() {});
    return PagedList(list: result.data.data, next: result.data.page + 1);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!AuthState.instance.logined) {
      _data.clear();
      return Center(
        child: LoginFirstView(),
      );
    }

    return Scaffold(
      body: PaginationListView<ShelfManga>(
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
          onAppend: (l) {
            if (l.length > 0) {
              Fluttertoast.showToast(msg: '新添了 ${l.length} 部漫画');
            }
          },
          onError: (e) => Fluttertoast.showToast(msg: e.toString()),
        ),
        separator: Divider(height: 1),
        itemBuilder: (c, item) => ShelfMangaLineView(manga: item),
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
                    child: Text('${AuthState.instance.username} 订阅的漫画'),
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
          heroTag: 'ShelfSubPage',
          onPressed: () => _controller.scrollToTop(),
        ),
      ),
    );
  }
}
