import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/common.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/dlg/category_dialog.dart';
import 'package:manhuagui_flutter/page/dlg/setting_ui_dialog.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/page/view/homepage_column.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

enum MangaAudRankingType {
  all,
  qingnian,
  shaonv,
}

/// 漫画受众排行榜，在 [RecommendSubPage] / [MangaAudRankingPage] 使用
class MangaAudRankingView extends StatefulWidget {
  const MangaAudRankingView({
    Key? key,
    required this.allRankings,
    required this.qingnianRankings,
    required this.shaonvRankings,
    this.allRankingsDateTime,
    this.qingnianRankingsDateTime,
    this.shaonvRankingsDateTime,
    this.remappedQingnianCategory,
    this.remappedShaonvCategory,
    this.allRankingsError = '',
    this.qingnianRankingsError = '',
    this.shaonvRankingsError = '',
    required this.mangaRows,
    this.highlightRecent = true,
    this.onRefreshPressed,
    this.onRefreshLongPressed,
    this.onFullListPressed,
    this.onMorePressed,
    this.onLineLongPressed,
    this.onAudCategoryRemapped,
  }) : super(key: key);

  final List<MangaRanking>? allRankings;
  final List<MangaRanking>? qingnianRankings;
  final List<MangaRanking>? shaonvRankings;
  final DateTime? allRankingsDateTime;
  final DateTime? qingnianRankingsDateTime;
  final DateTime? shaonvRankingsDateTime;
  final TinyCategory? remappedQingnianCategory;
  final TinyCategory? remappedShaonvCategory;
  final String allRankingsError;
  final String qingnianRankingsError;
  final String shaonvRankingsError;
  final int mangaRows;
  final bool highlightRecent;
  final void Function(MangaAudRankingType)? onRefreshPressed;
  final void Function()? onRefreshLongPressed;
  final void Function(MangaAudRankingType)? onFullListPressed;
  final void Function()? onMorePressed;
  final void Function(MangaRanking)? onLineLongPressed;
  final void Function(MangaAudRankingType)? onAudCategoryRemapped;

  @override
  State<MangaAudRankingView> createState() => _MangaAudRankingViewState();
}

