import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/manga_rank.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';

/// 首页排行
class RankingSubPage extends StatefulWidget {
  const RankingSubPage({
    Key key,
    this.action,
  }) : super(key: key);

  final ActionController action;

  @override
  _RankingSubPageState createState() => _RankingSubPageState();
}

class _RankingSubPageState extends State<RankingSubPage> with AutomaticKeepAliveClientMixin {
  ScrollMoreController _controller;
  ScrollFabController _fabController;
  var _genreLoading = true;
  var _genres = <Category>[];
  var _genreError = '';
  var _data = <MangaRank>[];
  var _duration = allRankDurations[0];
  var _lastDuration = allRankDurations[0];
  var _selectedType = allRankTypes[0];
  var _lastType = allRankTypes[0];
  var _disableOption = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollMoreController();
    _fabController = ScrollFabController();
    widget.action?.addAction('', () => _controller.scrollTop());
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

    var dio = DioManager.instance.dio;
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

  Future<List<MangaRank>> _getData() async {
    var dio = DioManager.instance.dio;
    var client = RestClient(dio);
    ErrorMessage err;
    var f = _duration.name == 'day'
        ? client.getDayRanking
        : _duration.name == 'week'
            ? client.getWeekRanking
            : _duration.name == 'month'
                ? client.getMonthRanking
                : client.getTotalRanking;
    var result = await f(type: _selectedType.name).catchError((e) {
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
      // ****************************************************************
      // 加载 Genre
      // ****************************************************************
      body: PlaceholderText.from(
        isLoading: _genreLoading,
        errorText: _genreError,
        isEmpty: _genres?.isNotEmpty != true,
        setting: PlaceholderSetting().toChinese(),
        onRefresh: () => _loadGenres(),
        childBuilder: (c) => RefreshableListView<MangaRank>(
          controller: _controller,
          data: _data,
          getData: () => _getData(),
          onStartLoading: () => mountedSetState(() => _disableOption = true),
          onStopLoading: () => mountedSetState(() => _disableOption = false),
          onAppend: (l) {
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
          clearWhenRefreshing: false,
          clearWhenError: false,
          refreshFirst: true,
          placeholderSetting: PlaceholderSetting().toChinese(),
          onStateChanged: (_, __) => _fabController.hide(),
          separator: Divider(height: 1),
          physics: AlwaysScrollableScrollPhysics(),
          itemBuilder: (c, item) => MangaRankView(manga: item),
          outTopWidget: Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
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
                            _controller.refresh();
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
        ),
      ),
      floatingActionButton: ScrollFloatingActionButton(
        scrollController: _controller,
        fabController: _fabController,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: 'RankingSubPage',
          onPressed: () => _controller.scrollTop(),
        ),
      ),
    );
  }
}
