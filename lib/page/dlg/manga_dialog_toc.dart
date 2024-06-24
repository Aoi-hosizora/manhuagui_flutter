part of 'manga_dialog.dart';

// => called in MangaPage, MangaTocPage (for MangaPage and MangaViewerPage), MangaHistoryPage
Future<void> showPopupMenuForMangaToc({
  required BuildContext context,
  required int mangaId,
  required String mangaTitle,
  required String mangaCover,
  required String mangaUrl,
  required TinyMangaChapter chapter,
  required MangaExtraDataForViewer extraData,
  required EventSource eventSource,
  // ===
  bool Function(int chapterId)? canOperateHistory, // => only for current chapter in MangaViewerPage
  VoidCallback? toSwitchChapter, // => only for switching chapter in MangaViewerPage
  NavigateWrapper? navigateWrapper, // => to update system ui, for MangaViewerPage
  // ===
  required HistoryUpdatedCallback? onHistoryUpdated,
  required FootprintUpdatedCallback? onFootprintUpdated,
  required LaterUpdatedCallback? onLaterUpdated,
  required NotateUpdatedCallback? onNotateUpdated,
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
            onPressed: () => helper.unmarkChapterLater(chapterId: chapter.cid, onRemoved: (_) => onNotateUpdated?.call(null), eventSource: eventSource),
          ),
        if (!isLaterChapter)
          IconTextDialogOption(
            icon: Icon(MdiIcons.clockPlus),
            text: Text('标记为稍后阅读'),
            popWhenPress: c,
            onPressed: () => helper.markChapterLater(chapterId: chapter.cid, extraData: extraData, onLmAdded: onLaterUpdated, onAdded: onNotateUpdated, eventSource: eventSource),
          ),

        /// 历史
        if (allowOperatingHistory && (isInHistory || isInFootprint))
          IconTextDialogOption(
            icon: Icon(CustomIcons.history_minus),
            text: Text('删除阅读历史'),
            popWhenPress: c,
            predicateForPress: () => helper.showCheckRemovingFootprintDialog(chapterTitle: chapter.title),
            onPressed: () => helper.removeFootprint(oldHistory: historyEntity!, chapterId: chapter.cid, onUpdated: onHistoryUpdated, onFpRemoved: (_) => onNotateUpdated?.call(null), eventSource: eventSource),
          ),
        if (allowOperatingHistory && !(isInHistory || isInFootprint))
          IconTextDialogOption(
            icon: Icon(CustomIcons.history_plus),
            text: Text('记录为已阅读'),
            popWhenPress: c,
            onPressed: () => helper.addFootprint(chapterId: chapter.cid, onAdded: onFootprintUpdated, eventSource: eventSource),
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
