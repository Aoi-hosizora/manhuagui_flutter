import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';

/// 漫画页-阅读章节对话框 [checkAndShowSwitchChapterDialogForMangaReadChapter]
/// 漫画页-继续阅读对话框 [checkAndShowSwitchChapterDialogForMangaContinueToRead]
/// 漫画章节阅读页-阅读章节对话框 [checkAndShowSwitchChapterDialogForViewer]
/// 漫画下载管理页-阅读章节对话框 [checkAndShowSwitchChapterDialogForDownload]
/// 用于获取上下章节的章节分组列表扩展 [MangaChapterGroupListExtension.findChapterNeighbor]

// => called in MangaPage
Future<void> checkAndShowSwitchChapterDialogForMangaReadChapter({
  required BuildContext context,
  required int mangaId,
  required int chapterId,
  required List<MangaChapterGroup> chapterGroups,
  required void Function({required int cid, required int page}) toReadChapter,
}) async {
  var history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: mangaId);
  if (history == null || (history.chapterId != chapterId && history.lastChapterId != chapterId)) {
    // (1) 所选章节不是上次/上上次阅读的章节 => 直接从第一页阅读
    toReadChapter(cid: chapterId, page: 1);
    return;
  }

  // (2) 所选章节在上次/上上次被阅读 => 弹出选项判断是否需要阅读
  var historyTitle = history.chapterId == chapterId ? history.chapterTitle : history.lastChapterTitle;
  var historyPage = history.chapterId == chapterId ? history.chapterPage : history.lastChapterPage;
  var chapter = chapterGroups.findChapter(chapterId);
  if (chapter == null) {
    showYesNoAlertDialog(context: context, title: Text('章节阅读'), content: Text('未找到所选章节，无法阅读。'), yesText: Text('确定'), noText: null);
    return; // actually unreachable
  }
  var checkNotfin = AppSetting.instance.ui.readGroupBehavior.needCheckNotfin(currentPage: historyPage, totalPage: chapter.pageCount); // 是否检查"未阅读完"
  var checkFinish = AppSetting.instance.ui.readGroupBehavior.needCheckFinish(currentPage: historyPage, totalPage: chapter.pageCount); // 是否检查"已阅读完"
  if (!checkNotfin && !checkFinish) {
    // (2.1) 所选章节无需弹出提示 => 继续阅读
    toReadChapter(cid: chapterId, page: historyPage);
  } else if (checkNotfin) {
    // (2.2) 所选章节需要弹出提示 (未阅读完) => 根据所选选项来确定阅读行为
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('章节阅读'),
        children: [
          SubtitleDialogOption(
            text: Text('该章节 ($historyTitle) 已阅读至第$historyPage页 (共${chapter.pageCount}页)，是否继续阅读该页？'),
          ),
          IconTextDialogOption(
            icon: Icon(CustomIcons.opened_book_arrow_right),
            text: Flexible(
              child: Text('继续阅读该章节 ($historyTitle 第$historyPage页)', maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            popWhenPress: c,
            onPressed: () => toReadChapter(cid: chapterId, page: historyPage),
          ),
          if (historyPage > 1)
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_book_replay),
              text: Flexible(
                child: Text('从头阅读该章节 ($historyTitle 第1页)', maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              popWhenPress: c,
              onPressed: () => toReadChapter(cid: chapterId, page: 1),
            ),
        ],
      ),
    );
  } else {
    // (2.3) 所选章节需要弹出提示 (已阅读完) => 寻找下一章节，再根据所选选项来确定阅读行为
    var neighbor = chapterGroups.findNextChapter(chapterId); // 从全部分组的章节中选取上下章节
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('章节阅读'),
        children: [
          SubtitleDialogOption(
            text: Text(
              neighbor != null && neighbor.hasNextChapter
                  ? '该章节 ($historyTitle) 已阅读至最后一页 (第$historyPage页)，是否继续下一章节该页？' // 已找到下一个章节 (可能会找到两个)
                  : '该章节 ($historyTitle) 已阅读至最后一页 (第$historyPage页)，且暂无下一章节，是否继续阅读该章节？', // 未找到下一个章节
            ),
          ),
          if (neighbor?.nextSameGroupChapter != null)
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_left_star_book),
              text: Flexible(
                child: Text('开始阅读新章节 (${neighbor!.nextSameGroupChapter!.title} 第1页)', maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              popWhenPress: c,
              onPressed: () => toReadChapter(cid: neighbor.nextSameGroupChapter!.cid, page: 1),
            ),
          if (neighbor?.nextDiffGroupChapter != null)
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_left_star_book),
              text: Flexible(
                child: Text('开始阅读新章节 (${neighbor!.nextDiffGroupChapter!.title} 第1页)', maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              popWhenPress: c,
              onPressed: () => toReadChapter(cid: neighbor.nextDiffGroupChapter!.cid, page: 1),
            ),
          if (historyPage > 1)
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_book_replay),
              text: Flexible(
                child: Text('从头阅读该章节 ($historyTitle 第1页)', maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              popWhenPress: c,
              onPressed: () => toReadChapter(cid: chapterId, page: 1),
            ),
          IconTextDialogOption(
            icon: Icon(CustomIcons.opened_book_arrow_right),
            text: Flexible(
              child: Text('继续阅读该章节 ($historyTitle 第$historyPage页)', maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            popWhenPress: c,
            onPressed: () => toReadChapter(cid: chapterId, page: historyPage),
          ),
        ],
      ),
    );
  }
}

