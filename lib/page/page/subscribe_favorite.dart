import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/favorite_author.dart';
import 'package:manhuagui_flutter/page/favorite_group.dart';
import 'package:manhuagui_flutter/page/favorite_reorder.dart';
import 'package:manhuagui_flutter/page/page/manga_dialog.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/favorite_manga_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/multi_selection_fab.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 订阅-收藏
class FavoriteSubPage extends StatefulWidget {
  const FavoriteSubPage({
    Key? key,
    this.action,
  }) : super(key: key);

  final ActionController? action;

  @override
  _FavoriteSubPageState createState() => _FavoriteSubPageState();
}

class _FavoriteSubPageState extends State<FavoriteSubPage> with AutomaticKeepAliveClientMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pdvKey = GlobalKey<PaginationDataViewState>();
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
        _pdvKey.currentState?.refresh(); // TODO use _getData or _pdvKey
      }));
      await AuthManager.instance.check();
    });
    _cancelHandlers.add(EventBusManager.instance.listen<FavoriteUpdatedEvent>((ev) => _updateByEvent(ev)));
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
  var _currentGroup = '';

  final _data = <FavoriteManga>[];
  var _total = 0;
  var _removed = 0; // for query offset
  late final _flagStorage = MangaCornerFlagStorage(stateSetter: () => mountedSetState(() {}), ignoreFavorites: true);
  final _histories = <int, MangaHistory?>{};
  var _isUpdated = false;

  Future<PagedList<FavoriteManga>> _getData({required int page}) async {
    if (page == 1) {
      // refresh
      _removed = 0;
      _isUpdated = false;
      _groups = null;
    }
    var username = AuthManager.instance.username;
    var data = await FavoriteDao.getFavorites(username: username, groupName: _currentGroup, page: page, offset: _removed) ?? [];
    _total = await FavoriteDao.getFavoriteCount(username: username, groupName: _currentGroup) ?? 0;
    _groups ??= await FavoriteDao.getGroups(username: AuthManager.instance.username);
    for (var item in data) {
      _histories[item.mangaId] = await HistoryDao.getHistory(username: username, mid: item.mangaId);
    }
    _flagStorage.queryAndStoreFlags(mangaIds: data.map((e) => e.mangaId), queryFavorites: false).then((_) => mountedSetState(() {}));
    return PagedList(list: data, next: page + 1);
  }

  void _switchGroup(FavoriteGroup group) {
    if (_currentGroup == group.groupName) {
      return;
    }

    // switch and refresh
    _currentGroup = group.groupName;
    if (mounted) setState(() {});
    Navigator.of(context).pop(); // close drawer
    _pdvKey.currentState?.refresh();
  }

  void _updateByEvent(FavoriteUpdatedEvent event) async {
    if (event.group != _currentGroup) {
      return; // 非当前分组 => 忽略
    }

    if (event.reason == UpdateReason.added) {
      // 新增 => 显示有更新
      _isUpdated = true;
      if (mounted) setState(() {});
    }
    if (event.reason == UpdateReason.deleted && !event.fromFavoritePage) {
      // 非本页引起的删除 => 显示有更新
      _isUpdated = true;
      if (mounted) setState(() {});
    }
    if (event.reason == UpdateReason.updated && !event.fromFavoritePage) {
      // 非本页引起的更新 => 显示有更新
      _isUpdated = true;
      if (mounted) setState(() {});
    }
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
      fromFavoriteList: true,
      inFavoriteSetter: (inFavorite) {
        // (更新数据库)、更新界面[↴]、(弹出提示)、(发送通知)
        // 新增 => 显示有更新, 本页引起的更新删除 => 更新列表显示
        if (!inFavorite) {
          _data.removeWhere((el) => el.mangaId == favorite.mangaId);
          _total--;
          _removed++;
          if (mounted) setState(() {});
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
      onUpdated: (newFavorite) {
        // (更新数据库)、退出多选模式、更新界面[↴]、(弹出提示)、(发送通知)
        // 本页引起的更新 => 更新列表显示
        _msController.exitMultiSelectionMode();
        for (var i = 0; i < _data.length; i++) {
          if (_data[i].mangaId == mangaId) {
            _data[i] = newFavorite;
          }
        }
        if (mounted) setState(() {});
      },
    );
  }

  void _moveFavoritesTo({required List<int> mangaIds}) {
    var oldFavorites = _data.where((el) => mangaIds.contains(el.mangaId)).toList();
    if (oldFavorites.isEmpty) {
      return;
    }

    // 不退出多选模式、先弹出菜单
    showUpdateFavoriteMangasGroupDialog(
      context: context,
      favorites: oldFavorites,
      selectedGroupName: _currentGroup,
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
            addToTop ? _data.insert(0, newFavorite) : _data.add(newFavorite);
          }
        }
        if (mounted) setState(() {});
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
  }

  Future<void> _adjustOrder() async {
    var ok = await Navigator.of(context).push<bool>(
      CustomPageRoute(
        context: context,
        builder: (c) => FavoriteReorderPage(
          groupName: _currentGroup,
        ),
      ),
    );
    if (ok != true) {
      return;
    }

    // 漫画顺序已调整 => 刷新列表
    Navigator.of(context).pop(); // close drawer
    _pdvKey.currentState?.refresh();
  }

  Future<void> _manageGroups() async {
    _groups = await FavoriteDao.getGroups(username: AuthManager.instance.username);
    if (_groups == null) {
      return; // unreachable
    }

    String? mappedGroupName;
    var ok = await Navigator.of(context).push<bool>(
      CustomPageRoute(
        context: context,
        builder: (c) => FavoriteGroupPage(
          groups: _groups!,
          listenedGroupName: _currentGroup,
          onGroupChanged: (n) => mappedGroupName = n, // null => 被删除; not_null => 未被删除，但可能被重命名
        ),
      ),
    );
    if (ok != true) {
      return;
    }

    // 修改可能被保存 => 获取最新分组并进一步处理
    _groups = await FavoriteDao.getGroups(username: AuthManager.instance.username);
    if (mappedGroupName == null) {
      // 被删除 => 转至默认分组并刷新列表
      _currentGroup = '';
      _pdvKey.currentState?.refresh();
    } else if (_currentGroup == mappedGroupName!) {
      // 未被重命名 => pass
    } else {
      // 被重命名 => 修改当前分组名
      _currentGroup = mappedGroupName!;
      var newData = _data.map((f) => f.copyWith(groupName: _currentGroup)).toList();
      _data.clear();
      _data.addAll(newData);
    }
    if (mounted) setState(() {});
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: () async {
        if (_scaffoldKey.currentState?.isEndDrawerOpen == true) {
          Navigator.of(context).pop(); // close drawer
          return false;
        }
        if (_msController.multiSelecting) {
          _msController.exitMultiSelectionMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
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
                    title: Text(g.checkedGroupName),
                    leading: _currentGroup == g.groupName ? Icon(Icons.radio_button_checked) : Icon(Icons.radio_button_unchecked),
                    selected: _currentGroup == g.groupName,
                    onTap: () => _switchGroup(g),
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
          child: PaginationListView<FavoriteManga>(
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
              onStartRefreshing: () => _msController.exitMultiSelectionMode(),
            ),
            separator: Divider(height: 0, thickness: 1),
            itemBuilder: (c, idx, item) => SelectableCheckboxItem<ValueKey<int>>(
              key: ValueKey<int>(item.mangaId),
              checkboxPosition: PositionArgument.fromLTRB(null, 0, 11, 0),
              checkboxBuilder: (_, __, tip) => CheckboxForSelectableItem(tip: tip, backgroundColor: Theme.of(context).scaffoldBackgroundColor),
              itemBuilder: (c, key, tip) => FavoriteMangaLineView(
                manga: item,
                index: idx + 1,
                history: _histories[item.mangaId],
                flags: _flagStorage.getFlags(mangaId: item.mangaId, forceInFavorite: true),
                onLongPressed: !tip.isNormal ? null : () => _msController.enterMultiSelectionMode(alsoSelect: [key]),
              ),
            ),
            extra: UpdatableDataViewExtraWidgets(
              outerTopWidgets: [
                ListHintView.textWidget(
                  // TODO padding: EdgeInsets.fromLTRB(10, 5, 6, 5),
                  leftText: (AuthManager.instance.logined ? '${AuthManager.instance.username} 的本地收藏' : '未登录用户的本地收藏') + //
                      (_currentGroup == '' ? '' : '  -  $_currentGroup') + //
                      (!_isUpdated ? '' : ' (有更新)'),
                  rightWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('共 $_total 部'),
                      SizedBox(width: 5),
                      HelpIconView.forListHint(
                        title: '"我的书架"与"本地收藏"的区别',
                        hint: '"我的书架"与漫画柜网页端保持同步，但受限于网页端功能，"我的书架"只能按照漫画更新时间的倒序显示。\n\n'
                            '"本地收藏"仅记录在移动端本地，不显示章节更新情况，但"本地收藏"支持分组管理漫画，且列表顺序可自由调整。',
                      ),
                      // TODO 搜索、排序
                      // PopupMenuButton(
                      //   child: Builder(
                      //     builder: (c) => HelpIconView.forListHint(
                      //       title: '',
                      //       hint: '',
                      //       iconData: Icons.more_vert,
                      //       onPressed: () => c.findAncestorStateOfType<PopupMenuButtonState>()?.showButtonMenu(),
                      //     ),
                      //   ),
                      //   itemBuilder: (_) => [
                      //     PopupMenuItem(child: Text('搜索'), onTap: () {}),
                      //     PopupMenuItem(child: Text('排序'), onTap: () {}),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: MultiSelectionFabContainer(
          multiSelectableController: _msController,
          onCounterPressed: () {
            var mangaIds = _msController.selectedItems.map((e) => e.value).toList();
            var titles = _data.where((el) => mangaIds.contains(el.mangaId)).map((m) => '《${m.mangaTitle}》').toList();
            MultiSelectionFabContainer.showSelectedItemsDialogForCounter(context, titles);
          },
          fabForMultiSelection: [
            MultiSelectionFabOption(
              child: Icon(Icons.more_horiz),
              show: _msController.selectedItems.length == 1,
              onPressed: () => _showPopupMenu(mangaId: _msController.selectedItems.first.value),
            ),
            MultiSelectionFabOption(
              child: Icon(MdiIcons.commentBookmark),
              show: _msController.selectedItems.length == 1,
              onPressed: () => _updateFavoriteRemark(mangaId: _msController.selectedItems.first.value),
            ),
            MultiSelectionFabOption(
              child: Icon(Icons.drive_file_move),
              onPressed: () => _moveFavoritesTo(mangaIds: _msController.selectedItems.map((e) => e.value).toList()),
            ),
            MultiSelectionFabOption(
              child: Icon(Icons.delete),
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
