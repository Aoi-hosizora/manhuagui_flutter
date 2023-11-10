part of 'manga_dialog.dart';

/// 一个 Helper 类，仅被 [manga_dialog.dart] 使用
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
      builder: (c) => SimpleDialog(
        title: Text('更新稍后阅读记录'),
        children: [
          SubtitleDialogOption(
            text: Text('确定将《${later.mangaTitle}》的稍后阅读记录最新为最新章节 "${extraData?.newestChapter}"？'),
          ),
          IconTextDialogOption(icon: Icon(CustomIcons.clock_topmost), text: Text('更新且置顶'), onPressed: () => Navigator.of(c).pop(true)),
          IconTextDialogOption(icon: Icon(CustomIcons.clock_sync), text: Text('更新且不置顶'), onPressed: () => Navigator.of(c).pop(false)),
          IconTextDialogOption(icon: Icon(Icons.do_not_disturb), text: Text('不更新'), onPressed: () => Navigator.of(c).pop(null)),
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
      newHistory = oldHistory.copyWithNoCurrChapterOnly(lastTime: DateTime.now()); // 更新漫画历史
      removedFpCids.add(chapterId);
    } else if (oldHistory.lastChapterId == chapterId) {
      newHistory = oldHistory.copyWithNoLastChapterOnly(lastTime: DateTime.now()); // 更新漫画历史
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

  // => called by showPopupMenuForMangaToc
  Future<void> markChapterLater({
    required int chapterId,
    required String chapterTitle,
    required void Function(LaterChapter)? onAdded,
    required bool fromMangaPage,
  }) async {
    var newLater = LaterChapter(mangaId: mangaId, chapterId: chapterId, chapterTitle: chapterTitle, createdAt: DateTime.now());
    await LaterMangaDao.addOrUpdateLaterChapter(username: AuthManager.instance.username, chapter: newLater);
    onAdded?.call(newLater);
    EventBusManager.instance.fire(LaterChapterUpdatedEvent(mangaId: mangaId, chapterId: chapterId, added: true, fromMangaPage: fromMangaPage));
  }

  // => called by showPopupMenuForMangaToc
  Future<void> unmarkChapterLater({
    required int chapterId,
    required void Function(int)? onRemoved,
    required bool fromMangaPage,
  }) async {
    await LaterMangaDao.deleteLaterChapter(username: AuthManager.instance.username, mid: mangaId, cid: chapterId);
    onRemoved?.call(chapterId);
    EventBusManager.instance.fire(LaterChapterUpdatedEvent(mangaId: mangaId, chapterId: chapterId, added: false, fromMangaPage: fromMangaPage));
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