// => called in MangaPage
Future<void> checkAndShowSwitchChapterDialogForMangaContinueToRead({
  required BuildContext context,
  required int mangaId,
  required List<MangaChapterGroup> chapterGroups,
  required void Function() toReadFirstChapter,
  required void Function({required int cid, required int page}) toReadChapter,
}) async {
  var history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: mangaId);
  if (history == null || !history.read) {
    // (1) 未访问 or 未开始阅读 => 开始阅读
    toReadFirstChapter.call();
    return;
  }

  // (2) 存在阅读历史 => 进一步判断阅读状态
  var historyCid = history.chapterId;
  var historyTitle = history.chapterTitle;
  var historyPage = history.chapterPage;
  var chapter = chapterGroups.findChapter(historyCid);
  if (chapter == null) {
    showYesNoAlertDialog(context: context, title: Text('章节阅读'), content: Text('未找到所选章节，无法阅读。'), yesText: Text('确定'), noText: null);
    return; // actually unreachable
  }
  var checkNotfin = AppSetting.instance.ui.readGroupBehavior.needCheckNotfin(currentPage: historyPage, totalPage: chapter.pageCount); // 是否检查"未阅读完"
  if (chapter.pageCount != historyPage && !checkNotfin) {
    // (2.1) 章节未阅读完，且无需弹出提示 => 继续阅读
    toReadChapter(cid: historyCid, page: historyPage); // 继续阅读
  } else if (chapter.pageCount != historyPage && checkNotfin) {
    // (2.2) 章节未阅读完，且需要弹出提示 => 根据所选选项来确定阅读行为
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('继续阅读'),
        children: [
          SubtitleDialogOption(
            text: Text('该章节 ($historyTitle) 已阅读至第$historyPage页 (共${chapter.pageCount}页)，是否继续阅读该页？'),
          ),
          IconTextDialogOption(
            icon: Icon(CustomIcons.opened_book_arrow_right),
            text: Flexible(
              child: Text('继续阅读该章节 ($historyTitle 第$historyPage页)', maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            popWhenPress: c,
            onPressed: () => toReadChapter(cid: historyCid, page: historyPage),
          ),
          if (historyPage > 1)
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_book_replay),
              text: Flexible(
                child: Text('从头阅读该章节 ($historyTitle 第1页)', maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              popWhenPress: c,
              onPressed: () => toReadChapter(cid: historyCid, page: 1),
            ),
        ],
      ),
    );
  } else {
    // (2.3) 该章节已阅读完 => 寻找下一章节，再根据所选选项来确定阅读行为
    var neighbor = chapterGroups.findNextChapter(historyCid); // 从全部分组的章节中选取上下章节
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('继续阅读'),
        children: [
          SubtitleDialogOption(
            text: Text(
              neighbor != null && neighbor.hasNextChapter
                  ? '该章节 ($historyTitle) 已阅读至最后一页 (第$historyPage页)，是否继续下一章节该页？' // 已找到下一个章节 (可能会找到两个)
                  : '该章节 ($historyTitle) 已阅读至最后一页 (第$historyPage页)，且暂无下一章节，是否继续阅读该章节？', // 未找到下一个章节
            ),
          ),
          if (neighbor?.nextSameGroupChapter != null)
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_left_star_book),
              text: Flexible(
                child: Text('开始阅读新章节 (${neighbor!.nextSameGroupChapter!.title} 第1页)', maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              popWhenPress: c,
              onPressed: () => toReadChapter(cid: neighbor.nextSameGroupChapter!.cid, page: 1),
            ),
          if (neighbor?.nextDiffGroupChapter != null)
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_left_star_book),
              text: Flexible(
                child: Text('开始阅读新章节 (${neighbor!.nextDiffGroupChapter!.title} 第1页)', maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              popWhenPress: c,
              onPressed: () => toReadChapter(cid: neighbor.nextDiffGroupChapter!.cid, page: 1),
            ),
          if (historyPage > 1)
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_book_replay),
              text: Flexible(
                child: Text('从头阅读该章节 ($historyTitle 第1页)', maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              popWhenPress: c,
              onPressed: () => toReadChapter(cid: historyCid, page: 1),
            ),
          IconTextDialogOption(
            icon: Icon(CustomIcons.opened_book_arrow_right),
            text: Flexible(
              child: Text('继续阅读该章节 ($historyTitle 第$historyPage页)', maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            popWhenPress: c,
            onPressed: () => toReadChapter(cid: historyCid, page: historyPage),
          ),
        ],
      ),
    );
  }
}

