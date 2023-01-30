import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/manga_ranking_line.dart';
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
  final _rdvKey = GlobalKey<RefreshableDataViewState>();
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
  final _genres = <TinyCategory>[];
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
      _genres.addAll(allRankingTypes);
      _genres.addAll(globalGenres!);
    } catch (e, s) {
      _genres.clear();
      _genreError = wrapError(e, s).text;
    } finally {
      _genreLoading = false;
      if (mounted) setState(() {});
    }
  }

  final _data = <MangaRanking>[];
  late final _flagStorage = MangaCornerFlagStorage(stateSetter: () => mountedSetState(() {}));
  var _currType = allRankingTypes[0];
  var _lastType = allRankingTypes[0];
  var _currDuration = allRankingDurations[0];
  var _lastDuration = allRankingDurations[0];
  var _getting = false;

  Future<List<MangaRanking>> _getData() async {
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
    await _flagStorage.queryAndStoreFlags(mangaIds: result.data.data.map((e) => e.mid));
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
        isEmpty: _genres.isEmpty,
        setting: PlaceholderSetting().copyWithChinese(),
        onRefresh: () => _loadGenres(),
        onChanged: (_, __) => _fabController.hide(),
        childBuilder: (c) => RefreshableListView<MangaRanking>(
          key: _rdvKey,
          data: _data,
          getData: () => _getData(),
          scrollController: _controller,
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
            onStartGettingData: () => mountedSetState(() => _getting = true),
            onStopGettingData: () => mountedSetState(() => _getting = false),
            onAppend: (_, l) {
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
          separator: Divider(height: 0, thickness: 1),
          itemBuilder: (c, _, item) => MangaRankingLineView(
            manga: item,
            flags: _flagStorage.getFlags(mangaId: item.mid),
          ),
          extra: UpdatableDataViewExtraWidgets(
            outerTopWidgets: [
              ListHintView.textWidget(
                leftText: '排行前50的漫画',
                rightWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OptionPopupView<TinyCategory>(
                      items: _genres,
                      value: _currType,
                      titleBuilder: (c, v) => v.isAll() ? '分类' : v.title,
                      enable: !_getting,
                      onSelect: (t) {
                        if (_currType != t) {
                          _lastType = _currType;
                          _currType = t;
                          if (mounted) setState(() {});
                          _rdvKey.currentState?.refresh();
                        }
                      },
                    ),
                    SizedBox(width: 12),
                    OptionPopupView<TinyCategory>(
                      items: allRankingDurations,
                      value: _currDuration,
                      titleBuilder: (c, v) => v.title,
                      enable: !_getting,
                      onSelect: (d) {
                        if (_currDuration != d) {
                          _lastDuration = _currDuration;
                          _currDuration = d;
                          if (mounted) setState(() {});
                          _rdvKey.currentState?.refresh();
                        }
                      },
                    ),
                  ],
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
