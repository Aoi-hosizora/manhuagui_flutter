import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/chapter_detail.dart';
import 'package:manhuagui_flutter/page/download_manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/manga_viewer.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
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
import 'package:manhuagui_flutter/service/storage/download_task.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 漫画列表页-漫画弹出菜单 [showPopupMenuForMangaList]
/// 漫画收藏页-移动分组对话框 [showUpdateFavoriteMangasGroupDialog]
/// 漫画收藏页-修改备注对话框 [showUpdateFavoriteMangaRemarkDialog]
/// 漫画页-漫画章节弹出菜单 [showPopupMenuForMangaToc]
/// 漫画页/章节页-漫画订阅对话框 [showPopupMenuForSubscribing]

// => called by pages which contains manga line view (tiny / ranking / *shelf* / *favorite* / *history* / download)
void showPopupMenuForMangaList({
  required BuildContext context,
  required int mangaId,
  required String mangaTitle,
  required String mangaCover,
  required String mangaUrl,
  bool fromShelfList = false,
  bool fromFavoriteList = false,
  bool fromHistoryList = false,
  void Function(bool inShelf)? inShelfSetter,
  void Function(bool inFavorite)? inFavoriteSetter,
  void Function(bool inHistory)? inHistorySetter,
}) async {
  var nowInDownload = await DownloadDao.checkMangaExistence(mid: mangaId) ?? false;
  var nowInFavorite = await FavoriteDao.checkExistence(username: AuthManager.instance.username, mid: mangaId) ?? false;
  var mangaHistory = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: mangaId);
  var expandShelfOptions = false;

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
    builder: (c) => StatefulBuilder(
      builder: (_, _setState) => SimpleDialog(
        title: Text(mangaTitle),
        children: [
          /// 基本选项
          IconTextDialogOption(
            icon: Icon(Icons.description_outlined),
            text: Text('查看该漫画'),
            onPressed: () => pop(c, () => helper.gotoMangaPage()),
          ),
          IconTextDialogOption(
            icon: Icon(Icons.copy),
            text: Text('复制漫画标题'),
            onPressed: () => copyText(mangaTitle, showToast: true),
          ),
          IconTextDialogOption(
            icon: Icon(Icons.open_in_browser),
            text: Text('用浏览器打开'),
            onPressed: () => pop(c, () => launchInBrowser(context: context, url: mangaUrl)),
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
          if (AuthManager.instance.logined && fromShelfList)
            IconTextDialogOption(
              icon: Icon(MdiIcons.starMinus),
              text: Text('移出我的书架'),
              onPressed: () => pop(
                c,
                () => helper.addOrRemoveShelf(toAdd: false, subscribing: null, onUpdated: inShelfSetter, fromShelfList: fromShelfList, fromMangaPage: false),
              ),
            ),
          if (AuthManager.instance.logined && !fromShelfList) ...[
            if (!expandShelfOptions)
              IconTextDialogOption(
                icon: Icon(MdiIcons.starCog),
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
                        icon: Icon(MdiIcons.starCog, color: Colors.black26),
                        text: Text('隐藏选项'),
                        padding: optionPadding,
                        onPressed: () => _setState(() => expandShelfOptions = false),
                      ),
                      IconTextDialogOption(
                        icon: Icon(MdiIcons.starPlus),
                        text: Text('放入我的书架'),
                        padding: optionPadding,
                        onPressed: () => pop(
                          c,
                          () => helper.addOrRemoveShelf(toAdd: true, subscribing: null, onUpdated: inShelfSetter, fromShelfList: fromShelfList, fromMangaPage: false),
                        ),
                      ),
                      IconTextDialogOption(
                        icon: Icon(MdiIcons.starMinus),
                        text: Text('移出我的书架'),
                        padding: optionPadding,
                        onPressed: () => pop(
                          c,
                          () => helper.addOrRemoveShelf(toAdd: false, subscribing: null, onUpdated: inShelfSetter, fromShelfList: fromShelfList, fromMangaPage: false),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],

          /// 收藏
          IconTextDialogOption(
            icon: Icon(!nowInFavorite ? CustomIcons.bookmark_plus : CustomIcons.bookmark_minus),
            text: Text(!nowInFavorite ? '添加本地收藏' : '取消本地收藏'),
            onPressed: () => pop(
              c,
              () => !nowInFavorite //
                  ? helper.addFavorite(subscribing: null, onAdded: (_) => inFavoriteSetter?.call(true), fromFavoriteList: fromFavoriteList, fromMangaPage: false)
                  : helper.removeFavorite(subscribing: null, onRemoved: () => inFavoriteSetter?.call(false), fromFavoriteList: fromFavoriteList, fromMangaPage: false),
            ),
          ),

          /// 历史
          if (mangaHistory != null)
            IconTextDialogOption(
              icon: Icon(MdiIcons.deleteClock), // use MdiIcons.deleteClock rather than Icons.auto_delete to align icons
              text: Text(!mangaHistory.read ? '删除浏览历史' : '删除阅读历史'),
              onPressed: () => pop(
                c,
                () => helper.removeHistory(oldHistory: mangaHistory, onRemoved: () => inHistorySetter?.call(false), fromHistoryList: fromHistoryList, fromMangaPage: false),
              ),
            ),
        ],
      ),
    ),
  );
}

// => called in FavoriteSubPage and FavoriteAllPage
void showUpdateFavoriteMangasGroupDialog({
  required BuildContext context,
  required List<FavoriteManga> favorites,
  required String? selectedGroupName,
  bool fromFavoriteList = false,
  required void Function(List<FavoriteManga> newFavorites, bool addToTop) onUpdated,
}) async {
  var helper = _DialogHelper(
    context: context,
    mangaId: 0 /* not be used here */,
    mangaTitle: '',
    mangaCover: '',
    mangaUrl: '',
  );
  await helper.updateFavsGroup(
    oldFavorites: favorites,
    selectedGroupName: selectedGroupName,
    onUpdated: onUpdated,
    showToast: true,
    fromFavoriteList: fromFavoriteList,
    fromMangaPage: false,
  );
}

// => called in FavoriteSubPage and FavoriteAllPage
void showUpdateFavoriteMangaRemarkDialog({
  required BuildContext context,
  required FavoriteManga favorite,
  bool fromFavoriteList = false,
  required void Function(FavoriteManga newFavorite) onUpdated,
}) async {
  var helper = _DialogHelper(
    context: context,
    mangaId: favorite.mangaId,
    mangaTitle: favorite.mangaTitle,
    mangaCover: favorite.mangaCover,
    mangaUrl: favorite.mangaUrl,
  );
  await helper.updateFavRemark(
    oldFavorite: favorite,
    onUpdated: onUpdated,
    showSnackBar: false,
    fromFavoriteList: fromFavoriteList,
    fromMangaPage: false,
  );
}

// => called in MangaPage and for MangaTocPage
void showPopupMenuForMangaToc({
  required BuildContext context,
  required int mangaId,
  required String mangaTitle,
  required String mangaCover,
  required String mangaUrl,
  required bool fromMangaPage,
  required bool fromMangaViewerPage,
  required TinyMangaChapter chapter,
  required List<MangaChapterGroup> chapterGroups,
  required void Function(MangaHistory history)? onHistoryUpdated,
}) async {
  var downloadEntity = await DownloadDao.getManga(mid: mangaId);
  var inDownloadTask = downloadEntity?.findChapter(chapter.cid) != null;
  var historyEntity = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: mangaId);
  var lastReadChapter = historyEntity?.chapterId == chapter.cid;

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
      title: Text(chapter.title),
      children: [
        /// 基本选项
        if (!fromMangaViewerPage)
          IconTextDialogOption(
            icon: Icon(Icons.import_contacts),
            text: Text('阅读该章节'),
            onPressed: () => pop(c, () => helper.gotoChapterPage(chapterId: chapter.cid, chapterGroups: chapterGroups, history: historyEntity)),
          ),
        IconTextDialogOption(
          icon: Icon(Icons.copy),
          text: Text('复制章节标题'),
          onPressed: () => copyText(chapter.title, showToast: true),
        ),
        IconTextDialogOption(
          icon: Icon(Icons.open_in_browser),
          text: Text('用浏览器打开'),
          onPressed: () => pop(c, () => launchInBrowser(context: context, url: chapter.url)),
        ),
        Divider(height: 16, thickness: 1),

        /// 下载
        if (!inDownloadTask)
          IconTextDialogOption(
            icon: Icon(Icons.download),
            text: Text('下载该章节'),
            onPressed: () => pop(c, () => helper.downloadSingleChapter(chapterId: chapter.cid, chapterTitle: chapter.title, chapterGroups: chapterGroups)),
          ),
        if (inDownloadTask)
          IconTextDialogOption(
            icon: Icon(Icons.download),
            text: Text('查看下载详情'),
            onPressed: () => pop(c, () => helper.gotoDownloadPage()),
          ),

        /// 历史
        if (!fromMangaViewerPage && lastReadChapter)
          IconTextDialogOption(
            icon: Icon(MdiIcons.deleteClock),
            text: Text('删除阅读历史'),
            onPressed: () => pop(
              c,
              () => helper.clearChapterHistory(oldHistory: historyEntity!, onUpdated: onHistoryUpdated, fromHistoryList: false, fromMangaPage: fromMangaPage),
            ),
          ),

        /// 查看信息
        IconTextDialogOption(
          icon: Icon(Icons.subject),
          text: Text('查看章节信息'),
          onPressed: () => pop(c, () => helper.gotoChapterDetailsPage(chapter: chapter, chapterGroups: chapterGroups, mangaTitle: mangaTitle, mangaUrl: mangaUrl)),
        ),
      ],
    ),
  );
}

