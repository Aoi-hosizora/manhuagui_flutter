part of 'author_dialog.dart';

// => called by pages which contains author line view (tiny / favorite)
Future<void> showPopupMenuForAuthorList({
  required BuildContext context,
  required int authorId,
  required String authorName,
  required String authorCover,
  required String authorUrl,
  required String authorZone,
  required EventSource eventSource,
  // ===
  FavoriteUpdatedCallback? onFavoriteUpdated,
}) async {
  var nowInFavorite = await FavoriteDao.checkAuthorExistence(username: AuthManager.instance.username, aid: authorId) ?? false;
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
      title: Text(authorName),
      children: [
        /// 基本选项
        IconTextDialogOption(
          icon: Icon(Icons.person),
          text: Text('查看该作者'),
          popWhenPress: c,
          onPressed: () => helper.gotoAuthorPage(),
        ),
        IconTextDialogOption(
          icon: Icon(Icons.copy),
          text: Text('复制作者名'),
          onPressed: () => copyText(authorName, showToast: true),
        ),
        IconTextDialogOption(
          icon: Icon(Icons.open_in_browser),
          text: Text('用浏览器打开'),
          onPressed: () => launchInBrowser(context: context, url: authorUrl),
        ),
        Divider(height: 16, thickness: 1),

        /// 收藏
        IconTextDialogOption(
          icon: Icon(!nowInFavorite ? CustomIcons.bookmark_plus : CustomIcons.bookmark_minus),
          text: Text(!nowInFavorite ? '添加本地收藏' : '取消本地收藏'),
          popWhenPress: c,
          predicateForPress: !nowInFavorite ? null : () => helper.showCheckRemovingFavoriteDialog(),
          onPressed: () => !nowInFavorite //
              ? helper.addFavoriteWithDlg(onAdded: onFavoriteUpdated, eventSource: eventSource)
              : helper.removeFavorite(onRemoved: () => onFavoriteUpdated?.call(null), eventSource: eventSource),
        ),
      ],
    ),
  );
}
