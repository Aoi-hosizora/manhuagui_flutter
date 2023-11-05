import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/chapter_detail.dart';
import 'package:manhuagui_flutter/page/download.dart';
import 'package:manhuagui_flutter/page/download_manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/manga_detail.dart';
import 'package:manhuagui_flutter/page/manga_shelf_cache.dart';
import 'package:manhuagui_flutter/page/manga_viewer.dart';
import 'package:manhuagui_flutter/page/sep_favorite.dart';
import 'package:manhuagui_flutter/page/sep_history.dart';
import 'package:manhuagui_flutter/page/sep_later.dart';
import 'package:manhuagui_flutter/page/sep_shelf.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/db/later_manga.dart';
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
/// 漫画页/章节页-漫画章节弹出菜单 [showPopupMenuForMangaToc]
/// 漫画页/章节页-漫画订阅对话框 [showPopupMenuForSubscribing]
/// 漫画页/书架同步页-同步书架对话框 [showPopupMenuForShelfCache]
/// 漫画页/章节页/漫画下载页-稍后阅读对话框 [showPopupMenuForLaterManga]
/// 漫画页-标题对话框 [showPopupMenuForMangaTitle]
/// 章节页-标题对话框 [showPopupMenuForChapterTitle]

// => called by pages which contains manga line view (tiny / ranking / *shelf* / *favorite* / *history* / *later* / download / aud_ranking) and DownloadMangaPage
void showPopupMenuForMangaList({
  required BuildContext context,
  required int mangaId,
  required String mangaTitle,
  required String mangaCover,
  required String mangaUrl,
  required MangaExtraDataForDialog? extraData,
  bool fromShelfList = false,
  bool fromFavoriteList = false,
  bool fromLaterList = false,
  bool fromHistoryList = false,
  bool fromDownloadList = false,
  bool fromDownloadPage = false,
  void Function(bool inShelf)? inShelfSetter,
  void Function(bool inFavorite)? inFavoriteSetter,
  void Function(bool inLater)? inLaterSetter,
  void Function(bool inHistory)? inHistorySetter,
  void Function(FavoriteManga? favorite)? favoriteSetter, // only for ``object modifying'' in more options
  void Function(LaterManga? later)? laterSetter, // only for ``object modifying'' in more options
}) async {
  var nowInDownload = await DownloadDao.checkMangaExistence(mid: mangaId) ?? false;
  var favoriteManga = await FavoriteDao.getFavorite(username: AuthManager.instance.username, mid: mangaId);
  var nowInFavorite = favoriteManga != null;
  var nowInShelfCache = await ShelfCacheDao.checkExistence(username: AuthManager.instance.username, mid: mangaId) ?? false;
  var laterManga = await LaterMangaDao.getLaterManga(username: AuthManager.instance.username, mid: mangaId);
  var nowInLater = laterManga != null;
  var mangaHistory = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: mangaId);
  var expandShelfOptions = false;

  var helper = _DialogHelper(
    context: context,
    mangaId: mangaId,
    mangaTitle: mangaTitle,
    mangaCover: mangaCover,
    mangaUrl: mangaUrl,
    extraData: extraData,
  );

  showDialog(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (_, _setState) => SimpleDialog(
        title: Text(mangaTitle),
        children: [
          /// 基本选项
          IconTextDialogOption(
            icon: Icon(MdiIcons.bookOutline),
            text: Text('查看该漫画'),
            popWhenPress: c,
            onPressed: () => helper.gotoMangaPage(),
          ),
          IconTextDialogOption(
            icon: Icon(Icons.copy),
            text: Text('复制漫画标题'),
            onPressed: () => copyText(mangaTitle, showToast: true),
          ),
          IconTextDialogOption(
            icon: Icon(Icons.open_in_browser),
            text: Text('用浏览器打开'),
            popWhenPress: c,
            onPressed: () => launchInBrowser(context: context, url: mangaUrl),
          ),
          Divider(height: 16, thickness: 1),

          /// 下载
          if (nowInDownload && !fromDownloadPage)
            IconTextDialogOption(
              icon: Icon(Icons.downloading),
              text: Text('查看下载详情'),
              popWhenPress: c,
              onPressed: () => helper.gotoDownloadMangaPage(),
            ),

          /// 书架
          if (AuthManager.instance.logined && fromShelfList)
            IconTextDialogOption(
              icon: Icon(MdiIcons.starMinus),
              text: Text('移出我的书架'),
              popWhenPress: c,
              predicateForPress: () => helper.showCheckRemovingShelfDialog(),
              onPressed: () => helper.addOrRemoveShelf(toAdd: false, subscribing: null, onUpdated: inShelfSetter, fromShelfList: fromShelfList, fromMangaPage: false),
            ),
          if (AuthManager.instance.logined && !fromShelfList) ...[
            if (!expandShelfOptions)
              IconTextDialogOption(
                icon: Icon(MdiIcons.starCog),
                text: Text('编辑我的书架'),
                onPressed: () => _setState(() => expandShelfOptions = true),
                onLongPressed: () => _setState(() => expandShelfOptions = true),
              ),
            if (expandShelfOptions)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10 /* <<< */),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                ),
                child: (kIconTextDialogOptionPadding - EdgeInsets.symmetric(horizontal: 10 /* <<< */)).let(
                  (optionPadding) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconTextDialogOption(
                        icon: Icon(MdiIcons.starCog, color: Colors.black26),
                        text: Text('隐藏书架选项'),
                        padding: optionPadding,
                        onPressed: () => _setState(() => expandShelfOptions = false),
                        onLongPressed: () => _setState(() => expandShelfOptions = false),
                      ),
                      IconTextDialogOption(
                        icon: Icon(MdiIcons.starPlus),
                        text: Text('放入我的书架' + (!nowInShelfCache ? ' (*)' : '')),
                        padding: optionPadding,
                        popWhenPress: c,
                        onPressed: () => helper.addOrRemoveShelf(toAdd: true, subscribing: null, onUpdated: inShelfSetter, fromShelfList: fromShelfList, fromMangaPage: false),
                      ),
                      IconTextDialogOption(
                        icon: Icon(MdiIcons.starMinus),
                        text: Text('移出我的书架' + (nowInShelfCache ? ' (*)' : '')),
                        padding: optionPadding,
                        popWhenPress: c,
                        predicateForPress: () => helper.showCheckRemovingShelfDialog(),
                        onPressed: () => helper.addOrRemoveShelf(toAdd: false, subscribing: null, onUpdated: inShelfSetter, fromShelfList: fromShelfList, fromMangaPage: false),
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
            popWhenPress: c,
            predicateForPress: !nowInFavorite ? null : () => helper.showCheckRemovingFavoriteDialog(),
            onPressed: () => !nowInFavorite //
                ? helper.addFavorite(subscribing: null, onAdded: (_) => inFavoriteSetter?.call(true), fromFavoriteList: fromFavoriteList, fromMangaPage: false)
                : helper.removeFavorite(subscribing: null, onRemoved: () => inFavoriteSetter?.call(false), fromFavoriteList: fromFavoriteList, fromMangaPage: false),
          ),

          /// 稍后阅读
          IconTextDialogOption(
            icon: Icon(!nowInLater ? MdiIcons.clockPlus : MdiIcons.clockMinus),
            text: Text(!nowInLater ? '添加至稍后阅读列表' : '移出稍后阅读列表'),
            popWhenPress: c,
            predicateForPress: !nowInLater ? null : () => helper.showCheckRemovingLaterDialog(),
            onPressed: () => helper.addOrRemoveLater(toAdd: !nowInLater, onUpdated: (l) => inLaterSetter?.call(l != null), fromLaterList: fromLaterList, fromMangaPage: false),
          ),

          /// 更多选项
          IconTextDialogOption(
            icon: Icon(Icons.more_horiz),
            text: Text('更多选项'),
            popWhenPress: c,
            onPressed: () => showDialog(
              context: context,
              builder: (c) => SimpleDialog(
                title: Text(mangaTitle),
                children: <List<Widget>>[
                  /// 基本选项
                  [
                    IconTextDialogOption(
                      icon: Icon(MdiIcons.bookOutline),
                      text: Text('查看该漫画'),
                      popWhenPress: c,
                      onPressed: () => helper.gotoMangaPage(),
                    ),
                  ],

                  /// 下载
                  if (nowInDownload)
                    [
                      if (!fromDownloadPage)
                        IconTextDialogOption(
                          icon: Icon(Icons.downloading),
                          text: Text('查看下载详情'),
                          popWhenPress: c,
                          onPressed: () => helper.gotoDownloadMangaPage(),
                        ),
                      if (!fromDownloadList)
                        IconTextDialogOption(
                          icon: Icon(MdiIcons.downloadMultiple),
                          text: Text('查看漫画下载列表'),
                          popWhenPress: c,
                          onPressed: () => helper.gotoDownloadListPage(),
                        ),
                    ],

                  /// 书架
                  if (nowInShelfCache)
                    [
                      IconTextDialogOption(
                        icon: Icon(CustomIcons.star_sync),
                        text: Text('查看已同步的书架记录'),
                        popWhenPress: c,
                        onPressed: () => helper.gotoShelfCachePage(),
                      ),
                      if (!fromShelfList)
                        IconTextDialogOption(
                          icon: Icon(MdiIcons.bookshelf),
                          text: Text('查看我的书架列表'),
                          popWhenPress: c,
                          onPressed: () => helper.gotoShelfPage(),
                        ),
                    ],

                  /// 收藏
                  if (favoriteManga != null)
                    [
                      IconTextDialogOption(
                        icon: Icon(Icons.folder),
                        text: Flexible(child: Text('修改收藏分组 - ${favoriteManga.checkedGroupName}', maxLines: 1, overflow: TextOverflow.ellipsis)),
                        popWhenPress: c,
                        onPressed: () => helper.updateFavGroup(oldFavorite: favoriteManga, onUpdated: favoriteSetter, showSnackBar: true, fromFavoriteList: fromFavoriteList, fromMangaPage: false),
                      ),
                      IconTextDialogOption(
                        icon: Icon(MdiIcons.commentBookmark),
                        text: Text('查看或修改收藏备注'),
                        popWhenPress: c,
                        onPressed: () => helper.showAndUpdateFavRemark(favorite: favoriteManga, onUpdated: favoriteSetter, showSnackBar: true, fromFavoriteList: fromFavoriteList, fromMangaPage: false),
                      ),
                      if (!fromFavoriteList)
                        IconTextDialogOption(
                          icon: Icon(CustomIcons.bookmark_multiple),
                          text: Text('查看漫画收藏列表'),
                          popWhenPress: c,
                          onPressed: () => helper.gotoFavoritePage(),
                        ),
                    ],

                  /// 稍后阅读
                  if (laterManga != null)
                    [
                      IconTextDialogOption(
                        icon: Icon(CustomIcons.clock_topmost),
                        text: Text('置顶于稍后阅读列表'),
                        popWhenPress: c,
                        onPressed: () => helper.topmostLater(later: laterManga, onUpdated: laterSetter, fromLaterList: fromLaterList, fromMangaPage: false),
                      ),
                      if (extraData != null && extraData.newestChapter != null && extraData.newestDate != null && extraData.newestChapter != laterManga.newestChapter)
                        IconTextDialogOption(
                          icon: Icon(CustomIcons.clock_sync),
                          text: Text('更新记录至最新章节 (*)'),
                          popWhenPress: c,
                          onPressed: () => helper.updateLaterToNewestChapter(later: laterManga, onUpdated: laterSetter, fromLaterList: false, fromMangaPage: false),
                        ),
                      if (!fromLaterList)
                        IconTextDialogOption(
                          icon: Icon(MdiIcons.bookClock),
                          text: Text('查看稍后阅读列表'),
                          popWhenPress: c,
                          onPressed: () => helper.gotoLaterPage(),
                        ),
                    ],

                  /// 历史
                  if (mangaHistory != null)
                    [
                      IconTextDialogOption(
                        icon: Icon(CustomIcons.history_delete),
                        text: Text(!mangaHistory.read ? '删除浏览历史' : '删除阅读与浏览历史'),
                        popWhenPress: c,
                        predicateForPress: () => helper.showCheckRemovingHistoryDialog(read: mangaHistory.read),
                        onPressed: () => helper.removeHistory(oldHistory: mangaHistory, onRemoved: () => inHistorySetter?.call(false), onFpCleared: null, fromHistoryList: fromHistoryList, fromMangaPage: false),
                      ),
                      if (!fromHistoryList)
                        IconTextDialogOption(
                          icon: Icon(Icons.history),
                          text: Text('查看漫画历史列表'),
                          popWhenPress: c,
                          onPressed: () => helper.gotoHistoryPage(),
                        ),
                    ],

                  /// ...
                  [
                    IconTextDialogOption(
                      icon: Icon(Icons.arrow_back),
                      text: Text('其他选项'),
                      popWhenPress: c,
                      onPressed: () => showPopupMenuForMangaList(
                        context: context,
                        mangaId: mangaId,
                        mangaTitle: mangaTitle,
                        mangaCover: mangaCover,
                        mangaUrl: mangaUrl,
                        extraData: extraData,
                        fromShelfList: fromShelfList,
                        fromFavoriteList: fromFavoriteList,
                        fromLaterList: fromLaterList,
                        fromHistoryList: fromHistoryList,
                        fromDownloadList: fromDownloadList,
                        fromDownloadPage: fromDownloadPage,
                        inShelfSetter: inShelfSetter,
                        inFavoriteSetter: inFavoriteSetter,
                        inLaterSetter: inLaterSetter,
                        inHistorySetter: inHistorySetter,
                        favoriteSetter: favoriteSetter,
                        laterSetter: laterSetter,
                      ),
                    ),
                  ]
                ].let((list) {
                  var newList = list.expand((el) => [...el, if (el.isNotEmpty) Divider(height: 10, thickness: 1)]);
                  return newList.toList().sublist(0, newList.length - 1);
                }),
              ),
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
    extraData: null,
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
    extraData: null,
  );
  await helper.updateFavRemark(
    oldFavorite: favorite,
    onUpdated: onUpdated,
    showSnackBar: false,
    fromFavoriteList: fromFavoriteList,
    fromMangaPage: false,
  );
}

void _navigateWrapper(Future<void> Function() navigate) => navigate();

// => called in MangaPage (MangaTocPage) and MangaViewerPage (ViewTocSubPage)
void showPopupMenuForMangaToc({
  required BuildContext context,
  required int mangaId,
  required String mangaTitle,
  required String mangaCover,
  required String mangaUrl,
  required bool fromMangaPage,
  required TinyMangaChapter chapter,
  required MangaChapterNeededData chapterNeededData,
  required void Function(MangaHistory history)? onHistoryUpdated,
  required void Function(ChapterFootprint footprint)? onFootprintAdded,
  required void Function(List<ChapterFootprint> footprints)? onFootprintsAdded,
  required void Function(List<int> chapterIds)? onFootprintsRemoved,
  void Function()? toSwitchChapter, // => only for switching chapter in MangaViewerPage
  void Function(Future<void> Function()) navigateWrapper = _navigateWrapper, // => to update system ui, for MangaViewerPage
}) async {
  var downloadEntity = await DownloadDao.getManga(mid: mangaId);
  var inDownloadTask = downloadEntity?.findChapter(chapter.cid) != null;
  var historyEntity = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: mangaId);
  var isChapterRead = historyEntity?.chapterId == chapter.cid || historyEntity?.lastChapterId == chapter.cid;
  var readChapterTitle = historyEntity?.chapterId == chapter.cid ? historyEntity!.chapterTitle : (historyEntity?.lastChapterId == chapter.cid ? historyEntity?.lastChapterTitle : null);
  var readChapterPage = historyEntity?.chapterId == chapter.cid ? historyEntity!.chapterPage : (historyEntity?.lastChapterId == chapter.cid ? historyEntity?.lastChapterPage : null);
  var allowDeletingHistory = toSwitchChapter == null || historyEntity?.chapterId != chapter.cid;
  var isInFootprint = await HistoryDao.checkFootprintExistence(username: AuthManager.instance.username, mid: mangaId, cid: chapter.cid) ?? false;

  var helper = _DialogHelper(
    context: context,
    mangaId: mangaId,
    mangaTitle: mangaTitle,
    mangaCover: mangaCover,
    mangaUrl: mangaUrl,
    extraData: null,
  );

  showDialog(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text(chapter.title),
      children: [
        /// 基本选项
        if (toSwitchChapter == null) ...[
          IconTextDialogOption(
            icon: Icon(!isChapterRead ? Icons.import_contacts : CustomIcons.opened_book_arrow_right),
            text: Text(!isChapterRead ? '阅读该章节 (第1页)' : '继续阅读该章节 (第${readChapterPage ?? 1}页)'),
            popWhenPress: c,
            onPressed: () => helper.gotoChapterPage(chapterId: chapter.cid, chapterNeededData: chapterNeededData, history: historyEntity, readFirstPage: false, onlineMode: true),
          ),
          if (isChapterRead && ((readChapterPage ?? 1) > 1))
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_book_replay),
              text: Text('从头阅读该章节 (第1页)'),
              popWhenPress: c,
              onPressed: () => helper.gotoChapterPage(chapterId: chapter.cid, chapterNeededData: chapterNeededData, history: historyEntity, readFirstPage: true, onlineMode: true),
            ),
          if (inDownloadTask)
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_book_offline),
              text: Text('离线阅读该章节 (第1页)'),
              popWhenPress: c,
              onPressed: () => helper.gotoChapterPage(chapterId: chapter.cid, chapterNeededData: chapterNeededData, history: historyEntity, readFirstPage: true, onlineMode: false),
            ),
        ],
        if (toSwitchChapter != null)
          IconTextDialogOption(
            icon: Icon(Icons.import_contacts),
            text: Text('切换为该章节'),
            popWhenPress: c,
            onPressed: toSwitchChapter, // 在 MangaViewerPage 中指定章节切换的流程，可能会进一步弹框判断是否继续阅读
          ),
        IconTextDialogOption(
          icon: Icon(Icons.copy),
          text: Text('复制章节标题'),
          onPressed: () => copyText(chapter.title, showToast: true),
        ),
        IconTextDialogOption(
          icon: Icon(Icons.open_in_browser),
          text: Text('用浏览器打开'),
          popWhenPress: c,
          onPressed: () => launchInBrowser(context: context, url: chapter.url),
        ),
        Divider(height: 16, thickness: 1),

        /// 下载
        if (!inDownloadTask)
          IconTextDialogOption(
            icon: Icon(Icons.download),
            text: Text('下载该章节'),
            popWhenPress: c,
            onPressed: () => helper.downloadSingleChapter(chapterId: chapter.cid, chapterTitle: chapter.title, chapterGroups: chapterNeededData.chapterGroups),
          ),
        if (inDownloadTask)
          IconTextDialogOption(
            icon: Icon(Icons.download),
            text: Text('查看下载详情'),
            popWhenPress: c,
            onPressed: () => navigateWrapper(() => helper.gotoDownloadMangaPage()),
          ),

        /// 历史
        if (allowDeletingHistory && isChapterRead)
          IconTextDialogOption(
            icon: Icon(CustomIcons.history_minus),
            text: Text('删除阅读历史') /* 删除章节阅读历史 */,
            popWhenPress: c,
            predicateForPress: () => helper.showCheckRemovingHistoryDialog(read: true, chapterTitle: readChapterTitle),
            onPressed: () => helper.removeChapterHistory(oldHistory: historyEntity!, chapterId: chapter.cid, onUpdated: onHistoryUpdated, onFpRemoved: onFootprintsRemoved, fromHistoryList: false, fromMangaPage: fromMangaPage),
          ),
        if (allowDeletingHistory && !isChapterRead && isInFootprint)
          IconTextDialogOption(
            icon: Icon(CustomIcons.history_minus),
            text: Text('删除阅读历史') /* 删除章节阅读历史 */,
            popWhenPress: c,
            predicateForPress: () => helper.showCheckRemovingHistoryDialog(read: true, chapterTitle: chapterNeededData.chapterGroups.findChapter(chapter.cid)?.title ?? '未知话'),
            onPressed: () => helper.removeChapterHistory(oldHistory: historyEntity!, chapterId: chapter.cid, onUpdated: onHistoryUpdated, onFpRemoved: onFootprintsRemoved, fromHistoryList: false, fromMangaPage: fromMangaPage),
          ),
        if (!isChapterRead && !isInFootprint)
          IconTextDialogOption(
            icon: Icon(CustomIcons.history_plus),
            text: Text('记录为已阅读') /* 添加章节阅读历史 */,
            popWhenPress: c,
            onPressed: () => helper.addChapterFootprint(chapterId: chapter.cid, onAdded: onFootprintAdded, fromHistoryList: false, fromMangaPage: fromMangaPage),
          ),

        /// 查看信息
        IconTextDialogOption(
          icon: Icon(Icons.subject),
          text: Text('查看章节信息'),
          popWhenPress: c,
          onPressed: () => navigateWrapper(() => helper.gotoChapterDetailsPage(chapter: chapter, chapterNeededData: chapterNeededData)),
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
  required MangaExtraDataForDialog? extraData,
  required bool fromMangaPage,
  required bool nowInShelf,
  required bool nowInFavorite,
  required bool nowInLater,
  required int? subscribeCount,
  required FavoriteManga? favoriteManga,
  required LaterManga? laterManga,
  required void Function(bool subscribing) subscribing,
  required void Function(bool inShelf) inShelfSetter,
  required void Function(FavoriteManga? favorite) inFavoriteSetter,
  required void Function(LaterManga? later) inLaterSetter,
}) {
  var helper = _DialogHelper(
    context: context,
    mangaId: mangaId,
    mangaTitle: mangaTitle,
    mangaCover: mangaCover,
    mangaUrl: mangaUrl,
    extraData: extraData,
  );

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
            popWhenPress: c,
            onPressed: () => helper.addOrRemoveShelf(toAdd: true, subscribing: subscribing, onUpdated: inShelfSetter, fromShelfList: false, fromMangaPage: fromMangaPage),
          ),
        if (AuthManager.instance.logined && nowInShelf)
          IconTextDialogOption(
            icon: Icon(MdiIcons.starMinus),
            text: Text('移出我的书架'),
            popWhenPress: c,
            predicateForPress: () => helper.showCheckRemovingShelfDialog(),
            onPressed: () => helper.addOrRemoveShelf(toAdd: false, subscribing: subscribing, onUpdated: inShelfSetter, fromShelfList: false, fromMangaPage: fromMangaPage),
          ),

        /// 收藏
        if (!nowInFavorite)
          IconTextDialogOption(
            icon: Icon(CustomIcons.bookmark_plus),
            text: Text('添加本地收藏'),
            popWhenPress: c,
            onPressed: () => helper.addFavorite(subscribing: subscribing, onAdded: inFavoriteSetter, fromFavoriteList: false, fromMangaPage: fromMangaPage),
          ),
        if (nowInFavorite)
          IconTextDialogOption(
            icon: Icon(CustomIcons.bookmark_minus),
            text: Text('取消本地收藏'),
            popWhenPress: c,
            predicateForPress: () => helper.showCheckRemovingFavoriteDialog(),
            onPressed: () => helper.removeFavorite(subscribing: subscribing, onRemoved: () => inFavoriteSetter(null), fromFavoriteList: false, fromMangaPage: fromMangaPage),
          ),

        /// 稍后阅读
        if (!nowInLater)
          IconTextDialogOption(
            icon: Icon(MdiIcons.clockPlus),
            text: Text('添加至稍后阅读列表'),
            popWhenPress: c,
            onPressed: () => helper.addOrRemoveLater(toAdd: true, onUpdated: inLaterSetter, fromLaterList: false, fromMangaPage: fromMangaPage),
          ),
        if (nowInLater)
          IconTextDialogOption(
            icon: Icon(MdiIcons.clockMinus),
            text: Text('移出稍后阅读列表'),
            popWhenPress: c,
            predicateForPress: () => helper.showCheckRemovingLaterDialog(),
            onPressed: () => helper.addOrRemoveLater(toAdd: false, onUpdated: inLaterSetter, fromLaterList: false, fromMangaPage: fromMangaPage),
          ),

        /// 额外选项
        if (nowInShelf || favoriteManga != null || laterManga != null) ...[
          Divider(height: 16, thickness: 1),
          if (nowInShelf && subscribeCount != null)
            IconTextDialogOption(
              icon: Icon(Icons.stars),
              text: Text('共 $subscribeCount 人将本漫画放入书架'),
              onPressed: () {},
            ),
          if (nowInShelf)
            IconTextDialogOption(
              icon: Icon(CustomIcons.star_sync),
              text: Text('查看已同步的书架记录'),
              popWhenPress: c,
              onPressed: () => helper.gotoShelfCachePage(),
            ),
          if (favoriteManga != null)
            IconTextDialogOption(
              icon: Icon(Icons.folder),
              text: Flexible(
                child: Text('当前收藏分组：${favoriteManga.checkedGroupName}', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              popWhenPress: c,
              onPressed: () => helper.updateFavGroup(oldFavorite: favoriteManga, onUpdated: inFavoriteSetter, showSnackBar: true, fromFavoriteList: false, fromMangaPage: fromMangaPage),
            ),
          if (favoriteManga != null)
            IconTextDialogOption(
              icon: Icon(MdiIcons.commentBookmark),
              text: Flexible(
                child: Text('当前收藏备注：${favoriteManga.remark.trim().isEmpty ? '暂无' : favoriteManga.remark.trim()}', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              popWhenPress: c,
              onPressed: () => helper.showAndUpdateFavRemark(favorite: favoriteManga, onUpdated: inFavoriteSetter, showSnackBar: true, fromFavoriteList: false, fromMangaPage: fromMangaPage),
            ),
          if (laterManga != null)
            IconTextDialogOption(
              icon: Icon(CustomIcons.clock_topmost),
              text: Text('置顶于稍后阅读列表'),
              popWhenPress: c,
              onPressed: () => helper.topmostLater(later: laterManga, onUpdated: inLaterSetter, fromLaterList: false, fromMangaPage: fromMangaPage),
            ),
          if (laterManga != null)
            IconTextDialogOption(
              icon: Icon(MdiIcons.bookClock),
              text: Text('查看稍后阅读列表'),
              popWhenPress: c,
              onPressed: () => helper.gotoLaterPage(),
            ),
        ],
      ],
    ),
  );
}

