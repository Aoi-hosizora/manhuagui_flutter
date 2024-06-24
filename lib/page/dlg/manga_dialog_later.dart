part of 'manga_dialog.dart';

// => called in MangaPage and MangaViewerPage and DownloadedMangaPage
Future<void> showPopupMenuForLaterManga({
  required BuildContext context,
  required int mangaId,
  required String mangaTitle,
  required String mangaCover,
  required String mangaUrl,
  required MangaExtraDataForDialog? extraData,
  required LaterManga laterManga,
  required EventSource eventSource,
  // ===
  NavigateWrapper? navigateWrapper, // => to update system ui, for MangaViewerPage
  // ===
  required LaterUpdatedCallback? onLaterUpdated,
  required NotateClearedCallback? onNotateCleared,
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
  var laterChapterCount = await LaterMangaDao.getLaterChapterCount(username: AuthManager.instance.username, mid: mangaId) ?? 0;

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
          predicateForPress: () => helper.showCheckRemovingLaterDialog(laterChapterCount: laterChapterCount),
          onPressed: () => helper.removeLater(onRemoved: () => onLaterUpdated?.call(null), onLaterChapterCleared: onNotateCleared, eventSource: eventSource),
        ),
        if (later != null && extraData != null && extraData.newestChapter != null && extraData.newestDate != null && extraData.newestChapter != later.newestChapter)
          IconTextDialogOption(
            icon: Icon(CustomIcons.clock_sync),
            text: Flexible(
              child: Text('更新记录至最新章节 (${extraData.newestChapter})', maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            popWhenPress: c,
            onPressed: () => helper.updateLaterToNewestChapterWithDlg(later: later, onUpdated: onLaterUpdated, eventSource: eventSource),
          ),
        if (later != null)
          IconTextDialogOption(
            icon: Icon(CustomIcons.clock_topmost),
            text: Text('置顶于稍后阅读列表'),
            popWhenPress: c,
            onPressed: () => helper.topmostLater(later: later, onUpdated: onLaterUpdated, eventSource: eventSource),
          ),
        if (laterChapterCount > 0)
          IconTextDialogOption(
            icon: Icon(CustomIcons.clock_delete),
            text: Text('取消章节的稍后阅读标记 (共 $laterChapterCount 个)'),
            popWhenPress: c,
            predicateForPress: () => helper.showCheckClearingLaterChapterDialog(laterChapterCount: laterChapterCount),
            onPressed: () => helper.clearChapterLaters(onCleared: onNotateCleared, eventSource: eventSource),
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
