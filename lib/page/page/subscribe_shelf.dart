import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/dlg/manga_dialog.dart';
import 'package:manhuagui_flutter/page/manga_shelf_cache.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/login_first.dart';
import 'package:manhuagui_flutter/page/view/shelf_manga_line.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
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
    this.isSepPage = false,
  }) : super(key: key);

  final ActionController? action;
  final bool isSepPage;

  @override
  _ShelfSubPageState createState() => _ShelfSubPageState();
}

class _ShelfSubPageState extends State<ShelfSubPage> with AutomaticKeepAliveClientMixin {
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _controller.scrollToTop());
    widget.action?.addAction('sync', () => _showPopupMenuForShelfCache());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandlers.add(AuthManager.instance.listen((ev) => _updateByAuthEvent(ev))); // !!! with checking AuthManager.instance.authData
      await AuthManager.instance.check();
    });
    _cancelHandlers.add(EventBusManager.instance.listen<ShelfUpdatedEvent>((ev) => _updateByEvent(ev)));
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    widget.action?.removeAction('sync');
    _cancelHandlers.forEach((c) => c.call());
    _controller.dispose();
    _fabController.dispose();
    _flagStorage.dispose();
    super.dispose();
  }

  var _authChecking = !AuthManager.instance.logined; // initialize to true when not logined
  var _authData = AuthManager.instance.authData;
  var _authError = '';

  void _updateByAuthEvent(AuthChangedEvent event) {
    if (_authChecking) {
      _authChecking = false;
      if (mounted) setState(() {});
    }
    if (AuthManager.instance.authData.equals(_authData)) {
      return;
    }

    _authData = AuthManager.instance.authData;
    _authError = event.error?.text ?? '';
    if (_authError.isNotEmpty) {
      return;
    }

    if (!AuthManager.instance.logined) {
      _data.clear();
      _total = 0;
      _isUpdated = false;
    } else {
      // 登录状态变更，刷新列表
      WidgetsBinding.instance?.addPostFrameCallback((_) => _pdvKey.currentState?.refresh());
    }
    if (mounted) setState(() {});
  }

  final _data = <ShelfManga>[];
  var _total = 0;
  late final _flagStorage = MangaCornerFlagStorage(stateSetter: () => mountedSetState(() {}), ignoreShelves: true);
  var _useLocalHistory = false;
  final _histories = <int, MangaHistory?>{};
  var _isUpdated = false;

  Future<PagedList<ShelfManga>> _getData({required int page}) async {
    if (page == 1) {
      // refresh
      _isUpdated = false;
    }
    final client = RestClient(DioManager.instance.dio);
    var result = await client.getShelfMangas(token: AuthManager.instance.token, page: page).onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
    _total = result.data.total;
    Future.microtask(() async {
      for (var data in result.data.data.reversed /* reversed, 书架上越老更新的漫画同步时间设置得越先 */) {
        var cache = ShelfCache(mangaId: data.mid, mangaTitle: data.title, mangaCover: data.cover, mangaUrl: data.url, cachedAt: DateTime.now());
        await ShelfCacheDao.addOrUpdateShelfCache(username: AuthManager.instance.username, cache: cache);
        EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: data.mid, added: true));
      }
    });
    for (var item in result.data.data) {
      _histories[item.mid] = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: item.mid);
    }
    if (mounted) setState(() {});
    _flagStorage.queryAndStoreFlags(mangaIds: result.data.data.map((e) => e.mid), queryShelves: false).then((_) => mountedSetState(() {}));
    return PagedList(list: result.data.data, next: result.data.page + 1);
  }

  void _updateByEvent(ShelfUpdatedEvent event) {
    if (event.added) {
      // 新增 => 显示有更新
      _isUpdated = true;
      if (mounted) setState(() {});
    }
    if (!event.added && !event.fromShelfPage) {
      // 非本页引起的删除 => 显示有更新
      _isUpdated = true;
      if (mounted) setState(() {});
    }
    if (!widget.isSepPage && event.fromSepShelfPage) {
      // 单独页引起的变更 => 显示有更新 (仅限主页子页)
      _isUpdated = true;
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
      extraData: MangaExtraDataForDialog.fromShelfManga(manga),
      fromShelfList: true,
      inShelfSetter: (inShelf) {
        // (更新数据库)、更新界面[↴]、(弹出提示)、(发送通知)
        // 本页引起的删除 => 更新列表显示
        if (!inShelf) {
          _data.removeWhere((el) => el.mid == manga.mid);
          _total--; // no "removed++"
          if (mounted) setState(() {});

          // 独立页时发送额外通知，让主页子页显示有更新
          if (widget.isSepPage) {
            EventBusManager.instance.fire(ShelfUpdatedEvent(mangaId: manga.mid, added: false, fromShelfPage: true, fromSepShelfPage: true));
          }
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
          IconTextDialogOption(
            icon: Icon(CustomIcons.bookmark_plus),
            text: Text('添加所有记录至本地收藏'),
            onPressed: () async {
              Navigator.of(c).pop();
              MangaShelfCachePage.addAllToFavorite(context);
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
    if (_authChecking || _authError.isNotEmpty || !AuthManager.instance.logined) {
      _data.clear();
      _total = 0;
      _isUpdated = false;
      return Scaffold(
        body: LoginFirstView(
          checking: _authChecking,
          error: _authError,
          onErrorRetry: () async {
            _authChecking = true;
            _authError = '';
            if (mounted) setState(() {});
            await AuthManager.instance.check();
          },
        ),
      );
    }

    return Scaffold(
      body: PaginationDataView<ShelfManga>(
        key: _pdvKey,
        style: !AppSetting.instance.ui.showTwoColumns ? UpdatableDataViewStyle.listView : UpdatableDataViewStyle.gridView,
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
          refreshFirst: true /* <<< refresh first */,
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
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 0.0,
          mainAxisSpacing: 0.0,
          childAspectRatio: GeneralLineView.getChildAspectRatioForTwoColumns(context),
        ),
        itemBuilder: (c, _, item) => ShelfMangaLineView(
          manga: item,
          history: _histories[item.mid],
          useLocalHistory: _useLocalHistory,
          flags: _flagStorage.getFlags(mangaId: item.mid, forceInShelf: true),
          twoColumns: AppSetting.instance.ui.showTwoColumns,
          highlightRecent: AppSetting.instance.ui.highlightRecentMangas,
          onLongPressed: () => _showPopupMenu(manga: item),
        ),
        extra: UpdatableDataViewExtraWidgets(
          outerTopWidgets: [
            ListHintView.textWidget(
              padding: EdgeInsets.fromLTRB(10, 5, 10 - 3, 5), // for popup btn
              leftText: '${AuthManager.instance.username} 的书架' + (_isUpdated ? ' (有更新)' : ''),
              rightWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('共 $_total 部'),
                  SizedBox(width: 5),
                  HelpIconView.forListHint(
                    title: '我的书架',
                    hint: '"我的书架"与漫画柜网页端保持同步，但受限于网页端功能，"我的书架"只能按照漫画更新时间的逆序显示。\n\n'
                        '提示：本页书架列表上显示的阅读记录来源于${_useLocalHistory ? '本地' : '在线'}的阅读历史，该数据${_useLocalHistory ? '跨设备不同步' : '跨设备同步'}。',
                    tooltip: '提示',
                  ),
                  PopupMenuButton(
                    child: Builder(
                      builder: (c) => HelpIconView.asButton(
                        iconData: Icons.more_vert,
                        tooltip: '更多选项',
                        onPressed: () => c.findAncestorStateOfType<PopupMenuButtonState>()?.showButtonMenu(),
                      ),
                    ),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        child: IconTextMenuItem(
                          _useLocalHistory ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                          '使用本地的阅读历史',
                        ),
                        onTap: () {
                          _useLocalHistory = !_useLocalHistory;
                          if (mounted) setState(() {});
                          // _pdvKey.currentState?.refresh();
                        },
                      ),
                      PopupMenuItem(
                        enabled: false,
                        child: IconTextMenuItem(Icons.search, '无法搜索书架上的漫画', color: Colors.grey),
                        onTap: () {},
                      ),
                    ],
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
