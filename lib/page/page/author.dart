import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/page/view/small_author_line.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';

/// 分类漫画家
class AuthorSubPage extends StatefulWidget {
  const AuthorSubPage({Key key}) : super(key: key);

  @override
  _AuthorSubPageState createState() => _AuthorSubPageState();
}

class _AuthorSubPageState extends State<AuthorSubPage> with AutomaticKeepAliveClientMixin {
  ScrollMoreController _controller;
  ScrollFabController _fabController;
  var _genreLoading = true;
  var _genres = <Category>[];
  var _genreError = '';
  var _data = <SmallAuthor>[];
  int _total;
  var _order = AuthorOrder.byPopular;
  var _lastOrder = AuthorOrder.byPopular;
  var _selectedGenre = allGenres[0];
  var _selectedAge = allAges[0];
  var _selectedZone = allZones[0];
  var _lastGenre = allGenres[0];
  var _lastAge = allAges[0];
  var _lastZone = allZones[0];
  var _disableOption = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollMoreController();
    _fabController = ScrollFabController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGenres());
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadGenres() {
    _genreLoading = true;
    if (mounted) setState(() {});

    var dio = DioManager.getInstance().dio;
    var client = RestClient(dio);
    return client.getGenres().then((r) async {
      _genreError = '';
      _genres.clear();
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _genres = r.data.data;
    }).catchError((e) {
      _genres.clear();
      _genreError = wrapError(e).text;
    }).whenComplete(() {
      _genreLoading = false;
      if (mounted) setState(() {});
    });
  }

  Future<List<SmallAuthor>> _getData({int page}) async {
    var dio = DioManager.getInstance().dio;
    var client = RestClient(dio);
    ErrorMessage err;
    var f = client.getAllAuthors(
      genre: _selectedGenre.name,
      zone: _selectedZone.name,
      age: _selectedAge.name,
      page: page,
      order: _order,
    );
    var result = await f.catchError((e) {
      err = wrapError(e);
    });
    if (err != null) {
      return Future.error(err.text);
    }

    _total = result.data.total;
    if (mounted) setState(() {});
    return result.data.data;
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
        isEmpty: _genres?.isNotEmpty != true,
        setting: PlaceholderSetting().toChinese(),
        onRefresh: () => _loadGenres(),
        childBuilder: (c) => PaginationListView<SmallAuthor>(
          controller: _controller,
          data: _data,
          strategy: PaginationStrategy.offsetBased,
          getDataByOffset: _getData,
          initialPage: 1,
          onStartLoading: () => mountedSetState(() => _disableOption = true),
          onStopLoading: () => mountedSetState(() => _disableOption = false),
          onAppend: (l) {
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
          clearWhenRefreshing: false,
          clearWhenError: false,
          updateOnlyIfNotEmpty: false,
          refreshFirst: true,
          placeholderSetting: PlaceholderSetting().toChinese(),
          onStateChanged: (_, __) => _fabController.hide(),
          padding: EdgeInsets.zero,
          separator: Divider(height: 1),
          itemBuilder: (c, item) => SmallAuthorLineView(author: item),
          outTopWidget: Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
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
                            _controller.refresh();
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
                            _controller.refresh();
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
                            _controller.refresh();
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
            ),
          ),
          topWidget: Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 5, top: 4, bottom: 3),
                        child: Text('搜索结果 (共 ${_total == null ? '?' : _total.toString()} 位)'),
                      ),
                      // ****************************************************************
                      // 检索排序
                      // ****************************************************************
                      OptionPopupView<AuthorOrder>(
                        title: _order.toTitle(),
                        top: 4,
                        doHighlight: true,
                        value: _order,
                        items: [AuthorOrder.byPopular, AuthorOrder.byComic, AuthorOrder.byUpdate],
                        onSelect: (o) {
                          if (_order != o) {
                            _lastOrder = _order;
                            _order = o;
                            if (mounted) setState(() {});
                            _controller.refresh();
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
      floatingActionButton: ScrollFloatingActionButton(
        scrollController: _controller,
        fabController: _fabController,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: 'AuthorSubPage',
          onPressed: () => _controller.scrollTop(),
        ),
      ),
    );
  }
}