// => called in MangaViewerPage
Future<void> checkAndShowSwitchChapterDialogForViewer({
  required BuildContext context,
  required int mangaId,
  required int chapterId,
  required int currentChapterId,
  required List<MangaChapterGroup> chapterGroups,
  required void Function({required int cid, required int page}) toReadChapter,
}) async {
  if (chapterId == currentChapterId) {
    // (1) 所选章节是当前正在阅读的章节 => 显示提示
    Fluttertoast.showToast(msg: '当前正在阅读 ${chapterGroups.findChapter(chapterId)?.title ?? '该章节'}');
    return;
  }

  var history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: mangaId);
  if (history == null || history.lastChapterId != chapterId) {
    // (2) 所选章节不是上上次阅读的章节 => 直接从第一页阅读
    toReadChapter(cid: chapterId, page: 1);
    return;
  }

  // (3) 所选章节在上上次被阅读 => 弹出选项判断是否需要阅读
  var historyTitle = history.lastChapterTitle;
  var historyPage = history.lastChapterPage;
  var chapter = chapterGroups.findChapter(chapterId);
  if (chapter == null) {
    showYesNoAlertDialog(context: context, title: Text('章节阅读'), content: Text('未找到所选章节，无法阅读。'), yesText: Text('确定'), noText: null);
    return; // actually unreachable
  }
  var checkNotfin = AppSetting.instance.ui.readGroupBehavior.needCheckNotfin(currentPage: historyPage, totalPage: chapter.pageCount); // 是否检查"未阅读完"
  var checkFinish = AppSetting.instance.ui.readGroupBehavior.needCheckFinish(currentPage: historyPage, totalPage: chapter.pageCount); // 是否检查"已阅读完"
  if (!checkNotfin && !checkFinish) {
    // (3.1) 所选章节无需弹出提示 => 继续阅读
    toReadChapter(cid: chapterId, page: historyPage);
  } else {
    // (3.2) 所选章节需要弹出提示 (未阅读完/已阅读完) => 根据所选选项来确定阅读行为
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('章节阅读'),
        children: [
          SubtitleDialogOption(
            text: checkNotfin //
                ? Text('所选章节 ($historyTitle) 已阅读至第$historyPage页 (共${chapter.pageCount}页)，是否继续阅读该页？') // 未阅读完
                : Text('所选章节 ($historyTitle) 已阅读至最后一页 (第$historyPage页)，是否选择其他章节阅读？'), // 已阅读完
          ),
          ...([
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_book_arrow_right),
              text: Flexible(
                child: Text('继续阅读该章节 ($historyTitle 第$historyPage页)', maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              popWhenPress: c,
              onPressed: () => toReadChapter(cid: chapterId, page: historyPage),
            ),
            if (historyPage > 1)
              IconTextDialogOption(
                icon: Icon(CustomIcons.opened_book_replay),
                text: Flexible(
                  child: Text('从头阅读该章节 ($historyTitle 第1页)', maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                popWhenPress: c,
                onPressed: () => toReadChapter(cid: chapterId, page: 1),
              ),
          ].let(
            (opt) => checkNotfin ? opt /* 未阅读完 */ : opt.reversed /* 已阅读完 */,
          )),
        ],
      ),
    );
  }
}

