import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/dlg/author_dialog.dart';
import 'package:manhuagui_flutter/page/dlg/list_assist_dialog.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/favorite_author_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/multi_selection_fab.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/db/query_helper.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 已收藏漫画作者页，查询 [FavoriteAuthor] 列表并展示
class FavoriteAuthorPage extends StatefulWidget {
  const FavoriteAuthorPage({Key? key}) : super(key: key);

  @override
  State<FavoriteAuthorPage> createState() => _FavoriteAuthorPageState();
}

class _FavoriteAuthorPageState extends State<FavoriteAuthorPage> {
  final _pdvKey = GlobalKey<PaginationDataViewState>();
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
    _cancelHandlers.add(EventBusManager.instance.listen<FavoriteAuthorUpdatedEvent>((ev) => _updateByEvent(ev)));
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

  final _data = <FavoriteAuthor>[];
  var _total = 0;
  var _removed = 0; // for query offset
  late final _flagStorage = AuthorCornerFlagStorage(stateSetter: () => mountedSetState(() {}), ignoreFavorites: true);
  var _searchKeyword = ''; // for query condition
  var _searchNameOnly = true; // for query condition
  var _sortMethod = SortMethod.byTimeDesc; // for query condition
  var _isUpdated = false;

  Future<PagedList<FavoriteAuthor>> _getData({required int page}) async {
    if (page == 1) {
      // refresh
      _removed = 0;
      _isUpdated = false;
    }
    var username = AuthManager.instance.username;
    var data = await FavoriteDao.getAuthors(username: username, keyword: _searchKeyword, pureSearch: _searchNameOnly, sortMethod: _sortMethod, page: page, offset: _removed) ?? [];
    _total = await FavoriteDao.getAuthorCount(username: username, keyword: _searchKeyword, pureSearch: _searchNameOnly) ?? 0;
    if (mounted) setState(() {});
    _flagStorage.queryAndStoreFlags(authorIds: data.map((e) => e.authorId), queryFavorites: false).then((_) => mountedSetState(() {})); // actually this will do nothing
    return PagedList(list: data, next: page + 1);
  }

  void _updateByEvent(FavoriteAuthorUpdatedEvent event) async {
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
  }

