import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/common.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/homepage_column.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 漫画排行列表集合，在 [RecommendSubPage] 使用
class MangaRankingTabView extends StatelessWidget {
  const MangaRankingTabView({
    Key? key,
    required this.rankings,
    required this.shouNenRankings,
    required this.shouJoRankings,
    this.error = '',
    required this.mangaCount,
  }) : super(key: key);

  final List<MangaRanking>? rankings;
  final List<MangaRanking>? shouNenRankings;
  final List<MangaRanking>? shouJoRankings;
  final String error;
  final Tuple1<int> mangaCount; // keep state in tricky way

  Widget _buildLine(BuildContext context, MangaRanking manga) {
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
              width: 82,
              height: 82,
              radius: BorderRadius.circular(8),
              border: Border.all(width: 0.7, color: Colors.grey[400]!),
            ),
            SizedBox(width: 12),
            Flexible(
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
                          color: manga.order == 1 ? Colors.red : (manga.order == 2 ? Colors.orange[600] : (manga.order == 3 ? Colors.yellow[700] : Colors.grey[400])),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 8.5, vertical: 1),
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
                      Icon(Icons.person, size: 15, color: Colors.grey),
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
                      Icon(Icons.notes, size: 15, color: Colors.grey),
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomepageColumnView(
      title: '漫画综合排行榜',
      icon: Icons.emoji_events,
      // onMorePressed: () => EventBusManager.instance.fire(ToRankingRequestedEvent()),
      rightText: '${formatDatetimeAndDuration(DateTime.now(), FormatPattern.date)} 更新',
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      headerChildSpace: 6,
      child: PlaceholderText.from(
        isLoading: rankings == null || shouNenRankings == null || shouJoRankings == null,
        isEmpty: rankings == null || shouNenRankings == null || shouJoRankings == null,
        errorText: error,
        setting: PlaceholderSetting(
          showLoadingText: false,
          showNothingRetry: false,
          showErrorRetry: false,
          progressPadding: const EdgeInsets.all(15),
          iconPadding: const EdgeInsets.all(5),
          textPadding: const EdgeInsets.all(5),
          progressSize: 40,
          iconSize: 42,
          textStyle: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.grey[600]),
        ).copyWithChinese(),
        childBuilder: (_) => StatefulBuilder(
          builder: (c, _setState) => DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: TabBar(
                    labelColor: Theme.of(context).primaryColor,
                    labelStyle: Theme.of(context).textTheme.subtitle1?.copyWith(fontSize: 16),
                    unselectedLabelColor: Colors.grey[700],
                    unselectedLabelStyle: Theme.of(context).textTheme.subtitle1?.copyWith(fontSize: 16),
                    tabs: [
                      for (var kv in [
                        [Icons.whatshot, '全部漫画'],
                        [Icons.female, '少女漫画'],
                        [Icons.male, '少年漫画'],
                      ])
                        Tab(
                          height: 42,
                          child: IconText(
                            mainAxisSize: MainAxisSize.min,
                            icon: Icon(kv[0] as IconData, size: 22),
                            text: Text(kv[1] as String),
                            textPadding: EdgeInsets.only(right: 5),
                            space: 5,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: (82.0 + 6 * 2) * mangaCount.item,
                  child: TabBarView(
                    physics: DefaultScrollPhysics.of(context) ?? AlwaysScrollableScrollPhysics(), // for scrolling in recommend page
                    children: [
                      Column(children: [for (var m in rankings!.sublist(0, mangaCount.item)) _buildLine(context, m)]),
                      Column(children: [for (var m in shouJoRankings!.sublist(0, mangaCount.item)) _buildLine(context, m)]),
                      Column(children: [for (var m in shouNenRankings!.sublist(0, mangaCount.item)) _buildLine(context, m)]),
                    ],
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (mangaCount.item != 20)
                      Container(
                        height: 36,
                        padding: EdgeInsets.only(right: 15),
                        child: OutlinedButton(
                          child: Text('显示更多'),
                          onPressed: () {
                            mangaCount.item = mangaCount.item <= 5 ? 10 : (mangaCount.item == 10 ? 15 : (mangaCount.item == 15 ? 20 : 20));
                            _setState(() {});
                          },
                        ),
                      ),
                    if (mangaCount.item != 5)
                      Container(
                        height: 36,
                        padding: EdgeInsets.only(right: 15),
                        child: OutlinedButton(
                          child: Text('显示更少'),
                          onPressed: () {
                            mangaCount.item = mangaCount.item >= 20 ? 15 : (mangaCount.item == 15 ? 10 : (mangaCount.item == 10 ? 5 : 5));
                            _setState(() {});
                          },
                        ),
                      ),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        child: Text('查看完整排行榜'),
                        onPressed: () => EventBusManager.instance.fire(ToRankingRequestedEvent()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
