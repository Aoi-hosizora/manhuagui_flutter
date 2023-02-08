import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/common.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/homepage_column.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

/// 漫画受众排行榜，在 [RecommendSubPage] / [MangaAudRankingPage] 使用

class MangaAudRankingView extends StatefulWidget {
  const MangaAudRankingView({
    Key? key,
    required this.rankings,
    required this.qingnianRankings,
    required this.shaonianRankings,
    required this.shaonvRankings,
    this.rankingsError = '',
    this.qingnianRankingsError = '',
    this.shaonianRankingsError = '',
    this.shaonvRankingsError = '',
    required this.mangaCount,
    this.onFullPressed,
    this.onMorePressed,
  }) : super(key: key);

  final List<MangaRanking>? rankings;
  final List<MangaRanking>? qingnianRankings;
  final List<MangaRanking>? shaonianRankings;
  final List<MangaRanking>? shaonvRankings;
  final String rankingsError;
  final String qingnianRankingsError;
  final String shaonianRankingsError;
  final String shaonvRankingsError;
  final int mangaCount;
  final void Function(int index)? onFullPressed;
  final void Function()? onMorePressed;

  @override
  State<MangaAudRankingView> createState() => _MangaAudRankingViewState();
}

class _MangaAudRankingViewState extends State<MangaAudRankingView> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final _controller = TabController(length: 4, vsync: this) //
    ..addListener(() => mountedSetState(() {}));
  var _currentPageIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isPageValid(int index) {
    return (index == 0 && widget.rankings?.isNotEmpty == true) || //
        (index == 1 && widget.qingnianRankings?.isNotEmpty == true) ||
        (index == 2 && widget.shaonianRankings?.isNotEmpty == true) ||
        (index == 3 && widget.shaonvRankings?.isNotEmpty == true);
  }

  bool _isPageLoading(int index) {
    return (index == 0 && widget.rankings == null) || //
        (index == 1 && widget.qingnianRankings == null) || //
        (index == 2 && widget.shaonianRankings == null) || //
        (index == 3 && widget.shaonvRankings == null);
  }

  double _getTextHeight(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.height;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return HomepageColumnView(
      title: '漫画受众排行榜' + (widget.onMorePressed == null ? '' : ' (更新于 ${formatDatetimeAndDuration(DateTime.now(), FormatPattern.dateNoYear)})'),
      icon: Icons.emoji_events,
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
                  Tuple2(Icons.whatshot, '全部'),
                  Tuple2(Icons.person, '青年'), // TODO remove
                  Tuple2(Icons.male, '少年'),
                  Tuple2(Icons.female, '少女'),
                ])
                  Tab(
                    height: 40,
                    child: IconText(
                      mainAxisSize: MainAxisSize.min,
                      icon: Icon(t.item1, size: 22),
                      text: Text(t.item2),
                      textPadding: EdgeInsets.only(right: 4, bottom: 1),
                      space: 5,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: _isPageValid(_currentPageIndex)
                ? ((85.0 + 6 * 2) * widget.mangaCount)
                : _isPageLoading(_currentPageIndex)
                    ? (40 + 15 * 2 + 12)
                    : (42 + 5 * 4 + 12 + _getTextHeight('　', Theme.of(context).textTheme.subtitle1!)),
            child: PageChangedListener(
              callPageChangedAtEnd: false,
              onPageChanged: (i) {
                if (!_controller.indexIsChanging /* for `swipe manually` */ || i == _controller.index /* for `select tabBar` */) {
                  _currentPageIndex = i;
                  if (mounted) setState(() {});
                }
              },
              child: TabBarView(
                controller: _controller,
                physics: DefaultScrollPhysics.of(context) ?? AlwaysScrollableScrollPhysics(),
                children: [
                  for (var t in [
                    Tuple2(widget.rankings, widget.rankingsError),
                    Tuple2(widget.qingnianRankings, widget.qingnianRankingsError),
                    Tuple2(widget.shaonianRankings, widget.shaonianRankingsError),
                    Tuple2(widget.shaonvRankings, widget.shaonvRankingsError),
                  ])
                    OverflowClipBox(
                      direction: OverflowDirection.vertical,
                      clip: true,
                      alignment: Alignment.topCenter,
                      child: PlaceholderText.from(
                        isLoading: t.item1 == null,
                        isEmpty: t.item1?.isNotEmpty != true,
                        errorText: t.item2,
                        setting: PlaceholderSetting(
                          showLoadingText: false,
                          showNothingRetry: false,
                          showErrorRetry: false,
                          progressPadding: const EdgeInsets.all(15) + EdgeInsets.only(top: 12) /* extra 12 at top */,
                          iconPadding: const EdgeInsets.all(5) + EdgeInsets.only(top: 12) /* extra 12 at top */,
                          textPadding: const EdgeInsets.all(5),
                          progressSize: 40,
                          iconSize: 42,
                          textStyle: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.grey[600]),
                        ).copyWithChinese(),
                        childBuilder: (_) => Column(
                          children: [
                            for (var m in t.item1!.sublist(0, widget.mangaCount.clamp(0, t.item1!.length))) //
                              MangaAudRankingLineView(manga: m),
                          ],
                        ),
                      ),
                    ),
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
                  child: Text('查看完整的排行榜'),
                  onPressed: () => widget.onFullPressed?.call(_controller.index),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MangaAudRankingLineView extends StatelessWidget {
  const MangaAudRankingLineView({
    Key? key,
    required this.manga,
  }) : super(key: key);

  final MangaRanking manga;

  @override
  Widget build(BuildContext context) {
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6), // | ▢ ▢▢ |
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
                direction: OverflowDirection.vertical,
                clip: false,
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
                    SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: manga.order == 1 ? Colors.red : (manga.order == 2 ? Colors.orange : (manga.order == 3 ? Colors.yellow[600] : Colors.grey[400])),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 8.5, vertical: 1.5),
                          child: Text(
                            manga.order.toString(),
                            style: Theme.of(context).textTheme.bodyText1?.copyWith(fontSize: 10.5, color: Colors.white),
                          ),
                        ),
                        SizedBox(width: 3),
                        manga.trend == 1
                            ? Icon(Icons.arrow_drop_up, size: 16, color: Colors.red) // up
                            : manga.trend == 2
                                ? Icon(Icons.arrow_drop_down, size: 16, color: Colors.blue[400]) // down
                                : Transform.scale(scaleX: 0.6, child: Icon(Icons.remove, size: 16, color: Colors.grey[600])) /* no change */,
                        SizedBox(width: 1),
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
                      ],
                    ),
                    SizedBox(height: 3),
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
                          '${manga.newestChapter}・${manga.formattedNewestDurationOrDate} ${manga.finished ? '已完结' : '连载中'}',
                          style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 12, color: Colors.grey[600]),
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
}
