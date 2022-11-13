import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/page/view/tiny_manga_line.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
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

class _SearchPageState extends State<SearchPage> {
  final _searchController = FloatingSearchBarController();
  final _searchScrollController = ScrollController();
  final _scrollController = ScrollController();
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _fabController = AnimatedFabController();

  String? _keyword;

  set _q(String? s) => _keyword = (s?.trim().isNotEmpty == true) ? s!.trim() : null;

  String? get _q => _keyword; // 当前搜索的关键词

  set _text(String s) => _searchController.query = s.trim();

  String get _text => _searchController.query.trim(); // 当前搜索框输入的内容

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await Future.delayed(Duration(milliseconds: 400));
      _searchController.open();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchScrollController.dispose();
    _scrollController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  final _data = <SmallManga>[];
  var _total = 0;
  var _currOrder = MangaOrder.byPopular;
  var _lastOrder = MangaOrder.byPopular;
  var _getting = false;
  final _histories = <String>[];

  Future<PagedList<SmallManga>> _getData({required int page}) async {
    final client = RestClient(DioManager.instance.dio);
    var result = await client.searchMangas(keyword: _q!, page: page, order: _currOrder).onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
    _total = result.data.total;
    if (mounted) setState(() {});
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
      _histories.clear(); // 获取聚焦 => 更新搜索历史
      _histories.addAll(l);
      if (mounted) setState(() {});
    }
  }

  Future<void> _changeQuery() async {
    var l = await _getHistories(keyword: _text);
    _histories.clear(); // 获取聚焦 => 更新搜索历史
    _histories.addAll(l);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _pop,
      child: Scaffold(
        drawer: AppDrawer(
          currentSelection: DrawerSelection.search,
        ),
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).padding.top,
                child: Container(color: Theme.of(context).primaryColor),
              ),
            ),
            Positioned.fill(
              top: MediaQuery.of(context).padding.top + 45,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: PaginationListView<SmallManga>(
                  key: _pdvKey,
                  data: _data,
                  getData: ({indicator}) => _getData(page: indicator),
                  scrollController: _scrollController,
                  paginationSetting: PaginationSetting(
                    initialIndicator: 1,
                    nothingIndicator: 0,
                  ),
                  setting: UpdatableDataViewSetting(
                    padding: EdgeInsets.zero,
                    interactiveScrollbar: true,
                    scrollbarCrossAxisMargin: 2,
                    placeholderSetting: PlaceholderSetting(
                      showNothingIcon: _q != null,
                      showNothingRetry: _q != null,
                    ).copyWithChinese(
                      nothingText: _q == null ? '请在搜索框中输入关键字...' : '无内容',
                    ),
                    onPlaceholderStateChanged: (_, __) => _fabController.hide(),
                    refreshFirst: false,
                    clearWhenRefresh: true,
                    clearWhenError: false,
                    updateOnlyIfNotEmpty: false,
                    onStartGettingData: () => mountedSetState(() => _getting = true),
                    onStopGettingData: () => mountedSetState(() => _getting = false),
                    onAppend: (_, l) {
                      _lastOrder = _currOrder;
                    },
                    onError: (e) {
                      if (_data.isNotEmpty) {
                        Fluttertoast.showToast(msg: e.toString());
                      }
                      _currOrder = _lastOrder;
                      if (mounted) setState(() {});
                    },
                  ),
                  separator: Divider(height: 0, thickness: 1),
                  itemBuilder: (c, _, item) => TinyMangaLineView(manga: item.toTiny()),
                  extra: UpdatableDataViewExtraWidgets(
                    innerTopWidgets: [
                      ListHintView.textWidget(
                        leftText: '"$_q" 的搜索结果 (共 $_total 部)',
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
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 45,
                child: AppBar(
                  automaticallyImplyLeading: false,
                  toolbarHeight: 45, // keep the same as AppBarTheme
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: _searchController.isOpen ? 0 : MediaQuery.of(context).size.height - (MediaQuery.of(context).padding.top + 45),
              left: 0,
              right: 0,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 5 + 35 + 46) /* padding_top_5 + height_35 + magic_46 */,
                ),
                child: ExtendedScrollbar(
                  controller: _searchScrollController,
                  interactive: true,
                  crossAxisMargin: 8 + 2 /* padding_right_8 + crossAxisMargin_2 */,
                  mainAxisMargin: -46 /* magic */,
                  child: FloatingSearchBar(
                    controller: _searchController,
                    scrollController: _searchScrollController,
                    height: 35 /* 35 + 5 + 5 => 45 */,
                    margins: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 5, left: 8, right: 8),
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
                    hint: '输入标题名称、拼音或者 mid 搜索漫画',
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
                          onPressed: () => Navigator.of(context).maybePop(), // 返回
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
                          onPressed: () => _text = '',
                        ),
                      ),
                      FloatingSearchBarAction(
                        showIfOpened: true,
                        showIfClosed: true,
                        child: CircularButton(
                          size: 18,
                          icon: Icon(Icons.search, size: 18),
                          tooltip: '清空',
                          onPressed: () => _search(), // 搜索
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
                            if (_text.isNotEmpty && _text != _q)
                              InkWell(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: IconText(
                                    icon: Icon(Icons.search, color: Colors.black45),
                                    text: Flexible(
                                      child: Text(
                                        '搜索 "$_text"',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                onTap: () => _search(), // 搜索
                              ),
                            if (_text.isNotEmpty && (int.tryParse(_text) ?? 0) > 0)
                              InkWell(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: IconText(
                                    icon: Icon(Icons.arrow_forward, color: Colors.black45),
                                    text: Text('访问漫画 mid: $_text'),
                                  ),
                                ),
                                onTap: () => Navigator.of(context).push(
                                  CustomPageRoute(
                                    context: context,
                                    builder: (c) => MangaPage(
                                      id: int.tryParse(_text)!,
                                      title: '漫画 mid: $_text',
                                      url: '',
                                    ),
                                  ),
                                ), // 访问
                              ),
                            if (_q != null)
                              InkWell(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: IconText.texts(
                                    icon: Icon(Icons.arrow_back, color: Colors.black45),
                                    texts: [
                                      Text('返回 "'),
                                      Flexible(
                                        child: Text(
                                          _q!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text('" 的搜索结果'),
                                    ],
                                  ),
                                ),
                                onTap: () => Navigator.of(context).maybePop(), // 返回
                              ),
                            // ===================================================================
                            for (var h in _histories)
                              InkWell(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: IconText(
                                    icon: Icon(Icons.history, color: Colors.black45),
                                    text: Flexible(
                                      child: Text(
                                        h,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  _text = h;
                                  _search(); // 候选并搜索
                                },
                                onLongPress: () => showDialog(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: Text('删除搜索记录'),
                                    content: Text('确定要删除 "$h" 吗？'),
                                    actions: [
                                      TextButton(
                                        child: Text('删除'),
                                        onPressed: () async {
                                          Navigator.of(c).pop();
                                          _histories.remove(h);
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
                                ), // 删除
                              ),
                            // ===================================================================
                            if (_histories.isEmpty)
                              InkWell(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Center(
                                    child: Text('暂无历史记录'),
                                  ),
                                ),
                                onTap: () {}, // 返回
                              ),
                            if (_histories.isNotEmpty && (_text.isEmpty || _q == _text))
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
                                    content: Text('确定要清空所有历史记录吗？'),
                                    actions: [
                                      TextButton(
                                        child: Text('清空'),
                                        onPressed: () async {
                                          _histories.clear();
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
                                ),
                              ),
                            // ===================================================================
                          ],
                        ),
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
