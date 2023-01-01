import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/image_viewer.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/manga_corner_icons.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/page/view/tiny_manga_line.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';

/// 漫画作者页，网络请求并展示 [Author] 信息
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
    _flagStorage.dispose();
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  var _loading = true;
  Author? _data;
  var _error = '';

  Future<void> _loadData() async {
    _loading = true;
    if (mounted) setState(() {});

    final client = RestClient(DioManager.instance.dio);
    try {
      var result = await client.getAuthor(aid: widget.id);
      _data = null;
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(kFlashListDuration);
      _data = result.data;
    } catch (e, s) {
      _data = null;
      _error = wrapError(e, s).text;
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  final _mangas = <SmallManga>[];
  var _total = 0;
  late final _flagStorage = MangaCornerFlagsStorage(stateSetter: () => mountedSetState(() {}));
  var _currOrder = AppSetting.instance.other.defaultMangaOrder;
  var _lastOrder = AppSetting.instance.other.defaultMangaOrder;
  var _getting = false;

  Future<PagedList<SmallManga>> _getMangas({required int page}) async {
    final client = RestClient(DioManager.instance.dio);
    var result = await client.getAuthorMangas(aid: widget.id, page: page, order: _currOrder).onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
    _total = result.data.total;
    await _flagStorage.queryAndStoreFlags(mangaIds: result.data.data.map((e) => e.mid));
    if (mounted) setState(() {});
    return PagedList(list: result.data.data, next: result.data.page + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_data?.name ?? widget.name),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: false),
        actions: [
          AppBarActionButton(
            icon: Icon(Icons.open_in_browser),
            tooltip: '用浏览器打开',
            onPressed: () => launchInBrowser(
              context: context,
              url: _data?.url ?? widget.url,
            ),
          ),
        ],
      ),
      drawer: AppDrawer(
        currentSelection: DrawerSelection.none,
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ****************************************************************
                    // 头像
                    // ****************************************************************
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: FullRippleWidget(
                        child: NetworkImageView(
                          url: _data!.cover,
                          height: 130,
                          width: 100,
                        ),
                        onTap: () => Navigator.of(context).push(
                          CustomPageRoute(
                            context: context,
                            builder: (c) => ImageViewerPage(
                              url: _data!.cover,
                              title: '作者头像',
                            ),
                          ),
                        ),
                      ),
                    ),
                    // ****************************************************************
                    // 信息
                    // ****************************************************************
                    Container(
                      width: MediaQuery.of(context).size.width - 14 * 3 - 100, // | ▢ ▢▢ |
                      padding: EdgeInsets.only(top: 10, bottom: 10, right: 0),
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconText(
                            icon: Icon(Icons.person, size: 20, color: Colors.orange),
                            text: Flexible(
                              child: Text(
                                '作者别名：${_data!.alias}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            space: 8,
                            iconPadding: EdgeInsets.symmetric(vertical: 2.8),
                          ),
                          IconText(
                            icon: Icon(Icons.place, size: 20, color: Colors.orange),
                            text: Text('地区：${_data!.zone}'),
                            space: 8,
                            iconPadding: EdgeInsets.symmetric(vertical: 2.8),
                          ),
                          IconText(
                            icon: Icon(Icons.stars, size: 20, color: Colors.orange),
                            text: Text('平均评分 ${_data!.averageScore}'),
                            space: 8,
                            iconPadding: EdgeInsets.symmetric(vertical: 2.8),
                          ),
                          IconText(
                            icon: Icon(Icons.edit, size: 20, color: Colors.orange),
                            text: Text('共收录 ${_data!.mangaCount} 部漫画'),
                            space: 8,
                            iconPadding: EdgeInsets.symmetric(vertical: 2.8),
                          ),
                          IconText(
                            icon: Icon(Icons.update, size: 20, color: Colors.orange),
                            text: Text('收录更新于 ${_data!.newestDate}'),
                            space: 8,
                            iconPadding: EdgeInsets.symmetric(vertical: 2.8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ****************************************************************
            // 作者介绍 & 最新收录
            // ****************************************************************
            SliverToBoxAdapter(
              child: Material(
                color: Colors.white,
                child: InkWell(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      '作者介绍：\n' + (_data!.introduction.trim().isEmpty ? '${_data!.name}漫画全集' : _data!.introduction.trim()),
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                  ),
                  onTap: () => copyText(_data!.introduction.trim().isEmpty ? '${_data!.name}漫画全集' : _data!.introduction.trim(), showToast: true),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                color: Colors.white,
                child: Divider(height: 0, thickness: 1),
              ),
            ),
            SliverToBoxAdapter(
              child: Material(
                color: Colors.white,
                child: InkWell(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      '最新收录：\n《${_data!.newestMangaTitle}》',
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                  ),
                  onTap: () => copyText(_data!.newestMangaTitle, showToast: true),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(height: 12),
            ),
            // ****************************************************************
            // 漫画列表头
            // ****************************************************************
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(c),
              sliver: SliverPersistentHeader(
                pinned: true,
                floating: true,
                delegate: SliverHeaderDelegate(
                  child: PreferredSize(
                    preferredSize: Size.fromHeight(26.0 + 5 * 2 + 1), // height: 26, padding: vertical_5, extra: divider_1
                    child: ListHintView.textWidget(
                      leftText: '全部漫画 (共 $_total 部)',
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
                  ),
                ),
              ),
            ),
          ],
          controller: _controller,
          // ****************************************************************
          // 漫画列表
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
                interactiveScrollbar: true,
                scrollbarMainAxisMargin: 2,
                scrollbarCrossAxisMargin: 2,
                scrollbarExtraMargin: EdgeInsets.only(top: NestedScrollView.sliverOverlapAbsorberHandleFor(c).layoutExtent ?? 0),
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
              separator: Divider(height: 0, thickness: 1),
              itemBuilder: (c, _, item) => TinyMangaLineView(
                manga: item.toTiny(),
                inDownload: _flagStorage.isInDownload(mangaId: item.mid),
                inShelf: _flagStorage.isInShelf(mangaId: item.mid),
                inFavorite: _flagStorage.isInFavorite(mangaId: item.mid),
                inHistory: _flagStorage.isInHistory(mangaId: item.mid),
              ),
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
