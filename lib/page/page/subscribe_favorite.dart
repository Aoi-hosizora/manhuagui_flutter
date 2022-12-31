import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/favorite_manga_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/manga_corner_icons.dart';
import 'package:manhuagui_flutter/page/view/multi_selection_fab.dart';
import 'package:manhuagui_flutter/page/view/setting_dialog.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 订阅-本地收藏
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
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  final _msController = MultiSelectableController<ValueKey<int>>();
  final _cancelHandlers = <VoidCallback>[];
  AuthData? _oldAuthData;

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _controller.scrollToTop());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandlers.add(AuthManager.instance.listen(() => _oldAuthData, (_) {
        _oldAuthData = AuthManager.instance.authData;
        _pdvKey.currentState?.refresh();
      }));
      await AuthManager.instance.check();
    });
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    _cancelHandlers.forEach((c) => c.call());
    _flagStorage.dispose();
    _controller.dispose();
    _fabController.dispose();
    _msController.dispose();
    super.dispose();
  }

  final _data = <FavoriteManga>[];
  final _histories = <int, MangaHistory?>{};
  late final _flagStorage = MangaCornerFlagsStorage(stateSetter: () => mountedSetState(() {}));
  var _total = 0;
  var _removed = 0;

  Future<PagedList<FavoriteManga>> _getData({required int page}) async {
    if (page == 1) {
      // refresh
      _removed = 0;
    }
    var username = AuthManager.instance.username;
    var data = await FavoriteDao.getFavorites(username: username, page: page, offset: _removed) ?? [];
    _total = await FavoriteDao.getFavoriteCount(username: username) ?? 0;
    for (var item in data) {
      _histories[item.mangaId] = await HistoryDao.getHistory(username: username, mid: item.mangaId);
    }
    await _flagStorage.queryAndStoreFlags(mangaIds: data.map((e) => e.mangaId), toQueryFavorites: false);
    if (mounted) setState(() {});
    return PagedList(list: data, next: page + 1);
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
      EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inShelf: null, inFavorite: false));
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
        if (!_msController.multiSelecting) {
          return true;
        }
        _msController.exitMultiSelectionMode();
        return false;
      },
      child: Scaffold(
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
              checkboxPosition: PositionArgument.fromLTRB(null, 0, 15, 0),
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
              innerTopWidgets: [
                ListHintView.textWidget(
                  leftText: (AuthManager.instance.logined ? '${AuthManager.instance.username} 的本地收藏' : '本地收藏'),
                  rightWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('共 $_total 部'),
                      SizedBox(width: 5),
                      HelpIconView(
                        title: '"本地收藏"与"我的书架"的区别',
                        hint: '"我的书架"与漫画柜网页版保持同步，但受限于网页版功能，"我的书架"只能按照漫画更新时间排序显示；\n\n'
                            '"本地收藏"仅记录在移动端本地，不提供章节更新提醒，但"本地收藏"的显示顺序可自由调整，默认添加至列表末尾或开头。',
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
          multiSelectableController: _msController,
          onCounterPressed: () {
            var mangaIds = _msController.selectedItems.map((e) => e.value).toList();
            var titles = _data.where((el) => mangaIds.contains(el.mangaId)).map((m) => '《${m.mangaTitle}》').toList();
            MultiSelectionFabContainer.showSelectedItemsDialogForCounter(context, titles);
          },
          fabForMultiSelection: [
            MultiSelectionFabOption(
              child: Icon(Icons.delete),
              onPressed: () => _deleteFavorites(mangaIds: _msController.selectedItems.map((e) => e.value).toList()),
            ),
          ],
        ),
      ),
    );
  }
}
