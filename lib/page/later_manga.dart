import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/dlg/list_assist_dialog.dart';
import 'package:manhuagui_flutter/page/dlg/manga_dialog.dart';
import 'package:manhuagui_flutter/page/search.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/page/view/later_manga_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/multi_selection_fab.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/db/later_manga.dart';
import 'package:manhuagui_flutter/service/db/query_helper.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 漫画稍后阅读页，查询并展示 [LaterManga] 列表信息，并提供列表整理功能
class LaterMangaPage extends StatefulWidget {
  const LaterMangaPage({Key? key}) : super(key: key);

  @override
  State<LaterMangaPage> createState() => _LaterMangaPageState();
}

class _LaterMangaPageState extends State<LaterMangaPage> {
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
    _cancelHandlers.add(EventBusManager.instance.listen<AppSettingChangedEvent>((_) => mountedSetState(() {})));
    _cancelHandlers.add(EventBusManager.instance.listen<LaterMangaUpdatedEvent>((ev) => _updateByEvent(ev)));
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

  final _data = <LaterManga>[];
  var _total = 0;
  var _removed = 0; // for query offset
  late final _flagStorage = MangaCornerFlagStorage(stateSetter: () => mountedSetState(() {}), ignoreLaters: true);
  final _histories = <int, MangaHistory?>{};
  var _searchKeyword = ''; // for query condition
  var _searchTitleOnly = true; // for query condition
  var _sortMethod = SortMethod.byTimeDesc; // for query condition
  var _isUpdated = false;

  Future<PagedList<LaterManga>> _getData({required int page}) async {
    if (page == 1) {
      // refresh
      _removed = 0;
      _isUpdated = false;
    }
    var username = AuthManager.instance.username; // maybe empty, which represents local records
    var data = await LaterMangaDao.getLaterMangas(username: username, keyword: _searchKeyword, pureSearch: _searchTitleOnly, sortMethod: _sortMethod, page: page, offset: _removed) ?? [];
    _total = await LaterMangaDao.getLaterMangaCount(username: username, keyword: _searchKeyword, pureSearch: _searchTitleOnly) ?? 0;
    if (mounted) setState(() {});
    for (var item in data) {
      _histories[item.mangaId] = await HistoryDao.getHistory(username: username, mid: item.mangaId);
    }
    if (mounted) setState(() {});
    _flagStorage.queryAndStoreFlags(mangaIds: data.map((e) => e.mangaId), queryLaters: false).then((_) => mountedSetState(() {}));
    return PagedList(list: data, next: page + 1);
  }

  void _updateByEvent(LaterMangaUpdatedEvent event) async {
    if (event.added) {
      // 新增 => 显示有更新
      _isUpdated = true;
      if (mounted) setState(() {});
    }
    if (!event.added && !event.fromLaterMangaPage) {
      // 非本页引起的删除 => 显示有更新
      _isUpdated = true;
      if (mounted) setState(() {});
    }
  }