  Future<void> _toSearch() async {
    var result = await showKeywordDialogForSearching(
      context: context,
      title: '搜索已收藏的漫画作者',
      textValue: _searchKeyword,
      optionTitle: '仅搜索作者名',
      optionValue: _searchNameOnly,
      optionHint: (only) => only ? '当前选项使得本次仅搜索作者名' : '当前选项使得本次将搜索作者ID、作者名以及收藏备注',
    );
    if (result != null && result.item1.isNotEmpty) {
      _searchKeyword = result.item1;
      _searchNameOnly = result.item2;
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
      title: '漫画作者排序方式',
      currValue: _sortMethod,
      idTitle: '作者ID',
      nameTitle: '作者名',
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

  void _showPopupMenu({required int authorId}) {
    var author = _data.where((el) => el.authorId == authorId).firstOrNull;
    if (author == null) {
      return;
    }

    // 退出多选模式、弹出菜单
    _msController.exitMultiSelectionMode();
    showPopupMenuForAuthorList(
      context: context,
      authorId: author.authorId,
      authorName: author.authorName,
      authorCover: author.authorCover,
      authorUrl: author.authorUrl,
      authorZone: author.authorZone,
      fromFavoriteList: true,
      inFavoriteSetter: (inFavorite) {
        // (更新数据库)、更新界面[↴]、(弹出提示)、(发送通知)
        // 本页引起的删除 => 更新列表显示
        if (!inFavorite) {
          _data.removeWhere((el) => el.authorId == author.authorId);
          _total--;
          _removed++;
          if (mounted) setState(() {});
        }
      },
    );
  }

  void _updateFavoriteRemark({required int authorId}) {
    var oldFavorite = _data.where((el) => el.authorId == authorId).firstOrNull;
    if (oldFavorite == null) {
      return;
    }

    // 不退出多选模式、先弹出菜单
    showUpdateFavoriteAuthorRemarkDialog(
      context: context,
      favoriteAuthor: oldFavorite,
      onUpdated: (newFavorite) {
        // (更新数据库)、退出多选模式、更新界面[↴]、(弹出提示)、(发送通知)
        // 本页引起的更新 => 更新列表显示
        _msController.exitMultiSelectionMode();
        _data.replaceWhere((el) => el.authorId == authorId, (_) => newFavorite);
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _deleteAuthors({required List<int> authorIds}) async {
    var authors = _data.where((el) => authorIds.contains(el.authorId)).toList();
    if (authors.isEmpty) {
      return;
    }

    // 不退出多选模式、先弹出对话框
    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('删除确认'),
        scrollable: true,
        content: authors.length == 1 //
            ? Text('是否从本地收藏中删除漫画作者 "${authors.first.authorName}"？')
            : Text(
                '是否从本地收藏删除以下 ${authors.length} 位漫画作者？\n\n' + //
                    [for (int i = 0; i < authors.length; i++) '${i + 1}. "${authors[i].authorName}"'].join('\n'),
              ),
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
    for (var authorId in authorIds) {
      await FavoriteDao.deleteAuthor(username: AuthManager.instance.username, aid: authorId);
      _data.removeWhere((h) => h.authorId == authorId);
      _total--;
      _removed++;
    }
    if (mounted) setState(() {});
    for (var authorId in authorIds) {
      EventBusManager.instance.fire(FavoriteAuthorUpdatedEvent(authorId: authorId, reason: UpdateReason.deleted, fromFavoritePage: true));
    }
  }

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
          title: Text('已收藏的漫画作者'),
          leading: AppBarActionButton.leading(context: context, allowDrawerButton: false),
          actions: [
            if (_searchKeyword.isNotEmpty)
              AppBarActionButton(
                icon: Icon(Icons.search_off),
                tooltip: '退出搜索',
                onPressed: () => _exitSearch(),
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
                  child: IconTextMenuItem(Icons.search, '搜索列表中的作者'),
                  onTap: () => WidgetsBinding.instance?.addPostFrameCallback((_) => _toSearch()),
                ),
                if (_searchKeyword.isNotEmpty)
                  PopupMenuItem(
                    child: IconTextMenuItem(Icons.search_off, '退出搜索'),
                    onTap: () => _exitSearch(),
                  ),
                PopupMenuItem(
                  child: IconTextMenuItem(Icons.sort, '作者排序方式'),
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
        drawer: AppDrawer(
          currentSelection: DrawerSelection.none,
        ),
        drawerEdgeDragWidth: MediaQuery.of(context).size.width,
        body: MultiSelectable<ValueKey<int>>(
          controller: _msController,
          stateSetter: () => mountedSetState(() {}),
          onModeChanged: (_) => mountedSetState(() {}),
          child: PaginationListView<FavoriteAuthor>(
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
            itemBuilder: (c, _, item) => SelectableCheckboxItem<ValueKey<int>>(
              key: ValueKey<int>(item.authorId),
              checkboxPosition: PositionArgument.fromLTRB(null, 0, 11, 0),
              checkboxBuilder: (_, __, tip) => CheckboxForSelectableItem(tip: tip, backgroundColor: Theme.of(context).scaffoldBackgroundColor),
              itemBuilder: (c, key, tip) => FavoriteAuthorLineView(
                author: item,
                flags: _flagStorage.getFlags(mangaId: item.authorId, forceInFavorite: true),
                onLongPressed: !tip.isNormal ? null : () => _msController.enterMultiSelectionMode(alsoSelect: [key]),
              ),
            ),
            extra: UpdatableDataViewExtraWidgets(
              outerTopWidgets: [
                ListHintView.textWidget(
                  leftText: (AuthManager.instance.logined ? '${AuthManager.instance.username} 的本地收藏' : '未登录用户的本地收藏') + //
                      (_searchKeyword.isNotEmpty ? ' ("$_searchKeyword" 的搜索结果)' : (_isUpdated ? ' (有更新)' : '')),
                  rightWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_sortMethod != SortMethod.byTimeDesc)
                        HelpIconView.asButton(
                          iconData: _sortMethod.toIcon(),
                          tooltip: '漫画排序方式',
                          onPressed: () => _toSort(),
                        ),
                      if (_sortMethod != SortMethod.byTimeDesc)
                        Container(
                          color: Theme.of(context).dividerColor,
                          child: SizedBox(height: 20, width: 1),
                          margin: EdgeInsets.only(left: 5, right: 5 + 3),
                        ),
                      Text('共 $_total 位'),
                      SizedBox(width: 5),
                      HelpIconView.forListHint(
                        title: '本地收藏的漫画作者',
                        hint: '"本地收藏"仅记录在移动端本地，但该作者列表并不支持分组管理，且不支持顺序自由调整。',
                        tooltip: '提示',
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
            var authorIds = _msController.selectedItems.map((e) => e.value).toList();
            var titles = _data.where((el) => authorIds.contains(el.authorId)).map((m) => '"${m.authorName}"').toList();
            var allKeys = _data.map((el) => ValueKey(el.authorId)).toList();
            MultiSelectionFabContainer.showCounterDialog(context, controller: _msController, selected: titles, allKeys: allKeys);
          },
          fabForMultiSelection: [
            MultiSelectionFabOption(
              child: Icon(Icons.more_horiz),
              tooltip: '查看更多选项',
              show: _msController.selectedItems.length == 1,
              onPressed: () => _showPopupMenu(authorId: _msController.selectedItems.first.value),
            ),
            MultiSelectionFabOption(
              child: Icon(MdiIcons.commentBookmark),
              tooltip: '修改收藏备注',
              show: _msController.selectedItems.length == 1,
              onPressed: () => _updateFavoriteRemark(authorId: _msController.selectedItems.first.value),
            ),
            MultiSelectionFabOption(
              child: Icon(Icons.delete),
              tooltip: '取消本地收藏',
              onPressed: () => _deleteAuthors(authorIds: _msController.selectedItems.map((e) => e.value).toList()),
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
