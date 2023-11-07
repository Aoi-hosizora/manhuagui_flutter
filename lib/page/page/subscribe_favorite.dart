import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/dlg/list_assist_dialog.dart';
import 'package:manhuagui_flutter/page/dlg/manga_dialog.dart';
import 'package:manhuagui_flutter/page/favorite_all.dart';
import 'package:manhuagui_flutter/page/favorite_author.dart';
import 'package:manhuagui_flutter/page/favorite_group.dart';
import 'package:manhuagui_flutter/page/favorite_reorder.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/favorite_manga_line.dart';
import 'package:manhuagui_flutter/page/view/fit_system_screenshot.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/multi_selection_fab.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/db/query_helper.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 订阅-收藏
class FavoriteSubPage extends StatefulWidget {
  const FavoriteSubPage({
    Key? key,
    this.action,
    this.isSepPage = false,
  }) : super(key: key);

  final ActionController? action;
  final bool isSepPage;

  @override
  _FavoriteSubPageState createState() => _FavoriteSubPageState();
}

class _FavoriteSubPageState extends State<FavoriteSubPage> with AutomaticKeepAliveClientMixin, FitSystemScreenshotMixin {
  final _scaffoldKey = GlobalKey<DrawerScaffoldState>();
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _scrollViewKey = GlobalKey();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  final _msController = MultiSelectableController<ValueKey<int>>();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _controller.scrollToTop());
    widget.action?.addAction('manage', () => _scaffoldKey.currentState?.let((s) => !s.isEndDrawerOpen ? s.openEndDrawer() : Navigator.of(context).pop()));
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandlers.add(AuthManager.instance.listenOnlyWhen(Tuple1(AuthManager.instance.authData), (_) {
        _searchKeyword = ''; // 清空搜索关键词
        if (mounted) setState(() {});
        _pdvKey.currentState?.refresh();
      }));
      await AuthManager.instance.check();
    });
    _cancelHandlers.add(EventBusManager.instance.listen<FavoriteUpdatedEvent>((ev) => _updateByEvent(ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<FavoriteOrderUpdatedEvent>((ev) => _updateOrderByEvent(ev)));
    _cancelHandlers.add(EventBusManager.instance.listen<FavoriteGroupUpdatedEvent>((ev) => _updateGroupsByEvent(ev)));
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    widget.action?.removeAction('manage');
    _cancelHandlers.forEach((c) => c.call());
    _controller.dispose();
    _fabController.dispose();
    _msController.dispose();
    _flagStorage.dispose();
    super.dispose();
  }

  List<FavoriteGroup>? _groups;
  Map<String, int>? _groupsLengths;
  int? _allMangasCount;
  var _currentGroup = '';

  final _data = <FavoriteManga>[];
  var _total = 0;
  var _removed = 0; // for query offset
  late final _flagStorage = MangaCornerFlagStorage(stateSetter: () => mountedSetState(() {}), ignoreFavorites: true);
  var _searchKeyword = ''; // for query condition
  var _searchTitleOnly = true; // for query condition
  var _sortMethod = SortMethod.byOrderAsc; // for query condition
  var _isUpdated = false;

  Future<PagedList<FavoriteManga>> _getData({required int page}) async {
    if (page == 1) {
      // refresh
      _groups = null;
      _groupsLengths = null;
      _allMangasCount = null;
      _removed = 0;
      _isUpdated = false;
    }
    var username = AuthManager.instance.username;
    var data = await FavoriteDao.getFavorites(username: username, groupName: _currentGroup, keyword: _searchKeyword, pureSearch: _searchTitleOnly, sortMethod: _sortMethod, page: page, offset: _removed) ?? [];
    _total = await FavoriteDao.getFavoriteCount(username: username, groupName: _currentGroup, keyword: _searchKeyword, pureSearch: _searchTitleOnly) ?? 0;
    _groups ??= await FavoriteDao.getGroups(username: username);
    _groupsLengths ??= await FavoriteDao.getGroupsLengths(username: username);
    _allMangasCount ??= await FavoriteDao.getFavoriteCount(username: username, groupName: null) ?? 0;
    if (mounted) setState(() {});
    _flagStorage.queryAndStoreFlags(mangaIds: data.map((e) => e.mangaId), queryFavorites: false).then((_) => mountedSetState(() {}));
    return PagedList(list: data, next: page + 1);
  }

  void _updateByEvent(FavoriteUpdatedEvent event) async {
    // 更新分组显示数量
    if (event.reason == UpdateReason.added || event.reason == UpdateReason.deleted) {
      var flag = (event.reason == UpdateReason.added ? 1 : (event.reason == UpdateReason.deleted ? -1 : 0));
      _groupsLengths?[event.group] = (_groupsLengths?[event.group] ?? 0) + flag;
      _allMangasCount = (_allMangasCount ?? 0) + flag;
      if (mounted) setState(() {});
    }

    if (_currentGroup != event.group && _currentGroup != event.oldGroup /* not null only when manga's group is updated */) {
      return; // 未影响当前分组 => 忽略
    }

    if (event.reason == UpdateReason.added) {
      // 新增 => 显示有更新
      _isUpdated = true;
      if (mounted) setState(() {});
    }
    if (event.reason == UpdateReason.updated && !event.fromFavoritePage) {
      // 非本页引起的更新 => 显示有更新
      _isUpdated = true;
      if (mounted) setState(() {});
    }
    if (event.reason == UpdateReason.deleted && !event.fromFavoritePage) {
      // 非本页引起的删除 => 显示有更新
      _isUpdated = true;
      if (mounted) setState(() {});
    }
    if (!widget.isSepPage && event.fromSepFavoritePage) {
      // 单独页引起的变更 => 显示有更新 (仅限主页子页)
      _isUpdated = true;
      if (mounted) setState(() {});
    }
  }

  Future<void> _toSearch() async {
    var result = await showKeywordDialogForSearching(
      context: context,
      title: '搜索已收藏的漫画',
      textValue: _searchKeyword,
      optionTitle: '仅搜索漫画标题',
      optionValue: _searchTitleOnly,
      optionHint: (only) => only ? '当前选项使得本次仅搜索漫画标题' : '当前选项使得本次将搜索漫画ID、漫画标题以及收藏备注',
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
      currValue: _sortMethod,
      idTitle: '漫画ID',
      nameTitle: '漫画标题',
      timeTitle: '收藏时间',
      orderTitle: '收藏顺序',
      defaultMethod: SortMethod.byOrderAsc,
    );
    if (sort != null && sort != _sortMethod) {
      _sortMethod = sort;
      if (mounted) setState(() {});
      _pdvKey.currentState?.refresh();
    }
  }

  void _exitSort() {
    _sortMethod = SortMethod.byOrderAsc; // 默认排序方式
    if (mounted) setState(() {});
    _pdvKey.currentState?.refresh();
  }

  void _showPopupMenu({required int mangaId}) {
    var favorite = _data.where((el) => el.mangaId == mangaId).firstOrNull;
    if (favorite == null) {
      return;
    }

    // 退出多选模式、弹出菜单
    _msController.exitMultiSelectionMode();
    showPopupMenuForMangaList(
      context: context,
      mangaId: favorite.mangaId,
      mangaTitle: favorite.mangaTitle,
      mangaCover: favorite.mangaCover,
      mangaUrl: favorite.mangaUrl,
      extraData: null,
      fromFavoriteList: true,
      inFavoriteSetter: (inFavorite) {
        // (更新数据库)、更新界面[↴]、(弹出提示)、(发送通知)
        // 本页引起的删除 => 更新列表显示
        if (!inFavorite) {
          _data.removeWhere((el) => el.mangaId == favorite.mangaId);
          _total--;
          _removed++;
          if (mounted) setState(() {});

          // 独立页时发送额外通知，让主页子页显示有更新 (fromSepFavoritePage)
          if (widget.isSepPage) {
            EventBusManager.instance.fire(FavoriteUpdatedEvent(mangaId: mangaId, group: favorite.groupName, reason: UpdateReason.deleted, fromFavoritePage: true, fromSepFavoritePage: true));
          }
        }
      },
      favoriteSetter: (newFavorite) {
        // (更新数据库)、更新界面[↴]、(弹出提示)、(发送通知)
        // 本页引起的更新 => 更新列表显示 (修改备注、移动至分组)

        if (newFavorite != null) {
          if (newFavorite.groupName == _currentGroup) {
            if (newFavorite.remark != favorite.remark) {
              _data.replaceWhere((el) => el.mangaId == mangaId, (_) => newFavorite); // 备注被修改 => 更新列表
              if (mounted) setState(() {});
            }
            if (newFavorite.order != favorite.order) {
              _data.removeWhere((el) => el.mangaId == newFavorite.mangaId); // 同一分组即置顶 => 更新顺序
              _data.insert(0, newFavorite); // <<< ignore previous order
              if (mounted) setState(() {});
            }

            // 独立页时发送额外通知，让主页子页显示有更新 (fromSepFavoritePage)
            if (widget.isSepPage) {
              EventBusManager.instance.fire(FavoriteUpdatedEvent(mangaId: mangaId, group: newFavorite.groupName, reason: UpdateReason.updated, fromFavoritePage: true, fromSepFavoritePage: true));
            }
          } else {
            _data.removeWhere((el) => el.mangaId == newFavorite.mangaId); // 不同分组 => 从列表删除
            _total--;
            _removed++;
            if (mounted) setState(() {});

            // 独立页时发送额外通知，让主页子页显示有更新 (fromSepFavoritePage)
            if (widget.isSepPage) {
              EventBusManager.instance.fire(FavoriteUpdatedEvent(mangaId: newFavorite.mangaId, group: newFavorite.groupName, oldGroup: _currentGroup, reason: UpdateReason.updated, fromFavoritePage: true, fromSepFavoritePage: true));
            }
          }
        }
      },
    );
  }

  void _updateFavoriteRemark({required int mangaId}) {
    var oldFavorite = _data.where((el) => el.mangaId == mangaId).firstOrNull;
    if (oldFavorite == null) {
      return;
    }

    // 不退出多选模式、先弹出菜单
    showUpdateFavoriteMangaRemarkDialog(
      context: context,
      favorite: oldFavorite,
      fromFavoriteList: true,
      onUpdated: (newFavorite) {
        // (更新数据库)、退出多选模式、更新界面[↴]、(弹出提示)、(发送通知)
        // 本页引起的更新 => 更新列表显示
        _msController.exitMultiSelectionMode();
        _data.replaceWhere((el) => el.mangaId == mangaId, (_) => newFavorite);
        if (mounted) setState(() {});

        // 独立页时发送额外通知，让主页子页显示有更新 (fromSepFavoritePage)
        if (widget.isSepPage) {
          EventBusManager.instance.fire(FavoriteUpdatedEvent(mangaId: mangaId, group: newFavorite.groupName, reason: UpdateReason.updated, fromFavoritePage: true, fromSepFavoritePage: true));
        }
      },
    );
  }

  void _moveFavoritesTo({required List<int> mangaIds}) {
    var oldFavorites = _data.where((el) => mangaIds.contains(el.mangaId)).toList()..sort((i, j) => i.order.compareTo(j.order));
    if (oldFavorites.isEmpty) {
      return;
    }

    // 不退出多选模式、先弹出菜单
    showUpdateFavoriteMangasGroupDialog(
      context: context,
      favorites: oldFavorites,
      selectedGroupName: _currentGroup,
      fromFavoriteList: true,
      onUpdated: (newFavorites, addToTop) {
        // (更新数据库)、退出多选模式、更新界面[↴]、(弹出提示)、(发送通知)
        // 本页引起的更新 => 更新列表显示
        _msController.exitMultiSelectionMode();
        for (var newFavorite in newFavorites) {
          if (newFavorite.groupName != _currentGroup) {
            _data.removeWhere((el) => el.mangaId == newFavorite.mangaId); // 不同分组 => 从列表删除
            _total--;
            _removed++;
          } else {
            _data.removeWhere((el) => el.mangaId == newFavorite.mangaId); // 同一分组 => 更新列表顺序
            addToTop ? _data.insert(0, newFavorite) : _data.add(newFavorite); // <<< ignore previous order
          }
        }
        if (mounted) setState(() {});

        // 独立页时发送额外通知，让主页子页显示有更新 (fromSepFavoritePage)
        if (widget.isSepPage) {
          for (var newFavorite in newFavorites) {
            var oldGroupName = oldFavorites.where((f) => f.mangaId == newFavorite.mangaId).firstOrNull?.groupName;
            EventBusManager.instance.fire(FavoriteUpdatedEvent(mangaId: newFavorite.mangaId, group: newFavorite.groupName, oldGroup: oldGroupName, reason: UpdateReason.updated, fromFavoritePage: true, fromSepFavoritePage: true));
          }
        }
      },
    );
  }

  Future<void> _deleteFavorites({required List<int> mangaIds}) async {
    var favorites = _data.where((el) => mangaIds.contains(el.mangaId)).toList();
    if (favorites.isEmpty) {
      return;
    }

    // 不退出多选模式、先弹出对话框
    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('删除确认'),
        content: favorites.length == 1 //
            ? Text('是否从本地收藏中删除《${favorites.first.mangaTitle}》？')
            : Text(
                '是否从本地收藏中删除以下 ${favorites.length} 部漫画？\n\n' + //
                    [for (int i = 0; i < favorites.length; i++) '${i + 1}. 《${favorites[i].mangaTitle}》'].join('\n'),
              ),
        scrollable: true,
        actions: [
          TextButton(child: Text('删除'), onPressed: () => Navigator.of(c).pop(true)),
          TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
        ],
      ),
    );
    if (ok != true) {
      return;
    }

    // 退出多选模式、更新数据库、更新界面[↴]、发送通知
    // 本页引起的删除 => 更新列表显示
    _msController.exitMultiSelectionMode();
    for (var mangaId in mangaIds) {
      await FavoriteDao.deleteFavorite(username: AuthManager.instance.username, mid: mangaId);
      _data.removeWhere((el) => el.mangaId == mangaId);
      _total--;
      _removed++;
    }
    if (mounted) setState(() {});
    for (var mangaId in mangaIds) {
      EventBusManager.instance.fire(FavoriteUpdatedEvent(mangaId: mangaId, group: _currentGroup, reason: UpdateReason.deleted, fromFavoritePage: true));
    }

    // 独立页时发送额外通知，让主页子页显示有更新 (fromSepFavoritePage)
    if (widget.isSepPage) {
      for (var mangaId in mangaIds) {
        EventBusManager.instance.fire(FavoriteUpdatedEvent(mangaId: mangaId, group: _currentGroup, reason: UpdateReason.deleted, fromFavoritePage: true, fromSepFavoritePage: true));
      }
    }
  }

  void _switchGroup(FavoriteGroup group) {
    if (_currentGroup == group.groupName) {
      return;
    }

    // switch and refresh
    _currentGroup = group.groupName; // 切换分组 (包括默认分组和所有漫画分组)
    _searchKeyword = ''; // 清除搜索关键词
    if (mounted) setState(() {});
    _scaffoldKey.currentState?.closeEndDrawer();
    _pdvKey.currentState?.refresh();
  }

  Future<void> _adjustOrder() async {
    await Navigator.of(context).push<bool>(
      CustomPageRoute(
        context: context,
        builder: (c) => FavoriteReorderPage(
          groupName: _currentGroup,
        ),
      ),
    );
  }

  void _updateOrderByEvent(FavoriteOrderUpdatedEvent ev) {
    // 漫画顺序被调整 => 刷新列表
    if (_scaffoldKey.currentState?.isEndDrawerOpen == true) {
      _scaffoldKey.currentState?.closeEndDrawer();
    }
    _searchKeyword = ''; // 清除搜索关键词
    if (mounted) setState(() {});
    _pdvKey.currentState?.refresh();
  }

  Future<void> _manageGroups() async {
    _groups = await FavoriteDao.getGroups(username: AuthManager.instance.username);
    if (_groups != null) {
      await Navigator.of(context).push<bool>(
        CustomPageRoute(
          context: context,
          builder: (c) => FavoriteGroupPage(
            groups: _groups!,
          ),
        ),
      );
    }
  }

  Future<void> _updateGroupsByEvent(FavoriteGroupUpdatedEvent ev) async {
    // 收藏分组被调整 => 获取最新分组并进一步处理
    _groups = await FavoriteDao.getGroups(username: AuthManager.instance.username);
    _groupsLengths = await FavoriteDao.getGroupsLengths(username: AuthManager.instance.username);
    var newName = ev.changedGroups[_currentGroup];
    if (newName == null) {
      // 被删除 => 转至默认分组并刷新列表
      _currentGroup = ''; // 切换为默认分组
      _searchKeyword = ''; // 清除搜索关键词
      _pdvKey.currentState?.refresh();
    } else if (newName == _currentGroup) {
      // 未被重命名 => pass
    } else {
      // 被重命名 => 修改当前分组名
      _currentGroup = newName;
      var newData = _data.map((f) => f.copyWith(groupName: newName)).toList();
      _data.clear();
      _data.addAll(newData);
    }
    if (mounted) setState(() {});
  }

  @override
  bool get wantKeepAlive => true;

  @override
  FitSystemScreenshotData get fitSystemScreenshotData => FitSystemScreenshotData(
        scrollViewKey: _scrollViewKey,
        scrollController: _controller,
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: () async {
        if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
          Navigator.of(context).pop(); // close drawer
          return false;
        }
        if (_scaffoldKey.currentState?.isEndDrawerOpen == true) {
          _scaffoldKey.currentState?.closeEndDrawer();
          return false;
        }
        if (_msController.multiSelecting) {
          _msController.exitMultiSelectionMode();
          return false;
        }
        if (_searchKeyword.isNotEmpty) {
          _exitSearch();
          return false;
        }
        return true;
      },
      child: DrawerScaffold(
        key: _scaffoldKey,
        endDrawerEdgeDragWidth: !widget.isSepPage ? 40 : null,
        physicsController: !widget.isSepPage ? null : DefaultScrollPhysics.of(context)?.asIf<CustomScrollPhysics>()?.controller /* shared physics controller */,
        checkPhysicsControllerForOverscroll: !widget.isSepPage ? false : true,
        implicitlyOverscrollableScaffold: !widget.isSepPage ? false : true,
        endDrawer: Drawer(
          child: Theme(
            data: Theme.of(context).copyWith(
              textTheme: Theme.of(context).textTheme.copyWith(
                    bodyText1: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 16),
                  ),
            ),
            child: ListView(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, spreadRadius: 1, offset: Offset(1, 0))],
                  ),
                  height: Theme.of(context).appBarTheme.toolbarHeight!,
                  alignment: Alignment.center,
                  child: IconText(
                    icon: Icon(Icons.bookmark_border, color: Colors.grey[700]),
                    text: Text('管理本地收藏', style: Theme.of(context).textTheme.subtitle1),
                    space: 8,
                    mainAxisSize: MainAxisSize.min,
                    textPadding: EdgeInsets.only(bottom: 2),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.low_priority),
                  title: Text('调整已收藏漫画的顺序'),
                  onTap: () => _adjustOrder(),
                ),
                ListTile(
                  leading: Icon(MdiIcons.folderMultipleOutline),
                  title: Text('管理漫画收藏分组'),
                  onTap: () => _manageGroups(),
                ),
                ListTile(
                  leading: Icon(Icons.people),
                  title: Text('查看已收藏的漫画作者'),
                  onTap: () => Navigator.of(context).push(
                    CustomPageRoute(
                      context: context,
                      builder: (c) => FavoriteAuthorPage(),
                    ),
                  ),
                ),
                ListTile(
                  title: Text('浏览所有已收藏的漫画'),
                  leading: Icon(MdiIcons.bookmarkBoxMultipleOutline),
                  trailing: Text((_allMangasCount ?? 0).toString()),
                  onTap: () => Navigator.of(context).push(
                    CustomPageRoute(
                      context: context,
                      builder: (c) => FavoriteAllPage(),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, spreadRadius: 1, offset: Offset(1, 0))],
                  ),
                  height: Theme.of(context).appBarTheme.toolbarHeight!,
                  alignment: Alignment.center,
                  child: IconText(
                    icon: Icon(Icons.folder_open, color: Colors.grey[700]),
                    text: Text('切换当前分组', style: Theme.of(context).textTheme.subtitle1),
                    space: 8,
                    mainAxisSize: MainAxisSize.min,
                    textPadding: EdgeInsets.only(bottom: 2),
                  ),
                ),
                for (var g in _groups ?? <FavoriteGroup>[]) ...[
                  ListTile(
                    title: Text(g.checkedGroupName, maxLines: 2, overflow: TextOverflow.ellipsis),
                    leading: _currentGroup == g.groupName ? Icon(Icons.radio_button_checked) : Icon(Icons.radio_button_unchecked),
                    trailing: Text((_groupsLengths?[g.groupName] ?? 0).toString()),
                    selected: _currentGroup == g.groupName,
                    onTap: () => _switchGroup(g),
                    onLongPress: () => showDialog(
                      context: context,
                      builder: (c) => SimpleDialog(
                        title: Text(g.checkedGroupName),
                        children: [
                          IconTextDialogOption(
                            icon: Icon(Icons.folder_open),
                            text: Text('切换为该分组'),
                            onPressed: () {
                              Navigator.of(c).pop();
                              _switchGroup(g);
                            },
                          ),
                          IconTextDialogOption(
                            icon: Icon(MdiIcons.folderMultipleOutline),
                            text: Text('管理漫画收藏分组'),
                            onPressed: () {
                              Navigator.of(c).pop();
                              _manageGroups();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (g.groupName != _groups!.last.groupName) //
                    Divider(height: 0, thickness: 1),
                ],
              ],
            ),
          ),
        ),
        body: MultiSelectable<ValueKey<int>>(
          controller: _msController,
          stateSetter: () => mountedSetState(() {}),
          onModeChanged: (_) => mountedSetState(() {}),
          child: PaginationDataView<FavoriteManga>(
            key: _pdvKey,
            style: !AppSetting.instance.ui.showTwoColumns ? UpdatableDataViewStyle.listView : UpdatableDataViewStyle.gridView,
            data: _data,
            getData: ({indicator}) => _getData(page: indicator),
            scrollViewKey: _scrollViewKey,
            scrollController: _controller,
            onStyleChanged: (_, __) => updatePageAttaching(),
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
              onStartRefreshing: () => _msController.exitMultiSelectionMode(),
            ),
            separator: Divider(height: 0, thickness: 1),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 0.0,
              mainAxisSpacing: 0.0,
              childAspectRatio: GeneralLineView.getChildAspectRatioForTwoColumns(context),
            ),
            itemBuilder: (c, idx, item) => SelectableCheckboxItem<ValueKey<int>>(
              key: ValueKey<int>(item.mangaId),
              checkboxPosition: PositionArgument.fromLTRB(null, 0, 11, 0),
              checkboxBuilder: (_, __, tip) => CheckboxForSelectableItem(tip: tip, backgroundColor: Theme.of(context).scaffoldBackgroundColor),
              useFullRipple: true,
              onFullRippleLongPressed: (c, key, tip) => _msController.selectedItems.length == 1 && tip.selected ? _showPopupMenu(mangaId: key.value) : tip.toToggle?.call(),
              itemBuilder: (c, key, tip) => FavoriteMangaLineView(
                manga: item,
                index: _searchKeyword.isNotEmpty /* show index badge only when no searching and sort by order asc */
                    ? null
                    : (_sortMethod == SortMethod.byOrderAsc
                        ? idx + 1
                        : _sortMethod == SortMethod.byOrderDesc
                            ? _total - idx
                            : null),
                history: _flagStorage.getHistory(mangaId: item.mangaId),
                flags: _flagStorage.getFlags(mangaId: item.mangaId, forceInFavorite: true),
                twoColumns: AppSetting.instance.ui.showTwoColumns,
                onLongPressed: !tip.isNormal ? null : () => _msController.enterMultiSelectionMode(alsoSelect: [key]),
              ),
            ),
            extra: UpdatableDataViewExtraWidgets(
              outerTopWidgets: [
                ListHintView.textWidget(
                  padding: EdgeInsets.fromLTRB(10, 5, 10 - 3, 5), // for popup btn
                  leftText: (AuthManager.instance.logined ? '${AuthManager.instance.username} 的本地收藏' : '未登录用户的本地收藏') + //
                      (_currentGroup == '' ? '' : ' - $_currentGroup') + //
                      (_searchKeyword.isNotEmpty ? ' ("$_searchKeyword" 的搜索结果)' : (_isUpdated ? ' (有更新)' : '')),
                  rightWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchKeyword.isNotEmpty)
                        HelpIconView.asButton(
                          iconData: Icons.search_off,
                          tooltip: '退出搜索',
                          onPressed: () => _exitSearch(),
                        ),
                      if (_sortMethod != SortMethod.byOrderAsc)
                        HelpIconView.asButton(
                          iconData: _sortMethod.toIcon(),
                          tooltip: '漫画排序方式',
                          onPressed: () => _toSort(),
                        ),
                      if (_searchKeyword.isNotEmpty || _sortMethod != SortMethod.byOrderAsc)
                        Container(
                          color: Theme.of(context).dividerColor,
                          child: SizedBox(height: 20, width: 1),
                          margin: EdgeInsets.only(left: 5, right: 5 + 3),
                        ),
                      Text('共 $_total 部'),
                      SizedBox(width: 5),
                      HelpIconView.forListHint(
                        title: '"我的书架"与"本地收藏"的区别',
                        hint: '"我的书架"与漫画柜网页端保持同步，但受限于网页端功能，"我的书架"只能按照漫画更新时间的逆序显示。\n\n'
                            '"本地收藏"仅记录在移动端本地，不显示章节更新情况，但"本地收藏"支持分组管理漫画，且列表顺序可自由调整。',
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
                        itemBuilder: (c) => [
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
                          if (_sortMethod != SortMethod.byOrderAsc)
                            PopupMenuItem(
                              child: IconTextMenuItem(MdiIcons.sortVariantRemove, '恢复默认排序'),
                              onTap: () => _exitSort(),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).fitSystemScreenshot(this),
        ),
        floatingActionButton: MultiSelectionFabContainer(
          multiSelectableController: _msController,
          onCounterPressed: () {
            var mangaIds = _msController.selectedItems.map((e) => e.value).toList();
            var titles = _data.where((el) => mangaIds.contains(el.mangaId)).map((m) => '《${m.mangaTitle}》').toList();
            var allKeys = _data.map((el) => ValueKey(el.mangaId)).toList();
            MultiSelectionFabContainer.showCounterDialog(context, controller: _msController, selected: titles, allKeys: allKeys);
          },
          fabForMultiSelection: [
            MultiSelectionFabOption(
              child: Icon(Icons.more_horiz),
              tooltip: '查看更多选项',
              show: _msController.selectedItems.length == 1,
              onPressed: () => _showPopupMenu(mangaId: _msController.selectedItems.first.value),
            ),
            MultiSelectionFabOption(
              child: Icon(MdiIcons.commentBookmark),
              tooltip: '修改收藏备注',
              show: _msController.selectedItems.length == 1,
              onPressed: () => _updateFavoriteRemark(mangaId: _msController.selectedItems.first.value),
            ),
            MultiSelectionFabOption(
              child: Icon(Icons.drive_file_move),
              tooltip: '移动收藏至分组',
              onPressed: () => _moveFavoritesTo(mangaIds: _msController.selectedItems.map((e) => e.value).toList()),
            ),
            MultiSelectionFabOption(
              child: Icon(Icons.delete),
              tooltip: '取消本地收藏',
              onPressed: () => _deleteFavorites(mangaIds: _msController.selectedItems.map((e) => e.value).toList()),
            ),
          ],
          fabForNormal: ScrollAnimatedFab(
            controller: _fabController,
            scrollController: _controller,
            condition: !_msController.multiSelecting ? ScrollAnimatedCondition.direction : ScrollAnimatedCondition.custom,
            customBehavior: (_) => false,
            fab: FloatingActionButton(
              child: Icon(Icons.vertical_align_top),
              heroTag: null,
              onPressed: () => _controller.scrollToTop(),
            ),
          ),
        ),
      ),
    );
  }
}
