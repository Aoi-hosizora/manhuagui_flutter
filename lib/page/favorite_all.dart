import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/dlg/list_assist_dialog.dart';
import 'package:manhuagui_flutter/page/dlg/manga_dialog.dart';
import 'package:manhuagui_flutter/page/favorite_author.dart';
import 'package:manhuagui_flutter/page/search.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
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

/// 所有已收藏漫画页，查询 [FavoriteManga] 列表并展示，代码基本与 [FavoriteSubPage] 一致
class FavoriteAllPage extends StatefulWidget {
  const FavoriteAllPage({Key? key}) : super(key: key);

  @override
  State<FavoriteAllPage> createState() => _FavoriteAllPageState();
}

class _FavoriteAllPageState extends State<FavoriteAllPage> with FitSystemScreenshotMixin {
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _scrollViewKey = GlobalKey();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  final _msController = MultiSelectableController<ValueKey<int>>();
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
    _cancelHandlers.add(EventBusManager.instance.listen<AppSettingChangedEvent>((_) => mountedSetState(() {})));
    // _cancelHandlers.add(EventBusManager.instance.listen<...>((ev) => _updateByEvent(ev))); => 该页不做任何更新
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _controller.dispose();
    _fabController.dispose();
    _msController.dispose();
    _flagStorage.dispose();
    super.dispose();
  }

  final _data = <FavoriteManga>[];
  var _total = 0;
  var _removed = 0; // for query offset
  late final _flagStorage = MangaCornerFlagStorage(stateSetter: () => mountedSetState(() {}), ignoreFavorites: true);
  var _searchKeyword = ''; // for query condition
  var _searchTitleOnly = true; // for query condition
  var _sortMethod = SortMethod.byTimeDesc; // for query condition

  Future<PagedList<FavoriteManga>> _getData({required int page}) async {
    if (page == 1) {
      // refresh
      _removed = 0;
    }
    var username = AuthManager.instance.username;
    var data = await FavoriteDao.getFavorites(username: username, groupName: null, keyword: _searchKeyword, pureSearch: _searchTitleOnly, sortMethod: _sortMethod, page: page, offset: _removed) ?? [];
    _total = await FavoriteDao.getFavoriteCount(username: username, groupName: null, keyword: _searchKeyword, pureSearch: _searchTitleOnly) ?? 0;
    if (mounted) setState(() {});
    _flagStorage.queryAndStoreFlags(mangaIds: data.map((e) => e.mangaId), queryFavorites: false).then((_) => mountedSetState(() {}));
    return PagedList(list: data, next: page + 1);
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
      orderTitle: null,
      defaultMethod: SortMethod.byTimeDesc,
    );
    if (sort != null && sort != _sortMethod) {
      _sortMethod = sort;
      if (mounted) setState(() {});
      _pdvKey.currentState?.refresh();
    }
  }

  void _exitSort() {
    _sortMethod = SortMethod.byTimeDesc; // 默认排序方式
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
      // fromFavoriteList: false /* <<< */,
      eventSource: EventSource.general,
      inFavoriteSetter: (inFavorite) {
        // (更新数据库)、更新界面[↴]、(弹出提示)、(发送通知)
        // 本页引起的删除 => 更新列表显示
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
      // fromFavoriteList: false /* <<< */,
      eventSource: EventSource.general,
      onUpdated: (newFavorite) {
        // (更新数据库)、退出多选模式、更新界面[↴]、(弹出提示)、(发送通知)
        // 本页引起的更新 => 更新列表显示
        _msController.exitMultiSelectionMode();
        _data.replaceWhere((el) => el.mangaId == mangaId, (_) => newFavorite);
        if (mounted) setState(() {});
      },
    );
  }

  void _moveFavoritesTo({required List<int> mangaIds}) {
    var oldFavorites = _data.where((el) => mangaIds.contains(el.mangaId)).toList(); // 不考虑多个收藏时 order 的顺序
    if (oldFavorites.isEmpty) {
      return;
    }

    // 不退出多选模式、先弹出菜单
    showUpdateFavoriteMangasGroupDialog(
      context: context,
      favorites: oldFavorites,
      selectedGroupName: null,
      // fromFavoriteList: false /* <<< */,
      eventSource: EventSource.general,
      onUpdated: (newFavorites, addToTop) {
        // (更新数据库)、退出多选模式、更新界面[↴]、(弹出提示)、(发送通知)
        // 本页引起的更新 => 更新列表显示
        _msController.exitMultiSelectionMode();
        for (var newFavorite in newFavorites) {
          _data.replaceWhere((el) => el.mangaId == newFavorite.mangaId, (_) => newFavorite); // 更换分组名
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
      var groupName = favorites.where((f) => f.mangaId == mangaId).firstOrNull?.groupName;
      if (groupName != null) {
        EventBusManager.instance.fire(FavoriteUpdatedEvent(mangaId: mangaId, group: groupName, reason: UpdateReason.deleted, source: EventSource.general));
      }
    }
  }

  @override
  FitSystemScreenshotData get fitSystemScreenshotData => FitSystemScreenshotData(
        scrollViewKey: _scrollViewKey,
        scrollController: _controller,
      );

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
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
      child: Scaffold(
        appBar: AppBar(
          title: Text('已收藏的所有漫画'),
          leading: AppBarActionButton.leading(context: context, allowDrawerButton: false),
          actions: [
            AppBarActionButton(
              icon: Icon(Icons.people),
              tooltip: '浏览已收藏的漫画作者',
              onPressed: () => Navigator.of(context).push(
                CustomPageRoute(
                  context: context,
                  builder: (c) => FavoriteAuthorPage(),
                ),
              ),
            ),
            AppBarActionButton(
              icon: Icon(Icons.search),
              tooltip: '搜索漫画',
              onPressed: () => Navigator.of(context).push(
                CustomPageRoute(
                  context: context,
                  builder: (c) => SearchPage(),
                ),
              ),
            ),
          ],
        ),
        drawer: AppDrawer(
          currentSelection: DrawerSelection.none,
        ),
        drawerEdgeDragWidth: MediaQuery.of(context).size.width,
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
                index: null /* don't show order badge */,
                history: _flagStorage.getHistory(mangaId: item.mangaId),
                flags: _flagStorage.getFlags(mangaId: item.mangaId, forceInFavorite: true),
                twoColumns: AppSetting.instance.ui.showTwoColumns,
                onLongPressed: !tip.isNormal ? null : () => _msController.enterMultiSelectionMode(alsoSelect: [key]),
              ),
            ),
            extra: UpdatableDataViewExtraWidgets(
              outerTopWidgets: [
                ListHintView.textWidget(
                  leftText: (AuthManager.instance.logined ? '${AuthManager.instance.username} 的所有本地收藏' : '未登录用户的所有本地收藏') + //
                      (_searchKeyword.isNotEmpty ? ' ("$_searchKeyword" 的搜索结果)' : ''),
                  rightWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchKeyword.isNotEmpty)
                        HelpIconView.asButton(
                          iconData: Icons.search_off,
                          tooltip: '退出搜索',
                          onPressed: () => _exitSearch(),
                        ),
                      if (_sortMethod != SortMethod.byTimeDesc)
                        HelpIconView.asButton(
                          iconData: _sortMethod.toIcon(),
                          tooltip: '漫画排序方式',
                          onPressed: () => _toSort(),
                        ),
                      if (_searchKeyword.isNotEmpty || _sortMethod != SortMethod.byTimeDesc)
                        Container(
                          color: Theme.of(context).dividerColor,
                          child: SizedBox(height: 20, width: 1),
                          margin: EdgeInsets.only(left: 5, right: 5 + 3),
                        ),
                      Text('共 $_total 部'),
                      SizedBox(width: 5),
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
                          if (_sortMethod != SortMethod.byTimeDesc)
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
