import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/dlg/category_dialog.dart';
import 'package:manhuagui_flutter/page/view/category_grid_list.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/manga_ranking_line.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/prefs/marked_category.dart';

/// 首页-排行
class RankingSubPage extends StatefulWidget {
  const RankingSubPage({
    Key? key,
    this.action,
  }) : super(key: key);

  final ActionController? action;

  @override
  _RankingSubPageState createState() => _RankingSubPageState();
}

class _RankingSubPageState extends State<RankingSubPage> with AutomaticKeepAliveClientMixin {
  final _rdvKey = GlobalKey<RefreshableDataViewState>();
  final _controllerForCategory = ScrollController();
  final _fabControllerForCategory = AnimatedFabController();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => (!_chosen ? _controllerForCategory : _controller).scrollToTop());
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadGenres());
    _cancelHandlers.add(EventBusManager.instance.listen<MarkedCategoryUpdatedEvent>((ev) => _updateByEvent(ev)));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    widget.action?.removeAction();
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
  var _chosen = false;
  final _categories = <TinyCategory>[];
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
      _categories.clear();
      _genreError = '';
      if (mounted) setState(() {});
      await Future.delayed(kFlashListDuration);
      _genres.add(allGenres[0]);
      _genres.addAll(globalCategoryList!.genres.map((g) => g.toTiny()).toList());
      _categories.addAll(_genres);
      _categories.addAll(allRankingTypes.sublist(1));
    } catch (e, s) {
      _genres.clear();
      _categories.clear();
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

    _currType = genre ?? age ?? zone ?? allRankingTypes[0]; // TODO test
    _lastType = allRankingTypes[0];

    _chosen = toChoose;
    _data.clear();
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

  final _data = <MangaRanking>[];
  late final _flagStorage = MangaCornerFlagStorage(stateSetter: () => mountedSetState(() {}));
  var _getting = false;

  var _currType = allRankingTypes[0];
  var _lastType = allRankingTypes[0];
  var _currDuration = allRankingDurations[0];
  var _lastDuration = allRankingDurations[0];

  Future<List<MangaRanking>> _getData() async {
    final client = RestClient(DioManager.instance.dio);
    var f = _currDuration.name == 'day'
        ? client.getDayRanking
        : _currDuration.name == 'week'
            ? client.getWeekRanking
            : _currDuration.name == 'month'
                ? client.getMonthRanking
                : client.getTotalRanking;
    var result = await f(type: _currType.name).onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
    _flagStorage.queryAndStoreFlags(mangaIds: result.data.data.map((e) => e.mid)).then((_) => mountedSetState(() {}));
    return result.data.data;
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
          useAnimatedSwitcher: true,
          customNormalStateBuilder: (c, _, childBuilder) => _chosen
              ? childBuilder.call(c) // normal state
              : CategoryGridListView(
                  key: PageStorageKey<String>('RankingSubPage_CategoryGridListView'),
                  controller: _controllerForCategory,
                  title: '选择一个漫画类别来查看排行榜',
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
        childBuilder: (c) => RefreshableDataView<MangaRanking>(
          key: _rdvKey,
          style: !AppSetting.instance.ui.showTwoColumns ? UpdatableDataViewStyle.listView : UpdatableDataViewStyle.gridView,
          data: _data,
          getData: () => _getData(),
          scrollController: _controller,
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
            onStartGettingData: () => mountedSetState(() => _getting = true),
            onStopGettingData: () => mountedSetState(() => _getting = false),
            onAppend: (_, l) {
              _lastDuration = _currDuration;
              _lastType = _currType;
            },
            onError: (e) {
              if (_data.isNotEmpty) {
                Fluttertoast.showToast(msg: e.toString());
              }
              _currDuration = _lastDuration;
              _currType = _lastType;
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
          itemBuilder: (c, _, item) => MangaRankingLineView(
            manga: item,
            flags: _flagStorage.getFlags(mangaId: item.mid),
            twoColumns: AppSetting.instance.ui.showTwoColumns,
          ),
          extra: UpdatableDataViewExtraWidgets(
            outerTopWidgets: [
              ListHintView.textWidget(
                leftText: '排行榜内前50的漫画',
                rightWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OptionPopupView<TinyCategory>(
                      items: _categories,
                      value: _currType,
                      titleBuilder: (c, v) => v.isAll() ? '分类' : v.title,
                      enable: !_getting,
                      onSelect: (t) {
                        if (_currType != t) {
                          _lastType = _currType;
                          _currType = t;
                          if (mounted) setState(() {});
                          _rdvKey.currentState?.refresh();
                        }
                      },
                      onLongPressed: () => _chooseCategory(toChoose: false),
                      ifNeedHighlight: (genre) => _markedCategoryNames.any((el) => genre.name == el) == true,
                      onOptionLongPressed: _longPressCategoryOption,
                    ),
                    SizedBox(width: 12),
                    OptionPopupView<TinyCategory>(
                      items: allRankingDurations,
                      value: _currDuration,
                      titleBuilder: (c, v) => v.title,
                      enable: !_getting,
                      onSelect: (d) {
                        if (_currDuration != d) {
                          _lastDuration = _currDuration;
                          _currDuration = d;
                          if (mounted) setState(() {});
                          _rdvKey.currentState?.refresh();
                        }
                      },
                      onLongPressed: () => _chooseCategory(toChoose: false),
                    ),
                  ],
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
