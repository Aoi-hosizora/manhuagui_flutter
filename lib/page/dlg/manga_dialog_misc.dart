part of 'manga_dialog.dart';

// => called in FavoriteSubPage and FavoriteAllPage
Future<void> showUpdateFavoriteMangasGroupDialog({
  required BuildContext context,
  required List<FavoriteManga> favorites,
  required String? currentGroupName,
  required EventSource eventSource,
  // ===
  required FavoritesUpdatedCallback onUpdated /* with `bool addToTop` argument */,
}) async {
  var helper = _DialogHelper(
    context: context,
    mangaId: 0 /* not be used here */,
    mangaTitle: '',
    mangaCover: '',
    mangaUrl: '',
    extraData: null,
  );
  await helper.updateFavsGroupWithDlg(
    oldFavorites: favorites,
    selectedGroupName: currentGroupName,
    onUpdated: onUpdated,
    eventSource: eventSource,
    showToast: true,
  );
}

// => called in FavoriteSubPage and FavoriteAllPage
Future<void> showUpdateFavoriteMangaRemarkDialog({
  required BuildContext context,
  required FavoriteManga favorite,
  required EventSource eventSource,
  // ===
  required FavoriteUpdatedCallback onUpdated /* favorite must not be null here */,
}) async {
  var helper = _DialogHelper(
    context: context,
    mangaId: favorite.mangaId,
    mangaTitle: favorite.mangaTitle,
    mangaCover: favorite.mangaCover,
    mangaUrl: favorite.mangaUrl,
    extraData: null,
  );
  await helper.updateFavRemarkWithDlg(
    oldFavorite: favorite,
    onUpdated: onUpdated,
    eventSource: eventSource,
    showSnackBar: false,
  );
}


// ================
// misc popup menus
// ================

// => called in MangaPage
void showPopupMenuForMangaTitle({
  required BuildContext context,
  required Manga? manga,
  required String fallbackTitle,
  bool vibrate = false,
}) {
  if (vibrate) {
    HapticFeedback.vibrate();
  }
  showDialog(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text(manga?.title ?? fallbackTitle),
      children: [
        IconTextDialogOption(
          icon: Icon(Icons.copy),
          text: Text('复制标题'),
          popWhenPress: c,
          onPressed: () => copyText(manga?.title ?? fallbackTitle, showToast: true),
        ),
        if (manga != null)
          IconTextDialogOption(
            icon: Icon(Icons.subject),
            text: Text('查看漫画详情'),
            popWhenPress: c,
            onPressed: () => Navigator.of(context).push(
              CustomPageRoute(
                context: context,
                builder: (c) => MangaDetailPage(
                  data: manga,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

// => called in MangaViewerPage
void showPopupMenuForChapterTitle({
  required BuildContext context,
  required String mangaTitle,
  required String chapterTitle,
  void Function()? onDetailsPressed,
  bool vibrate = false,
}) {
  if (vibrate) {
    HapticFeedback.vibrate();
  }
  showDialog(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text('《$mangaTitle》$chapterTitle'),
      children: [
        IconTextDialogOption(
          icon: Icon(Icons.copy),
          text: Text('复制章节标题'),
          popWhenPress: c,
          onPressed: () => copyText(chapterTitle, showToast: true),
        ),
        IconTextDialogOption(
          icon: Icon(Icons.copy),
          text: Text('复制漫画标题'),
          popWhenPress: c,
          onPressed: () => copyText(mangaTitle, showToast: true),
        ),
        if (onDetailsPressed != null)
          IconTextDialogOption(
            icon: Icon(Icons.subject),
            text: Text('查看章节详情'),
            popWhenPress: c,
            onPressed: onDetailsPressed,
          ),
      ],
    ),
  );
}
