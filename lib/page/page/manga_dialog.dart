import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/author.dart';
import 'package:manhuagui_flutter/page/download_manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/simple_widgets.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/db/shelf_cache.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';

/// 各个列表页-漫画弹出菜单 & 漫画作者弹出菜单
/// 漫画收藏页-移动分组对话框 & 修改备注对话框
/// 漫画页/章节页-漫画订阅对话框

void showPopupMenuForMangaList({
  required BuildContext context,
  required int mangaId,
  required String mangaTitle,
  required String mangaCover,
  required String mangaUrl,
  bool mustInShelf = false,
  void Function(bool inShelf)? inShelfSetter, // TODO update ShelfSubPage
  void Function(bool inFavorite)? inFavoriteSetter, // TODO update FavoriteSubPage
  void Function(bool inHistory)? inHistorySetter, // TODO update HistorySubPage
}) async {
  var nowInDownload = await DownloadDao.checkMangaExistence(mid: mangaId) ?? false;
  var nowInFavorite = await FavoriteDao.checkExistence(username: AuthManager.instance.username, mid: mangaId) ?? false;
  var mangaHistory = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: mangaId);

  var helper = _DialogHelper(
    context: context,
    mangaId: mangaId,
    mangaTitle: mangaTitle,
    mangaCover: mangaCover,
    mangaUrl: mangaUrl,
  );
  Future<void> pop(BuildContext context, VoidCallback callback) async {
    Navigator.of(context).pop();
    callback();
  }

  // TODO adjust icons

  var expandShelfOptions = false;
  showDialog(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (_, _setState) => SimpleDialog(
        title: Text(mangaTitle),
        children: [
          /// 查看漫画
          IconTextDialogOption(
            icon: Icon(Icons.arrow_forward),
            text: Text('查看该漫画'),
            onPressed: () => pop(c, () => helper.gotoMangaPage()),
          ),
          IconTextDialogOption(
            icon: Icon(Icons.open_in_browser),
            text: Text('用浏览器打开'),
            onPressed: () => pop(c, () => helper.launchBrowser()),
          ),
          Divider(height: 16, thickness: 1),

          /// 下载
          if (nowInDownload)
            IconTextDialogOption(
              icon: Icon(Icons.download),
              text: Text('查看下载详情'),
              onPressed: () => pop(c, () => helper.gotoDownloadPage()),
            ),

          /// 书架
          if (AuthManager.instance.logined && mustInShelf)
            IconTextDialogOption(
              icon: Icon(Icons.star),
              text: Text('移出我的书架'),
              onPressed: () => pop(c, () => helper.addToOrRemoveFromShelf(toAdd: false, subscribing: null, onUpdated: inShelfSetter)),
            ),
          if (AuthManager.instance.logined && !mustInShelf) ...[
            if (!expandShelfOptions)
              IconTextDialogOption(
                icon: Icon(Icons.star_half),
                text: Text('管理我的书架'),
                onPressed: () => _setState(() => expandShelfOptions = true),
              ),
            if (expandShelfOptions)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                ),
                child: EdgeInsets.symmetric(horizontal: 24.0 - 10, vertical: 10.0) /* _kIconTextDialogOptionPadding */ .let(
                  (optionPadding) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconTextDialogOption(
                        icon: Icon(Icons.star_half, color: Colors.black26),
                        text: Text('隐藏'),
                        padding: optionPadding,
                        onPressed: () => _setState(() => expandShelfOptions = false),
                      ),
                      IconTextDialogOption(
                        icon: Icon(Icons.star_border),
                        text: Text('放入我的书架'),
                        padding: optionPadding,
                        onPressed: () => pop(c, () => helper.addToOrRemoveFromShelf(toAdd: true, subscribing: null, onUpdated: inShelfSetter)),
                      ),
                      IconTextDialogOption(
                        icon: Icon(Icons.star),
                        text: Text('移出我的书架'),
                        padding: optionPadding,
                        onPressed: () => pop(c, () => helper.addToOrRemoveFromShelf(toAdd: false, subscribing: null, onUpdated: inShelfSetter)),
                      ),
                    ],
                  ),
                ),
              ),
          ],

          /// 收藏
          IconTextDialogOption(
            icon: Icon(!nowInFavorite ? Icons.bookmark_border : Icons.bookmark),
            text: Text(!nowInFavorite ? '添加本地收藏' : '取消本地收藏'),
            onPressed: () => pop(
              c,
              () => !nowInFavorite //
                  ? helper.addToFavorite(subscribing: null, onAdded: (_) => inFavoriteSetter?.call(true))
                  : helper.removeFromFavorite(subscribing: null, onRemoved: () => inFavoriteSetter?.call(false)),
            ),
          ),

          /// 历史
          if (mangaHistory != null)
            IconTextDialogOption(
              icon: CustomIcon(!mangaHistory.read ? CustomIcons.opened_empty_book : Icons.import_contacts),
              text: Text(!mangaHistory.read ? '删除浏览历史' : '删除阅读历史'),
              onPressed: () => pop(c, () => helper.removeHistory(onRemoved: () => inHistorySetter?.call(false), showSnackBar: true)),
            ),
        ],
      ),
    ),
  );
}

