import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/page/view/small_author_line.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';

/// 分类漫画家
class AuthorSubPage extends StatefulWidget {
  const AuthorSubPage({
    Key? key,
    this.action,
  }) : super(key: key);

  final ActionController? action;

  @override
  _AuthorSubPageState createState() => _AuthorSubPageState();
}

class _AuthorSubPageState extends State<AuthorSubPage> with AutomaticKeepAliveClientMixin {
  final _controller = ScrollController();
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _fabController = AnimatedFabController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadGenres());
    widget.action?.addAction(() => _controller.scrollToTop());
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  var _genreLoading = true;
  final _genres = <Category>[];
  var _genreError = '';
  final _data = <SmallAuthor>[];
  var _total = 0;
  var _order = AuthorOrder.byPopular;
  var _lastOrder = AuthorOrder.byPopular;
  var _selectedGenre = allGenres[0];
  var _selectedAge = allAges[0];
  var _selectedZone = allZones[0];
  var _lastGenre = allGenres[0];
  var _lastAge = allAges[0];
  var _lastZone = allZones[0];
  var _disableOption = false;

  Future<void> _loadGenres() {
    _genreLoading = true;
    if (mounted) setState(() {});

    var client = RestClient(DioManager.instance.dio);
    return client.getGenres().then((r) async {
      _genreError = '';
      _genres.clear();
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _genres.addAll(r.data.data);
    }).catchError((e, s) {
      _genres.clear();
      _genreError = wrapError(e, s).text;
    }).whenComplete(() {
      _genreLoading = false;
      if (mounted) setState(() {});
    });
  }

  Future<PagedList<SmallAuthor>> _getData({required int page}) async {
    var client = RestClient(DioManager.instance.dio);
    var f = client.getAllAuthors(
      genre: _selectedGenre.name,
      zone: _selectedZone.name,
      age: _selectedAge.name,
      page: page,
      order: _order,
    );
    var result = await f.onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });

    _total = result.data.total;
    if (mounted) setState(() {});
    return PagedList(list: result.data.data, next: result.data.page + 1);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      // ****************************************************************
      // 加载 Genre
      // ****************************************************************
      body: PlaceholderText.from(
        isLoading: _genreLoading,
        errorText: _genreError,
        isEmpty: _genres.isEmpty,
        setting: PlaceholderSetting().copyWithChinese(),
        onRefresh: () => _loadGenres(),
        childBuilder: (c) => PaginationListView<SmallAuthor>(
          key: _pdvKey,
          data: _data,
          getData: ({indicator}) => _getData(page: indicator),
          scrollController: _controller,
          paginationSetting: PaginationSetting(
            initialIndicator: 1,
            nothingIndicator: 0,
          ),
          setting: UpdatableDataViewSetting(
            padding: EdgeInsets.zero,
            placeholderSetting: PlaceholderSetting().copyWithChinese(),
            refreshFirst: true,
            clearWhenError: false,
            clearWhenRefresh: false,
            updateOnlyIfNotEmpty: false,
            onPlaceholderStateChanged: (_, __) => _fabController.hide(),
            onStartGettingData: () => mountedSetState(() => _disableOption = true),
            onStopGettingData: () => mountedSetState(() => _disableOption = false),
            onAppend: (l, _) {
              if (l.length > 0) {
                Fluttertoast.showToast(msg: '新添了 ${l.length} 位漫画家');
              }
              _lastOrder = _order;
              _lastGenre = _selectedGenre;
              _lastAge = _selectedAge;
              _lastZone = _selectedZone;
              if (mounted) setState(() {});
            },
            onError: (e) {
              Fluttertoast.showToast(msg: e.toString());
              _order = _lastOrder;
              _selectedGenre = _lastGenre;
              _selectedAge = _lastAge;
              _selectedZone = _lastZone;
              if (mounted) setState(() {});
            },
          ),
          separator: Divider(height: 1),
          itemBuilder: (c, _, item) => SmallAuthorLineView(author: item),
          extra: UpdatableDataViewExtraWidgets(
            outerTopWidgets: [
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // ****************************************************************
                    // 检索条件
                    // ****************************************************************
                    OptionPopupView<TinyCategory>(
                      title: _selectedGenre.isAll() ? '剧情' : _selectedGenre.title,
                      top: 4,
                      doHighlight: true,
                      value: _selectedGenre,
                      items: _genres.map((g) => g.toTiny()).toList()..insert(0, allGenres[0]),
                      onSelect: (g) {
                        if (_selectedGenre != g) {
                          _lastGenre = _selectedGenre;
                          _selectedGenre = g;
                          if (mounted) setState(() {});
                          _pdvKey.currentState?.refresh();
                        }
                      },
                      optionBuilder: (c, v) => v.title,
                      enable: !_disableOption,
                    ),
                    OptionPopupView<TinyCategory>(
                      title: _selectedAge.isAll() ? '受众' : _selectedAge.title,
                      top: 4,
                      doHighlight: true,
                      value: _selectedAge,
                      items: allAges,
                      onSelect: (a) {
                        if (_selectedAge != a) {
                          _lastAge = _selectedAge;
                          _selectedAge = a;
                          if (mounted) setState(() {});
                          _pdvKey.currentState?.refresh();
                        }
                      },
                      optionBuilder: (c, v) => v.title,
                      enable: !_disableOption,
                    ),
                    OptionPopupView<TinyCategory>(
                      title: _selectedZone.isAll() ? '地区' : _selectedZone.title,
                      top: 4,
                      doHighlight: true,
                      value: _selectedZone,
                      items: allZones,
                      onSelect: (z) {
                        if (_selectedZone != z) {
                          _lastZone = _selectedZone;
                          _selectedZone = z;
                          if (mounted) setState(() {});
                          _pdvKey.currentState?.refresh();
                        }
                      },
                      optionBuilder: (c, v) => v.title,
                      enable: !_disableOption,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1),
            ],
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
                        child: Text('搜索结果 (共 $_total 位)'),
                      ),
                    ),
                    // ****************************************************************
                    // 检索排序
                    // ****************************************************************
                    OptionPopupView<AuthorOrder>(
                      title: _order.toTitle(),
                      top: 4,
                      doHighlight: true,
                      value: _order,
                      items: const [AuthorOrder.byPopular, AuthorOrder.byComic, AuthorOrder.byUpdate],
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
