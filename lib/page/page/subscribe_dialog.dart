import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/page/setting_other.dart';
import 'package:manhuagui_flutter/page/view/setting_dialog.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';

void showSubscribeDialog({
  required BuildContext context,
  required int mangaId,
  required String mangaTitle,
  required String mangaCover,
  required String mangaUrl,
  required bool nowInShelf,
  required bool nowInFavorite,
  required int? subscribeCount,
  required FavoriteManga? favoriteManga,
  required void Function(bool subscribing) subscribingSetter,
  required VoidCallback stateSetter,
  required void Function(bool inShelf) inShelfSetter,
  required void Function(bool inShelf) inFavoriteSetter,
  required void Function(FavoriteManga? favorite) favoriteMangaSetter,
}) {
  // ****************************************************************
  Future<void> addToShelf({required bool toAdd}) async {
    final client = RestClient(DioManager.instance.dio);
    subscribingSetter(true);
    stateSetter();
    try {
      await (toAdd ? client.addToShelf : client.removeFromShelf)(token: AuthManager.instance.token, mid: mangaId);
      inShelfSetter(toAdd);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toAdd ? '成功将漫画放入书架' : '成功将漫画移出书架')));
      EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inShelf: toAdd));
    } catch (e, s) {
      var err = wrapError(e, s).text;
      var already = err.contains('已经被'), notYet = err.contains('还没有被');
      if (already || notYet) {
        inShelfSetter(already);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(already ? '漫画已经在书架上' : '漫画尚未在书架上'))); // 漫画已经被订阅 / 漫画还没有被订阅
        EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inShelf: already));
      } else {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toAdd ? '放入书架失败，$err' : '移出书架失败，$err')));
      }
    } finally {
      subscribingSetter(false);
      stateSetter();
    }
  }

  // ****************************************************************
  Future<void> addToFavorite({required bool toAdd}) async {
    var groups = await FavoriteDao.getGroups(username: AuthManager.instance.username);
    var groupName = '';
    var remark = '';
    var addToTop = AppSetting.instance.other.defaultToFavoriteTop;
    if (toAdd) {
      var controller = TextEditingController();
      var ok = await showDialog<bool>(
        context: context,
        builder: (c) => StatefulBuilder(
          builder: (c, _setState) => AlertDialog(
            title: Text('收藏漫画选项'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (groups != null)
                  Container(
                    width: getDialogMaxWidth(context),
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
                  width: getDialogMaxWidth(context),
                  padding: EdgeInsets.only(left: 8, right: 12, bottom: 12),
                  child: TextField(
                    controller: controller,
                    maxLines: 1,
                    autofocus: true,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 5),
                      labelText: '漫画备注',
                      icon: Padding(
                        padding: EdgeInsets.only(right: 2),
                        child: Icon(Icons.comment_bank),
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
        return;
      }
      remark = controller.text.trim();
      await updateOtherSettingDefaultToFavToTop(addToTop);
    }

    subscribingSetter(true);
    stateSetter();
    FavoriteManga? newFavorite, oldFavorite;
    try {
      var username = AuthManager.instance.username;
      if (toAdd) {
        var order = await FavoriteDao.getFavoriteNewOrder(username: username, groupName: groupName, addToTop: addToTop);
        newFavorite = FavoriteManga(
          mangaId: mangaId,
          mangaTitle: mangaTitle,
          mangaCover: mangaCover,
          mangaUrl: mangaUrl,
          remark: remark,
          groupName: groupName,
          order: order,
          createdAt: DateTime.now(),
        );
        await FavoriteDao.addOrUpdateFavorite(username: username, favorite: newFavorite);
        favoriteMangaSetter(newFavorite);
      } else {
        oldFavorite = await FavoriteDao.getFavorite(username: username, mid: mangaId);
        await FavoriteDao.deleteFavorite(username: username, mid: mangaId);
        favoriteMangaSetter(null);
      }
      inFavoriteSetter(toAdd);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toAdd ? '成功收藏漫画至 "${newFavorite?.checkedGroupName}"' : '成功取消收藏漫画')));
      EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inFavorite: toAdd, changedGroup: toAdd ? newFavorite?.groupName : oldFavorite?.groupName));
    } finally {
      subscribingSetter(false);
      stateSetter();
    }
  }

  // ****************************************************************
  Future<void> updateFavorite({required bool updateGroup, required bool updateRemark}) async {
    var oldFavorite = favoriteManga;
    if (oldFavorite == null) {
      return;
    }

    if (updateGroup) {
      var groups = await FavoriteDao.getGroups(username: AuthManager.instance.username);
      if (groups == null) {
        return;
      }
      var addToTop = AppSetting.instance.other.defaultToFavoriteTop;
      showDialog(
        context: context,
        builder: (c) => SimpleDialog(
          title: Text('移动收藏至分组'),
          children: [
            for (var group in groups)
              TextDialogOption(
                text: Text(
                  group.checkedGroupName,
                  style: TextStyle(color: group.groupName == oldFavorite.groupName ? Theme.of(context).primaryColor : null),
                ),
                onPressed: () async {
                  Navigator.of(c).pop();
                  await updateOtherSettingDefaultToFavToTop(addToTop);
                  var newGroupName = group.groupName;
                  var order = await FavoriteDao.getFavoriteNewOrder(username: AuthManager.instance.username, groupName: newGroupName, addToTop: addToTop);
                  var newFavorite = oldFavorite.copyWith(groupName: newGroupName, order: order);
                  await FavoriteDao.addOrUpdateFavorite(
                    username: AuthManager.instance.username,
                    favorite: newFavorite,
                  );
                  favoriteMangaSetter(newFavorite);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已将漫画收藏于 "${newFavorite.checkedGroupName}"')));
                  EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inFavorite: true, changedGroup: oldFavorite.groupName)); // 移动分组
                  EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inFavorite: true, changedGroup: newFavorite.groupName));
                  stateSetter();
                },
              ),
            CheckBoxDialogOption(
              initialValue: addToTop,
              onChanged: (v) => addToTop = v,
              text: '添加至本地收藏顶部',
            ),
          ],
        ),
      );
    }

    if (updateRemark) {
      var controller = TextEditingController()..text = oldFavorite.remark.trim();
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('修改收藏备注'),
          content: Container(
            width: getDialogMaxWidth(context),
            child: TextField(
              controller: controller,
              maxLines: 1,
              autofocus: true,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 5),
                labelText: '漫画备注',
                icon: Icon(Icons.comment_bank),
              ),
            ),
          ),
          actions: [
            if (oldFavorite.remark.trim().isNotEmpty)
              TextButton(
                child: Text('复制原备注'),
                onPressed: () => copyText(oldFavorite.remark.trim(), showToast: true),
              ),
            TextButton(
              child: Text('确定'),
              onPressed: () async {
                var newRemark = controller.text.trim();
                if (newRemark == oldFavorite.remark) {
                  Fluttertoast.showToast(msg: '备注没有变更');
                  return;
                }
                Navigator.of(c).pop();
                var newFavorite = oldFavorite.copyWith(remark: newRemark);
                await FavoriteDao.addOrUpdateFavorite(
                  username: AuthManager.instance.username,
                  favorite: newFavorite,
                );
                favoriteMangaSetter(newFavorite);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newFavorite.remark == '' ? '已删除收藏备注' : '已将备注修改为 "${newFavorite.remark}"')));
                EventBusManager.instance.fire(SubscribeUpdatedEvent(mangaId: mangaId, inFavorite: true, changedGroup: newFavorite.groupName));
                stateSetter();
              },
            ),
            TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop()),
          ],
        ),
      );
    }
  }

  // ****************************************************************
  void pop(BuildContext context, VoidCallback callback) {
    Navigator.of(context).pop();
    callback();
  }

  // ****************************************************************
  showDialog(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text('订阅《$mangaTitle》'),
      children: [
        if (AuthManager.instance.logined && !nowInShelf)
          IconTextDialogOption(
            icon: Icon(Icons.star_border, color: Colors.grey[800]),
            text: Text('放入我的书架'),
            onPressed: () => pop(c, () => addToShelf(toAdd: true)),
          ),
        if (AuthManager.instance.logined && nowInShelf)
          IconTextDialogOption(
            icon: Icon(Icons.star, color: Colors.grey[800]),
            text: Text('移出我的书架'),
            onPressed: () => pop(c, () => addToShelf(toAdd: false)),
          ),
        if (!nowInFavorite)
          IconTextDialogOption(
            icon: Icon(Icons.bookmark_border, color: Colors.grey[800]),
            text: Text('添加本地收藏'),
            onPressed: () => pop(c, () => addToFavorite(toAdd: true)),
          ),
        if (nowInFavorite)
          IconTextDialogOption(
            icon: Icon(Icons.bookmark, color: Colors.grey[800]),
            text: Text('取消本地收藏'),
            onPressed: () => pop(c, () => addToFavorite(toAdd: false)),
          ),
        if (subscribeCount != null || favoriteManga != null) ...[
          Divider(height: 16, thickness: 1),
          if (subscribeCount != null)
            IconTextDialogOption(
              icon: Icon(Icons.stars, color: Colors.grey[800]),
              text: Text('共 $subscribeCount 人将漫画放入书架'),
              onPressed: () {},
            ),
          if (favoriteManga != null)
            IconTextDialogOption(
              icon: Icon(Icons.label, color: Colors.grey[800]),
              text: Flexible(
                child: Text('当前收藏分组：${favoriteManga.checkedGroupName}', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              onPressed: () => pop(c, () => updateFavorite(updateGroup: true, updateRemark: false)),
            ),
          if (favoriteManga != null)
            IconTextDialogOption(
              icon: Icon(Icons.comment_bank, color: Colors.grey[800]),
              text: Flexible(
                child: Text('当前收藏备注：${favoriteManga.remark.trim().isEmpty ? '暂无' : favoriteManga.remark.trim()}', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              onPressed: () => pop(c, () => updateFavorite(updateGroup: false, updateRemark: true)),
            ),
        ],
      ],
    ),
  );
}
