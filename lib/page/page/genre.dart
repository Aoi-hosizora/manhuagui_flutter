import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/enums.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/category_grid.dart';
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
  var _data = <TinyManga>[];
  int _total;
  var _order = MangaOrder.byPopular;
  var _genreLoading = true;
  var _genres = <Category>[];
  var _genreError = '';
  var _selectedGenre = genres[0];
  var _selectedAge = ages[0];
  var _selectedZone = zones[0];
  var _selectedStatus = statuses[0];
  var _showGenreFilter = false;
  var _showAgeFilter = false;
  var _showZoneFilter = false;
  var _showStatusFilter = false;

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
      _genres = [];
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _genres = r.data.data;
    }).catchError((e) {
      _genres = [];
      _genreError = wrapError(e).text;
    }).whenComplete(() {
      _genreLoading = false;
      if (mounted) setState(() {});
    });
  }

  Future<List<TinyManga>> _getData({int page}) async {
    var dio = DioManager.getInstance().dio;
    var client = RestClient(dio);
    var f = client.getGenreMangas(
      genre: _selectedGenre.name,
      zone: _selectedZone.name,
      age: _selectedAge.name,
      status: _selectedStatus.name,
      page: page,
      order: _order,
    );
    ErrorMessage err;
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
    var workingHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - 45 - kBottomNavigationBarHeight;
    var workingWidth = MediaQuery.of(context).size.width;
    var filterHeight = 26.0 + 5 * 2 - 1;

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
        childBuilder: (c) => Stack(
          children: [
            // ****************************************************************
            // 检索结果
            // ****************************************************************
            Positioned.fill(
              child: PaginationListView<TinyManga>(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                // TODO
                                InkWell(
                                  onTap: () {
                                    _showGenreFilter = !_showGenreFilter;
                                    _showAgeFilter = false;
                                    _showZoneFilter = false;
                                    _showStatusFilter = false;
                                    if (mounted) setState(() {});
                                  },
                                  // 剧情
                                  child: Container(
                                    padding: EdgeInsets.only(left: 15),
                                    height: 26,
                                    width: 75,
                                    child: IconText(
                                      alignment: IconTextAlignment.r2l,
                                      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                                      text: Text(
                                        _selectedGenre == null || _selectedGenre.name == 'all' ? '剧情' : _selectedGenre.title,
                                        style: TextStyle(color: _showGenreFilter ? Colors.orange : Colors.black),
                                      ),
                                      space: 2,
                                    ),
                                  ),
                                ),
                                // 受众
                                InkWell(
                                  onTap: () {
                                    _showGenreFilter = false;
                                    _showAgeFilter = !_showAgeFilter;
                                    _showZoneFilter = false;
                                    _showStatusFilter = false;
                                    if (mounted) setState(() {});
                                  },
                                  child: Container(
                                    padding: EdgeInsets.only(left: 15),
                                    height: 26,
                                    width: 75,
                                    child: IconText(
                                      alignment: IconTextAlignment.r2l,
                                      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                                      text: Text(
                                        _selectedAge == null || _selectedAge.name == 'all' ? '受众' : _selectedAge.title,
                                        style: TextStyle(color: _showAgeFilter ? Colors.orange : Colors.black),
                                      ),
                                      space: 2,
                                    ),
                                  ),
                                ),
                                // 地区
                                InkWell(
                                  onTap: () {
                                    _showGenreFilter = false;
                                    _showAgeFilter = false;
                                    _showZoneFilter = !_showZoneFilter;
                                    _showStatusFilter = false;
                                    if (mounted) setState(() {});
                                  },
                                  child: Container(
                                    padding: EdgeInsets.only(left: 15),
                                    height: 26,
                                    width: 75,
                                    child: IconText(
                                      alignment: IconTextAlignment.r2l,
                                      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                                      text: Text(
                                        _selectedZone == null || _selectedZone.name == 'all' ? '地区' : _selectedZone.title,
                                        style: TextStyle(color: _showZoneFilter ? Colors.orange : Colors.black),
                                      ),
                                      space: 2,
                                    ),
                                  ),
                                ),
                                // 进度
                                InkWell(
                                  onTap: () {
                                    _showGenreFilter = false;
                                    _showAgeFilter = false;
                                    _showZoneFilter = false;
                                    _showStatusFilter = !_showStatusFilter;
                                    if (mounted) setState(() {});
                                  },
                                  child: Container(
                                    padding: EdgeInsets.only(left: 15),
                                    height: 26,
                                    width: 75,
                                    child: IconText(
                                      alignment: IconTextAlignment.r2l,
                                      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                                      text: Text(
                                        _selectedStatus == null || _selectedStatus.name == 'all' ? '进度' : _selectedStatus.title,
                                        style: TextStyle(color: _showStatusFilter ? Colors.orange : Colors.black),
                                      ),
                                      space: 2,
                                    ),
                                  ),
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
                            Container(
                              height: 26,
                              width: 75,
                              child: DropdownButton<MangaOrder>(
                                // TODO
                                value: _order,
                                items: [MangaOrder.byPopular, MangaOrder.byNew, MangaOrder.byUpdate]
                                    .map(
                                      (o) => DropdownMenuItem(
                                        value: o,
                                        child: Text(o.toTitle()),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != _order) {
                                    _order = v;
                                    if (mounted) setState(() {});
                                    _controller.refresh();
                                  }
                                },
                                isExpanded: true,
                                style: Theme.of(context).textTheme.bodyText1,
                                underline: Container(color: Colors.white),
                              ),
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
            // ****************************************************************
            // 剧情分类
            // ****************************************************************
            if (_showGenreFilter) ...[
              Positioned(
                top: filterHeight,
                child: GestureDetector(
                  child: Container(
                    height: workingHeight,
                    width: workingWidth,
                    color: Colors.black.withAlpha(100),
                  ),
                  onTap: () {
                    _showGenreFilter = false;
                    if (mounted) setState(() {});
                  },
                ),
              ),
              Positioned(
                top: filterHeight,
                child: CategoryGridView(
                  categories: _genres.map((g) => g.toTiny()).toList()..insert(0, genres[0]),
                  selectedCategory: _selectedGenre,
                  onCategoryClicked: (c) {
                    if (_selectedGenre.name != c.name) {
                      _selectedGenre = c;
                      _showGenreFilter = false;
                      if (mounted) setState(() {});
                      _controller.refresh();
                    }
                  },
                ),
              ),
            ],
            // ****************************************************************
            // 受众分类
            // ****************************************************************
            if (_showAgeFilter) ...[
              Positioned(
                top: filterHeight,
                child: GestureDetector(
                  child: Container(
                    height: workingHeight,
                    width: workingWidth,
                    color: Colors.black.withAlpha(100),
                  ),
                  onTap: () {
                    _showAgeFilter = false;
                    if (mounted) setState(() {});
                  },
                ),
              ),
              Positioned(
                top: filterHeight,
                child: CategoryGridView(
                  categories: ages,
                  selectedCategory: _selectedAge,
                  onCategoryClicked: (c) {
                    if (_selectedAge.name != c.name) {
                      _selectedAge = c;
                      _showAgeFilter = false;
                      if (mounted) setState(() {});
                      _controller.refresh();
                    }
                  },
                ),
              ),
            ],
            // ****************************************************************
            // 地区分类
            // ****************************************************************
            if (_showZoneFilter) ...[
              Positioned(
                top: filterHeight,
                child: GestureDetector(
                  child: Container(
                    height: workingHeight,
                    width: workingWidth,
                    color: Colors.black.withAlpha(100),
                  ),
                  onTap: () {
                    _showZoneFilter = false;
                    if (mounted) setState(() {});
                  },
                ),
              ),
              Positioned(
                top: filterHeight,
                child: CategoryGridView(
                  categories: zones,
                  selectedCategory: _selectedZone,
                  onCategoryClicked: (c) {
                    if (_selectedZone.name != c.name) {
                      _selectedZone = c;
                      _showZoneFilter = false;
                      if (mounted) setState(() {});
                      _controller.refresh();
                    }
                  },
                ),
              ),
            ],
            // ****************************************************************
            // 进度分类
            // ****************************************************************
            if (_showStatusFilter) ...[
              Positioned(
                top: filterHeight,
                child: GestureDetector(
                  child: Container(
                    height: workingHeight,
                    width: workingWidth,
                    color: Colors.black.withAlpha(100),
                  ),
                  onTap: () {
                    _showStatusFilter = false;
                    if (mounted) setState(() {});
                  },
                ),
              ),
              Positioned(
                top: filterHeight,
                child: CategoryGridView(
                  categories: statuses,
                  selectedCategory: _selectedStatus,
                  onCategoryClicked: (c) {
                    if (_selectedStatus.name != c.name) {
                      _selectedStatus = c;
                      _showStatusFilter = false;
                      if (mounted) setState(() {});
                      _controller.refresh();
                    }
                  },
                ),
              ),
            ],
            // ****************************************************************
            // ================================================================
            // ****************************************************************
          ],
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
