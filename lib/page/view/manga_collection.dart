import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/download_manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/homepage_column.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

enum MangaCollectionType {
  rankings,
  updates,
  histories,
  shelves,
  favorites,
  downloads,
}

/// 漫画集合，针对日排行榜、最近更新、阅读历史、我的书架、本地收藏、下载列表，在 [RecommendSubPage] 使用
class MangaCollectionView extends StatefulWidget {
  const MangaCollectionView({
    Key? key,
    required this.type,
    this.ranking,
    this.updates,
    this.histories,
    this.shelves,
    this.favorites,
    this.downloads,
    this.error,
    required this.username,
    this.onRefreshPressed,
    this.disableRefresh = false,
    this.onMorePressed,
  }) : super(key: key);

  final MangaCollectionType type;
  final List<MangaRanking>? ranking;
  final List<TinyManga>? updates;
  final List<MangaHistory>? histories;
  final List<ShelfManga>? shelves;
  final List<FavoriteManga>? favorites;
  final List<DownloadedManga>? downloads;
  final String? error;
  final String? username;
  final void Function()? onRefreshPressed;
  final bool disableRefresh;
  final void Function()? onMorePressed;

  @override
  State<MangaCollectionView> createState() => _MangaCollectionViewState();
}

class _MangaCollectionViewState extends State<MangaCollectionView> with AutomaticKeepAliveClientMixin {
  Widget _buildCover(BuildContext context, int mid, String title, String url, String cover, double width, double height, {bool gotoDownload = false}) {
    return FullRippleWidget(
      child: Container(
        width: width,
        height: height,
        child: NetworkImageView(
          url: cover,
          width: width,
          height: height,
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
    );
  }

  Widget _buildRankItem(BuildContext context, MangaRanking manga) {
    final width = (MediaQuery.of(context).size.width - 15 * 3) / 2.5; // | ▢ ▢ ▢|
    final height = width / 3 * 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCover(context, manga.mid, manga.title, manga.url, manga.cover, width, height),
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

  Widget _buildUpdateItem(BuildContext context, TinyManga manga) {
    final width = (MediaQuery.of(context).size.width - 15 * 4) / 3.5; // | ▢ ▢ ▢ ▢|
    final height = width / 3 * 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCover(context, manga.mid, manga.title, manga.url, manga.cover, width, height),
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
                !manga.finished ? '更新至 ${manga.newestChapter}' : '${manga.newestChapter} 全',
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
    final width = (MediaQuery.of(context).size.width - 15 * 6) / 5.5; // | ▢ ▢ ▢ ▢ ▢ ▢|
    final height = width / 3 * 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCover(context, manga.mangaId, manga.mangaTitle, manga.mangaUrl, manga.mangaCover, width, height),
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

  Widget _buildShelfItem(BuildContext context, ShelfManga manga) {
    final width = (MediaQuery.of(context).size.width - 15 * 4) / 3.5; // | ▢ ▢ ▢ ▢|
    final height = width / 3 * 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCover(context, manga.mid, manga.title, manga.url, manga.cover, width, height),
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
    final width = (MediaQuery.of(context).size.width - 15 * 6) / 5.5; // | ▢ ▢ ▢ ▢ ▢ ▢|
    final height = width / 3 * 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCover(context, manga.mangaId, manga.mangaTitle, manga.mangaUrl, manga.mangaCover, width, height),
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
    final width = (MediaQuery.of(context).size.width - 15 * 4) / 3.5; // | ▢ ▢ ▢ ▢|
    final height = width / 3 * 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCover(context, manga.mangaId, manga.mangaTitle, manga.mangaUrl, manga.mangaCover, width, height, gotoDownload: true),
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
    List<Widget>? widgets;
    bool twoLine = false;

    switch (widget.type) {
      case MangaCollectionType.rankings:
        title = '今日漫画排行榜';
        icon = Icons.trending_up;
        widgets = widget.ranking?.sublist(0, widget.ranking!.length.clamp(0, 20)).map((el) => _buildRankItem(context, el)).toList(); // # = 50 => 20
        break;
      case MangaCollectionType.updates:
        title = '最近更新的漫画';
        icon = Icons.cached;
        widgets = widget.updates?.sublist(0, widget.updates!.length.clamp(0, 30)).map((el) => _buildUpdateItem(context, el)).toList(); // # = 42 => 30
        break;
      case MangaCollectionType.histories:
        title = widget.username == null ? '本地阅读历史' : '${widget.username} 的阅读历史';
        icon = Icons.history;
        widgets = widget.histories?.map((el) => _buildHistoryItem(context, el)).toList(); // # = 50
        twoLine = widgets != null && widgets.length > 10;
        break;
      case MangaCollectionType.shelves:
        title = widget.username == null ? '我的书架' : '${widget.username} 的书架';
        icon = Icons.star;
        widgets = widget.shelves?.map((el) => _buildShelfItem(context, el)).toList(); // # = 20
        twoLine = widgets != null && widgets.length > 6;
        break;
      case MangaCollectionType.favorites:
        title = widget.username == null ? '我的本地收藏' : '${widget.username} 的本地收藏';
        icon = Icons.bookmark;
        widgets = widget.favorites?.map((el) => _buildFavoriteItem(context, el)).toList(); // # = 20
        twoLine = widgets != null && widgets.length > 10;
        break;
      case MangaCollectionType.downloads:
        title = '漫画下载列表';
        icon = Icons.download;
        widgets = widget.downloads?.sublist(0, widget.downloads!.length.clamp(0, 20)).map((el) => _buildDownloadItem(context, el)).toList(); // # = 20
        break;
    }

    return HomepageColumnView(
      title: title,
      icon: icon,
      onRefreshPressed: widget.onRefreshPressed,
      disableRefresh: widget.disableRefresh,
      onMorePressed: widget.onMorePressed,
      child: PlaceholderText.from(
        isLoading: widgets == null,
        isEmpty: widgets?.isNotEmpty != true,
        errorText: widget.error,
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
                            if (i + 1 < widgets.length) ...[
                              SizedBox(height: 10),
                              widgets[i + 1],
                            ],
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