class _MangaAudRankingViewState extends State<MangaAudRankingView> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _tabBarViewKey = GlobalKey<ExtendedTabBarViewState>();
  late final _controller = TabController(length: MangaAudRankingType.values.length, vsync: this)
    ..addListener(() {
      if (mounted) setState(() {});
    });
  final _physicsController = CustomScrollPhysicsController();
  var _animatingPage = false; // only used in _onPageChanged
  var _currentPageIndex = 0;
  late final _flagStorage = MangaCornerFlagStorage(stateSetter: () => mountedSetState(() {}));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _tabBarViewKey.currentState?.addListenerToPageController(_onPageChanged);
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabBarViewKey.currentState?.removeListenerFromPageController(_onPageChanged);
    _controller.dispose();
    _flagStorage.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    var newMangaIds = {
      if (widget.allRankings != null) ...(widget.allRankings?.map((r) => r.mid) ?? []),
      if (widget.qingnianRankings != null) ...(widget.qingnianRankings?.map((r) => r.mid) ?? []),
      if (widget.shaonvRankings != null) ...(widget.shaonvRankings?.map((r) => r.mid) ?? []),
    };
    _flagStorage.queryAndStoreFlags(mangaIds: newMangaIds).then((_) => mountedSetState(() {}));
  }

  @override
  void didUpdateWidget(covariant MangaAudRankingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    var changedMangaIds = {
      // => note: refreshing will replace the whole list object to a new list, so here use '!=' for updating detecting
      if (widget.allRankings != oldWidget.allRankings) ...(widget.allRankings?.map((r) => r.mid) ?? []),
      if (widget.qingnianRankings != oldWidget.qingnianRankings) ...(widget.qingnianRankings?.map((r) => r.mid) ?? []),
      if (widget.shaonvRankings != oldWidget.shaonvRankings) ...(widget.shaonvRankings?.map((r) => r.mid) ?? []),
    };
    _flagStorage.queryAndStoreFlags(mangaIds: changedMangaIds).then((_) => mountedSetState(() {}));
  }

  bool _isPageValid(int index) {
    return (index == 0 && widget.allRankings?.isNotEmpty == true) || //
        (index == 1 && widget.qingnianRankings?.isNotEmpty == true) ||
        (index == 2 && widget.shaonvRankings?.isNotEmpty == true);
  }

  bool _isPageLoading(int index) {
    return (index == 0 && widget.allRankings == null) || //
        (index == 1 && widget.qingnianRankings == null) || //
        (index == 2 && widget.shaonvRankings == null);
  }

  MangaAudRankingType _indexToType(int index) {
    return index == 0
        ? MangaAudRankingType.all
        : index == 1
            ? MangaAudRankingType.qingnian
            : MangaAudRankingType.shaonv;
  }

  Future<void> _onPageChanged() async {
    var pageController = _tabBarViewKey.currentState?.pageController;
    if (pageController == null || pageController.page == null) {
      return; // unreachable
    }

    var maxValidIndex = _controller.length - 1;
    if (pageController.page! < maxValidIndex) {
      // within the first n-1 pages
      if (_physicsController.disableScrollMore == true) {
        _physicsController.disableScrollMore = false;
        if (mounted) setState(() {});
      }
    } else {
      // reach the last page, or exceed valid page range !!!
      if (_physicsController.disableScrollMore == false) {
        _physicsController.disableScrollMore = true;
        if (mounted) setState(() {});
      }
      if (!_animatingPage && pageController.page! > maxValidIndex + 0.01) {
        _animatingPage = true;
        await pageController.defaultAnimateToPage(maxValidIndex);
        _animatingPage = false;
      }
    }
  }

  void _showFullButtonPopupMenu(MangaAudRankingType type) {
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('漫画受众排行榜'),
        children: [
          IconTextDialogOption(
            icon: Icon(Icons.whatshot),
            text: Text('查看完整的排行榜'),
            onPressed: () {
              Navigator.of(c).pop();
              widget.onFullListPressed?.call(type);
            },
          ),
          IconTextDialogOption(
            icon: Icon(Icons.settings),
            text: Text('受众排行榜显示设置'),
            onPressed: () {
              Navigator.of(c).pop();
              showUiSettingDialog(context: context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLine(MangaRanking manga) {
    return FullRippleWidget(
      highlightColor: null,
      splashColor: null,
      onTap: () => Navigator.of(context).push(
        CustomPageRoute(
          context: context,
          builder: (c) => MangaPage(
            id: manga.mid,
            title: manga.title,
            url: manga.url,
          ),
        ),
      ),
      onLongPress: widget.onLineLongPressed == null ? null : () => widget.onLineLongPressed?.call(manga),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20 /* 15 */, vertical: 6), // | ▢ ▢▢ |
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            NetworkImageView(
              url: manga.cover,
              width: 85,
              height: 85,
              radius: BorderRadius.circular(8),
              border: Border.all(width: 0.7, color: Colors.grey[400]!),
            ),
            SizedBox(width: 12),
            Flexible(
              child: OverflowClipBox(
                useOverflowBox: true,
                direction: OverflowDirection.vertical,
                useClipRect: true,
                alignment: Alignment.center,
                height: 85,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manga.title,
                      style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.5),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: manga.order == 1 ? Colors.red : (manga.order == 2 ? Colors.orange : (manga.order == 3 ? Colors.yellow[600] : Colors.grey[400])),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 8.5, vertical: 1.2),
                          child: Text(
                            manga.order.toString(),
                            style: Theme.of(context).textTheme.bodyText1?.copyWith(fontSize: 10.5, color: Colors.white),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 1.5, right: 1.5),
                          child: manga.trend == 1
                              ? Icon(Icons.arrow_drop_up, size: 17.5, color: Colors.red) // up
                              : manga.trend == 2
                                  ? Icon(Icons.arrow_drop_down, size: 17.5, color: Colors.blue[400]) // down
                                  : Transform.scale(scaleX: 0.6, child: Icon(Icons.remove, size: 17.5, color: Colors.grey[600])) /* no change */,
                        ),
                        Flexible(
                          child: Text(
                            '${manga.score}',
                            style: Theme.of(context).textTheme.bodyText2?.copyWith(
                                  fontSize: 12,
                                  color: manga.trend == 1 ? Colors.red : (manga.trend == 2 ? Colors.blue[400] : Colors.grey[600]),
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ..._flagStorage.getFlags(mangaId: manga.mid).buildIcons().let((flags) {
                          if (flags.isEmpty) return [];
                          return [
                            Container(
                              color: Colors.grey[400]!,
                              child: SizedBox(height: 14, width: 1),
                              margin: EdgeInsets.only(left: 6, right: 5.5),
                            ),
                            for (var icon in flags) Icon(icon, size: 14, color: Colors.grey),
                          ];
                        })
                      ],
                    ),
                    SizedBox(height: 1.5),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          manga.authors.map((el) => el.name).join('/'),
                          style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.notes, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          '${manga.newestChapter}・${manga.finished ? '已完结' : '连载中'}・${manga.formattedNewestDurationOrDate}',
                          style: Theme.of(context).textTheme.bodyText2?.copyWith(
                                fontSize: 12,
                                color: !widget.highlightRecent
                                    ? null
                                    : GeneralLineView.determineColorByNumber(
                                        manga.newestDateDayDuration,
                                        zero: GeneralLineView.textOrange,
                                        one: GeneralLineView.greyedTextOrange,
                                        two: GeneralLineView.moreGreyedTextOrange,
                                        other: Colors.grey[600],
                                      ),
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return HomepageColumnView(
      title: '漫画受众排行榜 (${formatDatetimeAndDuration( //
          (_currentPageIndex == 0 //
                  ? widget.allRankingsDateTime //
                  : _currentPageIndex == 1 //
                      ? widget.qingnianRankingsDateTime //
                      : widget.shaonvRankingsDateTime //
              ) ?? DateTime.now(), FormatPattern.dateNoYear)} 更新)',
      icon: Icons.emoji_events,
      onRefreshPressed: () => widget.onRefreshPressed?.call(_indexToType(_currentPageIndex)),
      onRefreshLongPressed: widget.onRefreshLongPressed,
      disableRefresh: (_currentPageIndex == 0 && widget.allRankings == null) || //
          (_currentPageIndex == 1 && widget.qingnianRankings == null) ||
          (_currentPageIndex == 2 && widget.shaonvRankings == null),
      hintIconData: _currentPageIndex == 0 ? null : Icons.edit,
      onHintPressed: _currentPageIndex == 0
          ? () => showYesNoAlertDialog(
                context: context,
                title: Text('漫画排行榜提示'),
                content: Text('提示：漫画柜中少年漫画排行榜与全部漫画排行榜基本一致，主页不单独显示少年漫画。'),
                yesText: Text('确定'),
                noText: null,
              )
          : () => showAudCategoryRemapPopupMenu(
                context: context,
                onRemapped: widget.onAudCategoryRemapped,
              ),
      onMorePressed: widget.onMorePressed,
      headerPadding: EdgeInsets.only(left: 15, right: 15, top: 12, bottom: 8),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: TabBar(
              controller: _controller,
              labelColor: Theme.of(context).primaryColor,
              labelStyle: Theme.of(context).textTheme.subtitle1?.copyWith(fontSize: 16),
              unselectedLabelColor: Colors.grey[700],
              unselectedLabelStyle: Theme.of(context).textTheme.subtitle1?.copyWith(fontSize: 16),
              tabs: [
                for (var t in [
                  // 1
                  Tuple2(Icons.whatshot, '全部/少年'),

                  // 2
                  if ((widget.remappedQingnianCategory ?? qingnianAgeCategory).name == qingnianAgeCategory.name) //
                    Tuple2(Icons.wc, '青年漫画'),
                  if ((widget.remappedQingnianCategory ?? qingnianAgeCategory).name != qingnianAgeCategory.name) //
                    Tuple2(Icons.category, '${widget.remappedQingnianCategory!.title}漫画'),

                  // 3
                  if ((widget.remappedShaonvCategory ?? shaonvAgeCategory).name == shaonvAgeCategory.name) //
                    Tuple2(Icons.female, '少女漫画'),
                  if ((widget.remappedShaonvCategory ?? shaonvAgeCategory).name != shaonvAgeCategory.name) //
                    Tuple2(Icons.category, '${widget.remappedShaonvCategory!.title}漫画'),
                ])
                  Tab(
                    height: 40,
                    child: IconText(
                      mainAxisSize: MainAxisSize.min,
                      icon: Icon(t.item1, size: 21),
                      text: Text(t.item2, style: TextStyle(fontSize: 15)),
                      textPadding: EdgeInsets.only(right: 2, bottom: 1),
                      space: 4,
                    ),
                  ),
              ],
            ),
          ),
          PageChangedListener(
            callPageChangedAtEnd: false,
            onPageChanged: (i) {
              if (!_controller.indexIsChanging /* for `swipe manually` */ || i == _controller.index /* for `select tabBar` */) {
                _currentPageIndex = i;
                if (mounted) setState(() {});
              }
            },
            child: SizedBox(
              height: _isPageValid(_currentPageIndex)
                  ? (3 + (85.0 + 6 * 2) * widget.mangaRows)
                  : _isPageLoading(_currentPageIndex)
                      ? (40 + 12 + 15 * 2)
                      : (42 + 12 + 5 * 4 + TextSpan(text: '　', style: Theme.of(context).textTheme.subtitle1!).layoutSize(context).height),
              child: ExtendedTabBarView(
                key: _tabBarViewKey,
                controller: _controller,
                physics: CustomScrollPhysics(
                  controller: _physicsController, // <<<
                  parent: DefaultScrollPhysics.of(context) ?? AlwaysScrollableScrollPhysics(),
                ),
                viewportFraction: widget.allRankings?.isNotEmpty != true || //
                        widget.qingnianRankings?.isNotEmpty != true ||
                        widget.shaonvRankings?.isNotEmpty != true ||
                        widget.allRankingsError != '' ||
                        widget.qingnianRankingsError != '' ||
                        widget.shaonvRankingsError != ''
                    ? 1 // don't modify viewport fraction if loading or empty or error
                    : (MediaQuery.of(context).size.width - 20 - 85 / 2) / MediaQuery.of(context).size.width /* <<< */,
                padEnds: false,
                warpTabIndex: false,
                assertForPages: false,
                children: [
                  for (var t in [
                    Tuple2(widget.allRankings, widget.allRankingsError),
                    Tuple2(widget.qingnianRankings, widget.qingnianRankingsError),
                    Tuple2(widget.shaonvRankings, widget.shaonvRankingsError),
                  ])
                    OverflowClipBox(
                      useOverflowBox: true,
                      direction: OverflowDirection.vertical,
                      useClipRect: true,
                      alignment: Alignment.topCenter,
                      child: PlaceholderText.from(
                        isLoading: t.item1 == null,
                        isEmpty: t.item1?.isNotEmpty != true,
                        errorText: t.item2,
                        setting: PlaceholderSetting(
                          showLoadingText: false,
                          showNothingRetry: false,
                          showErrorRetry: false,
                          progressPadding: const EdgeInsets.all(12) + EdgeInsets.only(top: 12) /* extra 12 at top */,
                          iconPadding: const EdgeInsets.all(5) + EdgeInsets.only(top: 12) /* extra 12 at top */,
                          textPadding: const EdgeInsets.all(5),
                          progressSize: 42,
                          iconSize: 42,
                          textStyle: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.grey[600]),
                        ).copyWithChinese(),
                        childBuilder: (_) => Column(
                          children: [
                            SizedBox(height: 3),
                            for (var m in t.item1!.sublist(0, widget.mangaRows.clamp(0, t.item1!.length))) //
                              _buildLine(m),
                          ],
                        ),
                      ),
                    ),

                  // fake last page
                  SizedBox.shrink(),
                ],
              ),
            ),
          ),
          if (_isPageValid(_currentPageIndex))
            Padding(
              padding: EdgeInsets.only(top: 6),
              child: Container(
                height: 36,
                child: OutlinedButton(
                  child: Text('查看完整排行榜'),
                  onPressed: () => widget.onFullListPressed?.call(_indexToType(_currentPageIndex)),
                  onLongPress: () => _showFullButtonPopupMenu(_indexToType(_currentPageIndex)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
