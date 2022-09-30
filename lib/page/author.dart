import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/page/view/tiny_manga_line.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/natives/browser.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';

/// 作者
/// Page for [Author].
class AuthorPage extends StatefulWidget {
  const AuthorPage({
    Key? key,
    required this.id,
    required this.name,
    required this.url,
  }) : super(key: key);

  final int id;
  final String name;
  final String url;

  @override
  _AuthorPageState createState() => _AuthorPageState();
}

class _AuthorPageState extends State<AuthorPage> {
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  var _loading = true;
  Author? _data;
  var _error = '';
  final _mangas = <SmallManga>[];
  var _total = 0;
  var _currOrder = MangaOrder.byPopular;
  late var _lastOrder = _currOrder;
  var _getting = false;

  Future<void> _loadData() async {
    _loading = true;
    if (mounted) setState(() {});

    final client = RestClient(DioManager.instance.dio);
    try {
      var result = await client.getAuthor(aid: widget.id);
      _data = null;
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _data = result.data;
    } catch (e, s) {
      _data = null;
      _error = wrapError(e, s).text;
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  Future<PagedList<SmallManga>> _getMangas({required int page}) async {
    final client = RestClient(DioManager.instance.dio);
    var result = await client.getAuthorMangas(aid: widget.id, page: page, order: _currOrder).onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
    _total = result.data.total;
    if (mounted) setState(() {});
    return PagedList(list: result.data.data, next: result.data.page + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_data?.name ?? widget.name),
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_browser),
            tooltip: '打开浏览器',
            onPressed: () => launchInBrowser(
              context: context,
              url: widget.url,
            ),
          ),
        ],
      ),
      body: PlaceholderText.from(
        isLoading: _loading,
        errorText: _error,
        isEmpty: _data == null,
        setting: PlaceholderSetting().copyWithChinese(),
        onRefresh: () => _loadData(),
        childBuilder: (c) => NestedScrollView(
          headerSliverBuilder: (c, o) => [
            // ****************************************************************
            // 头部框
            // ****************************************************************
            SliverToBoxAdapter(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0, 0.5, 1],
                    colors: [
                      Colors.blue[100]!,
                      Colors.orange[100]!,
                      Colors.purple[100]!,
                    ],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ****************************************************************
                    // 封面
                    // ****************************************************************
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: NetworkImageView(
                        url: _data!.cover,
                        height: 130,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // ****************************************************************
                    // 信息
                    // ****************************************************************
                    Container(
                      width: MediaQuery.of(context).size.width - 14 * 3 - 100, // | ▢ ▢ |
                      height: 150,
                      margin: EdgeInsets.only(top: 14, bottom: 14, right: 14),
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconText(
                              icon: Icon(Icons.person, size: 20, color: Colors.orange),
                              text: Text('别名 ${_data!.alias}'),
                              space: 8,
                            ),
                            IconText(
                              icon: Icon(Icons.place, size: 20, color: Colors.orange),
                              text: Text(_data!.zone),
                              space: 8,
                            ),
                            IconText(
                              icon: Icon(Icons.trending_up, size: 20, color: Colors.orange),
                              text: Text('平均评分 ${_data!.averageScore}'),
                              space: 8,
                            ),
                            IconText(
                              icon: Icon(Icons.edit, size: 20, color: Colors.orange),
                              text: Text('共收录 ${_data!.mangaCount} 部漫画'),
                              space: 8,
                            ),
                            IconText(
                              icon: Icon(Icons.fiber_new_outlined, size: 20, color: Colors.orange),
                              text: Text(
                                '最新收录 ${_data!.newestMangaTitle}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              space: 8,
                            ),
                            IconText(
                              icon: Icon(Icons.access_time, size: 20, color: Colors.orange),
                              text: Text('更新于 ${_data!.newestDate}'),
                              space: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ****************************************************************
            // 介绍
            // ****************************************************************
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.white,
                child: Text(
                  _data!.introduction.trim().isEmpty ? '暂无介绍' : _data!.introduction.trim(),
                  style: Theme.of(context).textTheme.subtitle1,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(height: 12),
            ),
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(c),
              sliver: SliverPersistentHeader(
                pinned: true,
                floating: true,
                delegate: SliverHeaderDelegate(
                  child: PreferredSize(
                    preferredSize: Size.fromHeight(26.0 + 5 * 2 + 1),
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  height: 26,
                                  padding: EdgeInsets.only(left: 5),
                                  child: Center(
                                    child: Text('全部漫画 (共 $_total 部)'),
                                  ),
                                ),
                                // ****************************************************************
                                // 漫画排序
                                // ****************************************************************
                                if (_total > 0)
                                  OptionPopupView<MangaOrder>(
                                    title: _currOrder.toTitle(),
                                    top: 4,
                                    value: _currOrder,
                                    items: const [MangaOrder.byPopular, MangaOrder.byNew, MangaOrder.byUpdate],
                                    onSelect: (o) {
                                      if (_currOrder != o) {
                                        _lastOrder = _currOrder;
                                        _currOrder = o;
                                        if (mounted) setState(() {});
                                        _pdvKey.currentState?.refresh();
                                      }
                                    },
                                    optionBuilder: (c, v) => v.toTitle(),
                                    enable: !_getting,
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
              ),
            ),
          ],
          controller: _controller,
          // ****************************************************************
          // 漫画
          // ****************************************************************
          body: Builder(
            builder: (c) => PaginationSliverListView<SmallManga>(
              key: _pdvKey,
              data: _mangas,
              getData: ({indicator}) => _getMangas(page: indicator),
              scrollController: PrimaryScrollController.of(c),
              paginationSetting: PaginationSetting(
                initialIndicator: 1,
                nothingIndicator: 0,
              ),
              setting: UpdatableDataViewSetting(
                padding: EdgeInsets.zero,
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
                },
                onError: (e) {
                  if (_mangas.isNotEmpty) {
                    Fluttertoast.showToast(msg: e.toString());
                  }
                  _currOrder = _lastOrder;
                  if (mounted) setState(() {});
                },
              ),
              useOverlapInjector: true,
              separator: Divider(height: 1),
              itemBuilder: (c, _, item) => TinyMangaLineView(manga: item.toTiny()),
            ),
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
