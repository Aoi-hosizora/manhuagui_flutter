import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/page/manga_dialog.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/shelf_cache_line.dart';
import 'package:manhuagui_flutter/service/db/query_helper.dart';
import 'package:manhuagui_flutter/service/db/shelf_cache.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 已同步的书架记录页，展示所给 [ShelfCache] 列表信息，并提供删除功能以及**同步书架缓存**功能
class MangaShelfCachePage extends StatefulWidget {
  const MangaShelfCachePage({Key? key}) : super(key: key);

  @override
  State<MangaShelfCachePage> createState() => _MangaShelfCachePageState();

  /// 同步书架缓存，在 [ShelfSubPage] 使用
  static Future<void> syncShelfCaches(BuildContext context, {void Function()? onFinish, bool fromShelfCachePage = false}) async {
    var caches = <ShelfCache>[];
    var currPage = 1;
    int? totalPages;
    var canceled = false;
    String? error;

    var ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => WillPopScope(
        onWillPop: () async => false,
        child: StatefulWidgetWithCallback.builder(
          postFrameCallbackForInitState: (_, _setState) => Future.microtask(
            () async {
              // !!!
              try {
                final client = RestClient(DioManager.instance.dio);
                while (!canceled) {
                  var result = await client.getShelfMangas(token: AuthManager.instance.token, page: currPage);
                  for (var item in result.data.data) {
                    if (canceled) {
                      break; // Concurrent modification during iteration: Instance(length:40) of '_GrowableList'
                    }
                    caches.add(ShelfCache(mangaId: item.mid, mangaTitle: item.title, mangaCover: item.cover, mangaUrl: item.url, cachedAt: DateTime.now()));
                  }

                  totalPages = (result.data.total / result.data.limit).ceil();
                  if (currPage >= totalPages!) {
                    break;
                  }
                  currPage++;
                  _setState(() {});
                  await Future.delayed(Duration(milliseconds: 500)); // 额外等待 0.5s
                  continue;
                }
              } catch (e, s) {
                error = wrapError(e, s).text; // 记录错误，但不等价于操作被取消
              } finally {
                if (!canceled) {
                  Navigator.of(c).pop(true); // 循环非被结束则需关闭"正在处理"对话框
                }
              }
            },
          ),
          builder: (_, _setState) => AlertDialog(
            title: Text('同步书架记录'),
            contentPadding: EdgeInsets.zero,
            content: SizedBox(
              width: getDialogMaxWidth(context),
              child: CircularProgressDialogOption(
                progress: CircularProgressIndicator(),
                child: Text('正在处理第 $currPage/${totalPages ?? '?'} 页 (已获得 ${caches.length} 项)...'),
              ),
            ),
            actions: [
              TextButton(
                child: Text('结束'),
                onPressed: () {
                  canceled = true;
                  Navigator.of(c).pop(true); // 操作被请求结束，同时结束处理循环
                },
              ),
              TextButton(
                child: Text('取消'),
                onPressed: () {
                  canceled = true;
                  Navigator.of(c).pop(false); // 操作被取消，同时结束处理循环
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (ok != true) {
      Fluttertoast.showToast(msg: '操作已取消');
      return;
    }
    if (error != null) {
      var ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('同步书架记录'),
          content: Text(
            '同步过程中发生错误：$error。' + //
                (caches.isEmpty ? '' : '\n是否继续执行已获得的 ${caches.length} 项记录的同步？'),
          ),
          actions: [
            if (caches.isNotEmpty) TextButton(child: Text('继续'), onPressed: () => Navigator.of(c).pop(true)),
            TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
          ],
        ),
      );
      if (ok != true) {
        if (caches.isNotEmpty) {
          Fluttertoast.showToast(msg: '操作已取消'); // 操作被取消，选择不继续
        }
        return;
      }
    }

    var newCaches = caches.toList(); // 拷贝一份，防止在更新数据库中途，列表被修改
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Text('同步书架记录'),
          contentPadding: EdgeInsets.zero,
          content: CircularProgressDialogOption(
            progress: CircularProgressIndicator(),
            child: Text('共获得 ${newCaches.length} 项记录，正在处理...'),
          ),
        ),
      ),
    );

    // !!!
    for (var i = newCaches.length - 1; i >= 0; i--) {
      newCaches[i] = newCaches[i].copyWith(cachedAt: DateTime.now()); // reversed, 书架上越老更新的漫画同步时间设置得越先
    }
    var oldCaches = await ShelfCacheDao.getShelfCaches(username: AuthManager.instance.username, page: null) ?? [];
    var canDelete = !canceled && error == null; // 如果非取消且非错误，则删除已被移出书架的记录
    if (canDelete) {
      // >>> 删除不存在的记录
      var toDelete = oldCaches.where((el) => newCaches.where((el2) => el2.mangaId == el.mangaId).isEmpty).toList();
      for (var item in toDelete) {
        await ShelfCacheDao.deleteShelfCache(username: AuthManager.instance.username, mangaId: item.mangaId);
        EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: item.mangaId, added: false, fromShelfCachePage: fromShelfCachePage));
      }
    }
    // >>> 更新所有新记录
    for (var item in newCaches) {
      await ShelfCacheDao.addOrUpdateShelfCache(username: AuthManager.instance.username, cache: item);
      EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: item.mangaId, added: true, fromShelfCachePage: fromShelfCachePage));
    }
    Navigator.of(context).pop(); // 关闭"正在处理"对话框
    onFinish?.call();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('同步书架记录'),
        content: Text('已完成 ${newCaches.length} 项书架记录的同步' + (!canDelete ? '。' : '，且已删除所有被移出书架的漫画。')),
        actions: [
          TextButton(
            child: Text('确定'),
            onPressed: () => Navigator.of(c).pop(),
          ),
        ],
      ),
    );
  }
}

