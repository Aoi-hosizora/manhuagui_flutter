import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/dlg/category_dialog.dart';
import 'package:manhuagui_flutter/page/view/category_grid_list.dart';
import 'package:manhuagui_flutter/page/view/category_popup.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/page/view/tiny_manga_line.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/prefs/marked_category.dart';

/// 分类-漫画类别
class MangaCategorySubPage extends StatefulWidget {
  const MangaCategorySubPage({
    Key? key,
    this.action,
    this.defaultGenre,
  }) : super(key: key);

  final ActionController? action;
  final TinyCategory? defaultGenre;

  @override
  _MangaCategorySubPageState createState() => _MangaCategorySubPageState();
}

class _MangaCategorySubPageState extends State<MangaCategorySubPage> with AutomaticKeepAliveClientMixin {
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _controllerForCategory = ScrollController();
  final _fabControllerForCategory = AnimatedFabController();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => (!_chosen ? _controllerForCategory : _controller).scrollToTop());
    widget.action?.addAction('ifNeedBack', () => _chosen);
    widget.action?.addAction('back', () => _chooseCategory(toChoose: false));
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadGenres());
    _cancelHandlers.add(EventBusManager.instance.listen<MarkedCategoryUpdatedEvent>((ev) => _updateByEvent(ev)));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    widget.action?.removeAction();
    widget.action?.removeAction('ifNeedBack');
    widget.action?.removeAction('back');
    _controllerForCategory.dispose();
    _fabControllerForCategory.dispose();
    _controller.dispose();
    _fabController.dispose();
    _flagStorage.dispose();
    super.dispose();
  }

  var _genreLoading = true; // initialize to true
  final _genres = <TinyCategory>[];
  var _genreError = '';
  final _markedCategoryNames = <String>[];

  Future<void> _loadGenres() async {
    var categories = await MarkedCategoryPrefs.getMarkedCategories();
    _markedCategoryNames.clear();
    _markedCategoryNames.addAll(categories);

    _genreLoading = true;
    if (mounted) setState(() {});

    final client = RestClient(DioManager.instance.dio);
    try {
      if (globalCategoryList == null) {
        var result = await client.getCategories();
        globalCategoryList ??= result.data; // 更新全局的漫画类别
      }
      _genres.clear();
      _genreError = '';
      if (mounted) setState(() {});
      await Future.delayed(kFlashListDuration);
      _genres.add(allGenres[0]);
      _genres.addAll(globalCategoryList!.genres.map((g) => g.toTiny()).toList());
      if (widget.defaultGenre != null) {
        // update CategorySubPage or SepCategoryPage if have default genre (_chosen == true)
        widget.action?.invoke('updateSubPage');
      }
    } catch (e, s) {
      _genres.clear();
      _genreError = wrapError(e, s).text;
    } finally {
      _genreLoading = false;
      if (mounted) setState(() {});
    }
  }

  void _updateByEvent(MarkedCategoryUpdatedEvent ev) async {
    var categories = await MarkedCategoryPrefs.getMarkedCategories();
    _markedCategoryNames.clear();
    _markedCategoryNames.addAll(categories);
    if (mounted) setState(() {});
  }

  late var _chosen = widget.defaultGenre != null; // initialize to false if defaultGenre is null
  late final _currGenre = RestorableObject(widget.defaultGenre ?? allGenres[0]);
  final _currAge = RestorableObject(allAges[0]);
  final _currZone = RestorableObject(allZones[0]);
  final _currStatus = RestorableObject(allStatuses[0]);
  final _currOrder = RestorableObject(AppSetting.instance.ui.defaultMangaOrder);

  void _chooseCategory({required bool toChoose, TinyCategory? genre, TinyCategory? age, TinyCategory? zone}) {
    if (toChoose == _chosen) {
      return;
    }

    _chosen = toChoose;
    _currGenre.select(genre ?? allGenres[0], sameLast: true);
    _currAge.select(age ?? allAges[0], sameLast: true);
    _currZone.select(zone ?? allZones[0], sameLast: true);
    _currStatus.select(allStatuses[0], sameLast: true);
    _currOrder.select(AppSetting.instance.ui.defaultMangaOrder, sameLast: true);

    _data.clear();
    _total = 0;
    widget.action?.invoke('updateSubPage'); // update CategorySubPage or SepCategoryPage
    if (mounted) setState(() {});
  }

  final _data = <TinyManga>[];
  var _total = 0;
  late final _flagStorage = MangaCornerFlagStorage(stateSetter: () => mountedSetState(() {}));
  var _getting = false;

  Future<PagedList<TinyManga>> _getData({required int page}) async {
    final client = RestClient(DioManager.instance.dio);
    var f = client.getGenreMangas /* get category mangas */ (
      genre: _currGenre.curr.name,
      zone: _currZone.curr.name,
      age: _currAge.curr.name,
      status: _currStatus.curr.name,
      page: page,
      order: _currOrder.curr,
    );
    var result = await f.onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
    _total = result.data.total;
    if (mounted) setState(() {});
    _flagStorage.queryAndStoreFlags(mangaIds: result.data.data.map((e) => e.mid)).then((_) => mountedSetState(() {}));
    return PagedList(list: result.data.data, next: result.data.page + 1);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: () async {
        if (_chosen && _currGenre.curr != widget.defaultGenre) {
          _chooseCategory(toChoose: false); // only de-choose if pop when current genre is not the default genre
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: PlaceholderText.from(
          isLoading: _genreLoading,
          errorText: _genreError,
          isEmpty: _genres.isEmpty,
          onRefresh: () => _loadGenres(),
          setting: PlaceholderSetting(
            useAnimatedSwitcher: _currGenre.curr != widget.defaultGenre /* only animate when current genre is not the default genre */,
            customNormalStateBuilder: (c, _, childBuilder) => _chosen
                ? childBuilder.call(c) // normal state
                : CategoryGridListView(
                    key: PageStorageKey<String>('MangaCategorySubPage_CategoryGridListView'),
                    title: '选择一个漫画类别来筛选漫画',
                    genres: _genres,
                    markedCategoryNames: _markedCategoryNames,
                    controller: _controllerForCategory,
                    onChoose: ({genre, age, zone}) => _chooseCategory(toChoose: true, genre: genre, age: age, zone: zone),
                    onLongPressed: ({genre, age, zone}) => showCategoryPopupMenu(
                      context: context,
                      category: genre ?? age ?? zone ?? allGenres[0],
                      onSelected: (_) => _chooseCategory(toChoose: true, genre: genre, age: age, zone: zone),
                    ),
                  ),
          ).copyWithChinese(),
          childBuilder: (c) => PaginationDataView<TinyManga>(
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
              onPlaceholderStateChanged: (_, __) => _fabController.hasClient.ifTrue(() => _fabController.hide()),
              refreshFirst: true /* <<< refresh first */,
              clearWhenRefresh: false,
              clearWhenError: false,
              updateOnlyIfNotEmpty: false,
              onStartGettingData: () => mountedSetState(() => _getting = true),
              onStopGettingData: () => mountedSetState(() => _getting = false),
              onAppend: (_, l) => [_currGenre, _currAge, _currZone, _currStatus, _currOrder].forEach((c) => c.pass()),
              onError: (e) {
                if (_data.isNotEmpty) {
                  Fluttertoast.showToast(msg: e.toString());
                }
                [_currGenre, _currAge, _currZone, _currStatus, _currOrder].forEach((c) => c.restore());
                if (mounted) setState(() {});
              },
            ),
            separator: Divider(height: 0, thickness: 1),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 0.0,
              mainAxisSpacing: 0.0,
              childAspectRatio: GeneralLineView.getChildAspectRatioForTwoColumns(context),
            ),
            itemBuilder: (c, _, item) => TinyMangaLineView(
              manga: item,
              history: _flagStorage.getHistory(mangaId: item.mid),
              flags: _flagStorage.getFlags(mangaId: item.mid),
              twoColumns: AppSetting.instance.ui.showTwoColumns,
              highlightRecent: AppSetting.instance.ui.highlightRecentMangas,
            ),
            extra: UpdatableDataViewExtraWidgets(
              outerTopWidgets: [
                ListHintView.widgets(
                  widgets: [
                    for (var t in [
                      Tuple4(_genres, _currGenre, '剧情', true),
                      Tuple4(allAges, _currAge, '受众', true),
                      Tuple4(allZones, _currZone, '地区', true),
                      Tuple4(allStatuses, _currStatus, '进度', false),
                    ])
                      CategoryPopupView(
                        categories: t.item1,
                        selectedCategory: t.item2.curr,
                        markedCategoryNames: t.item4 ? _markedCategoryNames : [],
                        defaultName: t.item3,
                        enable: !_getting,
                        allowLongPressCategory: t.item4,
                        onSelected: (c) {
                          t.item2.select(c, alsoPass: true);
                          if (mounted) setState(() {});
                          _pdvKey.currentState?.refresh();
                        },
                        onLongPressed: () => _chooseCategory(toChoose: false),
                      ),
                  ],
                ),
              ],
              innerTopWidgets: [
                ListHintView.textWidget(
                  leftText: '筛选结果 (共 $_total 部)',
                  rightWidget: OptionPopupView<MangaOrder>(
                    items: const [MangaOrder.byPopular, MangaOrder.byNew, MangaOrder.byUpdate],
                    value: _currOrder.curr,
                    titleBuilder: (c, v) => v.toTitle(),
                    enable: !_getting,
                    onSelected: (o) {
                      if (_currOrder.curr != o) {
                        _currOrder.select(o, alsoPass: true);
                        if (mounted) setState(() {});
                        _pdvKey.currentState?.refresh();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Stack(
          children: [
            ScrollAnimatedFab(
              controller: _fabControllerForCategory,
              scrollController: _controllerForCategory,
              condition: _chosen ? ScrollAnimatedCondition.forceHide : ScrollAnimatedCondition.direction,
              fab: FloatingActionButton(
                child: Icon(Icons.vertical_align_top),
                heroTag: null,
                onPressed: () => _controllerForCategory.scrollToTop(),
              ),
            ),
            ScrollAnimatedFab(
              controller: _fabController,
              scrollController: _controller,
              condition: !_chosen ? ScrollAnimatedCondition.forceHide : ScrollAnimatedCondition.direction,
              fab: FloatingActionButton(
                child: Icon(Icons.vertical_align_top),
                heroTag: null,
                onPressed: () => _controller.scrollToTop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
