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

part 'manga_dialog_helper.dart';

/// 漫画列表页-漫画弹出菜单 [showPopupMenuForMangaList]
/// 漫画收藏页-移动分组对话框 [showUpdateFavoriteMangasGroupDialog]
/// 漫画收藏页-修改备注对话框 [showUpdateFavoriteMangaRemarkDialog]
/// 漫画页/章节页-漫画章节弹出菜单 [showPopupMenuForMangaToc]
/// 漫画页/章节页-漫画订阅对话框 [showPopupMenuForSubscribing]
/// 漫画页/书架同步页-同步书架对话框 [showPopupMenuForShelfCache]
/// 漫画页/章节页/漫画下载页-稍后阅读对话框 [showPopupMenuForLaterManga]
/// 漫画页-标题对话框 [showPopupMenuForMangaTitle]
/// 章节页-标题对话框 [showPopupMenuForChapterTitle]

typedef NavigateWrapper = Future<void> Function(Future<void> Function());

Future<void> _navigateWrapper(Future<void> Function() navigate) => navigate();

// ==================
// manga list related
// ==================

// => called by pages which contains manga line view (tiny / ranking / *shelf* / *favorite* / *history* / *later* / download / aud_ranking) and DownloadMangaPage
Future<void> showPopupMenuForMangaList({
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
  var lcCount = await LaterMangaDao.getLaterChapterCount(username: AuthManager.instance.username, mid: mangaId) ?? 0;
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
            predicateForPress: !nowInLater ? null : () => helper.showCheckRemovingLaterDialog(lcCount: lcCount),
            onPressed: () => !nowInLater //
                ? helper.addLater(onAdded: (l) => inLaterSetter?.call(true), fromLaterList: fromLaterList, fromMangaPage: false)
                : helper.removeLater(onRemoved: () => inLaterSetter?.call(false), onLcCleared: null, fromLaterList: fromLaterList, fromMangaPage: false),
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
                        onPressed: () => helper.updateFavGroupWithDlg(oldFavorite: favoriteManga, onUpdated: favoriteSetter, showSnackBar: true, fromFavoriteList: fromFavoriteList, fromMangaPage: false),
                      ),
                      IconTextDialogOption(
                        icon: Icon(MdiIcons.commentBookmark),
                        text: Text('查看或修改收藏备注'),
                        popWhenPress: c,
                        onPressed: () => helper.showAndUpdateFavRemarkWithDlg(favorite: favoriteManga, onUpdated: favoriteSetter, showSnackBar: true, fromFavoriteList: fromFavoriteList, fromMangaPage: false),
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
                          onPressed: () => helper.updateLaterToNewestChapterWithDlg(later: laterManga, onUpdated: laterSetter, fromLaterList: false, fromMangaPage: false),
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

// ================
// favorite related
// ================

// => called in FavoriteSubPage and FavoriteAllPage
Future<void> showUpdateFavoriteMangasGroupDialog({
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
  await helper.updateFavsGroupWithDlg(
    oldFavorites: favorites,
    selectedGroupName: selectedGroupName,
    onUpdated: onUpdated,
    showToast: true,
    fromFavoriteList: fromFavoriteList,
    fromMangaPage: false,
  );
}

// => called in FavoriteSubPage and FavoriteAllPage
Future<void> showUpdateFavoriteMangaRemarkDialog({
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
  await helper.updateFavRemarkWithDlg(
    oldFavorite: favorite,
    onUpdated: onUpdated,
    showSnackBar: false,
    fromFavoriteList: fromFavoriteList,
    fromMangaPage: false,
  );
}

// =================
// manga toc related
// =================

// => called in MangaPage, MangaTocPage (for MangaPage and MangaViewerPage), MangaHistoryPage
Future<void> showPopupMenuForMangaToc({
  required BuildContext context,
  required int mangaId,
  required String mangaTitle,
  required String mangaCover,
  required String mangaUrl,
  required bool fromMangaPage,
  required bool fromMangaTocPage,
  required bool fromMangaHistoryPage,
  required TinyMangaChapter chapter,
  required MangaExtraDataForViewer extraData,
  required void Function(MangaHistory history)? onHistoryUpdated,
  required void Function(ChapterFootprint footprint)? onFootprintAdded,
  required void Function(List<ChapterFootprint> footprints)? onFootprintsAdded,
  required void Function(List<int> chapterIds)? onFootprintsRemoved,
  required void Function(LaterManga later)? onLaterAdded,
  required void Function(LaterChapter later)? onLaterMarked,
  required void Function(int chapterId)? onLaterUnmarked,
  bool Function(int chapterId)? canOperateHistory,
  void Function()? toSwitchChapter, // => only for switching chapter in MangaViewerPage
  NavigateWrapper? navigateWrapper, // => to update system ui, for MangaViewerPage
}) async {
  var downloadEntity = await DownloadDao.getManga(mid: mangaId);
  var inDownloadTask = downloadEntity?.findChapter(chapter.cid) != null;
  var historyEntity = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: mangaId);
  var isInHistory = historyEntity?.chapterId == chapter.cid || historyEntity?.lastChapterId == chapter.cid;
  var readChapterPage = historyEntity?.chapterId == chapter.cid ? historyEntity!.chapterPage : (historyEntity?.lastChapterId == chapter.cid ? historyEntity?.lastChapterPage : null);
  var allowOperatingHistory = canOperateHistory?.call(chapter.cid) ?? true;
  var isInFootprint = await HistoryDao.checkFootprintExistence(username: AuthManager.instance.username, mid: mangaId, cid: chapter.cid) ?? false;
  var isLaterChapter = await LaterMangaDao.checkChapterExistence(username: AuthManager.instance.username, mid: mangaId, cid: chapter.cid) ?? false;

  var helper = _DialogHelper(
    context: context,
    mangaId: mangaId,
    mangaTitle: mangaTitle,
    mangaCover: mangaCover,
    mangaUrl: mangaUrl,
    extraData: extraData.toExtraDataForDialog(),
  );

  navigateWrapper ??= _navigateWrapper;
  showDialog(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text(chapter.title),
      children: [
        /// 基本选项
        if (toSwitchChapter == null) ...[
          IconTextDialogOption(
            icon: Icon(!isInHistory ? Icons.import_contacts : CustomIcons.opened_book_arrow_right),
            text: Text(!isInHistory ? '阅读该章节 (第1页)' : '继续阅读该章节 (第${readChapterPage ?? 1}页)'),
            popWhenPress: c,
            onPressed: () => helper.gotoChapterPage(chapterId: chapter.cid, extraData: extraData, history: historyEntity, readFirstPage: false, onlineMode: true),
          ),
          if (isInHistory && ((readChapterPage ?? 1) > 1))
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_book_replay),
              text: Text('从头阅读该章节 (第1页)'),
              popWhenPress: c,
              onPressed: () => helper.gotoChapterPage(chapterId: chapter.cid, extraData: extraData, history: historyEntity, readFirstPage: true, onlineMode: true),
            ),
          if (inDownloadTask)
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_book_offline),
              text: Text('离线阅读该章节 (第1页)'),
              popWhenPress: c,
              onPressed: () => helper.gotoChapterPage(chapterId: chapter.cid, extraData: extraData, history: historyEntity, readFirstPage: true, onlineMode: false),
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
            onPressed: () => helper.downloadSingleChapter(chapterId: chapter.cid, chapterTitle: chapter.title, chapterGroups: extraData.chapterGroups),
          ),
        if (inDownloadTask)
          IconTextDialogOption(
            icon: Icon(Icons.download),
            text: Text('查看下载详情'),
            popWhenPress: c,
            onPressed: () => navigateWrapper?.call(() => helper.gotoDownloadMangaPage()),
          ),

        /// 稍后
        if (isLaterChapter)
          IconTextDialogOption(
            icon: Icon(MdiIcons.clockMinus),
            text: Text('取消标记稍后阅读'),
            popWhenPress: c,
            predicateForPress: () => helper.showCheckUnmarkingLaterChapterDialog(chapterTitle: chapter.title),
            onPressed: () => helper.unmarkChapterLater(chapterId: chapter.cid, onRemoved: onLaterUnmarked, fromMangaPage: fromMangaPage, fromMangaTocPage: fromMangaTocPage, fromMangaHistoryPage: fromMangaHistoryPage),
          ),
        if (!isLaterChapter)
          IconTextDialogOption(
            icon: Icon(MdiIcons.clockPlus),
            text: Text('标记为稍后阅读'),
            popWhenPress: c,
            onPressed: () => helper.markChapterLater(chapterId: chapter.cid, extraData: extraData, onLmAdded: onLaterAdded, onAdded: onLaterMarked, fromMangaPage: fromMangaPage, fromMangaTocPage: fromMangaTocPage, fromMangaHistoryPage: fromMangaHistoryPage),
          ),

        /// 历史
        if (allowOperatingHistory && (isInHistory || isInFootprint))
          IconTextDialogOption(
            icon: Icon(CustomIcons.history_minus),
            text: Text('删除阅读历史'),
            popWhenPress: c,
            predicateForPress: () => helper.showCheckRemovingFootprintDialog(chapterTitle: chapter.title),
            onPressed: () => helper.removeFootprint(oldHistory: historyEntity!, chapterId: chapter.cid, onUpdated: onHistoryUpdated, onFpRemoved: onFootprintsRemoved, fromHistoryList: false, fromMangaPage: fromMangaPage, fromMangaTocPage: fromMangaTocPage, fromMangaHistoryPage: fromMangaHistoryPage),
          ),
        if (allowOperatingHistory && !(isInHistory || isInFootprint))
          IconTextDialogOption(
            icon: Icon(CustomIcons.history_plus),
            text: Text('记录为已阅读'),
            popWhenPress: c,
            onPressed: () => helper.addFootprint(chapterId: chapter.cid, onAdded: onFootprintAdded, fromHistoryList: false, fromMangaPage: fromMangaPage, fromMangaTocPage: fromMangaTocPage, fromMangaHistoryPage: fromMangaHistoryPage),
          ),

        /// 查看信息
        IconTextDialogOption(
          icon: Icon(Icons.subject),
          text: Text('查看章节信息'),
          popWhenPress: c,
          onPressed: () => navigateWrapper?.call(() => helper.gotoChapterDetailsPage(chapter: chapter, extraData: extraData)),
        ),
      ],
    ),
  );
}