// => called in ShelfSubPage and MangaShelfCachePage
void showPopupMenuForShelfCache({
  required BuildContext context,
  required bool fromCachePage,
  void Function()? customSyncer,
}) {
  if (!AuthManager.instance.logined) {
    Fluttertoast.showToast(msg: '用户未登录');
    return;
  }

  showDialog(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text('同步'),
      children: [
        IconTextDialogOption(
          icon: Icon(Icons.sync),
          text: Text('同步我的书架'),
          onPressed: () async {
            var ok = await showYesNoAlertDialog(
              context: context,
              title: Text('同步确认'),
              content: Text('是否检索并同步我的书架上的漫画？'),
              yesText: Text('同步'),
              noText: Text('取消'),
            );
            if (ok ?? false) {
              Navigator.of(c).pop();
              if (customSyncer != null) {
                customSyncer.call();
              } else {
                MangaShelfCachePage.syncShelfCaches(context);
              }
            }
          },
        ),
        if (!fromCachePage)
          IconTextDialogOption(
            icon: Icon(CustomIcons.star_sync),
            text: Text('查看已同步的书架记录'),
            onPressed: () async {
              Navigator.of(c).pop();
              Navigator.of(context).push(
                CustomPageRoute(
                  context: context,
                  builder: (c) => MangaShelfCachePage(),
                ),
              );
            },
          ),
        IconTextDialogOption(
          icon: Icon(CustomIcons.bookmark_plus),
          text: Text('添加所有记录至本地收藏'),
          onPressed: () async {
            var ok = await showYesNoAlertDialog(
              context: context,
              title: Text('添加确认'),
              content: Text('是否将已同步的所有书架记录添加至本地收藏？'),
              yesText: Text('添加'),
              noText: Text('取消'),
            );
            if (ok ?? false) {
              Navigator.of(c).pop();
              MangaShelfCachePage.addAllToFavorite(context);
            }
          },
        ),
      ],
    ),
  );
}

