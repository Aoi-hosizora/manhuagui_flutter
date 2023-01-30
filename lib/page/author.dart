import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/author_detail.dart';
import 'package:manhuagui_flutter/page/image_viewer.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/page/author_dialog.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/page/view/tiny_manga_line.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';
import 'package:manhuagui_flutter/service/native/share.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  final _cancelHandlers = <VoidCallback>[];
  var _currAuthData = AuthManager.instance.authData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandlers.add(AuthManager.instance.listen(() => _currAuthData, (_) async {
        _currAuthData = AuthManager.instance.authData;
        _favoriteAuthor = null;
        _inFavorite = false;
        _loadData();
      }));
      await AuthManager.instance.check();
    });

    _cancelHandlers.add(EventBusManager.instance.listen<FavoriteAuthorUpdatedEvent>((ev) async {
      if (!ev.fromAuthorPage && ev.authorId == widget.id) {
        _inFavorite = ev.reason != UpdateReason.deleted;
        if (ev.reason == UpdateReason.updated) {
          _favoriteAuthor = await FavoriteDao.getAuthor(username: AuthManager.instance.username, aid: ev.authorId);
        }
        if (mounted) setState(() {});
      }
    }));
  }

  @override
  void dispose() {
    _flagStorage.dispose();
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  var _loading = false;
  Author? _data;
  var _error = '';
  FavoriteAuthor? _favoriteAuthor;
  var _inFavorite = false;

  Future<void> _loadData() async {
    _loading = true;
    _data = null;
    if (mounted) setState(() {});

    // 1. 获取数据库收藏信息
    _favoriteAuthor = await FavoriteDao.getAuthor(username: AuthManager.instance.username, aid: widget.id);
    _inFavorite = _favoriteAuthor != null;

    // 2. 获取作者信息
    final client = RestClient(DioManager.instance.dio);
    try {
      var result = await client.getAuthor(aid: widget.id);
      if (result.data.name == '') {
        throw Exception('未知错误'); // <<< 获取的数据有问题
      }
      _data = null;
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(kFlashListDuration);
      _data = result.data;

      // 3. 更新数据库收藏信息
      if (_favoriteAuthor != null) {
        var newAuthor = _favoriteAuthor!.copyWith(
          authorId: _data!.aid,
          authorName: _data!.name,
          authorCover: _data!.cover,
          authorUrl: _data!.url,
        );
        if (!newAuthor.equals(_favoriteAuthor!)) {
          _favoriteAuthor = newAuthor;
          await FavoriteDao.addOrUpdateAuthor(username: AuthManager.instance.username, author: newAuthor);
          EventBusManager.instance.fire(FavoriteAuthorUpdatedEvent(authorId: _data!.aid, reason: UpdateReason.updated, fromAuthorPage: true));
          if (mounted) setState(() {});
        }
      }
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
  late final _flagStorage = MangaCornerFlagStorage(stateSetter: () => mountedSetState(() {}));
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

  void _favorite() {
    showPopupMenuForAuthorFavorite(
      context: context,
      authorId: _data!.aid,
      authorName: _data!.name,
      authorCover: _data!.cover,
      authorUrl: _data!.url,
      authorZone: _data!.zone,
      favoriteAuthor: _favoriteAuthor,
      favoriteSetter: (f) {
        _inFavorite = f != null;
        _favoriteAuthor = f;
        if (mounted) setState(() {});
      },
    );
  }

  void _showRelatedAuthorsPopupMenu() {
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('相关作者'),
        children: [
          for (var author in _data!.relatedAuthors)
            TextDialogOption(
                text: Text('${author.name} (${author.zone})'),
                onPressed: () {
                  Navigator.of(c).pop();
                  Navigator.of(context).push(
                    CustomPageRoute(
                      context: context,
                      builder: (c) => AuthorPage(
                        id: author.aid,
                        name: author.name,
                        url: author.url,
                      ),
                    ),
                  );
                }),
        ],
      ),
    );
  }

  void _showDescriptionPopupMenu() {
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(_data!.name),
        children: [
          if (_data!.alias.trim().isEmpty || _data!.alias != '暂无')
            IconTextDialogOption(
              icon: Icon(Icons.copy),
              text: Text('复制作者别名'),
              onPressed: () {
                Navigator.of(c).pop();
                copyText(_data!.alias.trim(), showToast: true);
              },
            ),
          IconTextDialogOption(
            icon: Icon(Icons.copy),
            text: Text('复制作者介绍'),
            onPressed: () {
              Navigator.of(c).pop();
              copyText(_data!.introduction, showToast: false);
              Fluttertoast.showToast(msg: '作者介绍已经复制到剪贴板');
            },
          ),
        ],
      ),
    );
  }

  void _showMangaPopupMenu({bool forNewest = false, bool forHighest = false}) {
    if (forNewest) {
      showDialog(
        context: context,
        builder: (c) => SimpleDialog(
          title: Text(_data!.newestMangaTitle),
          children: [
            IconTextDialogOption(
              icon: Icon(Icons.description_outlined),
              text: Text('查看该漫画'),
              onPressed: () {
                Navigator.of(c).pop();
                Navigator.of(context).push(
                  CustomPageRoute(
                    context: context,
                    builder: (c) => MangaPage(
                      id: _data!.newestMangaId,
                      title: _data!.newestMangaTitle,
                      url: _data!.newestMangaUrl,
                    ),
                  ),
                );
              },
            ),
            IconTextDialogOption(
              icon: Icon(Icons.copy),
              text: Text('复制标题'),
              onPressed: () {
                Navigator.of(c).pop();
                copyText(_data!.newestMangaTitle, showToast: true);
              },
            ),
          ],
        ),
      );
    }
    if (forHighest) {
      showDialog(
        context: context,
        builder: (c) => SimpleDialog(
          title: Text(_data!.highestMangaTitle),
          children: [
            IconTextDialogOption(
              icon: Icon(Icons.description_outlined),
              text: Text('查看该漫画'),
              onPressed: () {
                Navigator.of(c).pop();
                Navigator.of(context).push(
                  CustomPageRoute(
                    context: context,
                    builder: (c) => MangaPage(
                      id: _data!.highestMangaId,
                      title: _data!.highestMangaTitle,
                      url: _data!.highestMangaUrl,
                    ),
                  ),
                );
              },
            ),
            IconTextDialogOption(
              icon: Icon(Icons.copy),
              text: Text('复制标题'),
              onPressed: () {
                Navigator.of(c).pop();
                copyText(_data!.highestMangaTitle, showToast: true);
              },
            ),
          ],
        ),
      );
    }
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
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () => _loadData(),
        notificationPredicate: (n) => n.depth <= 1,
        child: PlaceholderText.from(
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
                              icon: Icon(Icons.place, size: 20, color: Colors.orange),
                              text: Text('地区：${_data!.zone}'),
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
                              icon: Icon(Icons.stars, size: 20, color: Colors.orange),
                              text: Text('平均评分 ${_data!.averageScore} / 最高评分 ${_data!.highestScore}'),
                              space: 8,
                              iconPadding: EdgeInsets.symmetric(vertical: 2.8),
                            ),
                            IconText(
                              icon: Icon(Icons.trending_up, size: 20, color: Colors.orange),
                              text: Text('人气指数 ${_data!.popularity}'),
                              space: 8,
                              iconPadding: EdgeInsets.symmetric(vertical: 2.8),
                            ),
                            IconText(
                              icon: Icon(MdiIcons.update, size: 20, color: Colors.orange),
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
              // 四个按钮
              // ****************************************************************
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: ActionRowView.four(
                    action1: ActionItem(
                      text: !_inFavorite ? '收藏作者' : '取消收藏',
                      icon: !_inFavorite ? Icons.bookmark_border : Icons.bookmark,
                      action: () => _favorite(),
                      longPress: () => _favorite(),
                    ),
                    action2: ActionItem(
                      text: '相关作者',
                      icon: Icons.people,
                      action: () => _showRelatedAuthorsPopupMenu(),
                    ),
                    action3: ActionItem(
                      text: '作者详情',
                      icon: Icons.subject,
                      action: () => Navigator.of(context).push(
                        CustomPageRoute(
                          context: context,
                          builder: (c) => AuthorDetailPage(data: _data!),
                        ),
                      ),
                    ),
                    action4: ActionItem(
                      text: '分享作者',
                      icon: Icons.share,
                      action: () => shareText(
                        title: '漫画柜分享',
                        text: '【${_data!.name}】${_data!.url}',
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(height: 12),
              ),
              // ****************************************************************
              // 作者介绍/作者介绍 & 最新收录/评分最高
              // ****************************************************************
              SliverToBoxAdapter(
                child: Material(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          child: Text(
                            '作者别名：${_data!.alias}\n作者介绍：${_data!.introduction}',
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        ),
                        onTap: () => _showDescriptionPopupMenu(),
                        onLongPress: () => _showDescriptionPopupMenu(),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        color: Colors.white,
                        child: Divider(height: 0, thickness: 1),
                      ),
                      InkWell(
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          child: TextGroup.normal(
                            style: Theme.of(context).textTheme.bodyText2,
                            texts: [
                              if (_data!.newestMangaId == _data!.highestMangaId) ...[
                                SpanItem(span: WidgetSpan(child: Icon(Icons.trending_up, size: 20, color: Colors.grey[800]))),
                                PlainTextItem(text: ' 最新收录 / '),
                                SpanItem(span: WidgetSpan(child: Icon(Icons.fiber_new, size: 20, color: Colors.grey[800]))),
                                PlainTextItem(text: ' 评分最高：\n'),
                                PlainTextItem(text: '《${_data!.newestMangaTitle}》'),
                              ],
                              if (_data!.newestMangaId != _data!.highestMangaId) ...[
                                SpanItem(span: WidgetSpan(child: Icon(Icons.fiber_new, size: 20, color: Colors.grey[800]))),
                                PlainTextItem(text: ' 最新收录：\n'),
                                PlainTextItem(text: '《${_data!.newestMangaTitle}》'),
                              ],
                            ],
                          ),
                        ),
                        onTap: () => _showMangaPopupMenu(forNewest: true),
                        onLongPress: () => _showMangaPopupMenu(forNewest: true),
                      ),
                      if (_data!.newestMangaId != _data!.highestMangaId) ...[
                        Container(
                          width: MediaQuery.of(context).size.width,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          color: Colors.white,
                          child: Divider(height: 0, thickness: 1),
                        ),
                        InkWell(
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            child: TextGroup.normal(
                              style: Theme.of(context).textTheme.bodyText2,
                              texts: [
                                SpanItem(span: WidgetSpan(child: Icon(Icons.trending_up, size: 20, color: Colors.grey[800]))),
                                PlainTextItem(text: ' 评分最高：\n'),
                                PlainTextItem(text: '《${_data!.highestMangaTitle}》'),
                              ],
                            ),
                          ),
                          onTap: () => _showMangaPopupMenu(forHighest: true),
                          onLongPress: () => _showMangaPopupMenu(forHighest: true),
                        ),
                      ],
                    ],
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
                  refreshNotificationPredicate: (n) => false /* disable refresh */,
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
                  flags: _flagStorage.getFlags(mangaId: item.mid),
                ),
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
