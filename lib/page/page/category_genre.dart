import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/manga_corner_icons.dart';
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
    widget.action?.addAction(() => _controller.scrollToTop());
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadGenres());
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    _flagStorage.dispose();
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  var _genreLoading = true;
  late final _genres = <TinyCategory>[];
  var _genreError = '';

  Future<void> _loadGenres() async {
    _genreLoading = true;
    if (mounted) setState(() {});

    final client = RestClient(DioManager.instance.dio);
    try {
      if (globalGenres == null) {
        var result = await client.getGenres();
        globalGenres = result.data.data.map((c) => c.toTiny()).toList(); // 更新全局漫画类别
      }
      _genres.clear();
      _genreError = '';
      if (mounted) setState(() {});
      await Future.delayed(kFlashListDuration);
      _genres.add(allGenres[0]);
      _genres.addAll(globalGenres!);
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
  late final _flagStorage = MangaCornerFlagsStorage(stateSetter: () => mountedSetState(() {}));
  var _currOrder = AppSetting.instance.other.defaultMangaOrder;
  var _lastOrder = AppSetting.instance.other.defaultMangaOrder;
  late var _currGenre = widget.defaultGenre ?? allGenres[0];
  late var _lastGenre = widget.defaultGenre ?? allGenres[0];
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
    await _flagStorage.queryAndStoreFlags(mangaIds: result.data.data.map((e) => e.mid));
    if (mounted) setState(() {});
    return PagedList(list: result.data.data, next: result.data.page + 1);
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
            interactiveScrollbar: true,
            scrollbarMainAxisMargin: 2,
            scrollbarCrossAxisMargin: 2,
            placeholderSetting: PlaceholderSetting().copyWithChinese(),
            onPlaceholderStateChanged: (_, __) => _fabController.hide(),
            refreshFirst: true,
            clearWhenRefresh: false,
            clearWhenError: false,
            updateOnlyIfNotEmpty: false,
            onStartGettingData: () => mountedSetState(() => _getting = true),
            onStopGettingData: () => mountedSetState(() => _getting = false),
            onAppend: (_, l) {
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
          separator: Divider(height: 0, thickness: 1),
          itemBuilder: (c, _, item) => TinyMangaLineView(
            manga: item,
            inDownload: _flagStorage.isInDownload(mangaId: item.mid),
            inShelf: _flagStorage.isInShelf(mangaId: item.mid),
            inFavorite: _flagStorage.isInFavorite(mangaId: item.mid),
            inHistory: _flagStorage.isInHistory(mangaId: item.mid),
          ),
          extra: UpdatableDataViewExtraWidgets(
            outerTopWidgets: [
              ListHintView.widgets(
                widgets: [
                  OptionPopupView<TinyCategory>(
                    items: _genres,
                    value: _currGenre,
                    titleBuilder: (c, v) => v.isAll() ? '剧情' : v.title,
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
                    items: allAges,
                    value: _currAge,
                    titleBuilder: (c, v) => v.isAll() ? '受众' : v.title,
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
                    items: allZones,
                    value: _currZone,
                    titleBuilder: (c, v) => v.isAll() ? '地区' : v.title,
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
                    items: allStatuses,
                    value: _currStatus,
                    titleBuilder: (c, v) => v.isAll() ? '进度' : v.title,
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
            ],
            innerTopWidgets: [
              ListHintView.textWidget(
                leftText: '筛选结果 (共 $_total 部)',
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
