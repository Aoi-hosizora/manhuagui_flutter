import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/login_first.dart';
import 'package:manhuagui_flutter/page/view/shelf_manga_line.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';
import 'package:manhuagui_flutter/service/state/auth.dart';
import 'package:manhuagui_flutter/service/state/notifiable.dart';

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

class _ShelfSubPageState extends State<ShelfSubPage> with AutomaticKeepAliveClientMixin, NotifiableMixin {
  ScrollMoreController _controller;
  ScrollFabController _fabController;
  var _data = <ShelfManga>[];
  int _total;

  @override
  void initState() {
    super.initState();
    _controller = ScrollMoreController();
    _fabController = ScrollFabController();
    widget.action?.addAction('', () => print('ShelfSubPage'));
    AuthState.instance.registerListener(this, () => mountedSetState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthState.instance.logined) {
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabController.dispose();
    AuthState.instance.unregisterListener(this);
    super.dispose();
  }

  Future<List<ShelfManga>> _getData({int page}) async {
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
    return result.data.data;
  }

  @override
  String get key => 'SubscribeSubPage';

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
        controller: _controller,
        data: _data,
        strategy: PaginationStrategy.offsetBased,
        getDataByOffset: _getData,
        initialPage: 1,
        onAppend: (l) => doIf(l.length > 0, () => Fluttertoast.showToast(msg: '新添了 ${l.length} 部漫画')),
        onError: (e) => Fluttertoast.showToast(msg: e.toString()),
        clearWhenRefreshing: false,
        clearWhenError: false,
        updateOnlyIfNotEmpty: false,
        refreshFirst: true,
        placeholderSetting: PlaceholderSetting().toChinese(),
        onStateChanged: (_, __) => _fabController.hide(),
        padding: EdgeInsets.zero,
        separator: Divider(height: 1),
        itemBuilder: (c, item) => ShelfMangaLineView(manga: item),
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
                        child: Text('全部漫画 (共 ${_total == null ? '?' : _total.toString()} 部)'),
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
          heroTag: 'ShelfSubPage',
          onPressed: () => _controller.scrollTop(),
        ),
      ),
    );
  }
}
