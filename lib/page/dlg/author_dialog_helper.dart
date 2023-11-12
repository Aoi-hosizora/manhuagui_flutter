part of 'author_dialog.dart';

class _DialogHelper {
  const _DialogHelper({
    required this.context,
    required this.authorId,
    required this.authorName,
    required this.authorCover,
    required this.authorUrl,
    required this.authorZone,
  });

  final BuildContext context;
  final int authorId;
  final String authorName;
  final String authorCover;
  final String authorUrl;
  final String authorZone;

  // =====================
  // helper methods (misc)
  // =====================

  void gotoAuthorPage() {
    Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => AuthorPage(
          id: authorId,
          name: authorName,
          url: authorUrl,
        ),
      ),
    );
  }

  void gotoFavoritesPage() {
    Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => FavoriteAuthorPage(),
      ),
    );
  }

  // ======================
  // methods (check dialog)
  // ======================

  Future<bool> showCheckRemovingFavoriteDialog() async {
    var ok = await showYesNoAlertDialog(context: context, title: Text('取消收藏确认'), content: Text('确定取消收藏漫画作者 "$authorName"？'), yesText: Text('确定'), noText: Text('取消'));
    return ok ?? false;
  }

  // ============================
  // static methods (show dialog)
  // ============================

  static Future<String?> showAddToFavoriteDialog({
    required BuildContext context,
  }) async {
    var controller = TextEditingController(); // remark
    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => WillPopScope(
        onWillPop: () async {
          if (controller.text.trim().isEmpty) {
            return true;
          }
          var ok = await showYesNoAlertDialog(
            context: context,
            title: Text('收藏漫画作者'),
            content: Text('是否放弃当前的输入并不做任何变更？'),
            yesText: Text('放弃'),
            noText: Text('继续编辑'),
            reverseYesNoOrder: true,
          );
          return ok == true;
        },
        child: StatefulBuilder(
          builder: (c, _setState) => AlertDialog(
            title: Text('收藏漫画作者'),
            content: SizedBox(
              width: getDialogContentMaxWidth(context),
              child: TextField(
                controller: controller,
                maxLines: 1,
                autofocus: true,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                  labelText: '作者备注',
                  icon: Icon(MdiIcons.commentBookmarkOutline),
                ),
              ),
            ),
            actions: [
              TextButton(child: Text('确定'), onPressed: () => Navigator.of(c).pop(true)),
              TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).maybePop(false)),
            ],
          ),
        ),
      ),
    );
    if (ok != true) {
      return null;
    }

    return controller.text.trim(); // remark, empty-able
  }

  static Future<String?> showEditFavoriteRemarkDialog({
    required BuildContext context,
    required String remark,
  }) async {
    var controller = TextEditingController()..text = remark; // remark
    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => WillPopScope(
        onWillPop: () async {
          if (controller.text.trim() == remark) {
            return true;
          }
          var ok = await showYesNoAlertDialog(
            context: context,
            title: Text('修改收藏备注'),
            content: Text('是否放弃当前的输入并不做任何变更？'),
            yesText: Text('放弃'),
            noText: Text('继续编辑'),
            reverseYesNoOrder: true,
          );
          return ok == true;
        },
        child: AlertDialog(
          title: Text('修改收藏备注'),
          content: SizedBox(
            width: getDialogContentMaxWidth(context),
            child: TextField(
              controller: controller,
              maxLines: 1,
              autofocus: true,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 5),
                labelText: '作者备注',
                icon: Icon(MdiIcons.commentBookmarkOutline),
              ),
            ),
          ),
          actions: [
            if (remark.isNotEmpty)
              TextButton(
                child: Text('查看原备注'),
                onPressed: () => showYesNoAlertDialog(
                  context: context,
                  title: Text('收藏备注'),
                  content: Text(remark),
                  yesText: Text('复制'),
                  noText: Text('关闭'),
                  yesOnPressed: (c) => copyText(remark, showToast: true),
                ),
              ),
            TextButton(
              child: Text('确定'),
              onPressed: () async {
                if (controller.text.trim() == remark) {
                  Fluttertoast.showToast(msg: '备注没有变更');
                } else {
                  Navigator.of(c).pop(true);
                }
              },
            ),
            TextButton(
              child: Text('取消'),
              onPressed: () => Navigator.of(c).maybePop(false),
            ),
          ],
        ),
      ),
    );
    if (ok != true) {
      return null;
    }

    return controller.text.trim(); // remark, empty-able
  }

  static Future<bool> showFavoriteRemarkDialog({
    required BuildContext context,
    required String authorName,
    required String remark,
  }) async {
    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('"$authorName" 备注'),
        content: SelectableText(remark == '' ? '暂无备注' : remark),
        actions: [
          TextButton(child: Text('修改'), onPressed: () => Navigator.of(c).pop(true)),
          if (remark != '') TextButton(child: Text('复制'), onPressed: () => copyText(remark, showToast: true)),
          TextButton(child: Text('关闭'), onPressed: () => Navigator.of(c).pop()),
        ],
      ),
    );
    return ok ?? false;
  }

  // ==========================
  // methods (favorite related)
  // ==========================

  // => called by showPopupMenuForAuthorList, showPopupMenuForAuthorFavorite
  Future<void> addFavoriteWithDlg({
    required void Function(FavoriteAuthor newFavorite)? onAdded,
    required bool fromFavoriteList,
    required bool fromAuthorPage,
  }) async {
    var remark = await showAddToFavoriteDialog(context: context);
    if (remark == null) {
      return;
    }

    // 更新数据库、(更新界面)、弹出提示、发送通知
    var newFavorite = FavoriteAuthor(
      authorId: authorId,
      authorName: authorName,
      authorCover: authorCover,
      authorUrl: authorUrl,
      authorZone: authorZone,
      remark: remark,
      createdAt: DateTime.now(),
    );
    await FavoriteDao.addOrUpdateAuthor(username: AuthManager.instance.username, author: newFavorite);
    onAdded?.call(newFavorite);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已收藏漫画作者')));
    EventBusManager.instance.fire(FavoriteAuthorUpdatedEvent(authorId: authorId, reason: UpdateReason.added, fromFavoritePage: fromFavoriteList, fromAuthorPage: fromAuthorPage));
  }

  // => called by showPopupMenuForAuthorList, showPopupMenuForAuthorFavorite
  Future<void> removeFavorite({
    required void Function()? onRemoved,
    required bool fromFavoriteList,
    required bool fromAuthorPage,
  }) async {
    // 更新数据库、(更新界面)、弹出提示、发送通知
    await FavoriteDao.deleteAuthor(username: AuthManager.instance.username, aid: authorId);
    onRemoved?.call();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已取消收藏漫画作者')));
    EventBusManager.instance.fire(FavoriteAuthorUpdatedEvent(authorId: authorId, reason: UpdateReason.deleted, fromFavoritePage: fromFavoriteList, fromAuthorPage: fromAuthorPage));
  }

  // => called by showUpdateFavoriteAuthorRemarkDialog
  Future<void> updateFavRemarkWithDlg({
    required FavoriteAuthor oldFavorite,
    required void Function(FavoriteAuthor newFavorite) onUpdated,
    required bool showSnackBar,
    required bool fromFavoriteList,
    required bool fromAuthorPage,
  }) async {
    var remark = await showEditFavoriteRemarkDialog(context: context, remark: oldFavorite.remark.trim());
    if (remark == null) {
      return;
    }

    // 更新数据库、(更新界面)、弹出提示、发送通知
    var newFavorite = oldFavorite.copyWith(remark: remark);
    await FavoriteDao.addOrUpdateAuthor(username: AuthManager.instance.username, author: newFavorite);
    onUpdated(newFavorite);
    if (showSnackBar) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(remark == '' ? '已删除收藏备注' : '已将备注修改为 "$remark"')));
    }
    EventBusManager.instance.fire(FavoriteAuthorUpdatedEvent(authorId: authorId, reason: UpdateReason.updated, fromFavoritePage: fromFavoriteList, fromAuthorPage: fromAuthorPage));
  }

  // => called by showPopupMenuForAuthorFavorite
  Future<void> showAndUpdateFavRemarkWithDlg({
    required FavoriteAuthor favorite,
    required void Function(FavoriteAuthor newFavorite) onUpdated,
    required bool showSnackBar,
    required bool fromFavoriteList,
    required bool fromAuthorPage,
  }) async {
    var toEdit = await showFavoriteRemarkDialog(context: context, remark: favorite.remark.trim(), authorName: authorName);
    if (toEdit) {
      await updateFavRemarkWithDlg(
        oldFavorite: favorite,
        onUpdated: onUpdated,
        showSnackBar: showSnackBar,
        fromFavoriteList: fromFavoriteList,
        fromAuthorPage: fromAuthorPage,
      );
    }
  }
}
