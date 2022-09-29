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

/// 分类类别
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
  final _controller = ScrollController();
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _fabController = AnimatedFabController();

  @override
  void initState() {
    super.initState();
    if (widget.defaultGenre != null) {
      _selectedGenre = widget.defaultGenre!;
      _lastGenre = widget.defaultGenre!;
    }

    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadGenres());
    widget.action?.addAction('', () => _controller.scrollToTop());
  }

  @override
  void dispose() {
    widget.action?.removeAction('');
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  var _genreLoading = true;
  final _genres = <Category>[];
  var _genreError = '';
  final _data = <TinyManga>[];
  var _total = 0;
  var _order = MangaOrder.byPopular;
  var _lastOrder = MangaOrder.byPopular;
  var _selectedGenre = allGenres[0];
  var _selectedAge = allAges[0];
  var _selectedZone = allZones[0];
  var _selectedStatus = allStatuses[0];
  var _lastGenre = allGenres[0];
  var _lastAge = allAges[0];
  var _lastZone = allZones[0];
  var _lastStatus = allStatuses[0];
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

  Future<PagedList<TinyManga>> _getData({required int page}) async {
    var client = RestClient(DioManager.instance.dio);
    var f = client.getGenreMangas(
      genre: _selectedGenre.name,
      zone: _selectedZone.name,
      age: _selectedAge.name,
      status: _selectedStatus.name,
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
            padding: EdgeInsets.zero,
            placeholderSetting: PlaceholderSetting().copyWithChinese(),
            refreshFirst: true,
            clearWhenError: false,
            clearWhenRefresh: false,
            updateOnlyIfNotEmpty: false,
            onStartGettingData: () => mountedSetState(() => _disableOption = true),
            onStopGettingData: () => mountedSetState(() => _disableOption = false),
            onPlaceholderStateChanged: (_, __) => _fabController.hide(),
            onAppend: (l, _) {
              if (l.length > 0) {
                Fluttertoast.showToast(msg: '新添了 ${l.length} 部漫画');
              }
              _lastOrder = _order;
              _lastGenre = _selectedGenre;
              _lastAge = _selectedAge;
              _lastZone = _selectedZone;
              _lastStatus = _selectedStatus;
              if (mounted) setState(() {});
            },
            onError: (e) {
              Fluttertoast.showToast(msg: e.toString());
              _order = _lastOrder;
              _selectedGenre = _lastGenre;
              _selectedAge = _lastAge;
              _selectedZone = _lastZone;
              _selectedStatus = _lastStatus;
              if (mounted) setState(() {});
            },
          ),
          separator: Divider(height: 1),
          itemBuilder: (c, _, item) => TinyMangaLineView(manga: item),
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
                    OptionPopupView<TinyCategory>(
                      title: _selectedStatus.isAll() ? '进度' : _selectedStatus.title,
                      top: 4,
                      doHighlight: true,
                      value: _selectedStatus,
                      items: allStatuses,
                      onSelect: (s) {
                        if (_selectedStatus != s) {
                          _lastStatus = _selectedStatus;
                          _selectedStatus = s;
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
                        child: Text('搜索结果 (共 $_total 部)'),
                      ),
                    ),
                    // ****************************************************************
                    // 检索排序
                    // ****************************************************************
                    OptionPopupView<MangaOrder>(
                      title: _order.toTitle(),
                      top: 4,
                      doHighlight: true,
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
