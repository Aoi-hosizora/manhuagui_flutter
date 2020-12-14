import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/page/view/tiny_manga_line.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

/// 搜索
class SearchPage extends StatefulWidget {
  const SearchPage({Key key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  FloatingSearchBarController _searchController;
  ScrollMoreController _scrollController;
  ScrollFabController _fabController;
  String __q;
  var _data = <SmallManga>[];
  int _total;
  var _order = MangaOrder.byPopular;
  var _lastOrder = MangaOrder.byPopular;
  var _disableOption = false;

  String get _q => __q?.trim()?.isNotEmpty == true ? __q.trim() : null;

  set _q(String s) => __q = s?.trim();

  String get _text => _searchController?.query?.trim()?.isNotEmpty == true ? _searchController.query.trim() : null;

  set _text(String s) => _searchController?.query = s?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    _searchController = FloatingSearchBarController();
    _scrollController = ScrollMoreController();
    _fabController = ScrollFabController();
    WidgetsBinding.instance.addPostFrameCallback((_) => Future.delayed(Duration(milliseconds: 200), () => _searchController.open()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  List<String> _getHistories({String keyword}) {
    return ['lian', 'lianai', 'aiqing', 'ai'];
    // keyword = keyword?.trim();
    // if (keyword?.isNotEmpty != true) {
    //   return List.generate(20, (num) => 'Item ${num + 1}');
    // }
    // return List.generate(5, (num) => '$keyword ${num + 1}');
  }

  Future<List<SmallManga>> _getData({int page}) async {
    var dio = DioManager.getInstance().dio;
    var client = RestClient(dio);
    ErrorMessage err;
    var result = await client.searchMangas(keyword: _q ?? '?', page: page, order: _order).catchError((e) {
      err = wrapError(e);
    });
    if (err != null) {
      return Future.error(err.text);
    }
    _total = result.data.total;
    if (mounted) setState(() {});
    return result.data.data;
  }

  void _search() {
    if (_text == null) {
      Fluttertoast.showToast(msg: '请输入搜索内容');
      return;
    }

    if (_q != _text) {
      _q = _text;
      _searchController.close();
      _scrollController.refresh();
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
    }
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
                height: MediaQuery.of(context).padding.top + 36 + 4 * 2 + 1, // 45
                child: AppBar(),
              ),
            ),
            Positioned.fill(
              top: MediaQuery.of(context).padding.top + 45,
              child: PaginationListView<SmallManga>(
                controller: _scrollController,
                data: _data,
                strategy: PaginationStrategy.offsetBased,
                getDataByOffset: _getData,
                initialPage: 1,
                onAppend: (l) {
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
                clearWhenRefreshing: true,
                clearWhenError: false,
                updateOnlyIfNotEmpty: false,
                refreshFirst: false,
                placeholderSetting: PlaceholderSetting(
                  showNothingIcon: _q != null,
                  showNothingRetry: _q != null,
                ).toChinese(
                  nothingText: _q == null ? '请在搜索框中输入关键字...' : '无内容',
                ),
                onStateChanged: (_, __) => _fabController.hide(),
                padding: EdgeInsets.zero,
                separator: Divider(height: 1),
                itemBuilder: (c, item) => TinyMangaLineView(manga: item.toTiny()),
                topWidget: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 26,
                              padding: EdgeInsets.only(left: 5),
                              child: Center(
                                child: Text('"$_q" 的搜索结果 (共 ${_total == null ? '?' : _total.toString()} 部)'),
                              ),
                            ),
                            OptionPopupView<MangaOrder>(
                              title: _order.toTitle(),
                              top: 4,
                              value: _order,
                              items: [MangaOrder.byPopular, MangaOrder.byNew, MangaOrder.byUpdate],
                              onSelect: (o) {
                                if (_order != o) {
                                  _lastOrder = _order;
                                  _order = o;
                                  if (mounted) setState(() {});
                                  _scrollController.refresh();
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
            ),
            Scrollbar(
              child: FloatingSearchBar(
                controller: _searchController,
                height: 36,
                hint: '搜索',
                textInputType: TextInputType.text,
                textInputAction: TextInputAction.search,
                elevation: 3.0,
                iconColor: Colors.black54,
                margins: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 4),
                insets: EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.symmetric(horizontal: 3),
                scrollPadding: EdgeInsets.only(top: 0, bottom: 32),
                maxWidth: MediaQuery.of(context).size.width - 8 * 2,
                openMaxWidth: MediaQuery.of(context).size.width - 10 * 2,
                borderRadius: _searchController.isClosed ? BorderRadius.circular(3) : BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
                hintStyle: Theme.of(context).textTheme.bodyText2.copyWith(color: Theme.of(context).hintColor),
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
                onQueryChanged: (_) => mountedSetState(() {}),
                onFocusChanged: _changeFocus,
                onSubmitted: (_) => _search(),
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(3),
                    bottomRight: Radius.circular(3),
                  ),
                  child: Container(
                    color: Colors.white,
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_text != null && _text != _q)
                            ListTile(
                              title: Text('搜索 "$_text"'),
                              leading: Icon(Icons.search),
                              onTap: () => _search(), // 搜索
                            ),
                          if (_q != null)
                            ListTile(
                              title: Text('返回 "$_q" 的搜索结果'),
                              leading: Icon(Icons.search),
                              onTap: () => Navigator.of(context).maybePop(), // 返回
                            ),
                          ..._getHistories(keyword: _text).map(
                            (h) => ListTile(
                              title: Text(h),
                              leading: Icon(Icons.history),
                              trailing: IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () => Fluttertoast.showToast(msg: 'TODO'),
                              ),
                              onTap: () => _searchController.query = h,
                            ),
                          ),
                          if (_text != null)
                            ListTile(
                              title: Center(
                                child: Text('清空历史记录'),
                              ),
                              onTap: () => Fluttertoast.showToast(msg: 'TODO'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: ScrollFloatingActionButton(
          scrollController: _scrollController,
          fabController: _fabController,
          fab: FloatingActionButton(
            child: Icon(Icons.vertical_align_top),
            heroTag: 'SearchPage',
            onPressed: () => _scrollController.scrollTop(),
          ),
        ),
      ),
    );
  }
}