class _MangaShelfCachePageState extends State<MangaShelfCachePage> {
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandlers.add(AuthManager.instance.listenOnlyWhen(Tuple1(AuthManager.instance.authData), (_) {
        _searchKeyword = ''; // 清空搜索关键词
        if (mounted) setState(() {});
        _pdvKey.currentState?.refresh();
      }));
      await AuthManager.instance.check();
    });
    _cancelHandlers.add(EventBusManager.instance.listen<ShelfCacheUpdatedEvent>((ev) => _updateByEvent(ev)));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  final _data = <ShelfCache>[];
  var _total = 0;
  var _removed = 0; // for query offset
  var _searchKeyword = ''; // for query condition
  var _searchTitleOnly = true; // for query condition
  var _sortMethod = SortMethod.byTimeDesc; // for query condition
  var _isUpdated = false;

  Future<PagedList<ShelfCache>> _getData({required int page}) async {
    if (page == 1) {
      // refresh
      _removed = 0;
      _isUpdated = false;
    }
    var username = AuthManager.instance.username;
    var data = await ShelfCacheDao.getShelfCaches(username: username, keyword: _searchKeyword, pureSearch: _searchTitleOnly, sortMethod: _sortMethod, page: page, offset: _removed) ?? [];
    _total = await ShelfCacheDao.getShelfCacheCount(username: username, keyword: _searchKeyword, pureSearch: _searchTitleOnly) ?? 0;
    if (mounted) setState(() {});
    return PagedList(list: data, next: page + 1);
  }

  void _updateByEvent(ShelfCacheUpdatedEvent event) async {
    if (event.added && !event.fromShelfCachePage) {
      // 非本页引起的新增 => 显示有更新
      _isUpdated = true;
      if (mounted) setState(() {});
    }
    if (!event.added && !event.fromShelfCachePage) {
      // 非本页引起的删除 => 显示有更新
      _isUpdated = true;
      if (mounted) setState(() {});
    }
  }

  Future<void> _toSearch() async {
    var result = await showKeywordDialogForSearching(
      context: context,
      title: '搜索已同步的书架计划',
      defaultText: _searchKeyword,
      optionTitle: '仅搜索漫画标题',
      optionValue: _searchTitleOnly,
      optionHint: (only) => only ? '当前选项使得本次仅搜索漫画标题' : '当前选项使得本次将搜索漫画ID以及漫画标题',
    );
    if (result != null && result.item1.isNotEmpty) {
      _searchKeyword = result.item1;
      _searchTitleOnly = result.item2;
      if (mounted) setState(() {});
      _pdvKey.currentState?.refresh();
    }
  }

  void _exitSearch() {
    _searchKeyword = ''; // 清空搜索关键词
    if (mounted) setState(() {});
    _pdvKey.currentState?.refresh();
  }

  Future<void> _toSort() async {
    var sort = await showSortMethodDialogForSorting(
      context: context,
      title: '漫画排序方式',
      defaultValue: _sortMethod,
      idTitle: '漫画ID',
      nameTitle: '漫画标题',
      timeTitle: '同步时间',
      orderTitle: null,
    );
    if (sort != null && sort != _sortMethod) {
      _sortMethod = sort;
      if (mounted) setState(() {});
      _pdvKey.currentState?.refresh();
    }
  }

  Future<void> _deleteCache({required int mangaId}) async {
    // 更新数据库、更新界面、发送通知
    await ShelfCacheDao.deleteShelfCache(username: AuthManager.instance.username, mangaId: mangaId);
    _data.removeWhere((el) => el.mangaId == mangaId);
    _total--;
    if (mounted) setState(() {});
    EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: mangaId, added: false, fromShelfCachePage: true));
  }

  Future<void> _clearCaches() async {
    if (_data.isEmpty) {
      return;
    }
    var ok = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('清空确认'),
        content: Text('是否清空所有已同步的书架记录？'),
        actions: [
          TextButton(child: Text('清空'), onPressed: () => Navigator.of(c).pop(true)),
          TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
        ],
      ),
    );
    if (ok != true) {
      return;
    }

    // 更新数据库、更新界面、发送通知
    await ShelfCacheDao.clearShelfCaches(username: AuthManager.instance.username);
    var mangaIds = _data.map((el) => el.mangaId).toList();
    _data.clear();
    _total = 0;
    if (mounted) setState(() {});
    for (var mangaId in mangaIds) {
      EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: mangaId, added: false, fromShelfCachePage: true));
    }
  }

  void _syncShelves() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('同步确认'),
        content: Text('是否检索并同步我的书架到本地？'),
        actions: [
          TextButton(
            child: Text('同步'),
            onPressed: () {
              Navigator.of(c).pop();
              MangaShelfCachePage.syncShelfCaches(
                context,
                onFinish: () => _pdvKey.currentState?.refresh(),
                fromShelfCachePage: true,
              );
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

  void _showPopupMenu(ShelfCache cache) {
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(cache.mangaTitle),
        children: [
          IconTextDialogOption(
            icon: Icon(Icons.description_outlined),
            text: Text('查看该漫画'),
            onPressed: () {
              Navigator.of(c).pop();
              Navigator.of(context).push(
                CustomPageRoute(
                  context: context,
                  builder: (c) => MangaPage(
                    id: cache.mangaId,
                    title: cache.mangaTitle,
                    url: cache.mangaUrl,
                  ),
                ),
              );
            },
          ),
          IconTextDialogOption(
            icon: Icon(Icons.delete),
            text: Text('删除该记录'),
            onPressed: () async {
              Navigator.of(c).pop();
              await _deleteCache(mangaId: cache.mangaId);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_searchKeyword.isNotEmpty) {
          _exitSearch();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('已同步的书架记录'),
          leading: AppBarActionButton.leading(context: context, allowDrawerButton: false),
          actions: [
            if (_searchKeyword.isNotEmpty)
              AppBarActionButton(
                icon: Icon(Icons.search_off),
                tooltip: '退出搜索',
                onPressed: () => _exitSearch(),
              ),
            AppBarActionButton(
              icon: Icon(Icons.sync),
              tooltip: '同步我的书架',
              onPressed: () => _syncShelves(),
            ),
            PopupMenuButton(
              child: Builder(
                builder: (c) => AppBarActionButton(
                  icon: Icon(Icons.more_vert),
                  tooltip: '更多选项',
                  onPressed: () => c.findAncestorStateOfType<PopupMenuButtonState>()?.showButtonMenu(),
                ),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  child: IconTextMenuItem(Icons.delete, '清空所有书架记录'),
                  onTap: () => WidgetsBinding.instance?.addPostFrameCallback((_) => _clearCaches()),
                ),
                PopupMenuItem(
                  child: IconTextMenuItem(Icons.search, '搜索列表中的漫画'),
                  onTap: () => WidgetsBinding.instance?.addPostFrameCallback((_) => _toSearch()),
                ),
                if (_searchKeyword.isNotEmpty)
                  PopupMenuItem(
                    child: IconTextMenuItem(Icons.search_off, '退出搜索'),
                    onTap: () => _exitSearch(),
                  ),
                PopupMenuItem(
                  child: IconTextMenuItem(Icons.sort, '漫画排序方式'),
                  onTap: () => WidgetsBinding.instance?.addPostFrameCallback((_) => _toSort()),
                ),
              ],
            ),
          ],
        ),
        drawer: AppDrawer(
          currentSelection: DrawerSelection.none,
        ),
        drawerEdgeDragWidth: MediaQuery.of(context).size.width,
        body: PaginationListView<ShelfCache>(
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
            refreshFirst: true /* <<< refresh first */,
            clearWhenRefresh: false,
            clearWhenError: false,
            updateOnlyIfNotEmpty: false,
          ),
          separator: Divider(height: 0, thickness: 1),
          itemBuilder: (c, _, item) => ShelfCacheLineView(
            manga: item,
            onPressed: () => _showPopupMenu(item),
            onLongPressed: () => _showPopupMenu(item),
          ),
          extra: UpdatableDataViewExtraWidgets(
            outerTopWidgets: [
              ListHintView.textWidget(
                leftText: '${AuthManager.instance.username} 的书架记录' + //
                    (_searchKeyword.isNotEmpty ? ' ("$_searchKeyword" 的搜索结果)' : (_isUpdated ? ' (有更新)' : '')),
                rightWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('共 $_total 部'),
                    SizedBox(width: 5),
                    HelpIconView.forListHint(
                      title: '已同步的书架记录',
                      hint: '书架记录同步功能仅用于判断漫画是否在书架上，并用于显示漫画列表右下角的书架图标。',
                      tooltip: '提示',
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
      ),
    );
  }
}
