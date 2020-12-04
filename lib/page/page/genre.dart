import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/enums.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/page/view/tiny_manga_line.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';

/// 分类类别
class GenreSubPage extends StatefulWidget {
  const GenreSubPage({Key key}) : super(key: key);

  @override
  _GenreSubPageState createState() => _GenreSubPageState();
}

class _GenreSubPageState extends State<GenreSubPage> with AutomaticKeepAliveClientMixin {
  ScrollMoreController _controller;
  ScrollFabController _fabController;
  var _genreLoading = true;
  var _genres = <Category>[];
  var _genreError = '';
  var _data = <TinyManga>[];
  int _total;
  var _order = MangaOrder.byPopular;
  var _selectedGenre = genres[0];
  var _selectedAge = ages[0];
  var _selectedZone = zones[0];
  var _selectedStatus = statuses[0];

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

  Future<List<TinyManga>> _getData({int page}) async {
    var dio = DioManager.getInstance().dio;
    var client = RestClient(dio);
    ErrorMessage err;
    var f = client.getGenreMangas(
      genre: _selectedGenre.name,
      zone: _selectedZone.name,
      age: _selectedAge.name,
      status: _selectedStatus.name,
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
    // var workingHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - 45 - kBottomNavigationBarHeight;
    // var workingWidth = MediaQuery.of(context).size.width;
    // var filterHeight = 26.0 + 5 * 2 - 1;

    return Scaffold(
      // ****************************************************************
      // 加载 Genre
      // ****************************************************************
      body: PlaceholderText.from(
        isLoading: _genreLoading,
        errorText: _genreError,
        isEmpty: _genres?.isNotEmpty != true,
        setting: PlaceholderSetting(
          showProgress: true,
          loadingText: '加载中',
          retryText: '重试',
        ),
        onRefresh: () => _loadGenres(),
        childBuilder: (c) => PaginationListView<TinyManga>(
          controller: _controller,
          data: _data,
          strategy: PaginationStrategy.offsetBased,
          getDataByOffset: _getData,
          initialPage: 1,
          refreshFirst: true,
          updateOnlyIfNotEmpty: true,
          padding: EdgeInsets.symmetric(vertical: 3),
          placeholderSetting: PlaceholderSetting(
            showProgress: true,
            loadingText: '加载中',
            retryText: '重试',
          ),
          onStateChanged: (_) => _fabController.hide(),
          separator: Divider(height: 1),
          itemBuilder: (c, item) => TinyMangaLineView(manga: item),
          topWidget: Container(
            color: Colors.white,
            child: Column(
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ****************************************************************
                // 检索条件
                // ****************************************************************
                Container(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // 剧情
                          OptionPopupView<TinyCategory>(
                            title: _selectedGenre.name == 'all' ? '剧情' : _selectedGenre.title,
                            top: 4,
                            doHighlight: true,
                            value: _selectedGenre,
                            items: _genres.map((g) => g.toTiny()).toList()..insert(0, genres[0]),
                            onSelect: (g) {
                              if (_selectedGenre != g) {
                                _selectedGenre = g;
                                if (mounted) setState(() {});
                                _controller.refresh();
                              }
                            },
                            optionBuilder: (c, v) => v.title,
                          ),
                          // 受众

                          OptionPopupView<TinyCategory>(
                            title: _selectedAge.name == 'all' ? '受众' : _selectedAge.title,
                            top: 4,
                            doHighlight: true,
                            value: _selectedAge,
                            items: ages,
                            onSelect: (a) {
                              if (_selectedAge != a) {
                                _selectedAge = a;
                                if (mounted) setState(() {});
                                _controller.refresh();
                              }
                            },
                            optionBuilder: (c, v) => v.title,
                          ),
                          // 地区
                          OptionPopupView<TinyCategory>(
                            title: _selectedZone.name == 'all' ? '地区' : _selectedZone.title,
                            top: 4,
                            doHighlight: true,
                            value: _selectedZone,
                            items: zones,
                            onSelect: (z) {
                              if (_selectedZone != z) {
                                _selectedZone = z;
                                if (mounted) setState(() {});
                                _controller.refresh();
                              }
                            },
                            optionBuilder: (c, v) => v.title,
                          ),
                          // 进度
                          OptionPopupView<TinyCategory>(
                            title: _selectedStatus.name == 'all' ? '进度' : _selectedStatus.title,
                            top: 4,
                            doHighlight: true,
                            value: _selectedStatus,
                            items: statuses,
                            onSelect: (s) {
                              if (_selectedStatus != s) {
                                _selectedStatus = s;
                                if (mounted) setState(() {});
                                _controller.refresh();
                              }
                            },
                            optionBuilder: (c, v) => v.title,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1),
                // ****************************************************************
                // 检索排序
                // ****************************************************************
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Text('搜索结果 (共 ${_total == null ? '?' : _total.toString()} 部)'),
                      ),
                      OptionPopupView<MangaOrder>(
                        title: _order.toTitle(),
                        top: 4,
                        doHighlight: true,
                        value: _order,
                        items: [MangaOrder.byPopular, MangaOrder.byNew, MangaOrder.byUpdate],
                        onSelect: (o) {
                          if (_order != o) {
                            _order = o;
                            if (mounted) setState(() {});
                            _controller.refresh();
                          }
                        },
                        optionBuilder: (c, v) => v.toTitle(),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1.5),
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
          heroTag: 'GenreSubPage',
          onPressed: () => _controller.scrollTop(),
        ),
      ),
    );
  }
}