// ===========================
// subscribe and later related
// ===========================

// => called in MangaPage and MangaViewerPage
Future<void> showPopupMenuForSubscribing({
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
}) async {
  var helper = _DialogHelper(
    context: context,
    mangaId: mangaId,
    mangaTitle: mangaTitle,
    mangaCover: mangaCover,
    mangaUrl: mangaUrl,
    extraData: extraData,
  );

  var lcCount = await LaterMangaDao.getLaterChapterCount(username: AuthManager.instance.username, mid: mangaId) ?? 0;
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
            onPressed: () => helper.addLater(onAdded: inLaterSetter, fromLaterList: false, fromMangaPage: fromMangaPage),
          ),
        if (nowInLater)
          IconTextDialogOption(
            icon: Icon(MdiIcons.clockMinus),
            text: Text('移出稍后阅读列表'),
            popWhenPress: c,
            predicateForPress: () => helper.showCheckRemovingLaterDialog(lcCount: lcCount),
            onPressed: () => helper.removeLater(onRemoved: () => inLaterSetter(null), onLcCleared: null, fromLaterList: false, fromMangaPage: fromMangaPage),
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
              onPressed: () => helper.updateFavGroupWithDlg(oldFavorite: favoriteManga, onUpdated: inFavoriteSetter, showSnackBar: true, fromFavoriteList: false, fromMangaPage: fromMangaPage),
            ),
          if (favoriteManga != null)
            IconTextDialogOption(
              icon: Icon(MdiIcons.commentBookmark),
              text: Flexible(
                child: Text('当前收藏备注：${favoriteManga.remark.trim().isEmpty ? '暂无' : favoriteManga.remark.trim()}', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              popWhenPress: c,
              onPressed: () => helper.showAndUpdateFavRemarkWithDlg(favorite: favoriteManga, onUpdated: inFavoriteSetter, showSnackBar: true, fromFavoriteList: false, fromMangaPage: fromMangaPage),
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

// => called in MangaPage and MangaViewerPage and DownloadedMangaPage
Future<void> showPopupMenuForLaterManga({
  required BuildContext context,
  required int mangaId,
  required String mangaTitle,
  required String mangaCover,
  required String mangaUrl,
  required MangaExtraDataForDialog? extraData,
  required bool fromMangaPage,
  required LaterManga laterManga,
  required void Function(LaterManga? later)? onLaterUpdated,
  required void Function()? onLcCleared,
  NavigateWrapper? navigateWrapper, // => to update system ui, for MangaViewerPage
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
  var lcCount = await LaterMangaDao.getLaterChapterCount(username: AuthManager.instance.username, mid: mangaId) ?? 0;

  navigateWrapper ??= _navigateWrapper;
  showDialog(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text('稍后阅读'),
      children: [
        SubtitleDialogOption(
          text: Text(
            [
              '漫画标题：《$mangaTitle》',
              if (extraData == null || laterManga.newestChapter == extraData.newestChapter) //
                '最新章节：${laterManga.newestChapter ?? '未知话'}',
              if (extraData != null && laterManga.newestChapter != extraData.newestChapter) //
                '最新章节：${laterManga.newestChapter ?? '未知话'} (可更新为 ${extraData.newestChapter})',
              '添加时间：${laterManga.formattedCreatedAtAndFullDuration}',
            ].join('\n'),
          ),
        ),
        IconTextDialogOption(
          icon: Icon(MdiIcons.clockMinus),
          text: Text('移出稍后阅读列表'),
          popWhenPress: c,
          predicateForPress: () => helper.showCheckRemovingLaterDialog(lcCount: lcCount),
          onPressed: () => helper.removeLater(onRemoved: () => onLaterUpdated?.call(null), onLcCleared: null, fromLaterList: false, fromMangaPage: fromMangaPage),
        ),
        if (later != null && extraData != null && extraData.newestChapter != null && extraData.newestDate != null && extraData.newestChapter != later.newestChapter)
          IconTextDialogOption(
            icon: Icon(CustomIcons.clock_sync),
            text: Flexible(
              child: Text('更新记录至最新章节 (${extraData.newestChapter})', maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            popWhenPress: c,
            onPressed: () => helper.updateLaterToNewestChapterWithDlg(later: later, onUpdated: onLaterUpdated, fromLaterList: false, fromMangaPage: fromMangaPage),
          ),
        if (later != null)
          IconTextDialogOption(
            icon: Icon(CustomIcons.clock_topmost),
            text: Text('置顶于稍后阅读列表'),
            popWhenPress: c,
            onPressed: () => helper.topmostLater(later: later, onUpdated: onLaterUpdated, fromLaterList: false, fromMangaPage: fromMangaPage),
          ),
        if (lcCount > 0)
          IconTextDialogOption(
            icon: Icon(CustomIcons.clock_delete),
            text: Text('取消章节的稍后阅读标记 (共 $lcCount 个)'),
            popWhenPress: c,
            predicateForPress: () => helper.showCheckClearingLaterChapterDialog(lcCount: lcCount),
            onPressed: () => helper.clearChapterLaters(onCleared: onLcCleared, fromMangaPage: fromMangaPage),
          ),
        IconTextDialogOption(
          icon: Icon(MdiIcons.bookClock),
          text: Text('查看稍后阅读列表'),
          popWhenPress: c,
          onPressed: () => navigateWrapper?.call(() => helper.gotoLaterPage()),
        ),
      ],
    ),
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
