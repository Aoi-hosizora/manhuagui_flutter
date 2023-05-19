import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/dlg/category_dialog.dart';
import 'package:manhuagui_flutter/page/view/category_grid_list.dart';
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
  late var _chosen = widget.defaultGenre != null; // initialize to false if defaultGenre is null
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

  void _chooseCategory({required bool toChoose, TinyCategory? genre, TinyCategory? age, TinyCategory? zone}) {
    if (toChoose == _chosen) {
      return;
    }

    _currOrder = AppSetting.instance.ui.defaultMangaOrder;
    _lastOrder = AppSetting.instance.ui.defaultMangaOrder;
    _currGenre = genre ?? allGenres[0];
    _lastGenre = allGenres[0];
    _currAge = age ?? allAges[0];
    _lastAge = allAges[0];
    _currZone = zone ?? allZones[0];
    _lastZone = allZones[0];
    _currStatus = allStatuses[0];
    _lastStatus = allStatuses[0];

    _chosen = toChoose;
    _data.clear();
    _total = 0;
    widget.action?.invoke('updateSubPage'); // update CategorySubPage or SepCategoryPage
    if (mounted) setState(() {});
  }

  void _longPressCategoryOption(TinyCategory genre, void Function(TinyCategory) selectGenre, StateSetter _setState) {
    showCategoryPopupMenu(
      context: context,
      category: genre,
      onSelected: selectGenre,
      onMarkedChanged: (genre, marked) {
        (marked ? _markedCategoryNames.add : _markedCategoryNames.remove)(genre.name);
        _setState(() {});
      },
    );
  }

  final _data = <TinyManga>[];
  var _total = 0;
  late final _flagStorage = MangaCornerFlagStorage(stateSetter: () => mountedSetState(() {}));
  var _getting = false;

  var _currOrder = AppSetting.instance.ui.defaultMangaOrder;
  var _lastOrder = AppSetting.instance.ui.defaultMangaOrder;
  late var _currGenre = widget.defaultGenre ?? allGenres[0];
  late var _lastGenre = widget.defaultGenre ?? allGenres[0];
  var _currAge = allAges[0];
  var _lastAge = allAges[0];
  var _currZone = allZones[0];
  var _lastZone = allZones[0];
  var _currStatus = allStatuses[0];
  var _lastStatus = allStatuses[0];

  Future<PagedList<TinyManga>> _getData({required int page}) async {
    final client = RestClient(DioManager.instance.dio);
    var f = client.getGenreMangas /* get category mangas */ (
      genre: _currGenre.name,
      zone: _currZone.name,
      age: _currAge.name,
      status: _currStatus.name,
      page: page,
      order: _currOrder,
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
    return Scaffold(
      body: PlaceholderText.from(
        isLoading: _genreLoading,
        errorText: _genreError,
        isEmpty: _genres.isEmpty,
        onRefresh: () => _loadGenres(),
        setting: PlaceholderSetting(
          useAnimatedSwitcher: true, // TODO widget.defaultGenre == null /* only animate when no default genre */,
          customNormalStateBuilder: (c, _, childBuilder) => _chosen
              ? childBuilder.call(c) // normal state
              : CategoryGridListView(
                  key: PageStorageKey<String>('CategorySubPage_CategoryGridListView'),
                  controller: _controllerForCategory,
                  title: '选择一个漫画类别来筛选漫画',
                  genres: _genres,
                  markedCategoryNames: _markedCategoryNames,
                  // TODO test
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
            onAppend: (_, l) {
              _lastOrder = _currOrder;
              _lastGenre = _currGenre;
              _lastAge = _currAge;
              _lastZone = _currZone;
              _lastStatus = _currStatus;
            },
            onError: (e) {
              if (_data.isNotEmpty) {
                Fluttertoast.showToast(msg: e.toString());
              }
              _currOrder = _lastOrder;
              _currGenre = _lastGenre;
              _currAge = _lastAge;
              _currZone = _lastZone;
              _currStatus = _lastStatus;
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
            flags: _flagStorage.getFlags(mangaId: item.mid),
            twoColumns: AppSetting.instance.ui.showTwoColumns,
          ),
          extra: UpdatableDataViewExtraWidgets(
            outerTopWidgets: [
              ListHintView.widgets(
                widgets: [
                  OptionPopupView<TinyCategory>(
                    items: _genres,
                    value: _currGenre,
                    titleBuilder: (c, v) => v.isAll() ? '剧情' : v.title,
                    enable: !_getting,
                    onSelect: (g) {
                      if (_currGenre != g) {
                        _lastGenre = _currGenre;
                        _currGenre = g;
                        if (mounted) setState(() {});
                        _pdvKey.currentState?.refresh();
                      }
                    },
                    onLongPressed: () => _chooseCategory(toChoose: false),
                    ifNeedHighlight: (category) => _markedCategoryNames.any((el) => category.name == el) == true,
                    onOptionLongPressed: _longPressCategoryOption,
                  ),
                  OptionPopupView<TinyCategory>(
                    items: allAges,
                    value: _currAge,
                    titleBuilder: (c, v) => v.isAll() ? '受众' : v.title,
                    enable: !_getting,
                    onSelect: (a) {
                      if (_currAge != a) {
                        _lastAge = _currAge;
                        _currAge = a;
                        if (mounted) setState(() {});
                        _pdvKey.currentState?.refresh();
                      }
                    },
                    onLongPressed: () => _chooseCategory(toChoose: false),
                    ifNeedHighlight: (category) => _markedCategoryNames.any((el) => category.name == el) == true,
                    onOptionLongPressed: _longPressCategoryOption,
                  ),
                  OptionPopupView<TinyCategory>(
                    items: allZones,
                    value: _currZone,
                    titleBuilder: (c, v) => v.isAll() ? '地区' : v.title,
                    enable: !_getting,
                    onSelect: (z) {
                      if (_currZone != z) {
                        _lastZone = _currZone;
                        _currZone = z;
                        if (mounted) setState(() {});
                        _pdvKey.currentState?.refresh();
                      }
                    },
                    onLongPressed: () => _chooseCategory(toChoose: false),
                    ifNeedHighlight: (category) => _markedCategoryNames.any((el) => category.name == el) == true,
                    onOptionLongPressed: _longPressCategoryOption,
                  ),
                  OptionPopupView<TinyCategory>(
                    items: allStatuses,
                    value: _currStatus,
                    titleBuilder: (c, v) => v.isAll() ? '进度' : v.title,
                    enable: !_getting,
                    onSelect: (s) {
                      if (_currStatus != s) {
                        _lastStatus = _currStatus;
                        _currStatus = s;
                        if (mounted) setState(() {});
                        _pdvKey.currentState?.refresh();
                      }
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
                  value: _currOrder,
                  titleBuilder: (c, v) => v.toTitle(),
                  enable: !_getting,
                  onSelect: (o) {
                    if (_currOrder != o) {
                      _lastOrder = _currOrder;
                      _currOrder = o;
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
    );
  }
}
