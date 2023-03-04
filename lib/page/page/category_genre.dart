import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/category_grid.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/page/view/tiny_manga_line.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';

/// 分类-类别
class GenreSubPage extends StatefulWidget {
  const GenreSubPage({
    Key? key,
    this.action,
    this.defaultGenre,
  }) : super(key: key);

  final ActionController? action;
  final TinyCategory? defaultGenre;

  @override
  _GenreSubPageState createState() => _GenreSubPageState();
}

class _GenreSubPageState extends State<GenreSubPage> with AutomaticKeepAliveClientMixin {
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _controllerForGenre = ScrollController();
  final _fabControllerForGenre = AnimatedFabController();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => (!_chosen ? _controllerForGenre : _controller).scrollToTop());
    widget.action?.addAction('ifNeedBack', () => _chosen);
    widget.action?.addAction('back', () => _chooseCategory(toChoose: false));
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadGenres());
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    widget.action?.removeAction('ifNeedBack');
    widget.action?.removeAction('back');
    _controllerForGenre.dispose();
    _fabControllerForGenre.dispose();
    _controller.dispose();
    _fabController.dispose();
    _flagStorage.dispose();
    super.dispose();
  }

  var _genreLoading = true; // initialize to true
  final _genres = <TinyCategory>[];
  var _genreError = '';
  late var _chosen = widget.defaultGenre != null; // initialize to false if defaultGenre is null

  Future<void> _loadGenres() async {
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
    } catch (e, s) {
      _genres.clear();
      _genreError = wrapError(e, s).text;
    } finally {
      _genreLoading = false;
      if (mounted) setState(() {});
    }
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
    widget.action?.invoke('updateSubPage'); // update CategorySubPage
    if (mounted) setState(() {});
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
    var f = client.getGenreMangas(
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
          useAnimatedSwitcher: widget.defaultGenre == null /* only animate when no default genre */,
          customNormalStateBuilder: (c, childBuilder) => _chosen
              ? childBuilder.call(c) // normal state
              : Column(
                  key: PageStorageKey<String>('GenreSubPage_CategoryGridView_Column'),
                  children: [
                    ListHintView.textText(
                      leftText: '选择一个类别筛选漫画',
                      rightText: '',
                    ),
                    Expanded(
                      child: ExtendedScrollbar(
                        controller: _controllerForGenre,
                        interactive: true,
                        mainAxisMargin: 2,
                        crossAxisMargin: 2,
                        child: ListView(
                          controller: _controllerForGenre,
                          padding: EdgeInsets.zero,
                          physics: AlwaysScrollableScrollPhysics(),
                          cacheExtent: 999999 /* <<< keep states in ListView */,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 9, bottom: 10),
                              child: Text('・漫画剧情・', textAlign: TextAlign.center, style: Theme.of(context).textTheme.subtitle1),
                            ),
                            CategoryGridView(
                              categories: _genres.map((g) => g.toCategory(cover: globalCategoryList!.genres.where((el) => el.name == g.name).firstOrNull?.cover)).toList(),
                              onSelected: (c) => _chooseCategory(toChoose: true, genre: c.toTiny()),
                              style: CategoryGridViewStyle.threeColumns,
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 9, bottom: 10),
                              child: Text('・漫画受众・', textAlign: TextAlign.center, style: Theme.of(context).textTheme.subtitle1),
                            ),
                            CategoryGridView(
                              categories: allAges.sublist(1).map((g) => g.toCategory(cover: globalCategoryList!.ages.where((el) => el.name == g.name).firstOrNull?.cover)).toList(),
                              onSelected: (c) => _chooseCategory(toChoose: true, age: c.toTiny()),
                              style: CategoryGridViewStyle.fourColumns,
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 9, bottom: 10),
                              child: Text('・漫画地区・', textAlign: TextAlign.center, style: Theme.of(context).textTheme.subtitle1),
                            ),
                            CategoryGridView(
                              categories: allZones.sublist(1).map((g) => g.toCategory(cover: globalCategoryList!.zones.where((el) => el.name == g.name).firstOrNull?.cover)).toList(),
                              onSelected: (c) => _chooseCategory(toChoose: true, zone: c.toTiny()),
                              style: CategoryGridViewStyle.fourColumns,
                            ),
                            SizedBox(height: 15),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ).copyWithChinese(),
        childBuilder: (c) => PaginationListView<TinyManga>(
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
          itemBuilder: (c, _, item) => TinyMangaLineView(
            manga: item,
            flags: _flagStorage.getFlags(mangaId: item.mid),
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
            controller: _fabControllerForGenre,
            scrollController: _controllerForGenre,
            condition: _chosen ? ScrollAnimatedCondition.forceHide : ScrollAnimatedCondition.direction,
            fab: FloatingActionButton(
              child: Icon(Icons.vertical_align_top),
              heroTag: null,
              onPressed: () => _controllerForGenre.scrollToTop(),
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
