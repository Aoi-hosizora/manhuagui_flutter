part of 'manga_dialog.dart';

// => called by pages which contains manga line view (tiny / ranking / *shelf* / *favorite* / *history* / *later* / download / aud_ranking) and DownloadMangaPage
Future<void> showPopupMenuForMangaList({
  required BuildContext context,
  required int mangaId,
  required String mangaTitle,
  required String mangaCover,
  required String mangaUrl,
  required MangaExtraDataForDialog? extraData,
  required EventSource eventSource,
  // ===
  ShelfUpdatedCallback? onShelfUpdated,
  FavoriteUpdatedCallback? onFavoriteUpdated,
  LaterUpdatedCallback? onLaterUpdated,
  HistoryUpdatedCallback? onHistoryUpdated,
}) async {
  var nowInDownload = await DownloadDao.checkMangaExistence(mid: mangaId) ?? false;
  var favoriteManga = await FavoriteDao.getFavorite(username: AuthManager.instance.username, mid: mangaId);
  var nowInFavorite = favoriteManga != null;
  var nowInShelfCache = await ShelfCacheDao.checkExistence(username: AuthManager.instance.username, mid: mangaId) ?? false;
  var laterManga = await LaterMangaDao.getLaterManga(username: AuthManager.instance.username, mid: mangaId);
  var nowInLater = laterManga != null;
  var laterChapterCount = await LaterMangaDao.getLaterChapterCount(username: AuthManager.instance.username, mid: mangaId) ?? 0;
  var mangaHistory = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: mangaId);
  var expandShelfOptions = false;

  var helper = _DialogHelper(
    context: context,
    mangaId: mangaId,
    mangaTitle: mangaTitle,
    mangaCover: mangaCover,
    mangaUrl: mangaUrl,
    extraData: extraData,
  );

  showDialog(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (_, _setState) => SimpleDialog(
        title: Text(mangaTitle),
        children: [
          /// 基本选项
          IconTextDialogOption(
            icon: Icon(MdiIcons.bookOutline),
            text: Text('查看该漫画'),
            popWhenPress: c,
            onPressed: () => helper.gotoMangaPage(),
          ),
          IconTextDialogOption(
            icon: Icon(Icons.copy),
            text: Text('复制漫画标题'),
            onPressed: () => copyText(mangaTitle, showToast: true),
          ),
          IconTextDialogOption(
            icon: Icon(Icons.open_in_browser),
            text: Text('用浏览器打开'),
            popWhenPress: c,
            onPressed: () => launchInBrowser(context: context, url: mangaUrl),
          ),
          Divider(height: 16, thickness: 1),

          /// 下载
          if (nowInDownload && eventSource != EventSource.downloadPage)
            IconTextDialogOption(
              icon: Icon(Icons.downloading),
              text: Text('查看下载详情'),
              popWhenPress: c,
              onPressed: () => helper.gotoDownloadMangaPage(),
            ),

          /// 书架
          if (AuthManager.instance.logined && eventSource == EventSource.shelfPage)
            IconTextDialogOption(
              icon: Icon(MdiIcons.starMinus),
              text: Text('移出我的书架'),
              popWhenPress: c,
              predicateForPress: () => helper.showCheckRemovingShelfDialog(),
              onPressed: () => helper.addOrRemoveShelf(toAdd: false, subscribing: null, onUpdated: onShelfUpdated, eventSource: eventSource),
            ),
          if (AuthManager.instance.logined && eventSource != EventSource.shelfPage) ...[
            if (!expandShelfOptions)
              IconTextDialogOption(
                icon: Icon(MdiIcons.starCog),
                text: Text('编辑我的书架'),
                onPressed: () => _setState(() => expandShelfOptions = true),
                onLongPressed: () => _setState(() => expandShelfOptions = true),
              ),
            if (expandShelfOptions)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10 /* <<< */),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                ),
                child: (kIconTextDialogOptionPadding - EdgeInsets.symmetric(horizontal: 10 /* <<< */)).let(
                  (optionPadding) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconTextDialogOption(
                        icon: Icon(MdiIcons.starCog, color: Colors.black26),
                        text: Text('隐藏书架选项'),
                        padding: optionPadding,
                        onPressed: () => _setState(() => expandShelfOptions = false),
                        onLongPressed: () => _setState(() => expandShelfOptions = false),
                      ),
                      IconTextDialogOption(
                        icon: Icon(MdiIcons.starPlus),
                        text: Text('放入我的书架' + (!nowInShelfCache ? ' (*)' : '')),
                        padding: optionPadding,
                        popWhenPress: c,
                        onPressed: () => helper.addOrRemoveShelf(toAdd: true, subscribing: null, onUpdated: onShelfUpdated, eventSource: eventSource),
                      ),
                      IconTextDialogOption(
                        icon: Icon(MdiIcons.starMinus),
                        text: Text('移出我的书架' + (nowInShelfCache ? ' (*)' : '')),
                        padding: optionPadding,
                        popWhenPress: c,
                        predicateForPress: () => helper.showCheckRemovingShelfDialog(),
                        onPressed: () => helper.addOrRemoveShelf(toAdd: false, subscribing: null, onUpdated: onShelfUpdated, eventSource: eventSource),
                      ),
                    ],
                  ),
                ),
              ),
          ],

          /// 收藏
          IconTextDialogOption(
            icon: Icon(!nowInFavorite ? CustomIcons.bookmark_plus : CustomIcons.bookmark_minus),
            text: Text(!nowInFavorite ? '添加本地收藏' : '取消本地收藏'),
            popWhenPress: c,
            predicateForPress: !nowInFavorite ? null : () => helper.showCheckRemovingFavoriteDialog(),
            onPressed: () => !nowInFavorite //
                ? helper.addFavorite(subscribing: null, onAdded: (f) => onFavoriteUpdated?.call(f), eventSource: eventSource)
                : helper.removeFavorite(subscribing: null, onRemoved: () => onFavoriteUpdated?.call(null), eventSource: eventSource),
          ),

          /// 稍后阅读
          IconTextDialogOption(
            icon: Icon(!nowInLater ? MdiIcons.clockPlus : MdiIcons.clockMinus),
            text: Text(!nowInLater ? '添加至稍后阅读列表' : '移出稍后阅读列表'),
            popWhenPress: c,
            predicateForPress: !nowInLater ? null : () => helper.showCheckRemovingLaterDialog(laterChapterCount: laterChapterCount),
            onPressed: () => !nowInLater //
                ? helper.addLater(onAdded: (l) => onLaterUpdated?.call(l), eventSource: eventSource)
                : helper.removeLater(onRemoved: () => onLaterUpdated?.call(null), onLaterChapterCleared: null, eventSource: eventSource),
          ),

          /// 更多选项
          IconTextDialogOption(
            icon: Icon(Icons.more_horiz),
            text: Text('更多选项'),
            popWhenPress: c,
            onPressed: () => showDialog(
              context: context,
              builder: (c) => SimpleDialog(
                title: Text(mangaTitle),
                children: <List<Widget>>[
                  /// 基本选项
                  [
                    IconTextDialogOption(
                      icon: Icon(MdiIcons.bookOutline),
                      text: Text('查看该漫画'),
                      popWhenPress: c,
                      onPressed: () => helper.gotoMangaPage(),
                    ),
                  ],

                  /// 下载
                  if (nowInDownload)
                    [
                      if (eventSource != EventSource.downloadPage)
                        IconTextDialogOption(
                          icon: Icon(Icons.downloading),
                          text: Text('查看下载详情'),
                          popWhenPress: c,
                          onPressed: () => helper.gotoDownloadMangaPage(),
                        ),
                      if (eventSource != EventSource.downloadPage)
                        IconTextDialogOption(
                          icon: Icon(MdiIcons.downloadMultiple),
                          text: Text('查看漫画下载列表'),
                          popWhenPress: c,
                          onPressed: () => helper.gotoDownloadListPage(),
                        ),
                    ],

                  /// 书架
                  if (nowInShelfCache)
                    [
                      IconTextDialogOption(
                        icon: Icon(CustomIcons.star_sync),
                        text: Text('查看已同步的书架记录'),
                        popWhenPress: c,
                        onPressed: () => helper.gotoShelfCachePage(),
                      ),
                      if (eventSource != EventSource.shelfPage)
                        IconTextDialogOption(
                          icon: Icon(MdiIcons.bookshelf),
                          text: Text('查看我的书架列表'),
                          popWhenPress: c,
                          onPressed: () => helper.gotoShelfPage(),
                        ),
                    ],

                  /// 收藏
                  if (favoriteManga != null)
                    [
                      IconTextDialogOption(
                        icon: Icon(Icons.folder),
                        text: Flexible(child: Text('修改收藏分组 - ${favoriteManga.checkedGroupName}', maxLines: 1, overflow: TextOverflow.ellipsis)),
                        popWhenPress: c,
                        onPressed: () => helper.updateFavGroupWithDlg(oldFavorite: favoriteManga, onUpdated: onFavoriteUpdated, showSnackBar: true, eventSource: eventSource),
                      ),
                      IconTextDialogOption(
                        icon: Icon(MdiIcons.commentBookmark),
                        text: Text('查看或修改收藏备注'),
                        popWhenPress: c,
                        onPressed: () => helper.showAndUpdateFavRemarkWithDlg(favorite: favoriteManga, onUpdated: onFavoriteUpdated, showSnackBar: true, eventSource: eventSource),
                      ),
                      if (eventSource != EventSource.favoritePage)
                        IconTextDialogOption(
                          icon: Icon(CustomIcons.bookmark_multiple),
                          text: Text('查看漫画收藏列表'),
                          popWhenPress: c,
                          onPressed: () => helper.gotoFavoritePage(),
                        ),
                    ],

                  /// 稍后阅读
                  if (laterManga != null)
                    [
                      IconTextDialogOption(
                        icon: Icon(CustomIcons.clock_topmost),
                        text: Text('置顶于稍后阅读列表'),
                        popWhenPress: c,
                        onPressed: () => helper.topmostLater(later: laterManga, onUpdated: onLaterUpdated, eventSource: eventSource),
                      ),
                      if (extraData != null && extraData.newestChapter != null && extraData.newestDate != null && extraData.newestChapter != laterManga.newestChapter)
                        IconTextDialogOption(
                          icon: Icon(CustomIcons.clock_sync),
                          text: Text('更新记录至最新章节 (*)'),
                          popWhenPress: c,
                          onPressed: () => helper.updateLaterToNewestChapterWithDlg(later: laterManga, onUpdated: onLaterUpdated, eventSource: eventSource),
                        ),
                      if (eventSource != EventSource.laterPage)
                        IconTextDialogOption(
                          icon: Icon(MdiIcons.bookClock),
                          text: Text('查看稍后阅读列表'),
                          popWhenPress: c,
                          onPressed: () => helper.gotoLaterPage(),
                        ),
                    ],

                  /// 历史
                  if (mangaHistory != null)
                    [
                      IconTextDialogOption(
                        icon: Icon(CustomIcons.history_delete),
                        text: Text(!mangaHistory.read ? '删除浏览历史' : '删除阅读与浏览历史'),
                        popWhenPress: c,
                        predicateForPress: () => helper.showCheckRemovingHistoryDialog(read: mangaHistory.read),
                        onPressed: () => helper.removeHistory(oldHistory: mangaHistory, onRemoved: () => onHistoryUpdated?.call(null), onFpCleared: null, eventSource: eventSource),
                      ),
                      if (eventSource != EventSource.historyPage)
                        IconTextDialogOption(
                          icon: Icon(Icons.history),
                          text: Text('查看漫画历史列表'),
                          popWhenPress: c,
                          onPressed: () => helper.gotoHistoryPage(),
                        ),
                    ],

                  /// ...
                  [
                    IconTextDialogOption(
                      icon: Icon(Icons.arrow_back),
                      text: Text('其他选项'),
                      popWhenPress: c,
                      onPressed: () => showPopupMenuForMangaList(
                        context: context,
                        mangaId: mangaId,
                        mangaTitle: mangaTitle,
                        mangaCover: mangaCover,
                        mangaUrl: mangaUrl,
                        extraData: extraData,
                        eventSource: eventSource,
                        // ===
                        onShelfUpdated: onShelfUpdated,
                        onFavoriteUpdated: onFavoriteUpdated,
                        onLaterUpdated: onLaterUpdated,
                        onHistoryUpdated: onHistoryUpdated,
                      ),
                    ),
                  ]
                ].let((list) {
                  var newList = list.expand((el) => [...el, if (el.isNotEmpty) Divider(height: 10, thickness: 1)]);
                  return newList.toList().sublist(0, newList.length - 1);
                }),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
