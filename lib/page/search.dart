import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/page/view/tiny_manga_line.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/prefs/search.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

/// 搜索
class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = FloatingSearchBarController();
  final _scrollController = ScrollController();
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _fabController = AnimatedFabController();
  String? __q;
  var _histories = <String>[];
  final _data = <SmallManga>[];
  var _total = 0;
  var _order = MangaOrder.byPopular;
  var _lastOrder = MangaOrder.byPopular;
  var _disableOption = false;

  String? get _q => __q?.trim().isNotEmpty == true ? __q?.trim() : null;

  set _q(String? s) => __q = s?.trim();

  String? get _text => _searchController.query.trim().isNotEmpty == true ? _searchController.query.trim() : null;

  set _text(String? s) => _searchController.query = s?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => Future.delayed(Duration(milliseconds: 200), () => _searchController.open()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<PagedList<SmallManga>> _getData({required int page}) async {
    var client = RestClient(DioManager.instance.dio);
    var result = await client.searchMangas(keyword: _q ?? '?', page: page, order: _order).onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
    _total = result.data.total;
    if (mounted) setState(() {});
    return PagedList(list: result.data.data, next: result.data.page + 1);
  }

  Future<List<String>> _getHistories({required String? keyword}) async {
    var histories = await getSearchHistories();
    if (keyword == null) {
      return histories;
    }
    var keywords = keyword.split(' ');
    return histories.where((s) {
      for (var w in keywords) {
        if (s.contains(w)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  void _search() {
    if (_text == null) {
      Fluttertoast.showToast(msg: '请输入搜索内容');
      return;
    }

    if (_q != _text) {
      _q = _text;
      _searchController.close();
      _pdvKey.currentState?.refresh();
      addSearchHistory(_q!);
    } else {
      _searchController.close();
    }
  }

  Future<bool> _pop() async {
    if (_q == null) {
      return true; // 没搜索 => 退出
    }
    if (_searchController.isOpen) {
      _searchController.close(); // 有搜索 => 关闭、恢复搜索框
      _text = _q;
    } else {
      _q = null; // 有搜索 => 取消搜索，打开、清空搜索框
      _data.clear();
      _searchController.open();
      _text = null;
      if (mounted) setState(() {});
    }
    return false;
  }

  void _changeFocus(bool focus) {
    if (focus == false) {
      if (_q != null) {
        _text = _q; // 有搜索 => 恢复搜索框
      } else {
        Navigator.of(context).maybePop(); // 没搜索 => 退出
      }
    } else {
      _getHistories(keyword: _text).then((l) {
        _histories = l;
        if (mounted) setState(() {});
      });
    }
    if (mounted) setState(() {});
  }

  void _changeQuery(String s) {
    _getHistories(keyword: _text).then((l) {
      _histories = l;
      if (mounted) setState(() {});
    });
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _pop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).padding.top,
                child: Container(color: Theme.of(context).primaryColor),
              ),
            ),
            Positioned.fill(
              top: MediaQuery.of(context).padding.top + 45,
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
                  placeholderSetting: PlaceholderSetting(
                    showNothingIcon: _q != null,
                    showNothingRetry: _q != null,
                  ).copyWithChinese(
                    nothingText: _q == null ? '请在搜索框中输入关键字...' : '无内容',
                  ),
                  refreshFirst: false,
                  clearWhenError: false,
                  clearWhenRefresh: true,
                  updateOnlyIfNotEmpty: false,
                  onPlaceholderStateChanged: (_, __) => _fabController.hide(),
                  onStartGettingData: () => mountedSetState(() => _disableOption = true),
                  onStopGettingData: () => mountedSetState(() => _disableOption = false),
                  onAppend: (l, _) {
                    if (l.length > 0) {
                      Fluttertoast.showToast(msg: '新添了 ${l.length} 部漫画');
                    }
                    _lastOrder = _order;
                    if (mounted) setState(() {});
                  },
                  onError: (e) {
                    Fluttertoast.showToast(msg: e.toString());
                    _order = _lastOrder;
                    if (mounted) setState(() {});
                  },
                ),
                separator: Divider(height: 1),
                itemBuilder: (c, _, item) => TinyMangaLineView(manga: item.toTiny()),
                extra: UpdatableDataViewExtraWidgets(
                  innerTopWidgets: [
                    Container(
                      color: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 26,
                            padding: EdgeInsets.only(left: 5),
                            child: Center(
                              child: Text('"$_q" 的搜索结果 (共 $_total 部)'),
                            ),
                          ),
                          OptionPopupView<MangaOrder>(
                            title: _order.toTitle(),
                            top: 4,
                            value: _order,
                            items: const [MangaOrder.byPopular, MangaOrder.byNew, MangaOrder.byUpdate],
                            onSelect: (o) {
                              if (_order != o) {
                                _lastOrder = _order;
                                _order = o;
                                if (mounted) setState(() {});
                                _pdvKey.currentState?.refresh();
                              }
                            },
                            optionBuilder: (c, v) => v.toTitle(),
                            enable: !_disableOption,
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1),
                  ],
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 35.0 + 5 * 2, // 45
                child: AppBar(automaticallyImplyLeading: false),
              ),
            ),
            Scrollbar(
              child: FloatingSearchBar(
                controller: _searchController,
                height: 35,
                hint: '输入标题名称、拼音或者 mid 搜索漫画',
                textInputType: TextInputType.text,
                textInputAction: TextInputAction.search,
                iconColor: Colors.black54,
                margins: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 5),
                insets: EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.symmetric(horizontal: 3),
                scrollPadding: EdgeInsets.only(top: 0, bottom: 32),
                width: MediaQuery.of(context).size.width - 8 * 2,
                openWidth: MediaQuery.of(context).size.width - 8 * 2,
                // maxWidth: MediaQuery.of(context).size.width - 8 * 2,
                // openMaxWidth: MediaQuery.of(context).size.width - 8 * 2,
                elevation: 3.0,
                borderRadius: _searchController.isClosed
                    ? BorderRadius.circular(3)
                    : BorderRadius.only(
                        topLeft: Radius.circular(3),
                        topRight: Radius.circular(3),
                      ),
                hintStyle: Theme.of(context).textTheme.bodyText2?.copyWith(color: Theme.of(context).hintColor),
                queryStyle: Theme.of(context).textTheme.bodyText2,
                clearQueryOnClose: false,
                closeOnBackdropTap: false,
                automaticallyImplyBackButton: false,
                automaticallyImplyDrawerHamburger: false,
                transitionDuration: Duration(milliseconds: 500),
                transitionCurve: Curves.easeInOut,
                transition: CircularFloatingSearchBarTransition(),
                leadingActions: [
                  FloatingSearchBarAction.icon(
                    icon: Icon(Icons.arrow_back, size: 18),
                    size: 18,
                    showIfOpened: true,
                    showIfClosed: true,
                    onTap: () => Navigator.of(context).maybePop(), // 返回
                  ),
                ],
                actions: [
                  FloatingSearchBarAction.icon(
                    icon: Icon(Icons.close, size: 18),
                    size: 18,
                    showIfOpened: true,
                    showIfClosed: false,
                    onTap: () => mountedSetState(() => _searchController.clear()), // 清空
                  ),
                  FloatingSearchBarAction.icon(
                    icon: Icon(Icons.search, size: 18),
                    size: 18,
                    showIfOpened: true,
                    showIfClosed: true,
                    onTap: () => _search(), // 搜索
                  ),
                ],
                debounceDelay: Duration(milliseconds: 100),
                onQueryChanged: _changeQuery,
                onFocusChanged: _changeFocus,
                onSubmitted: (_) => _search(),
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                  child: Material(
                    color: Colors.white,
                    child: Column(
                      children: [
                        // ===================================================================
                        if (_text != null && _text != _q)
                          InkWell(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: IconText(
                                icon: Icon(Icons.search, color: Colors.black45),
                                text: Text('搜索 "$_text"'),
                              ),
                            ),
                            onTap: () => _search(), // 搜索
                          ),
                        if (_text != null && (int.tryParse(_text!) ?? 0) > 0)
                          InkWell(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: IconText(
                                icon: Icon(Icons.arrow_forward, color: Colors.black45),
                                text: Text('访问漫画 mid$_text'),
                              ),
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (c) => MangaPage(
                                  id: int.tryParse(_text!)!,
                                  title: '漫画 mid$_text',
                                  url: '',
                                ),
                              ),
                            ), // 访问
                          ),
                        if (_q != null)
                          InkWell(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: IconText(
                                icon: Icon(Icons.arrow_back, color: Colors.black45),
                                text: Text('返回 "$_q" 的搜索结果'),
                              ),
                            ),
                            onTap: () => Navigator.of(context).maybePop(), // 返回
                          ),
                        // ===================================================================
                        ..._histories.map(
                          (h) => InkWell(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: IconText(
                                icon: Icon(Icons.history, color: Colors.black45),
                                text: Text(h),
                              ),
                            ),
                            onTap: () => _searchController.query = h, // 候选
                            onLongPress: () => showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: Text('删除搜索记录'),
                                content: Text('确定要删除 $h 吗？'),
                                actions: [
                                  TextButton(
                                    child: Text('删除'),
                                    onPressed: () async {
                                      Navigator.of(c).pop();
                                      _histories.remove(h);
                                      await removeSearchHistory(h);
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
                        ),
                        // ===================================================================
                        if (_histories.isNotEmpty && _text == null)
                          InkWell(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
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
                                    onPressed: () {
                                      _histories.clear();
                                      clearSearchHistories();
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
