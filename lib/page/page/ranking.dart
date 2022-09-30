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

/// 首页-排行
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
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _controller = ScrollController();
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

  final _data = <MangaRank>[];
  var _currType = allRankTypes[0];
  var _lastType = allRankTypes[0];
  var _currDuration = allRankDurations[0];
  var _lastDuration = allRankDurations[0];
  var _getting = false;

  Future<List<MangaRank>> _getData() async {
    final client = RestClient(DioManager.instance.dio);
    var f = _currDuration.name == 'day'
        ? client.getDayRanking
        : _currDuration.name == 'week'
            ? client.getWeekRanking
            : _currDuration.name == 'month'
                ? client.getMonthRanking
                : client.getTotalRanking;
    var result = await f(type: _currType.name).onError((e, s) {
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
        isEmpty: _genres.isEmpty,
        setting: PlaceholderSetting().copyWithChinese(),
        onRefresh: () => _loadGenres(),
        onChanged: (_, __) => _fabController.hide(),
        childBuilder: (c) => RefreshableListView<MangaRank>(
          key: _pdvKey,
          data: _data,
          getData: () => _getData(),
          scrollController: _controller,
          setting: UpdatableDataViewSetting(
          padding: EdgeInsets.symmetric(vertical: 0),
            placeholderSetting: PlaceholderSetting().copyWithChinese(),
            onPlaceholderStateChanged: (_, __) => _fabController.hide(),
            interactiveScrollbar: true,
            scrollbarCrossAxisMargin: 2,
            refreshFirst: true,
            clearWhenRefresh: false,
            clearWhenError: false,
            onStartGettingData: () => mountedSetState(() => _getting = true),
            onStopGettingData: () => mountedSetState(() => _getting = false),
            onAppend: (l, _) {
              if (l.length > 0) {
                Fluttertoast.showToast(msg: '新添了 ${l.length} 部漫画');
              }
              _lastDuration = _currDuration;
              _lastType = _currType;
            },
            onError: (e) {
              if (_data.isNotEmpty) {
                Fluttertoast.showToast(msg: e.toString());
              }
              _currDuration = _lastDuration;
              _currType = _lastType;
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
                      title: _currType.isAll() ? '分类' : _currType.title,
                      top: 4,
                      highlightable: true,
                      value: _currType,
                      items: _genres.map((g) => g.toTiny()).toList()..insertAll(0, allRankTypes),
                      optionBuilder: (c, v) => v.title,
                      enable: !_getting,
                      onSelect: (t) {
                        if (_currType != t) {
                          _lastType = _currType;
                          _currType = t;
                          if (mounted) setState(() {});
                          _pdvKey.currentState?.refresh();
                        }
                      },
                    ),
                    OptionPopupView<TinyCategory>(
                      title: _currDuration.title,
                      top: 4,
                      highlightable: true,
                      value: _currDuration,
                      items: allRankDurations,
                      optionBuilder: (c, v) => v.title,
                      enable: !_getting,
                      onSelect: (d) {
                        if (_currDuration != d) {
                          _lastDuration = _currDuration;
                          _currDuration = d;
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