// => called in DownloadMangaPage
Future<void> checkAndShowSwitchChapterDialogForDownload({
  required BuildContext context,
  required int mangaId,
  required int chapterId,
  required List<DownloadedChapter> downloadedChapters,
  required void Function({required int cid, required int page}) toReadChapter,
}) async {
  var history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: mangaId);
  if (history == null || (history.chapterId != chapterId && history.lastChapterId != chapterId)) {
    // (1) 所选章节不是上次/上上次阅读的章节 => 直接从第一页阅读
    toReadChapter(cid: chapterId, page: 1);
    return;
  }

  // (2) 所选章节在上次/上上次被阅读 => 弹出选项判断是否需要阅读
  var historyTitle = history.chapterId == chapterId ? history.chapterTitle : history.lastChapterTitle;
  var historyPage = history.chapterId == chapterId ? history.chapterPage : history.lastChapterPage;
  var chapter = downloadedChapters.where((c) => c.chapterId == chapterId).firstOrNull;
  if (chapter == null) {
    showYesNoAlertDialog(context: context, title: Text('章节阅读'), content: Text('未找到所选章节，无法阅读。'), yesText: Text('确定'), noText: null);
    return; // actually unreachable
  }
  var checkNotfin = AppSetting.instance.ui.readGroupBehavior.needCheckNotfin(currentPage: historyPage, totalPage: chapter.totalPageCount); // 是否检查"未阅读完"
  var checkFinish = AppSetting.instance.ui.readGroupBehavior.needCheckFinish(currentPage: historyPage, totalPage: chapter.totalPageCount); // 是否检查"已阅读完"
  if (!checkNotfin && !checkFinish) {
    // (2.1) 所选章节无需弹出提示 => 继续阅读
    toReadChapter(cid: chapterId, page: historyPage);
  } else {
    // (2.2) 所选章节需要弹出提示 (未阅读完/已阅读完) => 根据所选选项来确定阅读行为
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('章节阅读'),
        children: [
          SubtitleDialogOption(
            text: checkNotfin //
                ? Text('所选章节 ($historyTitle) 已阅读至第$historyPage页 (共${chapter.totalPageCount}页)，是否继续阅读该页？') // 未阅读完
                : Text('所选章节 ($historyTitle) 已阅读至最后一页 (第$historyPage页)，是否选择其他章节阅读？'), // 已阅读完
          ),
          ...([
            IconTextDialogOption(
              icon: Icon(CustomIcons.opened_book_arrow_right),
              text: Flexible(
                child: Text('继续阅读该章节 ($historyTitle 第$historyPage页)', maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              popWhenPress: c,
              onPressed: () => toReadChapter(cid: chapterId, page: historyPage),
            ),
            if (historyPage > 1)
              IconTextDialogOption(
                icon: Icon(CustomIcons.opened_book_replay),
                text: Flexible(
                  child: Text('从头阅读该章节 ($historyTitle 第1页)', maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                popWhenPress: c,
                onPressed: () => toReadChapter(cid: chapterId, page: 1),
              ),
          ].let(
            (opt) => checkNotfin ? opt /* 未阅读完 */ : opt.reversed /* 已阅读完 */,
          )),
        ],
      ),
    );
  }
}

extension MangaChapterGroupListExtension on List<MangaChapterGroup> {
  // !!!
  MangaChapterNeighbor? findChapterNeighbor(int cid, {bool prev = false, bool next = false}) {
    var chapter = findChapter(cid);
    if (chapter == null) {
      return null;
    }

    // 对**所有分组**中的漫画章节排序
    var allChapters = this.allChapters;
    var prevChapters = !prev
        ? null
        : (allChapters.where((el) => el.group == chapter.group ? el.number < chapter.number : el.cid < chapter.cid).toList() //
          ..sort((a, b) => a.group == b.group ? b.number.compareTo(a.number) : b.cid.compareTo(a.cid))); // number (同一分组) 或 cid (不同分组) 从大到小排序
    var nextChapters = !next
        ? null
        : (allChapters.where((el) => el.group == chapter.group ? el.number > chapter.number : el.cid > chapter.cid).toList() //
          ..sort((a, b) => a.group == b.group ? a.number.compareTo(b.number) : a.cid.compareTo(b.cid))); // number (同一分组) 或 cid (不同分组) 从小到大排序

    // 从**所有分组**中找上一个章节
    TinyMangaChapter? prevDiffGroupChapter, prevSameGroupChapter;
    if (prev) {
      for (var prevChapter in prevChapters!) {
        if (prevChapter.group != chapter.group) {
          prevDiffGroupChapter ??= prevChapter; // 找到的章节不属于同一分组，且该章节的编号肯定小于当前章节的编号
          continue;
        }
        prevSameGroupChapter ??= prevChapter; // 找到的章节属于同一分组，且该章节的顺序肯定小于当前章节的顺序
        break;
      }
      if (prevDiffGroupChapter != null && prevSameGroupChapter != null && prevDiffGroupChapter.cid < prevSameGroupChapter.cid) {
        prevDiffGroupChapter = null; // 不同分组的章节出现得比同一分组的章节还要更前，舍弃
      }
    }

    // 从**所有分组**中找下一个章节
    TinyMangaChapter? nextDiffGroupChapter, nextSameGroupChapter;
    if (next) {
      for (var nextChapter in nextChapters!) {
        if (nextChapter.group != chapter.group) {
          nextDiffGroupChapter ??= nextChapter; // 找到的章节不属于同一分组，且该章节的编号肯定大于当前章节的编号
          continue;
        }
        nextSameGroupChapter ??= nextChapter; // 找到的章节属于同一分组，且该章节的顺序肯定大于当前章节的顺序
        break;
      }
      if (nextDiffGroupChapter != null && nextSameGroupChapter != null && nextDiffGroupChapter.cid > nextSameGroupChapter.cid) {
        nextDiffGroupChapter = null; // 不同分组的章节出现得比同一分组的章节还要更后，舍弃
      }
    }

    TinyMangaChapter? max(TinyMangaChapter? a, TinyMangaChapter? b) => a == null ? b : (b == null ? a : (a.cid > b.cid ? a : b));
    TinyMangaChapter? min(TinyMangaChapter? a, TinyMangaChapter? b) => a == null ? b : (b == null ? a : (a.cid < b.cid ? a : b));
    return MangaChapterNeighbor(
      notLoaded: false,
      prevChapter: max(prevDiffGroupChapter, prevSameGroupChapter)?.toTinier(),
      nextChapter: min(nextDiffGroupChapter, nextSameGroupChapter)?.toTinier(),
      prevSameGroupChapter: prevSameGroupChapter?.toTinier(),
      prevDiffGroupChapter: prevDiffGroupChapter?.toTinier(),
      nextSameGroupChapter: nextSameGroupChapter?.toTinier(),
      nextDiffGroupChapter: nextDiffGroupChapter?.toTinier(),
    );
  }

  MangaChapterNeighbor? findNextChapter(int cid) {
    return findChapterNeighbor(cid, next: true, prev: false);
  }

  MangaChapterNeighbor? findPrevChapter(int cid) {
    return findChapterNeighbor(cid, prev: true, next: false);
  }
}
