import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/page/manga_dialog.dart';
import 'package:manhuagui_flutter/page/page/subscribe_shelf_cache.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/login_first.dart';
import 'package:manhuagui_flutter/page/view/manga_corner_icons.dart';
import 'package:manhuagui_flutter/page/view/shelf_manga_line.dart';
import 'package:manhuagui_flutter/service/db/shelf_cache.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 订阅-书架
class ShelfSubPage extends StatefulWidget {
  const ShelfSubPage({
    Key? key,
    required this.parentContext,
    this.action,
  }) : super(key: key);

  final BuildContext parentContext;
  final ActionController? action;

  @override
  _ShelfSubPageState createState() => _ShelfSubPageState();
}

class _ShelfSubPageState extends State<ShelfSubPage> with AutomaticKeepAliveClientMixin {
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  VoidCallback? _cancelHandler;

  AuthData? _oldAuthData;
  var _loginChecking = true;
  var _loginCheckError = '';

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _controller.scrollToTop());
    widget.action?.addAction('sync', () => _openPopupMenuForShelfCache());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandler = AuthManager.instance.listen(() => _oldAuthData, (ev) {
        _oldAuthData = AuthManager.instance.authData;
        _loginChecking = false;
        _loginCheckError = ev.error?.text ?? '';
        if (mounted) setState(() {});
        if (AuthManager.instance.logined) {
          WidgetsBinding.instance?.addPostFrameCallback((_) => _pdvKey.currentState?.refresh());
        }
      });
      _loginChecking = true;
      await AuthManager.instance.check();
    });
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    widget.action?.removeAction('sync');
    _cancelHandler?.call();
    _flagStorage.dispose();
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  final _data = <ShelfManga>[];
  late final _flagStorage = MangaCornerFlagsStorage(stateSetter: () => mountedSetState(() {}));
  var _total = 0;

  Future<PagedList<ShelfManga>> _getData({required int page}) async {
    final client = RestClient(DioManager.instance.dio);
    var result = await client.getShelfMangas(token: AuthManager.instance.token, page: page).onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
    _total = result.data.total;
    for (var data in result.data.data) {
      var cache = ShelfCache(mangaId: data.mid, mangaTitle: data.title, mangaCover: data.cover, mangaUrl: data.url, cachedAt: DateTime.now());
      await ShelfCacheDao.addOrUpdateShelfCache(username: AuthManager.instance.username, cache: cache);
      EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: data.mid, inShelf: true));
    }
    await _flagStorage.queryAndStoreFlags(mangaIds: result.data.data.map((e) => e.mid), toQueryShelves: false);
    if (mounted) setState(() {});
    return PagedList(list: result.data.data, next: result.data.page + 1);
  }

  Future<void> _openPopupMenuForShelfCache() async {
    if (!AuthManager.instance.logined) {
      Fluttertoast.showToast(msg: '用户未登录');
      return;
    }

    await showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('同步我的书架'),
        children: [
          IconTextDialogOption(
            icon: Icon(Icons.sync),
            text: Text('同步'),
            onPressed: () async {
              Navigator.of(c).pop();
              ShelfCacheSubPage.syncShelfCaches(context);
            },
          ),
          IconTextDialogOption(
            icon: Icon(Icons.list_alt),
            text: Text('查看已同步的记录'),
            onPressed: () async {
              Navigator.of(c).pop();
              ShelfCacheSubPage.openShelfCachePage(widget.parentContext);
            },
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
          scrollbarMainAxisMargin: 2,
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
        itemBuilder: (c, _, item) => ShelfMangaLineView(
          manga: item,
          onLongPressed: () => showPopupMenuForMangaList(
            context: context,
            mangaId: item.mid,
            mangaTitle: item.title,
            mangaCover: item.cover,
            mangaUrl: item.url,
            mustInShelf: true,
            inShelfSetter: (inShelf) {
              if (!inShelf) {
                _data.removeWhere((el) => el.mid == item.mid); // TODO deal with deleting shelf
                _total--; // TODO removed++
                if (mounted) setState(() {});
              }
            },
          ),
          inDownload: _flagStorage.isInDownload(mangaId: item.mid),
          inFavorite: _flagStorage.isInFavorite(mangaId: item.mid),
          inHistory: _flagStorage.isInHistory(mangaId: item.mid),
        ),
        extra: UpdatableDataViewExtraWidgets(
          outerTopWidgets: [
            ListHintView.textText(
              leftText: '${AuthManager.instance.username} 的书架 (更新时间排序)',
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
