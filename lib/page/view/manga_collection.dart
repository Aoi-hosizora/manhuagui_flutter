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
  downloads,
}

/// 漫画集合，针对每日排行、最近更新、浏览历史、我的书架、下载列表，在 [RecommendSubPage] 使用
class MangaCollectionView extends StatelessWidget {
  const MangaCollectionView({
    Key? key,
    required this.type,
    this.ranking,
    this.updates,
    this.histories,
    this.shelves,
    this.downloads,
    this.error,
    required this.username,
    this.onMorePressed,
  }) : super(key: key);

  final MangaCollectionType type;
  final List<MangaRanking>? ranking;
  final List<TinyManga>? updates;
  final List<MangaHistory>? histories;
  final List<ShelfManga>? shelves;
  final List<DownloadedManga>? downloads;
  final String? error;
  final String? username;
  final void Function()? onMorePressed;

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
            !manga.read ? '未开始阅读' : manga.chapterTitle,
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
                '${manga.newestChapter}・${manga.newestDuration}',
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
                manga.triedChapterIds.length == manga.totalChapterIds.length
                    ? '已完成 (共 ${manga.totalChapterIds.length} 章节)' //
                    : '未完成 (${manga.triedChapterIds.length}/${manga.totalChapterIds.length})',
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
  Widget build(BuildContext context) {
    String title;
    IconData icon;
    List<Widget>? widgets;

    switch (type) {
      case MangaCollectionType.rankings:
        title = '今日漫画排行榜';
        icon = Icons.trending_up;
        widgets = ranking?.sublist(0, ranking!.length.clamp(0, 20)).map((el) => _buildRankItem(context, el)).toList();
        break;
      case MangaCollectionType.updates:
        title = '最近更新的漫画';
        icon = Icons.cached;
        widgets = updates?.map((el) => _buildUpdateItem(context, el)).toList();
        break;
      case MangaCollectionType.histories:
        title = username == null ? '本地浏览历史' : '$username 的浏览历史';
        icon = Icons.history;
        widgets = histories?.map((el) => _buildHistoryItem(context, el)).toList();
        break;
      case MangaCollectionType.shelves:
        title = username == null ? '我的书架' : '$username 的书架';
        icon = Icons.star_outlined;
        widgets = shelves?.map((el) => _buildShelfItem(context, el)).toList();
        break;
      case MangaCollectionType.downloads:
        title = '漫画下载列表';
        icon = Icons.download;
        widgets = downloads?.sublist(0, downloads!.length.clamp(0, 20)).map((el) => _buildDownloadItem(context, el)).toList();
        break;
    }

    return HomepageColumnView(
      title: title,
      icon: icon,
      onMorePressed: onMorePressed,
      hPadding: 15,
      vPadding: 10,
      child: PlaceholderText.from(
        isLoading: widgets == null,
        isEmpty: widgets?.isNotEmpty != true,
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
        childBuilder: (_) => SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 15),
          physics: AlwaysScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < widgets!.length; i++)
                Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 15),
                  child: widgets[i],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