void showPopupMenuForAuthorList({
  required BuildContext context,
  required int authorId,
  required String authorName,
  required String authorUrl,
}) {
  showDialog(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text(authorName),
      children: [
        IconTextDialogOption(
          icon: Icon(Icons.arrow_forward),
          text: Text('查看该作者'),
          onPressed: () {
            Navigator.of(c).pop();
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
          },
        ),
        IconTextDialogOption(
          icon: Icon(Icons.open_in_browser),
          text: Text('用浏览器打开'),
          onPressed: () {
            Navigator.of(c).pop();
            launchInBrowser(context: context, url: authorUrl);
          },
        ),
      ],
    ),
  );
}

void showUpdateFavoritesGroupDialog({
  required BuildContext context,
  required List<FavoriteManga> favorites,
  required String selectedGroupName,
  required void Function(List<FavoriteManga> newFavorites, bool addToTop) onUpdated,
}) async {
  var helper = _DialogHelper(
    context: context,
    mangaId: 0 /* not be used here */,
    mangaTitle: '',
    mangaCover: '',
    mangaUrl: '',
  );
  await helper.updateFavoritesGroup(
    oldFavorites: favorites,
    selectedGroupName: selectedGroupName,
    onUpdated: onUpdated,
    showToast: true,
    notifyFavList: false,
  );
}

void showUpdateFavoriteRemarkDialog({
  required BuildContext context,
  required FavoriteManga favorite,
  required void Function(FavoriteManga newFavorite) onUpdated,
}) async {
  var helper = _DialogHelper(
    context: context,
    mangaId: favorite.mangaId,
    mangaTitle: favorite.mangaTitle,
    mangaCover: favorite.mangaCover,
    mangaUrl: favorite.mangaUrl,
  );
  await helper.updateFavoriteRemark(
    oldFavorite: favorite,
    onUpdated: onUpdated,
    showSnackBar: false,
    notifyFavList: false,
  );
}

