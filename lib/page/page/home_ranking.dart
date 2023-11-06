import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/dlg/category_dialog.dart';
import 'package:manhuagui_flutter/page/view/category_grid_list.dart';
import 'package:manhuagui_flutter/page/view/category_popup.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/fit_system_screenshot.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/manga_ranking_line.dart';
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

class _RankingSubPageState extends State<RankingSubPage> with AutomaticKeepAliveClientMixin, FitSystemScreenshotMixin {
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
      _categories.addAll(allRankingCategories.sublist(1));
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

  var _chosen = false;
  final _currCategory = RestorableObject(allRankingCategories[0]);
  final _currDuration = RestorableObject(allRankingDurations[0]);

  void _chooseCategory({required bool toChoose, TinyCategory? genre, TinyCategory? age, TinyCategory? zone}) {
    if (toChoose == _chosen) {
      return;
    }
    _chosen = toChoose;
    _currCategory.select(genre ?? age ?? zone ?? allRankingCategories[0], sameLast: true);
    _currDuration.select(allRankingDurations[0], sameLast: true);

    _data.clear();
    if (mounted) setState(() {});
  }

  final _data = <MangaRanking>[];
  late final _flagStorage = MangaCornerFlagStorage(stateSetter: () => mountedSetState(() {}));
  var _getting = false;

  Future<List<MangaRanking>> _getData() async {
    final client = RestClient(DioManager.instance.dio);
    var f = _currDuration.curr.name == 'day'
        ? client.getDayRanking
        : _currDuration.curr.name == 'week'
            ? client.getWeekRanking
            : _currDuration.curr.name == 'month'
                ? client.getMonthRanking
                : client.getTotalRanking;
    var result = await f(type: _currCategory.curr.name).onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
    _flagStorage.queryAndStoreFlags(mangaIds: result.data.data.map((e) => e.mid)).then((_) => mountedSetState(() {}));
    return result.data.data;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  FitSystemScreenshotData get fitSystemScreenshotData => FitSystemScreenshotData(
        scrollViewKey: _rdvKey,
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
        if (_chosen) {
          _chooseCategory(toChoose: false);
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
            useAnimatedSwitcher: true,
            customNormalStateBuilder: (c, _, childBuilder) => _chosen
                ? childBuilder.call(c) // normal state
                : CategoryGridListView(
                    key: PageStorageKey<String>('RankingSubPage_CategoryGridListView'),
                    title: '选择一个漫画类别来查看排行榜',
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
              onAppend: (_, l) => [_currCategory, _currDuration].forEach((c) => c.pass()),
              onError: (e) {
                if (_data.isNotEmpty) {
                  Fluttertoast.showToast(msg: e.toString());
                }
                [_currCategory, _currDuration].forEach((c) => c.restore());
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
              history: _flagStorage.getHistory(mangaId: item.mid),
              flags: _flagStorage.getFlags(mangaId: item.mid, newestChapter: item.newestChapter),
              twoColumns: AppSetting.instance.ui.showTwoColumns,
              highlightRecent: AppSetting.instance.ui.highlightRecentMangas,
            ),
            extra: UpdatableDataViewExtraWidgets(
              outerTopWidgets: [
                ListHintView.textWidget(
                  leftText: '排行榜内前50的漫画',
                  rightWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CategoryPopupView(
                        categories: _categories,
                        selectedCategory: _currCategory.curr,
                        markedCategoryNames: _markedCategoryNames,
                        defaultName: '分类',
                        enable: !_getting,
                        allowLongPressCategory: true,
                        onSelected: (c) {
                          _currCategory.select(c, alsoPass: true);
                          if (mounted) setState(() {});
                          _rdvKey.currentState?.refresh();
                        },
                        onLongPressed: () => _chooseCategory(toChoose: false),
                      ),
                      SizedBox(width: 12),
                      CategoryPopupView(
                        categories: allRankingDurations,
                        selectedCategory: _currDuration.curr,
                        enable: !_getting,
                        allowLongPressCategory: false,
                        onSelected: (d) {
                          _currDuration.select(d, alsoPass: true);
                          if (mounted) setState(() {});
                          _rdvKey.currentState?.refresh();
                        },
                        onLongPressed: () => _chooseCategory(toChoose: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).fitSystemScreenshot(this),
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
