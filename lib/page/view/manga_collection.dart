import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/common.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/dlg/manga_dialog.dart';
import 'package:manhuagui_flutter/page/download_manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/homepage_column.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

enum MangaCollectionType {
  rankings,
  recents,
  histories,
  laters,
  shelves,
  favorites,
  downloads,
}

/// 漫画集合，针对日排行榜、最近更新、阅读历史、稍后阅读、我的书架、本地收藏、下载列表，在 [RecommendSubPage] 使用
class MangaCollectionView extends StatefulWidget {
  const MangaCollectionView({
    Key? key,
    required this.type,
    this.showMore = false,
    this.ranking,
    this.rankingDateTime,
    this.updates,
    this.histories,
    this.laters,
    this.shelves,
    this.favorites,
    this.downloads,
    this.error,
    required this.username,
    this.onRefreshPressed,
    this.disableRefresh = false,
    this.onMorePressed,
    this.onLongPressed,
  }) : super(key: key);

  final MangaCollectionType type;
  final bool showMore;
  final List<MangaRanking>? ranking;
  final DateTime? rankingDateTime;
  final List<TinyManga>? updates;
  final List<MangaHistory>? histories;
  final List<LaterManga>? laters;
  final List<ShelfManga>? shelves;
  final List<FavoriteManga>? favorites;
  final List<DownloadedManga>? downloads;
  final String? error;
  final String? username;
  final void Function()? onRefreshPressed;
  final bool disableRefresh;
  final void Function()? onMorePressed;
  final void Function(int mid, String title, String cover, String url, MangaExtraDataForDialog? extraData)? onLongPressed;

  @override
  State<MangaCollectionView> createState() => _MangaCollectionViewState();
}

class _MangaCollectionViewState extends State<MangaCollectionView> with AutomaticKeepAliveClientMixin {
  Widget _buildCover(
    BuildContext context,
    int mid,
    String title,
    String cover,
    String url,
    double width,
    double height, {
    bool highQuality = false,
    bool gotoDownload = false,
    required MangaExtraDataForDialog? extraData,
  }) {
    return FullRippleWidget(
      child: Container(
        width: width,
        height: height,
        child: NetworkImageView(
          url: cover,
          width: width,
          height: height,
          quality: !highQuality ? FilterQuality.low : FilterQuality.high,
          radius: BorderRadius.circular(8),
          border: Border.all(width: 0.7, color: Colors.grey[400]!),
        ),
      ),
      radius: BorderRadius.circular(8),
      highlightColor: null,
      splashColor: null,
      onTap: () {
        if (!gotoDownload) {
          Navigator.of(context).push(
            CustomPageRoute(
              context: context,
              builder: (c) => MangaPage(
                id: mid,
                title: title,
                url: url,
              ),
            ),
          );
        } else {
          Navigator.of(context).push(
            CustomPageRoute(
              context: context,
              builder: (c) => DownloadMangaPage(
                mangaId: mid,
              ),
              settings: DownloadMangaPage.buildRouteSetting(
                mangaId: mid,
              ),
            ),
          );
        }
      },
      onLongPress: widget.onLongPressed == null //
          ? null
          : () => widget.onLongPressed?.call(mid, title, cover, url, extraData),
    );
  }

