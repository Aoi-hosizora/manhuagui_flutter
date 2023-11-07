import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/dlg/list_assist_dialog.dart';
import 'package:manhuagui_flutter/page/dlg/manga_dialog.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/fit_system_screenshot.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/manga_history_line.dart';
import 'package:manhuagui_flutter/page/view/multi_selection_fab.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 订阅-阅读历史
class HistorySubPage extends StatefulWidget {
  const HistorySubPage({
    Key? key,
    this.action,
    this.isSepPage = false,
  }) : super(key: key);

  final ActionController? action;
  final bool isSepPage;

  @override
  _HistorySubPageState createState() => _HistorySubPageState();
}

class _HistorySubPageState extends State<HistorySubPage> with AutomaticKeepAliveClientMixin, FitSystemScreenshotMixin {
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
    widget.action?.addAction('clear', () => _clearHistories());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandlers.add(AuthManager.instance.listenOnlyWhen(Tuple1(AuthManager.instance.authData), (_) {
        _searchKeyword = ''; // 清空搜索关键词
        if (mounted) setState(() {});
        _pdvKey.currentState?.refresh();
      }));
      await AuthManager.instance.check();
    });
    _cancelHandlers.add(EventBusManager.instance.listen<HistoryUpdatedEvent>((ev) => _updateByEvent(ev)));
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    widget.action?.removeAction('clear');
    _cancelHandlers.forEach((c) => c.call());
    _controller.dispose();
    _fabController.dispose();
    _msController.dispose();
    _flagStorage.dispose();
    super.dispose();
  }

  final _data = <MangaHistory>[];
  var _total = 0;
  var _removed = 0; // for query offset
  late final _flagStorage = MangaCornerFlagStorage(stateSetter: () => mountedSetState(() {}), ignoreHistories: false /* for history read flag */);
  var _includeUnread = true; // for query condition
  var _searchKeyword = ''; // for query condition
  var _searchTitleOnly = true; // for query condition
  var _isUpdated = false;

  Future<PagedList<MangaHistory>> _getData({required int page}) async {
    if (page == 1) {
      // refresh
      _removed = 0;
      _isUpdated = false;
    }
    var username = AuthManager.instance.username; // maybe empty, which represents local history
    var data = await HistoryDao.getHistories(username: username, includeUnread: _includeUnread, keyword: _searchKeyword, pureSearch: _searchTitleOnly, page: page, offset: _removed) ?? [];
    _total = await HistoryDao.getHistoryCount(username: username, includeUnread: _includeUnread, keyword: _searchKeyword, pureSearch: _searchTitleOnly) ?? 0;
    if (mounted) setState(() {});
    _flagStorage.queryAndStoreFlags(mangaIds: data.map((e) => e.mangaId), queryHistories: true /* for history read flag */).then((_) => mountedSetState(() {}));
    return PagedList(list: data, next: page + 1);
  }

  void _updateByEvent(HistoryUpdatedEvent event) async {
    if (event.reason == UpdateReason.added) {
      // 新增 => 显示有更新
      _isUpdated = true;
      if (mounted) setState(() {});
    }
    if (event.reason == UpdateReason.updated && !event.fromHistoryPage) {
      // 非本页引起的更新 => 显示有更新
      _isUpdated = true;
      if (mounted) setState(() {});
    }
    if (event.reason == UpdateReason.deleted && !event.fromHistoryPage) {
      // 非本页引起的删除 => 显示有更新
      _isUpdated = true;
      if (mounted) setState(() {});
    }
    if (!widget.isSepPage && event.fromSepHistoryPage) {
      // 单独页引起的变更 => 显示有更新 (仅限主页子页)
      _isUpdated = true;
      if (mounted) setState(() {});
    }
  }

  Future<void> _toSearch() async {
    var result = await showKeywordDialogForSearching(
      context: context,
      title: '搜索漫画阅读历史',
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

  void _showPopupMenu({required int mangaId}) {
    var history = _data.where((el) => el.mangaId == mangaId).firstOrNull;
    if (history == null) {
      return;
    }

    // 退出多选模式、弹出菜单
    _msController.exitMultiSelectionMode();
    showPopupMenuForMangaList(
      context: context,
      mangaId: history.mangaId,
      mangaTitle: history.mangaTitle,
      mangaCover: history.mangaCover,
      mangaUrl: history.mangaUrl,
      extraData: null,
      fromHistoryList: true,
      inHistorySetter: (inHistory) {
        // (更新数据库)、更新界面[↴]、(弹出提示)、(发送通知)
        // 本页引起的删除 => 更新列表显示
        if (!inHistory) {
          _data.removeWhere((el) => el.mangaId == history.mangaId);
          _total--;
          _removed++;
          if (mounted) setState(() {});

          // 独立页时发送额外通知，让主页子页显示有更新 (fromSepHistoryPage)
          if (widget.isSepPage) {
            EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: mangaId, reason: UpdateReason.deleted, fromHistoryPage: true, fromSepHistoryPage: true));
          }
        }
      },
    );
  }

  Future<void> _deleteHistories({required List<int> mangaIds}) async {
    var histories = _data.where((el) => mangaIds.contains(el.mangaId)).toList();
    if (histories.isEmpty) {
      return;
    }

    // 不退出多选模式、先弹出对话框
    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('删除确认'),
        content: histories.length == 1 //
            ? Text('是否删除《${histories.first.mangaTitle}》阅读历史，包括所有的章节阅读历史？')
            : Text(
                '是否删除以下 ${histories.length} 项阅读历史，包括所有的章节阅读历史？\n\n' + //
                    [for (int i = 0; i < histories.length; i++) '${i + 1}. 《${histories[i].mangaTitle}》'].join('\n'),
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
      await HistoryDao.deleteHistory(username: AuthManager.instance.username, mid: mangaId);
      await HistoryDao.clearMangaFootprints(username: AuthManager.instance.username, mid: mangaId);
      _data.removeWhere((h) => h.mangaId == mangaId);
      _total--;
      _removed++;
    }
    if (mounted) setState(() {});
    for (var mangaId in mangaIds) {
      EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: mangaId, reason: UpdateReason.deleted, fromHistoryPage: true));
      EventBusManager.instance.fire(FootprintUpdatedEvent(mangaId: mangaId, chapterIds: null, reason: UpdateReason.deleted)); // currently no need for fromHistoryPage flag
    }

    // 独立页时发送额外通知，让主页子页显示有更新 (fromSepHistoryPage)
    if (widget.isSepPage) {
      for (var mangaId in mangaIds) {
        EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: mangaId, reason: UpdateReason.deleted, fromHistoryPage: true, fromSepHistoryPage: true));
      }
    }
  }

  Future<void> _clearHistories() async {
    _total = await HistoryDao.getHistoryCount(username: AuthManager.instance.username) ?? 0;
    if (_total == 0) {
      Fluttertoast.showToast(msg: '当前无漫画阅读历史');
      return;
    }

    // 不退出多选模式、先弹出对话框
    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('清空确认'),
        content: Text('是否清空所有阅读历史？'),
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
    await HistoryDao.clearHistories(username: AuthManager.instance.username);
    await HistoryDao.clearAllFootprints(username: AuthManager.instance.username);
    var mangaIds = _data.map((el) => el.mangaId).toList();
    _data.clear();
    _total = 0;
    _removed = mangaIds.length;
    if (mounted) setState(() {});
    for (var mangaId in mangaIds) {
      EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: mangaId, reason: UpdateReason.deleted, fromHistoryPage: true));
      EventBusManager.instance.fire(FootprintUpdatedEvent(mangaId: mangaId, chapterIds: null, reason: UpdateReason.deleted)); // currently no need for fromHistoryPage flag
    }

    // 独立页时发送额外通知，让主页子页显示有更新 (fromSepHistoryPage)
    if (widget.isSepPage) {
      for (var mangaId in mangaIds) {
        EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: mangaId, reason: UpdateReason.deleted, fromHistoryPage: true, fromSepHistoryPage: true));
      }
    }
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
        body: MultiSelectable<ValueKey<int>>(
          controller: _msController,
          stateSetter: () => mountedSetState(() {}),
          onModeChanged: (_) => mountedSetState(() {}),
          child: PaginationDataView<MangaHistory>(
            key: _pdvKey,
            data: _data,
            style: !AppSetting.instance.ui.showTwoColumns ? UpdatableDataViewStyle.listView : UpdatableDataViewStyle.gridView,
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
            itemBuilder: (c, _, item) => SelectableCheckboxItem<ValueKey<int>>(
              key: ValueKey<int>(item.mangaId),
              checkboxPosition: PositionArgument.fromLTRB(null, 0, 11, 0),
              checkboxBuilder: (_, __, tip) => CheckboxForSelectableItem(tip: tip, backgroundColor: Theme.of(context).scaffoldBackgroundColor),
              useFullRipple: true,
              onFullRippleLongPressed: (c, key, tip) => _msController.selectedItems.length == 1 && tip.selected ? _showPopupMenu(mangaId: key.value) : tip.toToggle?.call(),
              itemBuilder: (c, key, tip) => MangaHistoryLineView(
                history: item,
                flags: _flagStorage.getFlags(mangaId: item.mangaId, forceInHistory: true),
                twoColumns: AppSetting.instance.ui.showTwoColumns,
                onLongPressed: !tip.isNormal ? null : () => _msController.enterMultiSelectionMode(alsoSelect: [key]),
              ),
            ),
            extra: UpdatableDataViewExtraWidgets(
              outerTopWidgets: [
                ListHintView.textWidget(
                  padding: EdgeInsets.fromLTRB(10, 5, 10 - 3, 5), // for popup btn
                  leftText: (AuthManager.instance.logined ? '${AuthManager.instance.username} 的阅读历史' : '未登录用户的阅读历史') + //
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
                      if (_searchKeyword.isNotEmpty)
                        Container(
                          color: Theme.of(context).dividerColor,
                          child: SizedBox(height: 20, width: 1),
                          margin: EdgeInsets.only(left: 5, right: 5 + 3),
                        ),
                      Text('共 $_total 部'),
                      SizedBox(width: 5),
                      HelpIconView.forListHint(
                        title: '阅读历史',
                        hint: '提示：由于漫画柜官方并未提供记录漫画阅读历史的功能，所以本应用的阅读历史仅被记录在移动端本地，且不同账号间的阅读历史互不影响。',
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
                              _includeUnread ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                              '显示未阅读的漫画',
                            ),
                            onTap: () {
                              _includeUnread = !_includeUnread;
                              if (mounted) setState(() {});
                              _pdvKey.currentState?.refresh();
                            },
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
              child: Icon(Icons.delete),
              tooltip: '删除漫画历史',
              onPressed: () => _deleteHistories(mangaIds: _msController.selectedItems.map((e) => e.value).toList()),
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
