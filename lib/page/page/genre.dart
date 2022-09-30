import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/page/view/tiny_manga_line.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';

/// 分类-类别
class GenreSubPage extends StatefulWidget {
  const GenreSubPage({
    Key? key,
    this.defaultGenre,
    this.action,
  }) : super(key: key);

  final TinyCategory? defaultGenre;
  final ActionController? action;

  @override
  _GenreSubPageState createState() => _GenreSubPageState();
}

class _GenreSubPageState extends State<GenreSubPage> with AutomaticKeepAliveClientMixin {
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();

  @override
  void initState() {
    super.initState();
    if (widget.defaultGenre != null) {
      _currGenre = widget.defaultGenre!;
      _lastGenre = widget.defaultGenre!;
    }

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

  Future<void> _loadGenres() async {
    _genreLoading = true;
    if (mounted) setState(() {});

    final client = RestClient(DioManager.instance.dio);
    try {
      var result = await client.getGenres();
      _genres.clear();
      _genreError = '';
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _genres.addAll(result.data.data);
    } catch (e, s) {
      _genres.clear();
      _genreError = wrapError(e, s).text;
    } finally {
      _genreLoading = false;
      if (mounted) setState(() {});
    }
  }

  final _data = <TinyManga>[];
  var _total = 0;
  var _currOrder = MangaOrder.byPopular;
  var _lastOrder = MangaOrder.byPopular;
  var _currGenre = allGenres[0];
  var _lastGenre = allGenres[0];
  var _currAge = allAges[0];
  var _lastAge = allAges[0];
  var _currZone = allZones[0];
  var _lastZone = allZones[0];
  var _currStatus = allStatuses[0];
  var _lastStatus = allStatuses[0];
  var _getting = false;

  Future<PagedList<TinyManga>> _getData({required int page}) async {
    final client = RestClient(DioManager.instance.dio);
    var f = client.getGenreMangas(
      genre: _currGenre.name,
      zone: _currZone.name,
      age: _currAge.name,
      status: _currStatus.name,
      page: page,
      order: _currOrder,
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
        childBuilder: (c) => PaginationListView<TinyManga>(
          key: _pdvKey,
          data: _data,
          getData: ({indicator}) => _getData(page: indicator),
          scrollController: _controller,
          paginationSetting: PaginationSetting(
            initialIndicator: 1,
            nothingIndicator: 0,
          ),
          setting: UpdatableDataViewSetting(
          padding: EdgeInsets.symmetric(vertical: 0),
            placeholderSetting: PlaceholderSetting().copyWithChinese(),
            onPlaceholderStateChanged: (_, __) => _fabController.hide(),
            interactiveScrollbar: true,
            scrollbarCrossAxisMargin: 2,
            refreshFirst: true,
            clearWhenRefresh: false,
            clearWhenError: false,
            updateOnlyIfNotEmpty: false,
            onStartGettingData: () => mountedSetState(() => _getting = true),
            onStopGettingData: () => mountedSetState(() => _getting = false),
            onAppend: (l, _) {
              if (l.length > 0) {
                Fluttertoast.showToast(msg: '新添了 ${l.length} 部漫画');
              }
              _lastOrder = _currOrder;
              _lastGenre = _currGenre;
              _lastAge = _currAge;
              _lastZone = _currZone;
              _lastStatus = _currStatus;
            },
            onError: (e) {
              if (_data.isNotEmpty) {
                Fluttertoast.showToast(msg: e.toString());
              }
              _currOrder = _lastOrder;
              _currGenre = _lastGenre;
              _currAge = _lastAge;
              _currZone = _lastZone;
              _currStatus = _lastStatus;
              if (mounted) setState(() {});
            },
          ),
          separator: Divider(height: 1),
          itemBuilder: (c, _, item) => TinyMangaLineView(manga: item),
          extra: UpdatableDataViewExtraWidgets(
            outerTopWidgets: [
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // ****************************************************************
                    // 检索条件
                    // ****************************************************************
                    OptionPopupView<TinyCategory>(
                      title: _currGenre.isAll() ? '剧情' : _currGenre.title,
                      top: 4,
                      highlightable: true,
                      value: _currGenre,
                      items: _genres.map((g) => g.toTiny()).toList()..insert(0, allGenres[0]),
                      optionBuilder: (c, v) => v.title,
                      enable: !_getting,
                      onSelect: (g) {
                        if (_currGenre != g) {
                          _lastGenre = _currGenre;
                          _currGenre = g;
                          if (mounted) setState(() {});
                          _pdvKey.currentState?.refresh();
                        }
                      },
                    ),
                    OptionPopupView<TinyCategory>(
                      title: _currAge.isAll() ? '受众' : _currAge.title,
                      top: 4,
                      highlightable: true,
                      value: _currAge,
                      items: allAges,
                      optionBuilder: (c, v) => v.title,
                      enable: !_getting,
                      onSelect: (a) {
                        if (_currAge != a) {
                          _lastAge = _currAge;
                          _currAge = a;
                          if (mounted) setState(() {});
                          _pdvKey.currentState?.refresh();
                        }
                      },
                    ),
                    OptionPopupView<TinyCategory>(
                      title: _currZone.isAll() ? '地区' : _currZone.title,
                      top: 4,
                      highlightable: true,
                      value: _currZone,
                      items: allZones,
                      optionBuilder: (c, v) => v.title,
                      enable: !_getting,
                      onSelect: (z) {
                        if (_currZone != z) {
                          _lastZone = _currZone;
                          _currZone = z;
                          if (mounted) setState(() {});
                          _pdvKey.currentState?.refresh();
                        }
                      },
                    ),
                    OptionPopupView<TinyCategory>(
                      title: _currStatus.isAll() ? '进度' : _currStatus.title,
                      top: 4,
                      highlightable: true,
                      value: _currStatus,
                      items: allStatuses,
                      optionBuilder: (c, v) => v.title,
                      enable: !_getting,
                      onSelect: (s) {
                        if (_currStatus != s) {
                          _lastStatus = _currStatus;
                          _currStatus = s;
                          if (mounted) setState(() {});
                          _pdvKey.currentState?.refresh();
                        }
                      },
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
                        child: Text('搜索结果 (共 $_total 部)'),
                      ),
                    ),
                    // ****************************************************************
                    // 检索排序
                    // ****************************************************************
                    OptionPopupView<MangaOrder>(
                      title: _currOrder.toTitle(),
                      top: 4,
                      highlightable: true,
                      value: _currOrder,
                      items: const [MangaOrder.byPopular, MangaOrder.byNew, MangaOrder.byUpdate],
                      optionBuilder: (c, v) => v.toTitle(),
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