void showPopupMenuForSubscribing({
  required BuildContext context,
  required int mangaId,
  required String mangaTitle,
  required String mangaCover,
  required String mangaUrl,
  required bool nowInShelf,
  required bool nowInFavorite,
  required int? subscribeCount,
  required FavoriteManga? favoriteManga,
  required void Function(bool subscribing) subscribing,
  required void Function(bool inShelf) inShelfSetter,
  required void Function(bool inFavorite) inFavoriteSetter,
  required void Function(FavoriteManga? favorite) favoriteSetter,
}) {
  var helper = _DialogHelper(
    context: context,
    mangaId: mangaId,
    mangaTitle: mangaTitle,
    mangaCover: mangaCover,
    mangaUrl: mangaUrl,
  );
  void pop(BuildContext context, VoidCallback callback) {
    Navigator.of(context).pop();
    callback();
  }

  showDialog(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text('订阅《$mangaTitle》'),
      children: [
        /// 书架
        if (AuthManager.instance.logined && !nowInShelf)
          IconTextDialogOption(
            icon: Icon(Icons.star_border),
            text: Text('放入我的书架'),
            onPressed: () => pop(c, () => helper.addToOrRemoveFromShelf(toAdd: true, subscribing: subscribing, onUpdated: inShelfSetter)),
          ),
        if (AuthManager.instance.logined && nowInShelf)
          IconTextDialogOption(
            icon: Icon(Icons.star),
            text: Text('移出我的书架'),
            onPressed: () => pop(c, () => helper.addToOrRemoveFromShelf(toAdd: false, subscribing: subscribing, onUpdated: inShelfSetter)),
          ),

        /// 收藏
        if (!nowInFavorite)
          IconTextDialogOption(
            icon: Icon(Icons.bookmark_border),
            text: Text('添加本地收藏'),
            onPressed: () => pop(
              c,
              () => helper.addToFavorite(
                subscribing: subscribing,
                onAdded: (f) {
                  inFavoriteSetter.call(true);
                  favoriteSetter.call(f);
                },
              ),
            ),
          ),
        if (nowInFavorite)
          IconTextDialogOption(
            icon: Icon(Icons.bookmark),
            text: Text('取消本地收藏'),
            onPressed: () => pop(
              c,
              () => helper.removeFromFavorite(
                subscribing: subscribing,
                onRemoved: () {
                  inFavoriteSetter.call(false);
                  favoriteSetter.call(null);
                },
              ),
            ),
          ),

        /// 额外选项
        if (subscribeCount != null || favoriteManga != null) ...[
          Divider(height: 16, thickness: 1),
          if (subscribeCount != null)
            IconTextDialogOption(
              icon: Icon(Icons.stars),
              text: Text('共 $subscribeCount 人将漫画放入书架'),
              onPressed: () {},
            ),
          if (favoriteManga != null)
            IconTextDialogOption(
              icon: Icon(Icons.folder),
              text: Flexible(
                child: Text('当前收藏分组：${favoriteManga.checkedGroupName}', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              onPressed: () => pop(c, () => helper.updateFavoriteGroup(oldFavorite: favoriteManga, onUpdated: favoriteSetter)),
            ),
          if (favoriteManga != null)
            IconTextDialogOption(
              icon: Icon(Icons.comment_bank),
              text: Flexible(
                child: Text('当前收藏备注：${favoriteManga.remark.trim().isEmpty ? '暂无' : favoriteManga.remark.trim()}', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              onPressed: () => pop(c, () => helper.updateFavoriteRemark(oldFavorite: favoriteManga, onUpdated: favoriteSetter)),
            ),
        ],
      ],
    ),
  );
}

class _DialogHelper {
  const _DialogHelper({
    required this.context,
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
  });

  final BuildContext context;
  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;

  static Future<Tuple3<String, String, bool>?> showAddToFavoriteDialog({
    required BuildContext context,
    required List<FavoriteGroup> groups,
  }) async {
    var groupName = ''; // group
    var controller = TextEditingController(); // remark
    var addToTop = false; // order, 默认添加到末尾

    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (_, _setState) => AlertDialog(
          title: Text('收藏漫画'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TODO hide keyboard first, https://github.com/flutter/flutter/issues/22075
              Container(
                width: getDialogContentMaxWidth(context),
                padding: EdgeInsets.only(left: 5, right: 5, bottom: 12),
                child: CustomCombobox<String>(
                  value: groupName,
                  items: [
                    for (var group in groups)
                      CustomComboboxItem(
                        value: group.groupName,
                        text: group.checkedGroupName,
                      ),
                  ],
                  onChanged: (v) => v?.let((v) => _setState(() => groupName = v)),
                  textStyle: Theme.of(context).textTheme.subtitle1,
                ),
              ),
              Container(
                width: getDialogContentMaxWidth(context),
                padding: EdgeInsets.only(left: 8, right: 12, bottom: 12),
                child: TextField(
                  controller: controller,
                  maxLines: 1,
                  autofocus: false,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                    labelText: '漫画备注',
                    icon: Padding(
                      padding: EdgeInsets.only(right: 2),
                      child: Icon(Icons.comment_bank_outlined),
                    ),
                  ),
                ),
              ),
              CheckboxListTile(
                title: Text('添加至本地收藏顶部'),
                value: addToTop,
                onChanged: (v) => _setState(() => addToTop = v ?? false),
                visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
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

    return Tuple3(
      groupName, // group
      controller.text.trim(), // remark
      addToTop, // order
    );
  }

  static Future<Tuple2<FavoriteGroup, bool>?> showChooseFavoriteGroupDialog({
    required BuildContext context,
    required List<FavoriteGroup> groups,
    required String selectedGroupName,
  }) async {
    var addToTop = false; // order, 默认添加到末尾
    var group = await showDialog<FavoriteGroup>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('移动收藏至分组'),
        children: [
          for (var group in groups)
            TextDialogOption(
              text: Text(
                group.checkedGroupName,
                style: group.groupName != selectedGroupName //
                    ? null
                    : TextStyle(color: Theme.of(context).primaryColor),
              ),
              onPressed: () => Navigator.of(c).pop(group),
            ),
          CheckBoxDialogOption(
            initialValue: addToTop,
            onChanged: (v) => addToTop = v,
            text: '添加至本地收藏顶部',
          ),
        ],
      ),
    );
    if (group == null) {
      return null;
    }

    return Tuple2(
      group, // group
      addToTop, // order
    );
  }

  static Future<Tuple1<String>?> showEditFavoriteRemarkDialog({
    required BuildContext context,
    required String remark,
  }) async {
    var controller = TextEditingController()..text = remark; // remark
    var ok = await showDialog<bool>(
      context: context,
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
              icon: Icon(Icons.comment_bank_outlined),
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
          TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
        ],
      ),
    );
    if (ok != true) {
      return null;
    }

    return Tuple1(
      controller.text.trim(), // remark, empty-able
    );
  }

  void gotoMangaPage() {
    Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => MangaPage(
          id: mangaId,
          title: mangaTitle,
          url: mangaUrl,
        ),
      ),
    );
  }

  void launchBrowser() {
    launchInBrowser(
      context: context,
      url: mangaUrl,
    );
  }

  void gotoDownloadPage() {
    Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => DownloadMangaPage(
          mangaId: mangaId,
        ),
        settings: DownloadMangaPage.buildRouteSetting(
          mangaId: mangaId,
        ),
      ),
    );
  }

  Future<void> addToOrRemoveFromShelf({
    required bool toAdd,
    required void Function(bool subscribing)? subscribing,
    required void Function(bool inShelf)? onUpdated,
  }) async {
    final client = RestClient(DioManager.instance.dio);
    subscribing?.call(true);

    bool? added;
    try {
      await (toAdd ? client.addToShelf : client.removeFromShelf)(token: AuthManager.instance.token, mid: mangaId);
      added = toAdd;
      onUpdated?.call(added);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(added ? '成功将漫画放入书架' : '成功将漫画移出书架')));
      EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inShelf: added));
    } catch (e, s) {
      var err = wrapError(e, s).text;
      var already = err.contains('已经被'), notYet = err.contains('还没有被');
      if (already || notYet) {
        added = already;
        onUpdated?.call(added);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(added ? '漫画已经在书架上' : '漫画还未在书架上')));
        EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inShelf: added));
      } else {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toAdd ? '放入书架失败，$err' : '移出书架失败，$err')));
      }
    } finally {
      subscribing?.call(false);
    }

    if (added == true) {
      var cache = ShelfCache(mangaId: mangaId, mangaTitle: mangaTitle, mangaCover: mangaCover, mangaUrl: mangaUrl, cachedAt: DateTime.now());
      await ShelfCacheDao.addOrUpdateShelfCache(username: AuthManager.instance.username, cache: cache);
      EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: mangaId, inShelf: true));
    } else if (added == false) {
      await ShelfCacheDao.deleteShelfCache(username: AuthManager.instance.username, mangaId: mangaId);
      EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: mangaId, inShelf: false));
    }
  }

  Future<void> addToFavorite({
    required void Function(bool subscribing)? subscribing,
    required void Function(FavoriteManga newFavorite)? onAdded,
  }) async {
    var groups = await FavoriteDao.getGroups(username: AuthManager.instance.username);
    if (groups == null) {
      return;
    }
    var result = await showAddToFavoriteDialog(context: context, groups: groups);
    if (result == null) {
      return;
    }

    var groupName = result.item1;
    var remark = result.item2;
    var addToTop = result.item3;
    subscribing?.call(true);
    try {
      var order = await FavoriteDao.getFavoriteNewOrder(username: AuthManager.instance.username, groupName: groupName, addToTop: addToTop);
      var newFavorite = FavoriteManga(
        mangaId: mangaId,
        mangaTitle: mangaTitle,
        mangaCover: mangaCover,
        mangaUrl: mangaUrl,
        remark: remark,
        groupName: groupName,
        order: order,
        createdAt: DateTime.now(),
      );
      await FavoriteDao.addOrUpdateFavorite(username: AuthManager.instance.username, favorite: newFavorite);
      onAdded?.call(newFavorite);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功收藏漫画至 "${newFavorite.checkedGroupName}"')));
      EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inFavorite: true, changedGroup: newFavorite.groupName));
    } finally {
      subscribing?.call(false);
    }
  }

  Future<void> removeFromFavorite({
    required void Function(bool subscribing)? subscribing,
    required void Function()? onRemoved,
  }) async {
    subscribing?.call(true);
    try {
      var oldFavorite = await FavoriteDao.getFavorite(username: AuthManager.instance.username, mid: mangaId);
      await FavoriteDao.deleteFavorite(username: AuthManager.instance.username, mid: mangaId);
      onRemoved?.call();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功取消收藏漫画')));
      EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inFavorite: false, changedGroup: oldFavorite?.groupName));
    } finally {
      subscribing?.call(false);
    }
  }

  Future<void> updateFavoriteGroup({
    required FavoriteManga oldFavorite,
    required void Function(FavoriteManga newFavorite)? onUpdated,
    bool showSnackBar = true,
    bool notifyFavList = true,
  }) async {
    var groups = await FavoriteDao.getGroups(username: AuthManager.instance.username);
    if (groups == null) {
      return;
    }
    var result = await showChooseFavoriteGroupDialog(context: context, groups: groups, selectedGroupName: oldFavorite.groupName);
    if (result == null) {
      return;
    }

    var group = result.item1;
    var addToTop = result.item2;
    var order = await FavoriteDao.getFavoriteNewOrder(username: AuthManager.instance.username, groupName: group.groupName, addToTop: addToTop);
    var newFavorite = oldFavorite.copyWith(groupName: group.groupName, order: order);
    await FavoriteDao.addOrUpdateFavorite(username: AuthManager.instance.username, favorite: newFavorite);
    onUpdated?.call(newFavorite);

    if (showSnackBar) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已将漫画收藏于 "${group.checkedGroupName}"')));
    }
    if (notifyFavList) {
      EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inFavorite: true, changedGroup: oldFavorite.groupName)); // 移动分组
      EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inFavorite: true, changedGroup: newFavorite.groupName));
    } else {
      EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inFavorite: true, changedGroup: null)); // 收藏页将忽略该通知
    }
  }

  Future<void> updateFavoritesGroup({
    required List<FavoriteManga> oldFavorites, // 按照收藏列表从上到下的顺序
    required String selectedGroupName,
    required void Function(List<FavoriteManga> newFavorites, bool addToTop) onUpdated,
    bool showToast = true,
    bool notifyFavList = true,
  }) async {
    var groups = await FavoriteDao.getGroups(username: AuthManager.instance.username);
    if (groups == null) {
      return;
    }
    var result = await showChooseFavoriteGroupDialog(context: context, groups: groups, selectedGroupName: selectedGroupName);
    if (result == null) {
      return;
    }

    var group = result.item1;
    var addToTop = result.item2;
    if (addToTop) {
      oldFavorites = oldFavorites.reversed.toList(); // 移至顶部需要倒序一个一个移动，移至底部则不需要
    }
    var oldNewFavorites = <Tuple2<FavoriteManga, FavoriteManga>>[];
    for (var oldFavorite in oldFavorites) {
      var order = await FavoriteDao.getFavoriteNewOrder(username: AuthManager.instance.username, groupName: group.groupName, addToTop: addToTop);
      var newFavorite = oldFavorite.copyWith(groupName: group.groupName, order: order);
      await FavoriteDao.addOrUpdateFavorite(username: AuthManager.instance.username, favorite: newFavorite);
      oldNewFavorites.add(Tuple2(oldFavorite, newFavorite));
    }
    onUpdated(oldNewFavorites.map((t) => t.item2).toList(), addToTop);

    if (showToast) {
      Fluttertoast.showToast(msg: '已将 ${oldFavorites.length} 部漫画收藏于 "${group.checkedGroupName}"');
    }
    for (var tuple in oldNewFavorites) {
      var oldFavorite = tuple.item1;
      var newFavorite = tuple.item2;
      var mangaId = newFavorite.mangaId;
      if (notifyFavList) {
        EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inFavorite: true, changedGroup: oldFavorite.groupName)); // 移动分组
        EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inFavorite: true, changedGroup: newFavorite.groupName));
      } else {
        EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inFavorite: true, changedGroup: null)); // 本页将忽略该通知
      }
    }
  }

  Future<void> updateFavoriteRemark({
    required FavoriteManga oldFavorite,
    required void Function(FavoriteManga newFavorite) onUpdated,
    bool showSnackBar = true,
    bool notifyFavList = true,
  }) async {
    var result = await showEditFavoriteRemarkDialog(context: context, remark: oldFavorite.remark.trim());
    if (result == null) {
      return;
    }

    var newRemark = result.item;
    var newFavorite = oldFavorite.copyWith(remark: newRemark);
    await FavoriteDao.addOrUpdateFavorite(username: AuthManager.instance.username, favorite: newFavorite);
    onUpdated(newFavorite);

    if (showSnackBar) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newRemark == '' ? '已删除收藏备注' : '已将备注修改为 "$newRemark"')));
    }
    if (notifyFavList) {
      EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inFavorite: true, changedGroup: newFavorite.groupName)); // 修改备注
    } else {
      EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inFavorite: true, changedGroup: null)); // 收藏页将忽略该通知
    }
  }

  Future<void> removeHistory({
    required void Function()? onRemoved,
    bool showSnackBar = true,
  }) async {
    var ok = await HistoryDao.deleteHistory(username: AuthManager.instance.username, mid: mangaId);
    if (ok) {
      onRemoved?.call();
      if (showSnackBar) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('漫画历史已删除')));
      }
      EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: mangaId));
    }
  }
}