// => called in MangaPage and MangaViewerPage and DownloadedMangaPage
void showPopupMenuForLaterManga({
  required BuildContext context,
  required int mangaId,
  required String mangaTitle,
  required String mangaCover,
  required String mangaUrl,
  required MangaExtraDataForDialog? extraData,
  required bool fromMangaPage,
  required LaterManga laterManga,
  required void Function(LaterManga? later) inLaterSetter,
  void Function(Future<void> Function()) navigateWrapper = _navigateWrapper, // => to update system ui, for MangaViewerPage
}) async {
  var helper = _DialogHelper(
    context: context,
    mangaId: mangaId,
    mangaTitle: mangaTitle,
    mangaCover: mangaCover,
    mangaUrl: mangaUrl,
    extraData: extraData,
  );
  var later = await LaterMangaDao.getLaterManga(username: AuthManager.instance.username, mid: mangaId);

  showDialog(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text('稍后阅读'),
      children: [
        SubtitleDialogOption(
          text: Text('《$mangaTitle》(${laterManga.newestChapter ?? '未知话'}) 在 ${laterManga.formattedCreatedAtAndFullDuration} 被添加至稍后阅读列表中。'),
        ),
        IconTextDialogOption(
          icon: Icon(MdiIcons.clockMinus),
          text: Text('移出稍后阅读列表'),
          popWhenPress: c,
          predicateForPress: () => helper.showCheckRemovingLaterDialog(),
          onPressed: () => helper.addOrRemoveLater(toAdd: false, onUpdated: inLaterSetter, fromLaterList: false, fromMangaPage: fromMangaPage),
        ),
        if (later != null && extraData != null && extraData.newestChapter != null && extraData.newestDate != null && extraData.newestChapter != later.newestChapter)
          IconTextDialogOption(
            icon: Icon(CustomIcons.clock_sync),
            text: Text('更新记录至最新章节 (${extraData.newestChapter})'),
            popWhenPress: c,
            onPressed: () => helper.updateLaterToNewestChapter(later: later, onUpdated: inLaterSetter, fromLaterList: false, fromMangaPage: fromMangaPage),
          ),
        if (later != null)
          IconTextDialogOption(
            icon: Icon(CustomIcons.clock_topmost),
            text: Text('置顶于稍后阅读列表'),
            popWhenPress: c,
            onPressed: () => helper.topmostLater(later: later, onUpdated: inLaterSetter, fromLaterList: false, fromMangaPage: fromMangaPage),
          ),
        IconTextDialogOption(
          icon: Icon(MdiIcons.bookClock),
          text: Text('查看稍后阅读列表'),
          popWhenPress: c,
          onPressed: () => navigateWrapper(() => helper.gotoLaterPage()),
        ),
      ],
    ),
  );
}