  Future<void> _toSearch() async {
    var result = await showKeywordDialogForSearching(
      context: context,
      title: '搜索稍后阅读漫画',
      textValue: _searchKeyword,
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
      currValue: _sortMethod,
      idTitle: '漫画ID',
      nameTitle: '漫画标题',
      timeTitle: '添加时间',
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
    var manga = _data.where((el) => el.mangaId == mangaId).firstOrNull;
    if (manga == null) {
      return;
    }

    // 退出多选模式、弹出菜单
    _msController.exitMultiSelectionMode();
    showPopupMenuForMangaList(
      context: context,
      mangaId: manga.mangaId,
      mangaTitle: manga.mangaTitle,
      mangaCover: manga.mangaCover,
      mangaUrl: manga.mangaUrl,
      fromLaterList: true,
      inLaterSetter: (inLater) {
        // (更新数据库)、更新界面[↴]、(弹出提示)、(发送通知)
        // 本页引起的删除 => 更新列表显示
        if (!inLater) {
          _data.removeWhere((el) => el.mangaId == manga.mangaId);
          _total--;
          _removed++;
          if (mounted) setState(() {});
        }
      },
    );
  }

  Future<void> _topmostLaterManga({required int mangaId}) async {
    var manga = _data.where((el) => el.mangaId == mangaId).firstOrNull;
    if (manga == null) {
      return;
    }

    // 退出多选模式
    _msController.exitMultiSelectionMode();

    // 更新数据库、更新界面、弹出提示、发送通知
    var updatedManga = manga.copyWith(createdAt: DateTime.now());
    await LaterMangaDao.addOrUpdateLaterManga(username: AuthManager.instance.username, manga: updatedManga);
    _data.removeWhere((el) => el.mangaId == manga.mangaId);
    _data.insert(0, updatedManga);
    if (mounted) setState(() {});
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已将漫画置顶于稍后阅读列表')));
    EventBusManager.instance.fire(LaterMangaUpdatedEvent(mangaId: mangaId, added: false, fromLaterMangaPage: true));
  }

  Future<void> _deleteLaterMangas({required List<int> mangaIds}) async {
    var mangas = _data.where((el) => mangaIds.contains(el.mangaId)).toList();
    if (mangas.isEmpty) {
      return;
    }

    // 不退出多选模式、先弹出对话框
    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('删除确认'),
        content: mangas.length == 1 //
            ? Text('是否将《${mangas.first.mangaTitle}》移出稍后阅读列表？')
            : Text(
                '是否将以下 ${mangas.length} 部漫画移出稍后阅读列表？\n\n' + //
                    [for (int i = 0; i < mangas.length; i++) '${i + 1}. 《${mangas[i].mangaTitle}》'].join('\n'),
              ),
        scrollable: true,
        actions: [
          TextButton(child: Text('移出'), onPressed: () => Navigator.of(c).pop(true)),
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
      await LaterMangaDao.deleteLaterManga(username: AuthManager.instance.username, mid: mangaId);
      _data.removeWhere((el) => el.mangaId == mangaId);
      _total--;
      _removed++;
    }
    if (mounted) setState(() {});
    for (var mangaId in mangaIds) {
      EventBusManager.instance.fire(LaterMangaUpdatedEvent(mangaId: mangaId, added: false, fromLaterMangaPage: true));
    }
  }

  Future<void> _clearLaterMangas() async {
    _total = await LaterMangaDao.getLaterMangaCount(username: AuthManager.instance.username) ?? 0;
    if (_total == 0) {
      Fluttertoast.showToast(msg: '当前无稍后阅读记录');
      return;
    }

    // 不退出多选模式、先弹出对话框
    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('清空确认'),
        content: Text('是否清空稍后阅读列表？'),
        actions: [
          TextButton(child: Text('清空'), onPressed: () => Navigator.of(c).pop(true)),
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
    await LaterMangaDao.clearLaterMangas(username: AuthManager.instance.username);
    var mangaIds = _data.map((el) => el.mangaId).toList();
    _data.clear();
    _total = 0;
    _removed = mangaIds.length;
    if (mounted) setState(() {});
    for (var mangaId in mangaIds) {
      EventBusManager.instance.fire(LaterMangaUpdatedEvent(mangaId: mangaId, added: false, fromLaterMangaPage: true));
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
          title: Text('稍后阅读列表'),
          leading: AppBarActionButton.leading(context: context, allowDrawerButton: false),
          actions: [
            AppBarActionButton(
              icon: Icon(Icons.delete),
              tooltip: '清空稍后阅读列表',
              onPressed: () => _clearLaterMangas(),
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
          currentSelection: DrawerSelection.later,
        ),
        drawerEdgeDragWidth: MediaQuery.of(context).size.width,
        body: MultiSelectable<ValueKey<int>>(
          controller: _msController,
          stateSetter: () => mountedSetState(() {}),
          onModeChanged: (_) => mountedSetState(() {}),
          child: PaginationDataView<LaterManga>(
            key: _pdvKey,
            data: _data,
            style: !AppSetting.instance.ui.showTwoColumns ? UpdatableDataViewStyle.listView : UpdatableDataViewStyle.gridView,
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
              itemBuilder: (c, key, tip) => LaterMangaLineView(
                manga: item,
                history: _histories[item.mangaId],
                flags: _flagStorage.getFlags(mangaId: item.mangaId, forceInLater: true),
                twoColumns: AppSetting.instance.ui.showTwoColumns,
                onLongPressed: !tip.isNormal ? null : () => _msController.enterMultiSelectionMode(alsoSelect: [key]),
              ),
            ),
            extra: UpdatableDataViewExtraWidgets(
              outerTopWidgets: [
                ListHintView.textWidget(
                  padding: EdgeInsets.fromLTRB(10, 5, 10 - 3, 5), // for popup btn
                  leftText: (AuthManager.instance.logined ? '${AuthManager.instance.username} 的稍后阅读列表' : '未登录用户的稍后阅读列表') + //
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
                          // TODO add added date filter
                        ],
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
              child: Icon(MdiIcons.sortClockDescending),
              tooltip: '置顶稍后阅读记录',
              show: _msController.selectedItems.length == 1,
              onPressed: () => _topmostLaterManga(mangaId: _msController.selectedItems.first.value),
            ),
            MultiSelectionFabOption(
              child: Icon(Icons.delete),
              tooltip: '删除漫画记录',
              onPressed: () => _deleteLaterMangas(mangaIds: _msController.selectedItems.map((e) => e.value).toList()),
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
