import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/author_detail.dart';
import 'package:manhuagui_flutter/page/dlg/author_dialog.dart';
import 'package:manhuagui_flutter/page/image_viewer.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/page/view/small_manga_line.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/native/android.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _cancelHandlers.add(AuthManager.instance.listenOnlyWhen(Tuple1(AuthManager.instance.authData), (_) async {
        _favoriteAuthor = await FavoriteDao.getAuthor(username: AuthManager.instance.username, aid: widget.id);
        if (mounted) setState(() {});
      }));
      await AuthManager.instance.check();
    });

    _cancelHandlers.add(EventBusManager.instance.listen<AppSettingChangedEvent>((_) => mountedSetState(() {})));
    _cancelHandlers.add(EventBusManager.instance.listen<FavoriteAuthorUpdatedEvent>((ev) async {
      if (!ev.fromAuthorPage && ev.authorId == widget.id) {
        _favoriteAuthor = await FavoriteDao.getAuthor(username: AuthManager.instance.username, aid: ev.authorId);
        if (mounted) setState(() {});
      }
    }));
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabController.dispose();
    _flagStorage.dispose();
    super.dispose();
  }

  var _loading = true; // initialize to true
  Author? _data;
  var _error = '';
  FavoriteAuthor? _favoriteAuthor;

  Future<void> _loadData() async {
    _loading = true;
    _data = null;
    _mangas.clear(); // 无需手动更新漫画列表
    _total = 0;
    if (mounted) setState(() {});

    // 1. 获取数据库收藏信息
    _favoriteAuthor = await FavoriteDao.getAuthor(username: AuthManager.instance.username, aid: widget.id);

    // 2. 获取作者信息
    final client = RestClient(DioManager.instance.dio);
    try {
      var result = await client.getAuthor(aid: widget.id);
      if (result.data.name == '') {
        throw SpecialException('未知错误'); // <<< 获取的作者数据有问题
      }
      _data = null;
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(kFlashListDuration);
      _data = result.data;
      _total = _data!.mangaCount;

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
  var _getting = false;
  final _currOrder = RestorableObject(AppSetting.instance.ui.defaultMangaOrder);

  Future<PagedList<SmallManga>> _getMangas({required int page}) async {
    final client = RestClient(DioManager.instance.dio);
    var result = await client.getAuthorMangas(aid: widget.id, page: page, order: _currOrder.curr).onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
    _total = result.data.total;
    if (mounted) setState(() {});
    _flagStorage.queryAndStoreFlags(mangaIds: result.data.data.map((e) => e.mid)).then((_) => mountedSetState(() {}));
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
              },
            ),
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
            onPressed: () async {
              Navigator.of(c).pop();
              copyText(_data!.introduction, showToast: false);
              await Fluttertoast.cancel();
              Fluttertoast.showToast(msg: '作者介绍已经复制到剪贴板');
            },
          ),
        ],
      ),
    );
  }

  void _showMangaPopupMenu({bool forNewest = false, bool forHighest = false}) {
    var id = forNewest ? _data!.newestMangaId : (forHighest ? _data!.highestMangaId : 0);
    var title = forNewest ? _data!.newestMangaTitle : (forHighest ? _data!.highestMangaTitle : '');
    var url = forNewest ? _data!.newestMangaUrl : (forHighest ? _data!.highestMangaUrl : '');
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(title),
        children: [
          IconTextDialogOption(
            icon: Icon(MdiIcons.bookOutline),
            text: Text('查看该漫画'),
            onPressed: () {
              Navigator.of(c).pop();
              Navigator.of(context).push(
                CustomPageRoute(
                  context: context,
                  builder: (c) => MangaPage(id: id, title: title, url: url),
                ),
              );
            },
          ),
          IconTextDialogOption(
            icon: Icon(Icons.copy),
            text: Text('复制漫画标题'),
            onPressed: () => copyText(title, showToast: true),
          ),
          IconTextDialogOption(
            icon: Icon(Icons.open_in_browser),
            text: Text('用浏览器打开'),
            onPressed: () {
              Navigator.of(c).pop();
              launchInBrowser(context: context, url: url);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          child: Text(_data?.name ?? widget.name),
          onTap: () => showPopupMenuForAuthorName(
            context: context,
            author: _data,
            fallbackName: widget.name,
            vibrate: false,
          ),
          onLongPress: () => showPopupMenuForAuthorName(
            context: context,
            author: _data,
            fallbackName: widget.name,
            vibrate: true,
          ),
        ),
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
                            quality: FilterQuality.high,
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
                              text: Text('收录更新于 ${_data!.formattedNewestDate}'),
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
                      text: _favoriteAuthor == null ? '收藏作者' : '查看收藏',
                      icon: _favoriteAuthor == null ? Icons.bookmark_border : Icons.bookmark,
                      action: () => _favorite(),
                      longPress: () => _favorite(),
                    ),
                    action2: ActionItem(
                      text: '相关作者',
                      icon: Icons.people,
                      action: () => _showRelatedAuthorsPopupMenu(),
                      longPress: () => _showRelatedAuthorsPopupMenu(),
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
                      action: () => shareText(text: '【${_data!.name}】${_data!.url}'),
                      longPress: () => shareText(text: _data!.url),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(height: 12),
              ),
              SliverToBoxAdapter(
                child: Material(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ****************************************************************
                      // 最新收录/评分最高
                      // ****************************************************************
                      Column(
                        children: [
                          if (_data!.newestMangaId == _data!.highestMangaId)
                            InkWell(
                              onTap: () => _showMangaPopupMenu(forNewest: true),
                              onLongPress: () => _showMangaPopupMenu(forNewest: true),
                              child: IconText(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9), // | ▢ ▢▢ |
                                space: 8,
                                icon: Icon(MdiIcons.bookOutline, size: 26, color: Colors.black54),
                                text: Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '《${_data!.newestMangaTitle}》',
                                        style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 1),
                                      Text(
                                        '  最新收录的漫画 (${_data!.formattedNewestDate}) & 评分最高的漫画 (${_data!.highestScore})',
                                        style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (_data!.newestMangaId != _data!.highestMangaId) ...[
                            InkWell(
                              onTap: () => _showMangaPopupMenu(forHighest: true),
                              onLongPress: () => _showMangaPopupMenu(forHighest: true),
                              child: IconText(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9), // | ▢ ▢▢ |
                                space: 8,
                                icon: Icon(Icons.whatshot, size: 26, color: Colors.black54),
                                text: Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '《${_data!.highestMangaTitle}》',
                                        style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 1),
                                      Text(
                                        '  评分最高的漫画 (${_data!.highestScore})',
                                        style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              color: Colors.white,
                              child: Divider(height: 0, thickness: 1),
                            ),
                            InkWell(
                              onTap: () => _showMangaPopupMenu(forNewest: true),
                              onLongPress: () => _showMangaPopupMenu(forNewest: true),
                              child: IconText(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9), // | ▢ ▢▢ |
                                space: 8,
                                icon: Icon(Icons.fiber_new, size: 26, color: Colors.black54),
                                text: Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '《${_data!.newestMangaTitle}》',
                                        style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 1),
                                      Text(
                                        '  最新收录的漫画 (${_data!.formattedNewestDate})',
                                        style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      // ****************************************************************
                      // 作者别名/作者介绍
                      // ****************************************************************
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
                          child: Text(
                            '作者别名：${_data!.alias}\n'
                            '作者介绍：${_data!.introduction.trim().isEmpty ? '暂无' : _data!.introduction.trim()}',
                            style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 15, height: 1.5),
                          ),
                        ),
                        onTap: () => _showDescriptionPopupMenu(),
                        onLongPress: () => _showDescriptionPopupMenu(),
                      ),
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
                          value: _currOrder.curr,
                          titleBuilder: (c, v) => v.toTitle(),
                          enable: !_getting,
                          onSelected: (o) {
                            if (_currOrder.curr != o) {
                              _currOrder.select(o, alsoPass: true);
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
              builder: (c) => PaginationDataView<SmallManga>(
                key: _pdvKey,
                style: !AppSetting.instance.ui.showTwoColumns ? UpdatableDataViewStyle.sliverListView : UpdatableDataViewStyle.sliverGridView,
                data: _mangas,
                getData: ({indicator}) => _getMangas(page: indicator),
                scrollController: PrimaryScrollController.of(c),
                paginationSetting: PaginationSetting(
                  initialIndicator: 1,
                  nothingIndicator: 0,
                ),
                setting: UpdatableDataViewSetting(
                  padding: EdgeInsets.symmetric(vertical: 0),
                  interactiveScrollbar: true,
                  scrollbarMainAxisMargin: 2,
                  scrollbarCrossAxisMargin: 2,
                  scrollbarExtraMargin: EdgeInsets.only(top: NestedScrollView.sliverOverlapAbsorberHandleFor(c).layoutExtent ?? 0),
                  refreshNotificationPredicate: (n) => false /* disable refresh */,
                  placeholderSetting: PlaceholderSetting().copyWithChinese(),
                  onPlaceholderStateChanged: (_, __) => _fabController.hide(),
                  refreshFirst: true /* <<< refresh first */,
                  clearWhenRefresh: false,
                  clearWhenError: false,
                  updateOnlyIfNotEmpty: false,
                  onStartGettingData: () => mountedSetState(() => _getting = true),
                  onStopGettingData: () => mountedSetState(() => _getting = false),
                  onAppend: (_, l) => _currOrder.pass(),
                  onError: (e) {
                    if (_mangas.isNotEmpty) {
                      Fluttertoast.showToast(msg: e.toString());
                    }
                    _currOrder.restore();
                    if (mounted) setState(() {});
                  },
                ),
                useOverlapInjector: true,
                separator: Divider(height: 0, thickness: 1),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 0.0,
                  mainAxisSpacing: 0.0,
                  childAspectRatio: GeneralLineView.getChildAspectRatioForTwoColumns(context),
                ),
                itemBuilder: (c, _, item) => SmallMangaLineView(
                  manga: item.toSmaller(),
                  history: _flagStorage.getHistory(mangaId: item.mid),
                  flags: _flagStorage.getFlags(mangaId: item.mid),
                  twoColumns: AppSetting.instance.ui.showTwoColumns,
                  highlightRecent: AppSetting.instance.ui.highlightRecentMangas,
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
