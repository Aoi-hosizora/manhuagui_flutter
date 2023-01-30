import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/author.dart';
import 'package:manhuagui_flutter/page/favorite_author.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 作者列表页-作者弹出菜单
/// 作者收藏页-修改备注对话框
/// 作者页-作者收藏对话框

// => called by pages which contains author line view
void showPopupMenuForAuthorList({
  required BuildContext context,
  required int authorId,
  required String authorName,
  required String authorCover,
  required String authorUrl,
  required String authorZone,
  bool fromFavoriteList = false,
  void Function(bool inFavorite)? inFavoriteSetter,
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
  void pop(BuildContext context, VoidCallback callback) {
    Navigator.of(context).pop();
    callback();
  }

  showDialog(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text(authorName),
      children: [
        /// 查看作者
        IconTextDialogOption(
          icon: Icon(Icons.person),
          text: Text('查看该作者'),
          onPressed: () => pop(c, () => helper.gotoAuthorPage()),
        ),
        IconTextDialogOption(
          icon: Icon(Icons.open_in_browser),
          text: Text('用浏览器打开'),
          onPressed: () => pop(c, () => helper.launchBrowser()),
        ),
        Divider(height: 16, thickness: 1),

        /// 收藏
        IconTextDialogOption(
          icon: Icon(!nowInFavorite ? MdiIcons.bookmarkPlus : MdiIcons.bookmarkMinus),
          text: Text(!nowInFavorite ? '添加本地收藏' : '取消本地收藏'),
          onPressed: () => pop(
            c,
            () => !nowInFavorite //
                ? helper.addToFavorite(onAdded: (_) => inFavoriteSetter?.call(true), fromFavoriteList: fromFavoriteList, fromAuthorPage: false)
                : helper.removeFromFavorite(onRemoved: () => inFavoriteSetter?.call(false), fromFavoriteList: fromFavoriteList, fromAuthorPage: false),
          ),
        ),
      ],
    ),
  );
}

// => called in FavoriteAuthorPage
void showUpdateFavoriteAuthorRemarkDialog({
  required BuildContext context,
  required FavoriteAuthor favoriteAuthor,
  required void Function(FavoriteAuthor newFavorite) onUpdated,
}) async {
  var helper = _DialogHelper(
    context: context,
    authorId: favoriteAuthor.authorId,
    authorName: favoriteAuthor.authorName,
    authorCover: favoriteAuthor.authorCover,
    authorUrl: favoriteAuthor.authorUrl,
    authorZone: favoriteAuthor.authorZone,
  );
  await helper.updateFavoriteRemark(
    oldFavorite: favoriteAuthor,
    onUpdated: onUpdated,
    showSnackBar: false,
    fromFavoriteList: true /* <<< only for favorite list */,
    fromAuthorPage: false,
  );
}

// => called in AuthorPage
void showPopupMenuForAuthorFavorite({
  required BuildContext context,
  required int authorId,
  required String authorName,
  required String authorCover,
  required String authorUrl,
  required String authorZone,
  required FavoriteAuthor? favoriteAuthor,
  required void Function(FavoriteAuthor? favorite) favoriteSetter,
}) {
  var helper = _DialogHelper(
    context: context,
    authorId: authorId,
    authorName: authorName,
    authorCover: authorCover,
    authorUrl: authorUrl,
    authorZone: authorZone,
  );
  void pop(BuildContext context, VoidCallback callback) {
    Navigator.of(context).pop();
    callback();
  }

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
            onPressed: () => pop(c, () => helper.addToFavorite(onAdded: favoriteSetter, fromFavoriteList: false, fromAuthorPage: true)),
          ),
        if (favoriteAuthor != null)
          IconTextDialogOption(
            icon: Icon(Icons.bookmark),
            text: Text('取消本地收藏'),
            onPressed: () => pop(c, () => helper.removeFromFavorite(onRemoved: () => favoriteSetter(null), fromFavoriteList: false, fromAuthorPage: true)),
          ),

        /// 额外选项
        Divider(thickness: 1),
        IconTextDialogOption(
          icon: Icon(Icons.people),
          text: Text('查看已收藏的作者'),
          onPressed: () => pop(c, () => helper.gotoFavoritesPage()),
        ),
        if (favoriteAuthor != null)
          IconTextDialogOption(
            icon: Icon(MdiIcons.commentBookmark),
            text: Flexible(
              child: Text('当前收藏备注：${favoriteAuthor.remark.trim().isEmpty ? '暂无' : favoriteAuthor.remark.trim()}', maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            onPressed: () => pop(c, () => helper.updateFavoriteRemark(oldFavorite: favoriteAuthor, onUpdated: favoriteSetter, showSnackBar: true, fromFavoriteList: false, fromAuthorPage: true)),
          ),
      ],
    ),
  );
}

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

  // ============================
  // static methods (show dialog)
  // ============================

  static Future<String?> showAddToFavoriteDialog({
    required BuildContext context,
  }) async {
    var controller = TextEditingController(); // remark
    var ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => StatefulBuilder(
        builder: (_, _setState) => AlertDialog(
          title: Text('收藏漫画作者'),
          content: SizedBox(
            width: getDialogContentMaxWidth(context),
            child: TextField(
              controller: controller,
              maxLines: 1,
              autofocus: true,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 5),
                labelText: '漫画备注',
                icon: Icon(MdiIcons.commentBookmarkOutline),
              ),
            ),
          ),
          actions: [
            TextButton(child: Text('确定'), onPressed: () => Navigator.of(c).pop(true)),
            TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
          ],
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
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text('修改收藏备注'),
        content: SizedBox(
          width: getDialogContentMaxWidth(context),
          child: TextField(
            controller: controller,
            maxLines: 1,
            autofocus: true,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 5),
              labelText: '漫画备注',
              icon: Icon(MdiIcons.commentBookmarkOutline),
            ),
          ),
        ),
        actions: [
          if (remark.isNotEmpty)
            TextButton(
              child: Text('复制原备注'),
              onPressed: () => copyText(remark, showToast: true),
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
            onPressed: () => Navigator.of(c).pop(false),
          ),
        ],
      ),
    );
    if (ok != true) {
      return null;
    }

    return controller.text.trim(); // remark, empty-able
  }

  // =======================
  // helper methods (others)
  // =======================

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

  void launchBrowser() {
    launchInBrowser(
      context: context,
      url: authorUrl,
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

  // ===================================
  // methods (add and remove and update)
  // ===================================

  // => called by showPopupMenuForAuthorList, showPopupMenuForAuthorFavorite
  Future<void> addToFavorite({
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
  Future<void> removeFromFavorite({
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

  // => called by showUpdateFavoriteAuthorRemarkDialog, showPopupMenuForAuthorFavorite
  Future<void> updateFavoriteRemark({
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
}
