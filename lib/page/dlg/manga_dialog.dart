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

/// [_DialogHelper] 帮助类
part 'manga_dialog_helper.dart';

/// 漫画列表页-漫画弹出菜单 [showPopupMenuForMangaList]
part 'manga_dialog_list.dart';

/// 漫画页/章节页-漫画订阅对话框 [showPopupMenuForSubscribing]
part 'manga_dialog_sub.dart';

/// 漫画页/章节页-漫画章节弹出菜单 [showPopupMenuForMangaToc]
part 'manga_dialog_toc.dart';

/// 漫画页/章节页/漫画下载页-稍后阅读对话框 [showPopupMenuForLaterManga]
part 'manga_dialog_later.dart';

/// 漫画收藏页-移动分组对话框 [showUpdateFavoriteMangasGroupDialog]
/// 漫画收藏页-修改备注对话框 [showUpdateFavoriteMangaRemarkDialog]
/// 漫画页-标题对话框 [showPopupMenuForMangaTitle]
/// 章节页-标题对话框 [showPopupMenuForChapterTitle]
part 'manga_dialog_misc.dart';

// ===

// basic updated callbacks
typedef ShelfUpdatedCallback = void Function(bool inShelf);
typedef FavoriteUpdatedCallback = void Function(FavoriteManga? favorite);
typedef LaterUpdatedCallback = void Function(LaterManga? later);
typedef NotateUpdatedCallback = void Function(NotateChapter? notate);
typedef HistoryUpdatedCallback = void Function(MangaHistory? history);
typedef FootprintUpdatedCallback = void Function(ChapterFootprint? footprint);

// other updated callbacks
typedef SubscribingUpdatedCallback = void Function(bool subscribing);
typedef FavoritesUpdatedCallback = void Function(List<FavoriteManga> favorites, bool addToTop);
typedef NotateClearedCallback = void Function();
typedef FootprintClearedCallback = void Function();

// typedef navigate wrapper
typedef NavigateWrapper = Future<void> Function(Future<void> Function());

// idle navigate wrapper
Future<void> _navigateWrapper(Future<void> Function() navigate) {
  return navigate.call();
}

// dialog callback object
class DialogObject<T extends Object> {
  const DialogObject(this.id, [this.value]);

  final int id; // mangaId or chapterId
  final T? value; // `null` almost means deleted
}

// dialog callback objects
class DialogObjects<T extends Object> {
  const DialogObjects(this.id, [this.value]);

  final List<int> id; // mangaId or chapterId
  final T? value; // `null` almost means deleted
}
