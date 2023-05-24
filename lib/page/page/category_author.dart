import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/author.dart';
import 'package:manhuagui_flutter/page/dlg/author_dialog.dart';
import 'package:manhuagui_flutter/page/view/category_popup.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/page/view/small_author_line.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/prefs/marked_category.dart';

/// 分类-作者类别
class AuthorCategorySubPage extends StatefulWidget {
  const AuthorCategorySubPage({
    Key? key,
    this.action,
  }) : super(key: key);

  final ActionController? action;

  @override
  _AuthorCategorySubPageState createState() => _AuthorCategorySubPageState();
}

class _AuthorCategorySubPageState extends State<AuthorCategorySubPage> with AutomaticKeepAliveClientMixin {
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _controller.scrollToTop());
    widget.action?.addAction('find', () => _inputAndFind());
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadGenres());
    _cancelHandlers.add(EventBusManager.instance.listen<MarkedCategoryUpdatedEvent>((ev) => _updateByEvent(ev)));
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    widget.action?.removeAction('find');
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

  final _data = <SmallAuthor>[];
  var _total = 0;
  late final _flagStorage = AuthorCornerFlagStorage(stateSetter: () => mountedSetState(() {}));
  var _getting = false;

  final _currGenre = RestorableObject(allGenres[0]);
  final _currAge = RestorableObject(allAges[0]);
  final _currZone = RestorableObject(allZones[0]);
  final _currOrder = RestorableObject(AppSetting.instance.ui.defaultAuthorOrder);

  Future<PagedList<SmallAuthor>> _getData({required int page}) async {
    final client = RestClient(DioManager.instance.dio);
    var f = client.getAllAuthors(
      genre: _currGenre.curr.name,
      zone: _currZone.curr.name,
      age: _currAge.curr.name,
      page: page,
      order: _currOrder.curr,
    );
    var result = await f.onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
    _total = result.data.total;
    if (mounted) setState(() {});
    _flagStorage.queryAndStoreFlags(authorIds: result.data.data.map((e) => e.aid)).then((_) => mountedSetState(() {}));
    return PagedList(list: result.data.data, next: result.data.page + 1);
  }

  Future<void> _inputAndFind() async {
    var aid = await showFindAuthorByIdDialog(context: context, title: '寻找作者', textLabel: '漫画作者 aid');
    if (aid == null) {
      return;
    }
    Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => AuthorPage(id: aid, name: '漫画作者 aid: $aid', url: 'https://www.manhuagui.com/author/$aid'),
      ),
    );
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
        setting: PlaceholderSetting(useAnimatedSwitcher: false).copyWithChinese(),
        onRefresh: () => _loadGenres(),
        onChanged: (_, __) => _fabController.hide(),
        childBuilder: (c) => PaginationDataView<SmallAuthor>(
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
            onPlaceholderStateChanged: (_, __) => _fabController.hide(),
            refreshFirst: true /* <<< refresh first */,
            clearWhenRefresh: false,
            clearWhenError: false,
            updateOnlyIfNotEmpty: false,
            onStartGettingData: () => mountedSetState(() => _getting = true),
            onStopGettingData: () => mountedSetState(() => _getting = false),
            onAppend: (_, l) => [_currGenre, _currAge, _currZone, _currOrder].forEach((c) => c.pass()),
            onError: (e) {
              if (_data.isNotEmpty) {
                Fluttertoast.showToast(msg: e.toString());
              }
              [_currGenre, _currAge, _currZone, _currOrder].forEach((c) => c.restore());
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
          itemBuilder: (c, _, item) => SmallAuthorLineView(
            author: item,
            flags: _flagStorage.getFlags(mangaId: item.aid),
            twoColumns: AppSetting.instance.ui.showTwoColumns,
          ),
          extra: UpdatableDataViewExtraWidgets(
            outerTopWidgets: [
              ListHintView.widgets(
                widgets: [
                  for (var t in [
                    Tuple4(_genres, _currGenre, '剧情', true),
                    Tuple4(allAges, _currAge, '受众', true),
                    Tuple4(allZones, _currZone, '地区', true),
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
                    ),
                ],
              ),
            ],
            innerTopWidgets: [
              ListHintView.textWidget(
                leftText: '筛选结果 (共 $_total 位)',
                rightWidget: OptionPopupView<AuthorOrder>(
                  items: const [AuthorOrder.byPopular, AuthorOrder.byComic, AuthorOrder.byNew],
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
      floatingActionButton: ScrollAnimatedFab(
        controller: _fabController,
        scrollController: _controller,
        condition: ScrollAnimatedCondition.direction,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: null,
          onPressed: () => _controller.scrollToTop(),
        ),
      ),
    );
  }
}
