import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/manga_rank.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';

/// 首页排行
class RankingSubPage extends StatefulWidget {
  const RankingSubPage({
    Key? key,
    this.action,
  }) : super(key: key);

  final ActionController? action;

  @override
  _RankingSubPageState createState() => _RankingSubPageState();
}

class _RankingSubPageState extends State<RankingSubPage> with AutomaticKeepAliveClientMixin {
  final _controller = ScrollController();
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _fabController = AnimatedFabController();

  @override
  void initState() {
    super.initState();
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
  final _data = <MangaRank>[];
  var _duration = allRankDurations[0];
  var _lastDuration = allRankDurations[0];
  var _selectedType = allRankTypes[0];
  var _lastType = allRankTypes[0];
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
    }).onError((e, s) {
      _genres.clear();
      _genreError = wrapError(e, s).text;
    }).whenComplete(() {
      _genreLoading = false;
      if (mounted) setState(() {});
    });
  }

  Future<List<MangaRank>> _getData() async {
    var client = RestClient(DioManager.instance.dio);
    var f = _duration.name == 'day'
        ? client.getDayRanking
        : _duration.name == 'week'
            ? client.getWeekRanking
            : _duration.name == 'month'
                ? client.getMonthRanking
                : client.getTotalRanking;
    var result = await f(type: _selectedType.name).onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
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
        isEmpty: _genres.isNotEmpty != true,
        setting: PlaceholderSetting().copyWithChinese(),
        onRefresh: () => _loadGenres(),
        childBuilder: (c) => RefreshableListView<MangaRank>(
          key: _pdvKey,
          data: _data,
          getData: () => _getData(),
          scrollController: _controller,
          setting: UpdatableDataViewSetting(
            padding: EdgeInsets.zero,
            placeholderSetting: PlaceholderSetting().copyWithChinese(),
            refreshFirst: true,
            clearWhenError: false,
            clearWhenRefresh: false,
            onPlaceholderStateChanged: (_, __) => _fabController.hide(),
            onStartGettingData: () => mountedSetState(() => _disableOption = true),
            onStopGettingData: () => mountedSetState(() => _disableOption = false),
            onAppend: (l, _) {
              if (l.length > 0) {
                Fluttertoast.showToast(msg: '新添了 ${l.length} 部漫画');
              }
              _lastDuration = _duration;
              _lastType = _selectedType;
              if (mounted) setState(() {});
            },
            onError: (e) {
              Fluttertoast.showToast(msg: e.toString());
              _duration = _lastDuration;
              _selectedType = _lastType;
              if (mounted) setState(() {});
            },
          ),
          separator: Divider(height: 1),
          itemBuilder: (c, _, item) => MangaRankView(manga: item),
          extra: UpdatableDataViewExtraWidgets(
            outerTopWidgets: [
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OptionPopupView<TinyCategory>(
                      title: _selectedType.isAll() ? '分类' : _selectedType.title,
                      top: 4,
                      doHighlight: true,
                      value: _selectedType,
                      items: _genres.map((g) => g.toTiny()).toList()..insertAll(0, allRankTypes),
                      onSelect: (t) {
                        if (_selectedType != t) {
                          _lastType = _selectedType;
                          _selectedType = t;
                          if (mounted) setState(() {});
                          _pdvKey.currentState?.refresh();
                        }
                      },
                      optionBuilder: (c, v) => v.title,
                      enable: !_disableOption,
                    ),
                    OptionPopupView<TinyCategory>(
                      title: _duration.title,
                      top: 4,
                      doHighlight: true,
                      value: _duration,
                      items: allRankDurations,
                      onSelect: (d) {
                        if (_duration != d) {
                          _lastDuration = _duration;
                          _duration = d;
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
