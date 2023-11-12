import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/author.dart';
import 'package:manhuagui_flutter/page/author_detail.dart';
import 'package:manhuagui_flutter/page/favorite_author.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

part 'author_dialog_helper.dart';

/// 作者列表页-作者弹出菜单 [showPopupMenuForAuthorList]
/// 作者收藏页-修改备注对话框 [showUpdateFavoriteAuthorRemarkDialog]
/// 作者页-作者收藏对话框 [showPopupMenuForAuthorFavorite]
/// 作者列表页/收藏作者页-寻找ID对话框 [showFindAuthorByIdDialog]
/// 作者页-作者名对话框 [showPopupMenuForAuthorName]

// => called by pages which contains author line view (tiny / favorite)
Future<void> showPopupMenuForAuthorList({
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
              ? helper.addFavoriteWithDlg(onAdded: (_) => inFavoriteSetter?.call(true), fromFavoriteList: fromFavoriteList, fromAuthorPage: false)
              : helper.removeFavorite(onRemoved: () => inFavoriteSetter?.call(false), fromFavoriteList: fromFavoriteList, fromAuthorPage: false),
        ),
      ],
    ),
  );
}

// => called in FavoriteAuthorPage
Future<void> showUpdateFavoriteAuthorRemarkDialog({
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
  await helper.updateFavRemarkWithDlg(
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
            onPressed: () => helper.addFavoriteWithDlg(onAdded: favoriteSetter, fromFavoriteList: false, fromAuthorPage: true),
          ),
        if (favoriteAuthor != null)
          IconTextDialogOption(
            icon: Icon(Icons.bookmark),
            text: Text('取消本地收藏'),
            popWhenPress: c,
            predicateForPress: () => helper.showCheckRemovingFavoriteDialog(),
            onPressed: () => helper.removeFavorite(onRemoved: () => favoriteSetter(null), fromFavoriteList: false, fromAuthorPage: true),
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
            onPressed: () => helper.showAndUpdateFavRemarkWithDlg(favorite: favoriteAuthor, onUpdated: favoriteSetter, showSnackBar: true, fromFavoriteList: false, fromAuthorPage: true),
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