void showPopupMenuForMangaTitle({required BuildContext context, required Manga? manga, required String fallbackTitle, bool vibrate = false}) {
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

void showPopupMenuForChapterTitle({
  required BuildContext context,
  required String mangaTitle,
  required String chapterTitle,
  required void Function()? onDetailsPressed,
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

class MangaExtraDataForDialog {
  const MangaExtraDataForDialog({this.mangaAuthors, this.newestChapter, this.newestDate});

  final List<String>? mangaAuthors;
  final String? newestChapter;
  final String? newestDate;

  factory MangaExtraDataForDialog.fromManga(Manga manga) => //
      MangaExtraDataForDialog(mangaAuthors: manga.authors.map((a) => a.name).toList(), newestChapter: manga.newestChapter, newestDate: manga.formattedNewestDate);

  factory MangaExtraDataForDialog.fromMangaViewer(MangaViewerPageData manga) => //
      MangaExtraDataForDialog(mangaAuthors: manga.mangaAuthors?.map((a) => a.name).toList(), newestChapter: manga.newestChapter, newestDate: manga.newestDate);

  factory MangaExtraDataForDialog.fromSmallManga(SmallManga manga) => //
      MangaExtraDataForDialog(mangaAuthors: manga.authors.map((a) => a.name).toList(), newestChapter: manga.newestChapter, newestDate: manga.formattedNewestDate);

  factory MangaExtraDataForDialog.fromSmallerManga(SmallerManga manga) => //
      MangaExtraDataForDialog(mangaAuthors: manga.authors, newestChapter: manga.newestChapter, newestDate: manga.formattedNewestDate);

  factory MangaExtraDataForDialog.fromTinyManga(TinyManga manga) => //
      MangaExtraDataForDialog(newestChapter: manga.newestChapter, newestDate: manga.formattedNewestDate);

  factory MangaExtraDataForDialog.fromMangaRanking(MangaRanking manga) => //
      MangaExtraDataForDialog(mangaAuthors: manga.authors.map((a) => a.name).toList(), newestChapter: manga.newestChapter, newestDate: manga.formattedNewestDate);

  factory MangaExtraDataForDialog.fromShelfManga(ShelfManga manga) => //
      MangaExtraDataForDialog(newestChapter: manga.newestChapter, newestDate: manga.formattedNewestDate);

  factory MangaExtraDataForDialog.fromLaterManga(LaterManga manga) => //
      MangaExtraDataForDialog(newestChapter: manga.newestChapter, newestDate: manga.newestDate);
}

class _DialogHelper {
  const _DialogHelper({
    required this.context,
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.extraData,
  });

  final BuildContext context;
  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final MangaExtraDataForDialog? extraData;

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
      builder: (c) => WillPopScope(
        onWillPop: () async {
          if (controller.text.trim().isEmpty) {
            return true;
          }
          var ok = await showYesNoAlertDialog(
            context: context,
            title: Text('收藏漫画'),
            content: Text('是否放弃当前的输入并不做任何变更？'),
            yesText: Text('放弃'),
            noText: Text('继续编辑'),
            reverseYesNoOrder: true,
          );
          return ok == true;
        },
        child: StatefulBuilder(
          builder: (c, _setState) => AlertDialog(
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
              TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).maybePop(false)),
            ],
          ),
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
              onPressed: () {
                if (group.groupName == selectedGroupName && !addToTop) {
                  // pass
                } else {
                  Navigator.of(c).pop(group);
                }
              },
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
                labelText: '漫画备注',
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

    return Tuple1(
      controller.text.trim(), // remark, empty-able
    );
  }

  static Future<bool> showFavoriteRemarkDialog({
    required BuildContext context,
    required String mangaTitle,
    required String remark,
  }) async {
    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('《$mangaTitle》备注'),
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

  Future<void> gotoDownloadMangaPage({bool gotoDownloading = false}) async {
    await Navigator.of(context).push(
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

  Future<void> gotoDownloadListPage() async {
    await Navigator.of(context).push(
      CustomPageRoute(context: context, builder: (c) => DownloadPage()),
    );
  }

  void gotoChapterPage({
    required int chapterId,
    required MangaChapterNeededData chapterNeededData,
    required MangaHistory? history,
    required bool readFirstPage,
    required bool onlineMode,
  }) {
    Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => MangaViewerPage(
          mangaId: mangaId,
          chapterId: chapterId,
          mangaTitle: mangaTitle,
          mangaCover: mangaCover,
          mangaUrl: mangaUrl,
          neededData: chapterNeededData,
          initialPage: readFirstPage
              ? 1 // require to read first page
              : history?.chapterId == chapterId
                  ? history?.chapterPage ?? 1 // have read
                  : history?.lastChapterId == chapterId
                      ? history?.lastChapterPage ?? 1 // have read
                      : 1 /* have not read */,
          onlineMode: onlineMode,
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
          onPressed: () => gotoDownloadMangaPage(gotoDownloading: true),
        ),
      ),
    );
  }

  Future<void> gotoChapterDetailsPage({required TinyMangaChapter chapter, required MangaChapterNeededData chapterNeededData}) async {
    var groupLength = chapterNeededData.chapterGroups.where((el) => el.title == chapter.group).firstOrNull?.chapters.length;
    await Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => ChapterDetailPage(
          data: chapter,
          chapterCover: null,
          groupLength: groupLength /* almost non-null */,
          mangaTitle: mangaTitle,
          mangaCover: mangaCover,
          mangaUrl: mangaUrl,
          mangaAuthors: chapterNeededData.mangaAuthors.map((a) => a.name).toList(),
          isTocLoaded: true,
        ),
      ),
    );
  }

  Future<void> gotoShelfCachePage() async {
    await Navigator.of(context).push(
      CustomPageRoute(
        context: context,
        builder: (c) => MangaShelfCachePage(),
      ),
    );
  }

  Future<void> gotoShelfPage() async {
    if (AppSetting.instance.ui.alwaysOpenNewListPage) {
      await Navigator.of(context).push(
        CustomPageRoute(
          context: context,
          builder: (c) => SepShelfPage(),
        ),
      );
    } else {
      EventBusManager.instance.fire(ToShelfRequestedEvent());
    }
  }

  Future<void> gotoFavoritePage() async {
    if (AppSetting.instance.ui.alwaysOpenNewListPage) {
      await Navigator.of(context).push(
        CustomPageRoute(
          context: context,
          builder: (c) => SepFavoritePage(),
        ),
      );
    } else {
      EventBusManager.instance.fire(ToFavoriteRequestedEvent());
    }
  }

  Future<void> gotoHistoryPage() async {
    if (AppSetting.instance.ui.alwaysOpenNewListPage) {
      await Navigator.of(context).push(
        CustomPageRoute(
          context: context,
          builder: (c) => SepHistoryPage(),
        ),
      );
    } else {
      EventBusManager.instance.fire(ToHistoryRequestedEvent());
    }
  }

  Future<void> gotoLaterPage() async {
    if (AppSetting.instance.ui.alwaysOpenNewListPage) {
      await Navigator.of(context).push(
        CustomPageRoute(
          context: context,
          builder: (c) => SepLaterPage(),
        ),
      );
    } else {
      EventBusManager.instance.fire(ToLaterRequestedEvent());
    }
  }

  // ========================
  // methods (check removing)
  // ========================

  Future<bool> showCheckRemovingShelfDialog() async {
    var ok = await showYesNoAlertDialog(context: context, title: Text('移出书架确认'), content: Text('确定将《$mangaTitle》移出书架？'), yesText: Text('移出'), noText: Text('取消'));
    return ok ?? false;
  }

  Future<bool> showCheckRemovingFavoriteDialog() async {
    var ok = await showYesNoAlertDialog(context: context, title: Text('取消收藏确认'), content: Text('确定取消收藏《$mangaTitle》？'), yesText: Text('确定'), noText: Text('取消'));
    return ok ?? false;
  }

  Future<bool> showCheckRemovingLaterDialog() async {
    var ok = await showYesNoAlertDialog(context: context, title: Text('稍后阅读确认'), content: Text('确定将《$mangaTitle》移出稍后阅读列表？'), yesText: Text('移出'), noText: Text('取消'));
    return ok ?? false;
  }

  Future<bool> showCheckRemovingHistoryDialog({required bool read, String? chapterTitle}) async {
    var verb = read ? '阅读' : '浏览';
    var ok = await showYesNoAlertDialog(context: context, title: Text('删除历史确认'), content: Text('确定删除《${chapterTitle ?? mangaTitle}》的$verb历史？'), yesText: Text('删除'), noText: Text('取消'));
    return ok ?? false;
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
      try {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(added ? '成功将漫画放入书架' : '成功将漫画移出书架')));
      } catch (_) {} // for destroyed context
      EventBusManager.instance.fire(ShelfUpdatedEvent(mangaId: mangaId, added: added, fromShelfPage: fromShelfList, fromMangaPage: fromMangaPage));
    } catch (e, s) {
      var err = wrapError(e, s).text;
      var already = err.contains('已经被'), notYet = err.contains('还没有被');
      if (already || notYet) {
        added = already;
        onUpdated?.call(added);
        try {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(added ? '漫画已经在书架上' : '漫画还未在书架上')));
        } catch (_) {} // for destroyed context
        EventBusManager.instance.fire(ShelfUpdatedEvent(mangaId: mangaId, added: added, fromShelfPage: fromShelfList, fromMangaPage: fromMangaPage));
      } else {
        try {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toAdd ? '放入书架失败，$err' : '移出书架失败，$err')));
        } catch (_) {} // for destroyed context
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

  // => called by showPopupMenuForMangaList, showPopupMenuForSubscribing, showPopupMenuForLaterManga
  Future<void> addOrRemoveLater({
    required bool toAdd,
    required void Function(LaterManga? later)? onUpdated,
    required bool fromLaterList,
    required bool fromMangaPage,
  }) async {
    // 更新数据库、(更新界面)、弹出提示、发送通知
    if (toAdd) {
      var newLaterManga = LaterManga(
        mangaId: mangaId,
        mangaTitle: mangaTitle,
        mangaCover: mangaCover,
        mangaUrl: mangaUrl,
        newestChapter: extraData?.newestChapter?.let((c) => RegExp('^[0-9]').hasMatch(c) ? '第$c' : c) /* null => 未知 */,
        newestDate: extraData?.newestDate /* null => 未知 */,
        createdAt: DateTime.now(),
      );
      await LaterMangaDao.addOrUpdateLaterManga(username: AuthManager.instance.username, manga: newLaterManga);
      onUpdated?.call(newLaterManga);
    } else {
      await LaterMangaDao.deleteLaterManga(username: AuthManager.instance.username, mid: mangaId);
      onUpdated?.call(null);
    }
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toAdd ? '已添加至稍后阅读列表' : '已从稍后阅读列表中移出')));
    EventBusManager.instance.fire(LaterUpdatedEvent(mangaId: mangaId, added: toAdd, fromLaterPage: fromLaterList, fromMangaPage: fromMangaPage));
  }

  // => called by showPopupMenuForSubscribing, showPopupMenuForLaterManga
  Future<void> topmostLater({
    required LaterManga later,
    required void Function(LaterManga? later)? onUpdated,
    required bool fromLaterList,
    required bool fromMangaPage,
  }) async {
    // 更新数据库、(更新界面)、弹出提示、发送通知
    var updatedLaterManga = later.copyWith(createdAt: DateTime.now());
    await LaterMangaDao.addOrUpdateLaterManga(username: AuthManager.instance.username, manga: updatedLaterManga);
    onUpdated?.call(updatedLaterManga);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已将本漫画置顶于稍后阅读列表')));
    EventBusManager.instance.fire(LaterUpdatedEvent(mangaId: mangaId, added: false, fromLaterPage: fromLaterList, fromMangaPage: fromMangaPage));
  }

  // => called by showPopupMenuForLaterManga
  Future<void> updateLaterToNewestChapter({
    required LaterManga later,
    required void Function(LaterManga? later)? onUpdated,
    required bool fromLaterList,
    required bool fromMangaPage,
  }) async {
    var topmost = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('更新稍后阅读记录'),
        content: Text('即将更新稍后阅读记录为本漫画的最新章节，是否同时置顶稍后阅读记录？'),
        actions: [
          TextButton(child: Text('置顶'), onPressed: () => Navigator.of(c).pop(true)),
          TextButton(child: Text('不置顶'), onPressed: () => Navigator.of(c).pop(false)),
          TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(null)),
        ],
      ),
    );
    if (topmost == null) {
      return;
    }

    var newestChapter = extraData?.newestChapter?.let((c) => RegExp('^[0-9]').hasMatch(c) ? '第$c' : c);
    var newestDate = extraData?.newestDate;
    if (newestChapter == null || newestDate == null) {
      return; // almost unreachable
    }
    var updatedLaterManga = later.copyWith(newestChapter: newestChapter, newestDate: newestDate, createdAt: topmost ? DateTime.now() : null);
    await LaterMangaDao.addOrUpdateLaterManga(username: AuthManager.instance.username, manga: updatedLaterManga);
    onUpdated?.call(updatedLaterManga);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已将本漫画的稍后阅读记录更新到最新章节')));
    EventBusManager.instance.fire(LaterUpdatedEvent(mangaId: mangaId, added: false, fromLaterPage: fromLaterList, fromMangaPage: fromMangaPage));
  }

  // => called by showPopupMenuForMangaList
  Future<void> removeHistory({
    required MangaHistory oldHistory,
    required void Function()? onRemoved,
    required void Function()? onFpCleared,
    required bool fromHistoryList,
    required bool fromMangaPage,
  }) async {
    // 更新数据库、(更新界面)、弹出提示、发送通知
    await HistoryDao.deleteHistory(username: AuthManager.instance.username, mid: mangaId);
    onRemoved?.call();
    await HistoryDao.clearMangaFootprints(username: AuthManager.instance.username, mid: mangaId);
    onFpCleared?.call();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(oldHistory.read ? '漫画阅读历史已删除' : '漫画浏览历史已删除')));
    EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: mangaId, reason: UpdateReason.deleted, fromHistoryPage: fromHistoryList, fromMangaPage: fromMangaPage));
    EventBusManager.instance.fire(FootprintUpdatedEvent(mangaId: mangaId, chapterIds: null, reason: UpdateReason.deleted, fromMangaPage: fromMangaPage));
  }

  // => called by showPopupMenuForMangaToc
  Future<void> removeChapterHistory({
    required MangaHistory oldHistory,
    required int chapterId,
    required void Function(MangaHistory newHistory)? onUpdated,
    required void Function(List<int> chapterIds)? onFpRemoved,
    required bool fromHistoryList,
    required bool fromMangaPage,
  }) async {
    // 更新数据库、(更新界面)、弹出提示、发送通知
    MangaHistory? newHistory;
    var removedFpCids = <int>[];
    if (oldHistory.chapterId == chapterId) {
      newHistory = oldHistory.copyWith(
        chapterId: oldHistory.lastChapterId /* last延续上来 */,
        chapterTitle: oldHistory.lastChapterTitle,
        chapterPage: oldHistory.lastChapterPage,
        lastChapterId: 0 /* 未开始阅读 */,
        lastChapterTitle: '',
        lastChapterPage: 1,
        lastTime: DateTime.now(),
      ); // 更新漫画历史
      removedFpCids.add(chapterId);
    } else if (oldHistory.lastChapterId == chapterId) {
      newHistory = oldHistory.copyWith(
        lastChapterId: 0 /* 未开始阅读 */,
        lastChapterTitle: '',
        lastChapterPage: 1,
        lastTime: DateTime.now(),
      ); // 更新漫画历史
      removedFpCids.add(chapterId);
    } else {
      newHistory = null; // 无需更新漫画历史
      removedFpCids.add(chapterId); // 仅删除章节历史
    }

    if (newHistory != null) {
      await HistoryDao.addOrUpdateHistory(username: AuthManager.instance.username, history: newHistory);
      onUpdated?.call(newHistory);
    }
    if (removedFpCids.isNotEmpty) {
      for (var cid in removedFpCids) {
        await HistoryDao.deleteFootprint(username: AuthManager.instance.username, mid: mangaId, cid: cid);
      }
      onFpRemoved?.call(removedFpCids);
    }

    if (newHistory != null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('章节阅读历史已删除')));
      EventBusManager.instance.fire(HistoryUpdatedEvent(mangaId: mangaId, reason: UpdateReason.updated, fromHistoryPage: fromHistoryList, fromMangaPage: fromMangaPage));
    }
    if (removedFpCids.isNotEmpty) {
      EventBusManager.instance.fire(FootprintUpdatedEvent(mangaId: mangaId, chapterIds: removedFpCids, reason: UpdateReason.deleted, fromMangaPage: fromMangaPage));
    }
  }

  // => called by showPopupMenuForMangaToc
  Future<void> addChapterFootprint({
    required int chapterId,
    required void Function(ChapterFootprint)? onAdded,
    required bool fromHistoryList,
    required bool fromMangaPage,
  }) async {
    var newFootprint = ChapterFootprint(mangaId: mangaId, chapterId: chapterId, createdAt: DateTime.now());
    await HistoryDao.addOrUpdateFootprint(username: AuthManager.instance.username, footprint: newFootprint);
    onAdded?.call(newFootprint);
    EventBusManager.instance.fire(FootprintUpdatedEvent(mangaId: mangaId, chapterIds: [chapterId], reason: UpdateReason.added, fromMangaPage: fromMangaPage));
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
    required void Function(List<FavoriteManga> newFavorites, bool addToTop)? onUpdated,
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
    onUpdated?.call(oldNewFavorites.map((t) => t.item2).toList(), addToTop);
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

  // => called by showUpdateFavoriteRemarkDialog
  Future<void> updateFavRemark({
    required FavoriteManga oldFavorite,
    required void Function(FavoriteManga newFavorite)? onUpdated,
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
    onUpdated?.call(newFavorite);
    if (showSnackBar) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newRemark == '' ? '已删除收藏备注' : '已将备注修改为 "$newRemark"')));
    }
    EventBusManager.instance.fire(FavoriteUpdatedEvent(mangaId: mangaId, group: newFavorite.groupName, reason: UpdateReason.updated, fromFavoritePage: fromFavoriteList, fromMangaPage: fromMangaPage));
  }

  // => called by showPopupMenuForSubscribing
  Future<void> showAndUpdateFavRemark({
    required FavoriteManga favorite,
    required void Function(FavoriteManga newFavorite)? onUpdated,
    required bool showSnackBar,
    required bool fromFavoriteList,
    required bool fromMangaPage,
  }) async {
    var toEdit = await showFavoriteRemarkDialog(context: context, remark: favorite.remark.trim(), mangaTitle: mangaTitle);
    if (toEdit) {
      await updateFavRemark(
        oldFavorite: favorite,
        onUpdated: onUpdated,
        showSnackBar: showSnackBar,
        fromFavoriteList: fromFavoriteList,
        fromMangaPage: fromMangaPage,
      );
    }
  }
}
