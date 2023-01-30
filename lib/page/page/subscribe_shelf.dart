import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga_shelf_cache.dart';
import 'package:manhuagui_flutter/page/page/manga_dialog.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/login_first.dart';
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
  final _cancelHandlers = <VoidCallback>[];

  var _currAuthData = AuthManager.instance.authData;
  var _authChecking = true; // initialize to true
  var _authCheckError = '';

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _controller.scrollToTop());
    widget.action?.addAction('sync', () => _showPopupMenuForShelfCache());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandlers.add(AuthManager.instance.listen(() => _currAuthData, (ev) {
        _currAuthData = AuthManager.instance.authData;
        _authChecking = false;
        _authCheckError = ev.error?.text ?? '';
        if (AuthManager.instance.logined) {
          _pdvKey.currentState?.refresh();
        }
        if (mounted) setState(() {});
      }));
      _authChecking = true;
      if (mounted) setState(() {});
      await AuthManager.instance.check();
      _authChecking = false;
      if (mounted) setState(() {});
    });
    _cancelHandlers.add(EventBusManager.instance.listen<ShelfUpdatedEvent>((ev) => _updateByEvent(ev)));
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    widget.action?.removeAction('sync');
    _cancelHandlers.forEach((c) => c.call());
    _flagStorage.dispose();
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  final _data = <ShelfManga>[];
  late final _flagStorage = MangaCornerFlagStorage(stateSetter: () => mountedSetState(() {}));
  var _total = 0;
  var _shelfUpdated = false;

  Future<PagedList<ShelfManga>> _getData({required int page}) async {
    if (page == 1) {
      // refresh
      _shelfUpdated = false;
    }
    final client = RestClient(DioManager.instance.dio);
    var result = await client.getShelfMangas(token: AuthManager.instance.token, page: page).onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
    _total = result.data.total;
    for (var data in result.data.data.reversed) {
      var cache = ShelfCache(mangaId: data.mid, mangaTitle: data.title, mangaCover: data.cover, mangaUrl: data.url, cachedAt: DateTime.now());
      await ShelfCacheDao.addOrUpdateShelfCache(username: AuthManager.instance.username, cache: cache);
      EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: data.mid, added: true));
    }
    await _flagStorage.queryAndStoreFlags(mangaIds: result.data.data.map((e) => e.mid), queryShelves: false);
    if (mounted) setState(() {});
    return PagedList(list: result.data.data, next: result.data.page + 1);
  }

  void _updateByEvent(ShelfUpdatedEvent event) {
    if (event.added) {
      // 新增 => 显示有更新
      _shelfUpdated = true;
      if (mounted) setState(() {});
    }
    if (!event.added && !event.fromShelfPage) {
      // 非本页引起的删除 => 显示有更新
      _shelfUpdated = true;
      if (mounted) setState(() {});
    }
  }

  void _showPopupMenu({required ShelfManga manga}) {
    showPopupMenuForMangaList(
      context: context,
      mangaId: manga.mid,
      mangaTitle: manga.title,
      mangaCover: manga.cover,
      mangaUrl: manga.url,
      fromShelfList: true,
      inShelfSetter: (inShelf) {
        // (更新数据库)、更新界面[↴]、(弹出提示)、(发送通知)
        // 新增 => 显示有更新, 本页引起的更新删除 => 更新列表显示
        if (!inShelf) {
          _data.removeWhere((el) => el.mid == manga.mid);
          _total--; // no "removed++"
          if (mounted) setState(() {});
        }
      },
    );
  }

  Future<void> _showPopupMenuForShelfCache() async {
    if (!AuthManager.instance.logined) {
      Fluttertoast.showToast(msg: '用户未登录');
      return;
    }

    await showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('同步'),
        children: [
          IconTextDialogOption(
            icon: Icon(Icons.sync),
            text: Text('同步我的书架'),
            onPressed: () async {
              Navigator.of(c).pop();
              MangaShelfCachePage.syncShelfCaches(context);
            },
          ),
          IconTextDialogOption(
            icon: Icon(Icons.format_list_bulleted),
            text: Text('查看已同步的记录'),
            onPressed: () async {
              Navigator.of(c).pop();
              Navigator.of(context).push(
                CustomPageRoute(
                  context: context,
                  builder: (c) => MangaShelfCachePage(),
                ),
              );
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
    if (_authChecking || _authCheckError.isNotEmpty || !AuthManager.instance.logined) {
      _data.clear();
      _total = 0;
      _shelfUpdated = false;
      return Scaffold(
        body: LoginFirstView(
          checking: _authChecking,
          error: _authCheckError,
          onErrorRetry: () async {
            _authChecking = true;
            _authCheckError = '';
            if (mounted) setState(() {});
            await AuthManager.instance.check();
          },
        ),
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
          flags: _flagStorage.getFlags(mangaId: item.mid, forceInShelf: true),
          onLongPressed: () => _showPopupMenu(manga: item),
        ),
        extra: UpdatableDataViewExtraWidgets(
          outerTopWidgets: [
            ListHintView.textWidget(
              leftText: '${AuthManager.instance.username} 的书架' + (_shelfUpdated ? ' (有更新)' : ''),
              rightWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('共 $_total 部'),
                  SizedBox(width: 5),
                  HelpIconView.forListHint(
                    title: '我的书架',
                    hint: '"我的书架"与漫画柜网页端保持同步，但受限于网页端功能，"我的书架"只能按照漫画更新时间的倒序显示。',
                    iconData: Icons.error_outline,
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
