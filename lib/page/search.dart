import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/fit_system_screenshot.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/page/view/small_manga_line.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/prefs/search_history.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

/// 搜索页
class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with FitSystemScreenshotMixin {
  final _searchController = FloatingSearchBarController();
  final _searchScrollController = ScrollController();
  final _scrollController = ScrollController();
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _scrollViewKey = GlobalKey();
  final _fabController = AnimatedFabController();
  final _cancelHandlers = <VoidCallback>[];

  String? _keyword;

  set _q(String? s) => _keyword = (s?.trim().isNotEmpty == true) ? s!.trim() : null;

  String? get _q => _keyword; // 当前搜索的关键词

  set _text(String s) => _searchController.query = s.trim();

  String get _text => _searchController.query.trim(); // 当前搜索框输入的内容

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await Future.delayed(Duration(milliseconds: 300)); // open delay, faster than route's transitionDuration, which equals to 400ms
      _searchController.open();
    });
    _cancelHandlers.add(EventBusManager.instance.listen<AppSettingChangedEvent>((_) => mountedSetState(() {})));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _searchController.dispose();
    _searchScrollController.dispose();
    _scrollController.dispose();
    _fabController.dispose();
    _flagStorage.dispose();
    super.dispose();
  }

  final _data = <SmallManga>[];
  var _total = 0;
  late final _flagStorage = MangaCornerFlagStorage(stateSetter: () => mountedSetState(() {}));
  final _searchHistories = <String>[];
  var _getting = false;
  final _currOrder = RestorableObject(AppSetting.instance.ui.defaultMangaOrder);

  Future<PagedList<SmallManga>> _getData({required int page}) async {
    final client = RestClient(DioManager.instance.dio);
    var result = await client.searchMangas(keyword: _q!, page: page, order: _currOrder.curr).onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
    _total = result.data.total;
    if (mounted) setState(() {});
    _flagStorage.queryAndStoreFlags(mangaIds: result.data.data.map((e) => e.mid)).then((_) => mountedSetState(() {}));
    return PagedList(list: result.data.data, next: result.data.page + 1);
  }

  Future<bool> _pop() async {
    if (_q == null) {
      return true; // 没搜索 => 退出
    }
    if (_searchController.isOpen) {
      _searchController.close(); // 有搜索，且列表打开着 => 关闭列表、恢复搜索框
      _text = _q!;
    } else {
      _q = null; // 有搜索，且列表关闭着 => 取消搜索、打开列表、清空搜索框、清空数据
      _searchController.open();
      _text = '';
      _data.clear();
    }
    if (mounted) setState(() {}); // 搜索框状态变更，更新界面
    return false;
  }

  void _search() async {
    if (_text.isEmpty) {
      Fluttertoast.showToast(msg: '请输入搜索内容'); // 搜索框为空 => 提示输入
      return;
    }
    if (_q != _text) {
      _q = _text; // 搜索框不为空，且与当前关键词不同 => 更新搜索关键词、关闭列表、添加搜索历史、执行搜索
      _searchController.close();
      await SearchHistoryPrefs.addSearchHistory(_q!);
      _pdvKey.currentState?.refresh();
    } else {
      _searchController.close(); // 搜索框不为空，且与当前关键词相同 => 关闭列表
    }
    if (mounted) setState(() {}); // 搜索框状态变更，更新界面
  }

  Future<List<String>> _getHistories({required String keyword}) async {
    var histories = await SearchHistoryPrefs.getSearchHistories();
    if (keyword.isEmpty) {
      return histories;
    }
    var keywords = keyword.split(' ');
    return histories.where((history) {
      return keywords.any((word) => history.contains(word));
    }).toList();
  }

  Future<void> _changeFocus(bool focus) async {
    if (!focus) {
      if (_q != null) {
        _text = _q!; // 取消聚焦，有搜索 => 恢复搜索框
      } else {
        Navigator.of(context).maybePop(); // 取消聚焦，没搜索 => 退出
      }
    } else {
      var l = await _getHistories(keyword: _text);
      _searchHistories.clear(); // 获取聚焦 => 更新搜索历史
      _searchHistories.addAll(l);
      if (mounted) setState(() {});
    }
  }

  Future<void> _changeQuery() async {
    var l = await _getHistories(keyword: _text);
    _searchHistories.clear(); // 获取聚焦 => 更新搜索历史
    _searchHistories.addAll(l);
    if (mounted) setState(() {});
  }

  double get appBarHeight => Theme.of(context).appBarTheme.toolbarHeight!;

  @override
  FitSystemScreenshotData get fitSystemScreenshotData => FitSystemScreenshotData(
        scrollViewKey: _scrollViewKey,
        scrollController: _scrollController,
      );

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _pop,
      child: Scaffold(
        drawer: AppDrawer(
          currentSelection: DrawerSelection.search,
        ),
        drawerEdgeDragWidth: MediaQuery.of(context).size.width,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).padding.top,
                child: Container(color: Theme.of(context).primaryColor), // inside system notification bar
              ),
            ),
            Positioned.fill(
              top: MediaQuery.of(context).padding.top + appBarHeight,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: PaginationDataView<SmallManga>(
                  key: _pdvKey,
                  style: !AppSetting.instance.ui.showTwoColumns ? UpdatableDataViewStyle.listView : UpdatableDataViewStyle.gridView,
                  data: _data,
                  getData: ({indicator}) => _getData(page: indicator),
                  scrollViewKey: _scrollViewKey,
                  scrollController: _scrollController,
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
                    placeholderSetting: PlaceholderSetting(
                      showNothingIcon: _q != null,
                      showNothingRetry: _q != null,
                    ).copyWithChinese(
                      nothingText: _q == null ? '请在搜索框中输入关键字...' : '无内容',
                    ),
                    onPlaceholderStateChanged: (_, __) => _fabController.hide(),
                    refreshFirst: false /* not to refresh first for search list */,
                    clearWhenRefresh: true,
                    clearWhenError: false,
                    updateOnlyIfNotEmpty: false,
                    onStartGettingData: () => mountedSetState(() => _getting = true),
                    onStopGettingData: () => mountedSetState(() => _getting = false),
                    onAppend: (_, l) => _currOrder.pass(),
                    onError: (e) {
                      if (_data.isNotEmpty) {
                        Fluttertoast.showToast(msg: e.toString());
                      }
                      _currOrder.restore();
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
                  itemBuilder: (c, _, item) => SmallMangaLineView(
                    manga: item.toSmaller(),
                    history: _flagStorage.getHistory(mangaId: item.mid),
                    flags: _flagStorage.getFlags(mangaId: item.mid, newestChapter: item.newestChapter),
                    twoColumns: AppSetting.instance.ui.showTwoColumns,
                    highlightRecent: AppSetting.instance.ui.highlightRecentMangas,
                  ),
                  extra: UpdatableDataViewExtraWidgets(
                    innerTopWidgets: [
                      ListHintView.textWidget(
                        leftText: '"$_q" 的搜索结果 (共 $_total 部)',
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
                ).fitSystemScreenshot(this),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: appBarHeight,
                child: AppBar(
                  automaticallyImplyLeading: false,
                  toolbarHeight: appBarHeight, // fake AppBar, height => 45
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: _searchController.isOpen
                  ? 0 // full of screen
                  : MediaQuery.of(context).size.height - (MediaQuery.of(context).padding.top + appBarHeight) /* only lays on app bar */,
              left: 0,
              right: 0,
              child: ExtendedScrollbar(
                controller: _searchScrollController,
                interactive: true,
                crossAxisMargin: 8 + 2 /* marginRight_8 + crossAxisMargin_2 */,
                mainAxisMargin: -46 /* magic */,
                extraMargin: EdgeInsets.only(top: 5 + 35 + 46 + 2 /* marginTop_5 + height_35 + magic_46 + mainAxisMargin_2 */),
                child: FloatingSearchBar(
                  controller: _searchController,
                  scrollController: _searchScrollController,
                  height: 35 /* 35 + 5 + 5 => 45 */,
                  margins: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 5 /* marginTop_5 */, left: 8, right: 8 /* marginRight_8 */),
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  insets: EdgeInsets.symmetric(horizontal: 4),
                  scrollPadding: EdgeInsets.only(bottom: 16),
                  elevation: 3.0,
                  borderRadius: _searchController.isClosed
                      ? BorderRadius.all(Radius.circular(4)) // all border sides have radius
                      : BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)) /* only top borders have radius */,
                  transitionDuration: Duration(milliseconds: 400),
                  transitionCurve: Curves.easeInOut,
                  transition: CircularFloatingSearchBarTransition(),
                  hint: '输入漫画标题、作者名、mid 等搜索漫画',
                  hintStyle: Theme.of(context).textTheme.bodyText2?.copyWith(color: Theme.of(context).hintColor),
                  queryStyle: Theme.of(context).textTheme.bodyText2,
                  textInputType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  clearQueryOnClose: false,
                  closeOnBackdropTap: false,
                  iconColor: Colors.black54,
                  automaticallyImplyBackButton: false,
                  automaticallyImplyDrawerHamburger: false,
                  leadingActions: [
                    FloatingSearchBarAction(
                      showIfOpened: true,
                      showIfClosed: true,
                      child: CircularButton(
                        size: 18,
                        icon: Icon(Icons.arrow_back, size: 18),
                        tooltip: '返回',
                        onPressed: () => Navigator.of(context).maybePop(), // => 返回
                      ),
                    ),
                  ],
                  actions: [
                    FloatingSearchBarAction(
                      showIfOpened: true,
                      showIfClosed: false,
                      child: CircularButton(
                        size: 18,
                        icon: Icon(Icons.close, size: 18),
                        tooltip: '清空',
                        onPressed: () => _text = '', // => 清空
                      ),
                    ),
                    FloatingSearchBarAction(
                      showIfOpened: true,
                      showIfClosed: true,
                      child: CircularButton(
                        size: 18,
                        icon: Icon(Icons.search, size: 18),
                        tooltip: '搜索',
                        onPressed: () => _search(), // => 搜索
                      ),
                    ),
                  ],
                  debounceDelay: Duration(milliseconds: 150),
                  onSubmitted: (_) => _search(),
                  onFocusChanged: (focus) => _changeFocus(focus),
                  onQueryChanged: (_) => _changeQuery(),
                  builder: (_, __) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          spreadRadius: -1,
                          offset: Offset(0, 5),
                        ),
                      ],
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        children: [
                          // ===================================================================
                          if (_text.isNotEmpty && _text != _q) // 输入的关键词不为空，且和当前的关键词不同
                            InkWell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: IconText(
                                  icon: Icon(Icons.search, color: Colors.deepOrange),
                                  text: Flexible(
                                    child: Text('搜索 "$_text"', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.deepOrange)),
                                  ),
                                ),
                              ),
                              onTap: () => _search(), // => 搜索
                            ),
                          if (_text.isNotEmpty && (int.tryParse(_text) ?? 0) > 0) // 输入的关键词不为空，且是纯数字
                            InkWell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: IconText(
                                  icon: Icon(Icons.arrow_forward, color: Colors.deepOrange),
                                  text: Flexible(
                                    child: Text('查看漫画 "mid: $_text"', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.deepOrange)),
                                  ),
                                ),
                              ),
                              onTap: () => Navigator.of(context).push(
                                CustomPageRoute(
                                  context: context,
                                  builder: (c) => MangaPage(id: int.tryParse(_text)!, title: '漫画 mid: $_text', url: 'https://www.manhuagui.com/comic/$_text'),
                                ),
                              ), // => 查看漫画
                            ),
                          if (_q != null) // 当前已搜索
                            InkWell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: DefaultTextStyle(
                                  style: TextStyle(color: Colors.deepOrange),
                                  child: IconText.texts(
                                    icon: Icon(Icons.arrow_back, color: Colors.deepOrange),
                                    texts: [
                                      Text('返回 "'),
                                      Flexible(child: Text(_q!, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      Text('" 的搜索结果'),
                                    ],
                                  ),
                                ),
                              ),
                              onTap: () => Navigator.of(context).maybePop(), // => 返回
                            ),
                          // ===================================================================
                          for (var h in _searchHistories)
                            InkWell(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      child: IconText(
                                        icon: Icon(Icons.history, color: Colors.black45),
                                        text: Flexible(
                                          child: Text(h, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (AppSetting.instance.ui.clickToSearch)
                                    Padding(
                                      padding: EdgeInsets.only(right: 5),
                                      child: InkWell(
                                        child: Tooltip(
                                          child: Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(Icons.north_west, size: 22, color: Colors.black45),
                                          ),
                                          message: '更新关键词',
                                        ),
                                        onTap: () => _text = h, // => 候选
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () {
                                _text = h; // => 候选
                                if (AppSetting.instance.ui.clickToSearch) {
                                  _search(); // => 搜索
                                }
                              },
                              onLongPress: () => showDialog(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: Text('删除搜索历史'),
                                  content: Text('是否删除 "$h" 搜索历史？'),
                                  actions: [
                                    TextButton(
                                      child: Text('删除'),
                                      onPressed: () async {
                                        Navigator.of(c).pop();
                                        _searchHistories.remove(h);
                                        await SearchHistoryPrefs.removeSearchHistory(h);
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                    TextButton(
                                      child: Text('取消'),
                                      onPressed: () => Navigator.of(c).pop(),
                                    ),
                                  ],
                                ),
                              ), // => 删除
                            ),
                          // ===================================================================
                          if (_searchHistories.isEmpty && _q == null) // 历史为空且当前不在搜索
                            InkWell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Center(
                                  child: Text('暂无历史记录'),
                                ),
                              ),
                              onTap: () {},
                            ),
                          if (_searchHistories.isNotEmpty && _text.isEmpty) // 历史不为空且当前没有输入
                            InkWell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Center(
                                  child: Text('清空历史记录'),
                                ),
                              ),
                              onTap: () => showDialog(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: Text('清空历史记录'),
                                  content: Text('是否清空所有历史记录？'),
                                  actions: [
                                    TextButton(
                                      child: Text('清空'),
                                      onPressed: () async {
                                        _searchHistories.clear();
                                        await SearchHistoryPrefs.clearSearchHistories();
                                        if (mounted) setState(() {});
                                        Navigator.of(c).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: Text('取消'),
                                      onPressed: () => Navigator.of(c).pop(),
                                    ),
                                  ],
                                ),
                              ), // => 清空
                            ),
                          // ===================================================================
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: ScrollAnimatedFab(
          controller: _fabController,
          scrollController: _scrollController,
          condition: ScrollAnimatedCondition.direction,
          fab: FloatingActionButton(
            child: Icon(Icons.vertical_align_top),
            heroTag: null,
            onPressed: () => _scrollController.scrollToTop(),
          ),
        ),
      ),
    );
  }
}
