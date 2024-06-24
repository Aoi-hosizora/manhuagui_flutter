part of 'author_dialog.dart';

// => called in FavoriteAuthorPage
Future<void> showUpdateFavoriteAuthorRemarkDialog({
  required BuildContext context,
  required FavoriteAuthor favoriteAuthor,
  required EventSource eventSource,
  // ===
  required FavoriteUpdatedCallback onUpdated /* favorite must not be null here */,
}) async {
  var helper = _DialogHelper(
    context: context,
    authorId: favoriteAuthor.authorId,
    authorName: favoriteAuthor.authorName,
    authorCover: favoriteAuthor.authorCover,
    authorUrl: favoriteAuthor.authorUrl,
    authorZone: favoriteAuthor.authorZone,
  );
  await helper.updateFavRemarkWithDlg(
    oldFavorite: favoriteAuthor,
    onUpdated: onUpdated,
    showSnackBar: false,
    eventSource: eventSource,
  );
}

// => called in AuthorCategorySubPage / FavoriteAuthorPage
Future<int?> showFindAuthorByIdDialog({
  required BuildContext context,
  required String title,
  String textLabel = '漫画作者 aid',
  String textValue = '',
  String emptyToast = '请输入作者 aid',
  String invalidToast = '输入的作者 aid 有误',
}) async {
  var controller = TextEditingController()..text = textValue;
  var ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: getDialogContentMaxWidth(context),
        child: TextField(
          controller: controller,
          maxLines: 1,
          autofocus: true,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 5),
            labelText: textLabel,
            icon: Icon(Icons.person_search),
          ),
          keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ),
      actions: [
        TextButton(
          child: Text('确定'),
          onPressed: () async {
            var text = controller.text.trim();
            if (text.isEmpty) {
              Fluttertoast.showToast(msg: emptyToast);
            } else if ((int.tryParse(text) ?? 0) <= 0) {
              Fluttertoast.showToast(msg: invalidToast);
            } else {
              Navigator.of(c).pop(true);
            }
          },
        ),
        TextButton(
          child: Text('取消'),
          onPressed: () => Navigator.of(c).pop(false),
        ),
      ],
    ),
  );
  if (ok != true) {
    return null;
  }
  return int.tryParse(controller.text.trim());
}

// => called in AuthorPage
void showPopupMenuForAuthorName({
  required BuildContext context,
  required Author? author,
  required String fallbackName,
  bool vibrate = false,
}) {
  if (vibrate) {
    HapticFeedback.vibrate();
  }

  showDialog(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text(author?.name ?? fallbackName),
      children: [
        IconTextDialogOption(
          icon: Icon(Icons.copy),
          text: Text('复制作者名'),
          popWhenPress: c,
          onPressed: () => copyText(author?.name ?? fallbackName, showToast: true),
        ),
        if (author != null)
          IconTextDialogOption(
            icon: Icon(Icons.subject),
            text: Text('查看作者详情'),
            popWhenPress: c,
            onPressed: () => Navigator.of(context).push(
              CustomPageRoute(
                context: context,
                builder: (c) => AuthorDetailPage(
                  data: author,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
