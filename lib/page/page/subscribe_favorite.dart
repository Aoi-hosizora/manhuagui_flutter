import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/favorite_group.dart';
import 'package:manhuagui_flutter/page/favorite_reorder.dart';
import 'package:manhuagui_flutter/page/view/favorite_manga_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/manga_corner_icons.dart';
import 'package:manhuagui_flutter/page/view/multi_selection_fab.dart';
import 'package:manhuagui_flutter/page/view/simple_widgets.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

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
  var _favoriteUpdated = false;
  AuthData? _oldAuthData;

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _controller.scrollToTop());
    widget.action?.addAction('manage', () => _scaffoldKey.currentState?.let((s) => !s.isEndDrawerOpen ? s.openEndDrawer() : Navigator.of(context).pop()));
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandlers.add(AuthManager.instance.listen(() => _oldAuthData, (_) {
        _oldAuthData = AuthManager.instance.authData;
        _pdvKey.currentState?.refresh();
      }));
      await AuthManager.instance.check();
    });
    _cancelHandlers.add(EventBusManager.instance.listen<SubscribeUpdatedEvent>((ev) {
      if (ev.inFavorite != null && _currentGroup == ev.changedGroup /* 当前显示分组发生更新，且是非本页引起的更新 */) {
        _favoriteUpdated = true;
        if (mounted) setState(() {});
      }
    }));
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    widget.action?.removeAction('manage');
    _cancelHandlers.forEach((c) => c.call());
    _flagStorage.dispose();
    _controller.dispose();
    _fabController.dispose();
    _msController.dispose();
    super.dispose();
  }

  List<FavoriteGroup>? _groups;
  var _currentGroup = '';
  final _data = <FavoriteManga>[];
  final _histories = <int, MangaHistory?>{};
  late final _flagStorage = MangaCornerFlagsStorage(stateSetter: () => mountedSetState(() {}));
  var _total = 0;
  var _removed = 0;

  Future<PagedList<FavoriteManga>> _getData({required int page}) async {
    if (page == 1) {
      // refresh
      _removed = 0;
      _favoriteUpdated = false;
      _groups = null;
    }
    _groups ??= await FavoriteDao.getGroups(username: AuthManager.instance.username);

    var username = AuthManager.instance.username;
    var data = await FavoriteDao.getFavorites(username: username, groupName: _currentGroup, page: page, offset: _removed) ?? [];
    _total = await FavoriteDao.getFavoriteCount(username: username, groupName: _currentGroup) ?? 0;
    for (var item in data) {
      _histories[item.mangaId] = await HistoryDao.getHistory(username: username, mid: item.mangaId);
    }
    await _flagStorage.queryAndStoreFlags(mangaIds: data.map((e) => e.mangaId), toQueryFavorites: false);
    if (mounted) setState(() {});
    return PagedList(list: data, next: page + 1);
  }

  Future<void> _moveFavoritesTo({required List<int> mangaIds}) async {
    var favorites = _data.where((el) => mangaIds.contains(el.mangaId)).toList();
    if (favorites.isEmpty) {
      return;
    }
    mangaIds = favorites.map((e) => e.mangaId).toList();
    var groups = await FavoriteDao.getGroups(username: AuthManager.instance.username);
    if (groups == null) {
      return;
    }

    var addToTop = false; // 默认添加到末尾
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('移动收藏至分组'),
        children: [
          for (var group in groups)
            TextDialogOption(
              text: Text(
                group.checkedGroupName,
                style: TextStyle(color: group.groupName == _currentGroup ? Theme.of(context).primaryColor : null),
              ),
              onPressed: () async {
                // 退出对话框、退出多选模式、保存新设置、调整顺序
                var newGroupName = group.groupName;
                var newCheckedGroupName = group.checkedGroupName;
                Navigator.of(c).pop();
                _msController.exitMultiSelectionMode();
                if (addToTop) {
                  mangaIds = mangaIds.reversed.toList(); // 移至顶部需要倒序一个一个移动，移至底部则不需要
                }

                // 一个一个更新数据库、更新数据
                for (var mid in mangaIds) {
                  var oldFavorite = _data.where((el) => el.mangaId == mid).firstOrNull;
                  if (oldFavorite == null) {
                    continue;
                  }
                  var order = await FavoriteDao.getFavoriteNewOrder(username: AuthManager.instance.username, groupName: newGroupName, addToTop: addToTop);
                  var newFavorite = oldFavorite.copyWith(groupName: newGroupName, order: order);
                  await FavoriteDao.addOrUpdateFavorite(username: AuthManager.instance.username, favorite: newFavorite);
                  if (newGroupName != _currentGroup) {
                    _data.removeWhere((el) => el.mangaId == mid); // 不同分组则删除数据
                    _removed++;
                    _total--;
                  } else {
                    _data.remove(oldFavorite); // 同一分组则更新列表
                    addToTop ? _data.insert(0, newFavorite) : _data.add(newFavorite);
                  }
                  EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mid, inFavorite: true)); // 不设置 changedGroup
                }

                Fluttertoast.showToast(msg: '已将 ${mangaIds.length} 项漫画移动至 $newCheckedGroupName');
                if (mounted) setState(() {});
              },
            ),
          CheckBoxDialogOption(
            initialValue: addToTop,
            onChanged: (v) => addToTop = v,
            text: '添加至本地收藏顶部',
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFavorites({required List<int> mangaIds}) async {
    var favorites = _data.where((el) => mangaIds.contains(el.mangaId)).toList();
    if (favorites.isEmpty) {
      return;
    }

    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('刪除确认'),
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

    // 退出多选模式、更新列表和数据库
    _msController.exitMultiSelectionMode();
    for (var mangaId in mangaIds) {
      _data.removeWhere((h) => h.mangaId == mangaId);
      _removed++;
      _total--;
      await FavoriteDao.deleteFavorite(username: AuthManager.instance.username, mid: mangaId);
      EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inFavorite: false)); // 不设置 changedGroup
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
          Navigator.of(context).pop();
          return false; // close drawer
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
                AppBar(
                  leading: AppBarActionButton(
                    icon: Icon(Icons.low_priority),
                    tooltip: '调整漫画顺序',
                    onPressed: () async {
                      var ok = await Navigator.of(context).push<bool>(
                        CustomPageRoute(
                          context: context,
                          builder: (c) => FavoriteReorderPage(
                            groupName: _currentGroup,
                          ),
                        ),
                      );
                      if (ok == true) {
                        // 漫画顺序已调整
                        Navigator.of(context).pop();
                        _pdvKey.currentState?.refresh();
                      }
                    },
                  ),
                  title: Text(
                    '收藏分组',
                    style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.white),
                  ),
                  actions: [
                    AppBarActionButton(
                      icon: Icon(Icons.label_outline),
                      tooltip: '管理收藏分组',
                      onPressed: () async {
                        if (_groups == null) {
                          return;
                        }
                        String? mappedGroupName;
                        var ok = await Navigator.of(context).push<bool>(
                          CustomPageRoute(
                            context: context,
                            builder: (c) => FavoriteGroupPage(
                              groups: _groups!,
                              listenedGroupName: _currentGroup,
                              onGroupChanged: (n) => mappedGroupName = n, // null => 被删除; not_null => 未被重命名/被重命名
                            ),
                          ),
                        );
                        if (ok == true) {
                          // 修改可能被保存
                          _groups = await FavoriteDao.getGroups(username: AuthManager.instance.username);
                          if (mappedGroupName == null) {
                            _currentGroup = ''; // 被删除 => 转至默认分组
                            _pdvKey.currentState?.refresh();
                          } else {
                            if (_currentGroup == mappedGroupName!) {
                              // 未被重命名 => pass
                            } else {
                              _currentGroup = mappedGroupName!; // 被重命名 => 修改当前分组名
                              var newData = _data.map((f) => f.copyWith(groupName: _currentGroup)).toList();
                              _data.clear();
                              _data.addAll(newData);
                            }
                          }
                          if (mounted) setState(() {});
                        }
                      },
                    ),
                  ],
                ),
                for (var group in _groups ?? <FavoriteGroup>[]) ...[
                  ListTile(
                    title: Text(group.checkedGroupName),
                    leading: _currentGroup == group.groupName ? Icon(Icons.radio_button_checked) : Icon(Icons.radio_button_unchecked),
                    selected: _currentGroup == group.groupName,
                    onTap: () {
                      if (_currentGroup != group.groupName) {
                        _currentGroup = group.groupName;
                        if (mounted) setState(() {});
                        Navigator.of(context).pop();
                        _pdvKey.currentState?.refresh();
                      }
                    },
                  ),
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
              refreshFirst: true,
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
                onLongPressed: !tip.isNormal ? null : () => _msController.enterMultiSelectionMode(alsoSelect: [key]),
                inDownload: _flagStorage.isInDownload(mangaId: item.mangaId),
                inShelf: _flagStorage.isInShelf(mangaId: item.mangaId),
                inHistory: _flagStorage.isInHistory(mangaId: item.mangaId),
              ),
            ),
            extra: UpdatableDataViewExtraWidgets(
              outerTopWidgets: [
                ListHintView.textWidget(
                  leftText: (AuthManager.instance.logined ? '${AuthManager.instance.username} 的本地收藏' : '未登录用户的本地收藏') + //
                      (_currentGroup == '' ? '' : '  -  $_currentGroup') + //
                      (!_favoriteUpdated ? '' : ' (有更新)'),
                  rightWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('共 $_total 部'),
                      SizedBox(width: 5),
                      HelpIconView(
                        title: '"本地收藏"与"我的书架"的区别',
                        hint: '"我的书架"与漫画柜网页版保持同步，但受限于网页版功能，"我的书架"只能按照漫画更新时间排序显示。\n\n'
                            '"本地收藏"仅记录在移动端本地，不提供章节更新提醒，但"本地收藏"中漫画的显示顺序可自由调整，且支持分组管理。',
                        useRectangle: true,
                        padding: EdgeInsets.all(3),
                      ),
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
