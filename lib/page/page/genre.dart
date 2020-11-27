import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  var _order = MangaOrder.NEW;
  var _genreLoading = true;
  var _genres = <Category>[];
  var _genreError = '';

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
    // TODO
    var dio = DioManager.getInstance().dio;
    var client = RestClient(dio);
    ErrorMessage err;
    var result = await client.getAllMangas(page: page, order: _order).catchError((e) {
      err = wrapError(e);
    });
    if (err != null) {
      return Future.error(err.text);
    }
    return result.data.data;
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
          // TODO
          topWidget: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryGridView(
                  categories: _genres.map((g) => g.toTiny()).toList(),
                  onCategoryClicked: (c) => Fluttertoast.showToast(msg: c.title),
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