  Widget _buildRankingItem(BuildContext context, MangaRanking manga) {
    final count = !widget.showMore ? 3 : 4;
    final width = (MediaQuery.of(context).size.width - 15 * count) / (count - 0.5); // | ▢ ▢ ▢|
    final height = width / 3 * 4;
    final extraData = MangaExtraDataForDialog.fromMangaRanking(manga);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCover(context, manga.mid, manga.title, manga.cover, manga.url, width, height, highQuality: true, extraData: extraData),
        Container(
          width: width,
          padding: EdgeInsets.only(top: 2),
          child: Row(
            children: [
              Text(
                manga.order.toString(),
                style: Theme.of(context).textTheme.subtitle1?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: manga.order == 1 ? Colors.red : (manga.order == 2 ? Colors.orange : (manga.order == 3 ? Colors.yellow[600] : Colors.grey[400])),
                    ),
              ),
              SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manga.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      manga.authors.map((a) => a.name).join('/'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentItem(BuildContext context, TinyManga manga) {
    final count = !widget.showMore ? 4 : 5;
    final width = (MediaQuery.of(context).size.width - 15 * count) / (count - 0.5); // | ▢ ▢ ▢ ▢|
    final height = width / 3 * 4;
    final extraData = MangaExtraDataForDialog.fromTinyManga(manga);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCover(context, manga.mid, manga.title, manga.cover, manga.url, width, height, extraData: extraData),
        Container(
          width: width,
          padding: EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                manga.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                manga.newestChapter.let((c) => RegExp('^[0-9]').hasMatch(c) ? '第$c' : c).let((c) => !manga.finished ? '更新至 $c' : '$c 完结'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(BuildContext context, MangaHistory manga) {
    final count = !widget.showMore ? 6 : 8;
    final width = (MediaQuery.of(context).size.width - 15 * count) / (count - 0.5); // | ▢ ▢ ▢ ▢ ▢ ▢|
    final height = width / 3 * 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCover(context, manga.mangaId, manga.mangaTitle, manga.mangaCover, manga.mangaUrl, width, height, extraData: null),
        Container(
          width: width,
          padding: EdgeInsets.only(top: 2),
          child: Text(
            !manga.read ? '未阅读' : manga.chapterTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 12, color: !manga.read ? Colors.grey : null),
          ),
        ),
      ],
    );
  }

  Widget _buildLaterItem(BuildContext context, LaterManga manga) {
    final count = !widget.showMore ? 6 : 8;
    final width = (MediaQuery.of(context).size.width - 15 * count) / (count - 0.5); // | ▢ ▢ ▢ ▢ ▢ ▢|
    final height = width / 3 * 4;
    final extraData = MangaExtraDataForDialog.fromLaterManga(manga);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCover(context, manga.mangaId, manga.mangaTitle, manga.mangaCover, manga.mangaUrl, width, height, extraData: extraData),
        Container(
          width: width,
          padding: EdgeInsets.only(top: 2),
          child: Text(
            manga.mangaTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildShelfItem(BuildContext context, ShelfManga manga) {
    final count = !widget.showMore ? 4 : 5;
    final width = (MediaQuery.of(context).size.width - 15 * count) / (count - 0.5); // | ▢ ▢ ▢ ▢|
    final height = width / 3 * 4;
    final extraData = MangaExtraDataForDialog.fromShelfManga(manga);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCover(context, manga.mid, manga.title, manga.cover, manga.url, width, height, extraData: extraData),
        Container(
          width: width,
          padding: EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                manga.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${manga.newestChapter}・${manga.formattedNewestDurationOrTime}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteItem(BuildContext context, FavoriteManga manga) {
    final count = !widget.showMore ? 6 : 8;
    final width = (MediaQuery.of(context).size.width - 15 * count) / (count - 0.5); // | ▢ ▢ ▢ ▢ ▢ ▢|
    final height = width / 3 * 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCover(context, manga.mangaId, manga.mangaTitle, manga.mangaCover, manga.mangaUrl, width, height, extraData: null),
        Container(
          width: width,
          padding: EdgeInsets.only(top: 2),
          child: Text(
            manga.mangaTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadItem(BuildContext context, DownloadedManga manga) {
    final count = !widget.showMore ? 4 : 5;
    final width = (MediaQuery.of(context).size.width - 15 * count) / (count - 0.5); // | ▢ ▢ ▢ ▢|
    final height = width / 3 * 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCover(context, manga.mangaId, manga.mangaTitle, manga.mangaCover, manga.mangaUrl, width, height, gotoDownload: true, extraData: null),
        Container(
          width: width,
          padding: EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                manga.mangaTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                manga.allChaptersSucceeded
                    ? '已完成 (共 ${manga.totalChaptersCount} 章节)' //
                    : '未完成 (${manga.successChaptersCount}/${manga.totalChaptersCount} 章节)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    String title;
    IconData icon;
    String? right;
    List<Widget>? widgets;
    bool twoLine = false;

    switch (widget.type) {
      case MangaCollectionType.rankings:
        title = '今日漫画排行榜';
        icon = Icons.trending_up;
        right = '更新于 ${formatDatetimeAndDuration(widget.rankingDateTime ?? DateTime.now(), FormatPattern.date)}';
        widgets = widget.ranking?.sublist(0, widget.ranking!.length.clamp(0, 20)).map((el) => _buildRankingItem(context, el)).toList(); // # = 50 => 20
        break;
      case MangaCollectionType.recents:
        title = '最近更新的漫画';
        icon = Icons.cached;
        widgets = widget.updates?.sublist(0, widget.updates!.length.clamp(0, 30)).map((el) => _buildRecentItem(context, el)).toList(); // # = 42 => 30
        break;
      case MangaCollectionType.histories:
        title = widget.username == null ? '本地阅读历史' : '${widget.username} 的阅读历史';
        icon = Icons.history;
        widgets = widget.histories?.sublist(0, widget.histories!.length.clamp(0, 30)).map((el) => _buildHistoryItem(context, el)).toList(); // # = 30
        twoLine = widgets != null && widgets.length > 10;
        break;
      case MangaCollectionType.laters:
        title = widget.username == null ? '我的稍后阅读列表' : '${widget.username} 的稍后阅读列表';
        icon = Icons.watch_later;
        widgets = widget.laters?.sublist(0, widget.laters!.length.clamp(0, 20)).map((el) => _buildLaterItem(context, el)).toList(); // # = 20
        twoLine = false;
        break;
      case MangaCollectionType.shelves:
        title = widget.username == null ? '我的书架' : '${widget.username} 的书架';
        icon = Icons.star;
        widgets = widget.shelves?.sublist(0, widget.shelves!.length.clamp(0, 20)).map((el) => _buildShelfItem(context, el)).toList(); // # = 20
        twoLine = widgets != null && widgets.length > 6;
        break;
      case MangaCollectionType.favorites:
        title = widget.username == null ? '我的本地收藏' : '${widget.username} 的本地收藏';
        icon = Icons.bookmark;
        widgets = widget.favorites?.sublist(0, widget.favorites!.length.clamp(0, 30)).map((el) => _buildFavoriteItem(context, el)).toList(); // # = 30
        twoLine = widgets != null && widgets.length > 10;
        break;
      case MangaCollectionType.downloads:
        title = '漫画下载列表';
        icon = Icons.download;
        widgets = widget.downloads?.sublist(0, widget.downloads!.length.clamp(0, 10)).map((el) => _buildDownloadItem(context, el)).toList(); // # = 10
        break;
    }

    return HomepageColumnView(
      title: title,
      icon: icon,
      onRefreshPressed: widget.onRefreshPressed /* for all types */,
      disableRefresh: widget.disableRefresh,
      rightText: right /* only for rankings */,
      onMorePressed: widget.onMorePressed,
      child: PlaceholderText.from(
        isLoading: widgets == null,
        isEmpty: widgets?.isNotEmpty != true,
        errorText: widget.error,
        setting: PlaceholderSetting(
          showLoadingText: false,
          showNothingRetry: false,
          showErrorRetry: false,
          progressPadding: const EdgeInsets.all(12),
          iconPadding: const EdgeInsets.all(5),
          textPadding: const EdgeInsets.all(5),
          progressSize: 42,
          iconSize: 42,
          textStyle: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.grey[600]),
        ).copyWithChinese(),
        childBuilder: (_) => SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 15),
          physics: DefaultScrollPhysics.of(context) ?? AlwaysScrollableScrollPhysics(), // for scrolling in recommend page
          scrollDirection: Axis.horizontal,
          child: !twoLine
              ? Row(
                  children: [
                    for (var i = 0; i < widgets!.length; i++)
                      Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 15),
                        child: widgets[i],
                      ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < widgets!.length; i += 2)
                      Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 15),
                        child: Column(
                          children: [
                            widgets[i],
                            if (i + 1 < widgets.length)
                              Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: widgets[i + 1],
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
