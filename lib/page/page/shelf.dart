import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/login_first.dart';
import 'package:manhuagui_flutter/page/view/shelf_manga_line.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';

/// 订阅-书架
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
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  VoidCallback? _cancelHandler;

  var _loginChecking = true;
  var _loginCheckError = '';

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _controller.scrollToTop());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandler = AuthManager.instance.listen((ev) {
        _loginChecking = false;
        _loginCheckError = ev.error?.text ?? '';
        if (mounted) setState(() {});
        if (AuthManager.instance.logined) {
          WidgetsBinding.instance?.addPostFrameCallback((_) => _pdvKey.currentState?.refresh());
        }
      });
      _loginChecking = true;
      await AuthManager.instance.check();
      // _loginChecking = false;
      // if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    _cancelHandler?.call();
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  final _data = <ShelfManga>[];
  var _total = 0;

  Future<PagedList<ShelfManga>> _getData({required int page}) async {
    final client = RestClient(DioManager.instance.dio);
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
    if (_loginChecking || _loginCheckError.isNotEmpty || !AuthManager.instance.logined) {
      _data.clear();
      return LoginFirstView(
        checking: _loginChecking,
        error: _loginCheckError,
        onErrorRetry: () async {
          _loginChecking = true;
          _loginCheckError = '';
          if (mounted) setState(() {});
          await AuthManager.instance.check();
          // _loginChecking = false;
          // if (mounted) setState(() {});
        },
      );
    }

    return Scaffold(
      body: PaginationListView<ShelfManga>(
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
          onError: (e) {
            if (_data.isNotEmpty) {
              Fluttertoast.showToast(msg: e.toString());
            }
          },
        ),
        separator: Divider(height: 0, thickness: 1),
        itemBuilder: (c, _, item) => ShelfMangaLineView(manga: item),
        extra: UpdatableDataViewExtraWidgets(
          innerTopWidgets: [
            ListHintView.textText(
              leftText: '${AuthManager.instance.username} 订阅的漫画',
              rightText: '共 $_total 部',
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
