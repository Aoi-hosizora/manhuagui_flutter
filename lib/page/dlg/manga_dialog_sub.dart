part of 'manga_dialog.dart';

// => called in MangaPage and MangaViewerPage
Future<void> showPopupMenuForSubscribing({
  required BuildContext context,
  required int mangaId,
  required String mangaTitle,
  required String mangaCover,
  required String mangaUrl,
  required MangaExtraDataForDialog? extraData,
  required EventSource eventSource,
  // ===
  required bool nowInShelf,
  required FavoriteManga? nowFavorite,
  required LaterManga? nowLater,
  required int? subscribeCount,
  // ===
  required SubscribingUpdatedCallback? onSubscribingUpdated,
  required ShelfUpdatedCallback? onShelfUpdated,
  required FavoriteUpdatedCallback? onFavoriteUpdated,
  required LaterUpdatedCallback? onLaterUpdated,
  required NotateClearedCallback? onNotateCleared,
}) async {
  var helper = _DialogHelper(
    context: context,
    mangaId: mangaId,
    mangaTitle: mangaTitle,
    mangaCover: mangaCover,
    mangaUrl: mangaUrl,
    extraData: extraData,
  );

  var laterChapterCount = await LaterMangaDao.getLaterChapterCount(username: AuthManager.instance.username, mid: mangaId) ?? 0;
  showDialog(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text('订阅《$mangaTitle》'),
      children: [
        /// 书架
        if (AuthManager.instance.logined && !nowInShelf)
          IconTextDialogOption(
            icon: Icon(MdiIcons.starPlus),
            text: Text('放入我的书架'),
            popWhenPress: c,
            onPressed: () => helper.addOrRemoveShelf(toAdd: true, subscribing: onSubscribingUpdated, onUpdated: onShelfUpdated, eventSource: eventSource),
          ),
        if (AuthManager.instance.logined && nowInShelf)
          IconTextDialogOption(
            icon: Icon(MdiIcons.starMinus),
            text: Text('移出我的书架'),
            popWhenPress: c,
            predicateForPress: () => helper.showCheckRemovingShelfDialog(),
            onPressed: () => helper.addOrRemoveShelf(toAdd: false, subscribing: onSubscribingUpdated, onUpdated: onShelfUpdated, eventSource: eventSource),
          ),

        /// 收藏
        if (nowFavorite == null)
          IconTextDialogOption(
            icon: Icon(CustomIcons.bookmark_plus),
            text: Text('添加本地收藏'),
            popWhenPress: c,
            onPressed: () => helper.addFavorite(subscribing: onSubscribingUpdated, onAdded: onFavoriteUpdated, eventSource: eventSource),
          ),
        if (nowFavorite != null)
          IconTextDialogOption(
            icon: Icon(CustomIcons.bookmark_minus),
            text: Text('取消本地收藏'),
            popWhenPress: c,
            predicateForPress: () => helper.showCheckRemovingFavoriteDialog(),
            onPressed: () => helper.removeFavorite(subscribing: onSubscribingUpdated, onRemoved: () => onFavoriteUpdated?.call(null), eventSource: eventSource),
          ),

        /// 稍后阅读
        if (nowLater != null)
          IconTextDialogOption(
            icon: Icon(MdiIcons.clockPlus),
            text: Text('添加至稍后阅读列表'),
            popWhenPress: c,
            onPressed: () => helper.addLater(onAdded: onLaterUpdated, eventSource: eventSource),
          ),
        if (nowLater == null)
          IconTextDialogOption(
            icon: Icon(MdiIcons.clockMinus),
            text: Text('移出稍后阅读列表'),
            popWhenPress: c,
            predicateForPress: () => helper.showCheckRemovingLaterDialog(laterChapterCount: laterChapterCount),
            onPressed: () => helper.removeLater(onRemoved: () => onLaterUpdated?.call(null), onLaterChapterCleared: onNotateCleared, eventSource: eventSource),
          ),

        /// 额外选项
        if (nowInShelf || nowFavorite != null || nowLater != null) ...[
          Divider(height: 16, thickness: 1),
          if (nowInShelf && subscribeCount != null)
            IconTextDialogOption(
              icon: Icon(Icons.stars),
              text: Text('共 $subscribeCount 人将本漫画放入书架'),
              onPressed: () {},
            ),
          if (nowInShelf)
            IconTextDialogOption(
              icon: Icon(CustomIcons.star_sync),
              text: Text('查看已同步的书架记录'),
              popWhenPress: c,
              onPressed: () => helper.gotoShelfCachePage(),
            ),
          if (nowFavorite != null)
            IconTextDialogOption(
              icon: Icon(Icons.folder),
              text: Flexible(
                child: Text('当前收藏分组：${nowFavorite.checkedGroupName}', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              popWhenPress: c,
              onPressed: () => helper.updateFavGroupWithDlg(oldFavorite: nowFavorite, onUpdated: onFavoriteUpdated, showSnackBar: true, eventSource: eventSource),
            ),
          if (nowFavorite != null)
            IconTextDialogOption(
              icon: Icon(MdiIcons.commentBookmark),
              text: Flexible(
                child: Text('当前收藏备注：${nowFavorite.remark.trim().isEmpty ? '暂无' : nowFavorite.remark.trim()}', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              popWhenPress: c,
              onPressed: () => helper.showAndUpdateFavRemarkWithDlg(favorite: nowFavorite, onUpdated: onFavoriteUpdated, showSnackBar: true, eventSource: eventSource),
            ),
          if (nowLater != null)
            IconTextDialogOption(
              icon: Icon(CustomIcons.clock_topmost),
              text: Text('置顶于稍后阅读列表'),
              popWhenPress: c,
              onPressed: () => helper.topmostLater(later: nowLater, onUpdated: onLaterUpdated, eventSource: eventSource),
            ),
          if (nowLater != null)
            IconTextDialogOption(
              icon: Icon(MdiIcons.bookClock),
              text: Text('查看稍后阅读列表'),
              popWhenPress: c,
              onPressed: () => helper.gotoLaterPage(),
            ),
        ],
      ],
    ),
  );
}
