import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/login_first.dart';
import 'package:manhuagui_flutter/page/view/shelf_manga_line.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';

/// 订阅书架
class ShelfSubPage extends StatefulWidget {
  const ShelfSubPage({
    Key? key,
    this.action,
  }) : super(key: key);

  final ActionController? action;

  @override
  _ShelfSubPageState createState() => _ShelfSubPageState();
}

class _ShelfSubPageState extends State<ShelfSubPage> with AutomaticKeepAliveClientMixin {
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();

  @override
  void initState() {
    super.initState();

    AuthManager.instance.check();
    EventBusManager.instance.on<AuthChangedEvent>().listen((_) {
      if (AuthManager.instance.logined) {
        if (mounted) setState(() {});
      }
    });

    widget.action?.addAction('', () => _controller.scrollToTop());
  }

  @override
  void dispose() {
    widget.action?.removeAction('');
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  final _data = <ShelfManga>[];
  var _total = 0;

  Future<PagedList<ShelfManga>> _getData({required int page}) async {
    var client = RestClient(DioManager.instance.dio);
    var result = await client.getShelfMangas(token: AuthManager.instance.token, page: page).onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
    _total = result.data.total;
    if (mounted) setState(() {});
    return PagedList(list: result.data.data, next: result.data.page + 1);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!AuthManager.instance.logined) {
      _data.clear();
      return Center(
        child: LoginFirstView(),
      );
    }

    return Scaffold(
      body: PaginationListView<ShelfManga>(
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
          onAppend: (l, _) {
            if (l.length > 0) {
              Fluttertoast.showToast(msg: '新添了 ${l.length} 部漫画');
            }
          },
          onError: (e) => Fluttertoast.showToast(msg: e.toString()),
        ),
        separator: Divider(height: 1),
        itemBuilder: (c, _, item) => ShelfMangaLineView(manga: item),
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
                      child: Text('${AuthManager.instance.username} 订阅的漫画'),
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
