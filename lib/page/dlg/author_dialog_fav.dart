part of 'author_dialog.dart';

// => called in AuthorPage
void showPopupMenuForAuthorFavoriting({
  required BuildContext context,
  required int authorId,
  required String authorName,
  required String authorCover,
  required String authorUrl,
  required String authorZone,
  required FavoriteAuthor? favoriteAuthor,
  required EventSource eventSource,
  // ===
  required FavoriteUpdatedCallback favoriteSetter,
}) {
  var helper = _DialogHelper(
    context: context,
    authorId: authorId,
    authorName: authorName,
    authorCover: authorCover,
    authorUrl: authorUrl,
    authorZone: authorZone,
  );

  showDialog(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text('收藏 "$authorName"'),
      children: [
        /// 收藏
        if (favoriteAuthor == null)
          IconTextDialogOption(
            icon: Icon(Icons.bookmark_border),
            text: Text('添加本地收藏'),
            popWhenPress: c,
            onPressed: () => helper.addFavoriteWithDlg(onAdded: favoriteSetter, eventSource: eventSource),
          ),
        if (favoriteAuthor != null)
          IconTextDialogOption(
            icon: Icon(Icons.bookmark),
            text: Text('取消本地收藏'),
            popWhenPress: c,
            predicateForPress: () => helper.showCheckRemovingFavoriteDialog(),
            onPressed: () => helper.removeFavorite(onRemoved: () => favoriteSetter(null), eventSource: eventSource),
          ),
        Divider(thickness: 1),

        /// 额外选项
        if (favoriteAuthor != null)
          IconTextDialogOption(
            icon: Icon(MdiIcons.commentBookmark),
            text: Flexible(
              child: Text('当前收藏备注：${favoriteAuthor.remark.trim().isEmpty ? '暂无' : favoriteAuthor.remark.trim()}', maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            popWhenPress: c,
            onPressed: () => helper.showAndUpdateFavRemarkWithDlg(favorite: favoriteAuthor, onUpdated: favoriteSetter, showSnackBar: true, eventSource: eventSource),
          ),
        IconTextDialogOption(
          icon: Icon(Icons.people),
          text: Text('查看已收藏的作者'),
          popWhenPress: c,
          onPressed: () => helper.gotoFavoritesPage(),
        ),
      ],
    ),
  );
}