// => called in MangaPage and MangaViewerPage
void showPopupMenuForSubscribing({
  required BuildContext context,
  required int mangaId,
  required String mangaTitle,
  required String mangaCover,
  required String mangaUrl,
  required bool fromMangaPage,
  required bool nowInShelf,
  required bool nowInFavorite,
  required int? subscribeCount,
  required FavoriteManga? favoriteManga,
  required void Function(bool subscribing) subscribing,
  required void Function(bool inShelf) inShelfSetter,
  required void Function(FavoriteManga? favorite) inFavoriteSetter,
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
            icon: Icon(MdiIcons.starPlus),
            text: Text('放入我的书架'),
            onPressed: () => pop(
              c,
              () => helper.addOrRemoveShelf(toAdd: true, subscribing: subscribing, onUpdated: inShelfSetter, fromShelfList: false, fromMangaPage: fromMangaPage),
            ),
          ),
        if (AuthManager.instance.logined && nowInShelf)
          IconTextDialogOption(
            icon: Icon(MdiIcons.starMinus),
            text: Text('移出我的书架'),
            onPressed: () => pop(
              c,
              () => helper.addOrRemoveShelf(toAdd: false, subscribing: subscribing, onUpdated: inShelfSetter, fromShelfList: false, fromMangaPage: fromMangaPage),
            ),
          ),

        /// 收藏
        if (!nowInFavorite)
          IconTextDialogOption(
            icon: Icon(CustomIcons.bookmark_plus),
            text: Text('添加本地收藏'),
            onPressed: () => pop(
              c,
              () => helper.addFavorite(subscribing: subscribing, onAdded: inFavoriteSetter, fromFavoriteList: false, fromMangaPage: fromMangaPage),
            ),
          ),
        if (nowInFavorite)
          IconTextDialogOption(
            icon: Icon(CustomIcons.bookmark_minus),
            text: Text('取消本地收藏'),
            onPressed: () => pop(
              c,
              () => helper.removeFavorite(subscribing: subscribing, onRemoved: () => inFavoriteSetter(null), fromFavoriteList: false, fromMangaPage: fromMangaPage),
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
              onPressed: () => pop(
                c,
                () => helper.updateFavGroup(oldFavorite: favoriteManga, onUpdated: inFavoriteSetter, showSnackBar: true, fromFavoriteList: false, fromMangaPage: fromMangaPage),
              ),
            ),
          if (favoriteManga != null)
            IconTextDialogOption(
              icon: Icon(MdiIcons.commentBookmark),
              text: Flexible(
                child: Text('当前收藏备注：${favoriteManga.remark.trim().isEmpty ? '暂无' : favoriteManga.remark.trim()}', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              onPressed: () => pop(
                c,
                () => helper.updateFavRemark(oldFavorite: favoriteManga, onUpdated: inFavoriteSetter, showSnackBar: true, fromFavoriteList: false, fromMangaPage: fromMangaPage),
              ),
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

  // ============================
  // static methods (show dialog)
  // ============================

  static Future<Tuple3<String, String, bool>?> showAddToFavoriteDialog({
    required BuildContext context,
    required List<FavoriteGroup> groups,
  }) async {
    var groupName = ''; // group
    var controller = TextEditingController(); // remark
    var addToTop = false; // order, 默认添加到末尾

    var ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => StatefulBuilder(
        builder: (_, _setState) => AlertDialog(
          title: Text('收藏漫画'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: getDialogContentMaxWidth(context),
                padding: EdgeInsets.only(left: 5, right: 5, bottom: 12),
                child: CustomCombobox<String>(
                  value: groupName,
                  items: [
                    for (var group in groups) // TODO hide keyboard first, https://github.com/flutter/flutter/issues/22075
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
                      child: Icon(MdiIcons.commentBookmarkOutline),
                    ),
                  ),
                ),
              ),
              Container(
                width: getDialogContentMaxWidth(context),
                padding: EdgeInsets.only(top: 3),
                child: CheckboxListTile(
                  title: Text('添加至收藏顶部'),
                  value: addToTop,
                  onChanged: (v) => _setState(() => addToTop = v ?? false),
                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
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
      controller.text.trim(), // remark, empty-able
      addToTop, // order
    );
  }

  static Future<Tuple2<FavoriteGroup, bool>?> showChooseFavoriteGroupDialog({
    required BuildContext context,
    required List<FavoriteGroup> groups,
    required String? selectedGroupName,
  }) async {
    var addToTop = false; // order, 默认添加到末尾
    var group = await showDialog<FavoriteGroup>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('移动收藏至分组'),
        children: [
          CheckBoxDialogOption(
            initialValue: addToTop,
            onChanged: (v) => addToTop = v,
            text: '添加至收藏顶部',
          ),
          Divider(thickness: 1),
          for (var group in groups)
            TextDialogOption(
              text: Text(
                group.checkedGroupName,
                style: selectedGroupName == null || group.groupName != selectedGroupName //
                    ? null
                    : TextStyle(color: Theme.of(context).primaryColor),
              ),
              onPressed: () => Navigator.of(c).pop(group),
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

    return Tuple1(
      controller.text.trim(), // remark, empty-able
    );
  }

  // =======================
  // helper methods (others)
  // =======================

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

  void gotoDownloadPage({bool gotoDownloading = false}) {
    Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => DownloadMangaPage(
          mangaId: mangaId,
          gotoDownloading: gotoDownloading,
        ),
        settings: DownloadMangaPage.buildRouteSetting(
          mangaId: mangaId,
        ),
      ),
    );
  }

  void gotoChapterPage({required int chapterId, required List<MangaChapterGroup> chapterGroups, required MangaHistory? history}) {
    Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => MangaViewerPage(
          parentContext: context,
          mangaId: mangaId,
          chapterId: chapterId,
          mangaCover: mangaCover,
          chapterGroups: chapterGroups,
          initialPage: history?.chapterId == chapterId
              ? history?.chapterPage ?? 1 // have read
              : 1 /* have not read */,
          onlineMode: true,
        ),
      ),
    );
  }

  Future<void> downloadSingleChapter({required int chapterId, required String chapterTitle, required List<MangaChapterGroup> chapterGroups}) async {
    await quickBuildDownloadMangaQueueTask(
      mangaId: mangaId,
      mangaTitle: mangaTitle,
      mangaCover: mangaCover,
      mangaUrl: mangaUrl,
      chapterIds: [chapterId],
      alsoAddTask: true,
      throughGroupList: chapterGroups,
      throughChapterList: null,
    );
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已添加 "$chapterTitle" 至漫画下载任务'),
        action: SnackBarAction(
          label: '查看',
          onPressed: () => gotoDownloadPage(gotoDownloading: true),
        ),
      ),
    );
  }

  void gotoChapterDetailsPage({required TinyMangaChapter chapter, required List<MangaChapterGroup> chapterGroups, required String mangaTitle, required String mangaUrl}) {
    var group = chapterGroups.findChapterAndGroup(chapter.cid)?.item2;
    Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => ChapterDetailsPage(
          data: chapter,
          group: group?.title,
          groupLength: group?.chapters.length,
          mangaTitle: mangaTitle,
          mangaUrl: mangaUrl,
        ),
      ),
    );
  }

  // ========================
  // methods (add and remove)
  // ========================

  // => called by showPopupMenuForMangaList, showPopupMenuForSubscribing
  Future<void> addOrRemoveShelf({
    required bool toAdd,
    required void Function(bool subscribing)? subscribing,
    required void Function(bool inShelf)? onUpdated,
    required bool fromShelfList,
    required bool fromMangaPage,
  }) async {
    final client = RestClient(DioManager.instance.dio);

    subscribing?.call(true);
    bool? added;
    try {
      // 网络请求、(更新界面)、弹出提示、发送通知
      await (toAdd ? client.addToShelf : client.removeFromShelf)(token: AuthManager.instance.token, mid: mangaId);
      added = toAdd;
      onUpdated?.call(added);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(added ? '成功将漫画放入书架' : '成功将漫画移出书架')));
      EventBusManager.instance.fire(ShelfUpdatedEvent(mangaId: mangaId, added: added, fromShelfPage: fromShelfList, fromMangaPage: fromMangaPage));
    } catch (e, s) {
      var err = wrapError(e, s).text;
      var already = err.contains('已经被'), notYet = err.contains('还没有被');
      if (already || notYet) {
        added = already;
        onUpdated?.call(added);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(added ? '漫画已经在书架上' : '漫画还未在书架上')));
        EventBusManager.instance.fire(ShelfUpdatedEvent(mangaId: mangaId, added: added, fromShelfPage: fromShelfList, fromMangaPage: fromMangaPage));
      } else {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toAdd ? '放入书架失败，$err' : '移出书架失败，$err')));
      }
    } finally {
      subscribing?.call(false);
    }

    // 针对书架，同时更新书架缓存
    if (added == true) {
      var cache = ShelfCache(mangaId: mangaId, mangaTitle: mangaTitle, mangaCover: mangaCover, mangaUrl: mangaUrl, cachedAt: DateTime.now());
      await ShelfCacheDao.addOrUpdateShelfCache(username: AuthManager.instance.username, cache: cache);
      EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: mangaId, added: true, fromShelfCachePage: false));
    } else if (added == false) {
      await ShelfCacheDao.deleteShelfCache(username: AuthManager.instance.username, mangaId: mangaId);
      EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: mangaId, added: false, fromShelfCachePage: false));
    }
  }

  // => called by showPopupMenuForMangaList, showPopupMenuForSubscribing
  Future<void> addFavorite({
    required void Function(bool subscribing)? subscribing,
    required void Function(FavoriteManga newFavorite)? onAdded,
    required bool fromFavoriteList,
    required bool fromMangaPage,
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
      // 更新数据库、(更新界面)、弹出提示、发送通知
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
      EventBusManager.instance.fire(FavoriteUpdatedEvent(mangaId: mangaId, group: newFavorite.groupName, reason: UpdateReason.added, fromFavoritePage: fromFavoriteList, fromMangaPage: fromMangaPage));
    } finally {
      subscribing?.call(false);
    }
  }

  // => called by showPopupMenuForMangaList, showPopupMenuForSubscribing
  Future<void> removeFavorite({
    required void Function(bool subscribing)? subscribing,
    required void Function()? onRemoved,
    required bool fromFavoriteList,
    required bool fromMangaPage,
  }) async {
    subscribing?.call(true);
    try {
      // 更新数据库、(更新界面)、弹出提示、发送通知
      var oldFavorite = await FavoriteDao.getFavorite(username: AuthManager.instance.username, mid: mangaId);
      var oldGroupName = oldFavorite?.groupName ?? '';
      await FavoriteDao.deleteFavorite(username: AuthManager.instance.username, mid: mangaId);
      onRemoved?.call();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功取消收藏漫画')));
      EventBusManager.instance.fire(FavoriteUpdatedEvent(mangaId: mangaId, group: oldGroupName, reason: UpdateReason.deleted, fromFavoritePage: fromFavoriteList, fromMangaPage: fromMangaPage));
    } finally {
      subscribing?.call(false);
    }
  }

  // => called by showPopupMenuForMangaList
  Future<void> removeHistory({
    required MangaHistory oldHistory,
    required void Function()? onRemoved,
    required bool fromHistoryList,
    required bool fromMangaPage,
  }) async {
    // 更新数据库、(更新界面)、弹出提示、发送通知
    await HistoryDao.deleteHistory(username: AuthManager.instance.username, mid: mangaId);
    onRemoved?.call();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(oldHistory.read ? '漫画阅读历史已删除' : '漫画浏览历史已删除')));
    EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: mangaId, reason: UpdateReason.deleted, fromHistoryPage: fromHistoryList, fromMangaPage: fromMangaPage));
  }

  // => called by showPopupMenuForMangaToc
  Future<void> clearChapterHistory({
    required MangaHistory oldHistory,
    required void Function(MangaHistory newHistory)? onUpdated,
    required bool fromHistoryList,
    required bool fromMangaPage,
  }) async {
    // 更新数据库、(更新界面)、弹出提示、发送通知
    var newHistory = oldHistory.copyWith(chapterId: 0 /* 未开始阅读 */, chapterTitle: '', chapterPage: 1, lastTime: DateTime.now());
    await HistoryDao.addOrUpdateHistory(username: AuthManager.instance.username, history: newHistory);
    onUpdated?.call(newHistory);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('章节阅读历史已删除')));
    EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: mangaId, reason: UpdateReason.updated, fromHistoryPage: fromHistoryList, fromMangaPage: fromMangaPage));
  }

  // =========================
  // methods (update favorite)
  // =========================

  // => called by showPopupMenuForSubscribing
  Future<void> updateFavGroup({
    required FavoriteManga oldFavorite,
    required void Function(FavoriteManga newFavorite)? onUpdated,
    required bool showSnackBar,
    required bool fromFavoriteList,
    required bool fromMangaPage,
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

    // 更新数据库、(更新界面)、弹出提示、发送通知
    var order = await FavoriteDao.getFavoriteNewOrder(username: AuthManager.instance.username, groupName: group.groupName, addToTop: addToTop);
    var newFavorite = oldFavorite.copyWith(groupName: group.groupName, order: order);
    await FavoriteDao.addOrUpdateFavorite(username: AuthManager.instance.username, favorite: newFavorite);
    onUpdated?.call(newFavorite);
    if (showSnackBar) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已将漫画收藏于 "${group.checkedGroupName}"')));
    }
    EventBusManager.instance.fire(FavoriteUpdatedEvent(mangaId: mangaId, group: newFavorite.groupName, oldGroup: oldFavorite.groupName, reason: UpdateReason.updated, fromFavoritePage: fromFavoriteList, fromMangaPage: fromMangaPage));
  }

  // => called by showUpdateFavoritesGroupDialog
  Future<void> updateFavsGroup({
    required List<FavoriteManga> oldFavorites, // 按照收藏列表从上到下的顺序
    required String? selectedGroupName,
    required void Function(List<FavoriteManga> newFavorites, bool addToTop) onUpdated,
    required bool showToast,
    required bool fromFavoriteList,
    required bool fromMangaPage,
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

    // 更新数据库、(更新界面)、弹出提示、发送通知
    if (addToTop) {
      oldFavorites.sort((i, j) => j.order.compareTo(i.order)); // 移至顶部 => 逆序一个一个移动
    } else {
      oldFavorites.sort((i, j) => i.order.compareTo(j.order)); // 移至底部 => 正序一个一个移动
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
      await Fluttertoast.cancel();
      Fluttertoast.showToast(msg: '已将 ${oldFavorites.length} 部漫画收藏于 "${group.checkedGroupName}"');
    }
    for (var tuple in oldNewFavorites) {
      var oldFavorite = tuple.item1;
      var newFavorite = tuple.item2;
      EventBusManager.instance.fire(FavoriteUpdatedEvent(mangaId: newFavorite.mangaId, group: newFavorite.groupName, oldGroup: oldFavorite.groupName, reason: UpdateReason.updated, fromFavoritePage: fromFavoriteList, fromMangaPage: fromMangaPage));
    }
  }

  // => called by showUpdateFavoriteRemarkDialog, showPopupMenuForSubscribing
  Future<void> updateFavRemark({
    required FavoriteManga oldFavorite,
    required void Function(FavoriteManga newFavorite) onUpdated,
    required bool showSnackBar,
    required bool fromFavoriteList,
    required bool fromMangaPage,
  }) async {
    var result = await showEditFavoriteRemarkDialog(context: context, remark: oldFavorite.remark.trim());
    if (result == null) {
      return;
    }
    var newRemark = result.item;

    // 更新数据库、(更新界面)、弹出提示、发送通知
    var newFavorite = oldFavorite.copyWith(remark: newRemark);
    await FavoriteDao.addOrUpdateFavorite(username: AuthManager.instance.username, favorite: newFavorite);
    onUpdated(newFavorite);
    if (showSnackBar) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newRemark == '' ? '已删除收藏备注' : '已将备注修改为 "$newRemark"')));
    }
    EventBusManager.instance.fire(FavoriteUpdatedEvent(mangaId: mangaId, group: newFavorite.groupName, reason: UpdateReason.updated, fromFavoritePage: fromFavoriteList, fromMangaPage: fromMangaPage));
  }
}
