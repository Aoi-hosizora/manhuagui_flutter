import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/db/shelf_cache.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 构建用于各类漫画行的 Corner 图标列表，在 [TinyMangaLineView] / [ShelfMangaLineView] / [MangaHistoryLineView] / [MangaRankingLineView] 使用

class MangaCornerFlags {
  const MangaCornerFlags({
    required this.inDownload,
    required this.inShelf,
    required this.inFavorite,
    required this.inHistory,
    required this.historyRead,
  });

  final bool inDownload;
  final bool inShelf;
  final bool inFavorite;
  final bool inHistory;
  final bool historyRead;

  List<dynamic> buildIcons() {
    if (!AppSetting.instance.other.enableMangaFlags) {
      return [];
    }
    return [
      if (inDownload) Icons.download,
      if (inShelf) Icons.star,
      if (inFavorite) Icons.bookmark,
      if (inHistory && !historyRead) CustomIcons.opened_empty_book, // TODO use same ???
      if (inHistory && historyRead) Icons.import_contacts,
    ];
  }
}

class MangaCornerFlagStorage {
  final _cancelHandlers = <VoidCallback>[];
  AuthData? _oldAuthData;

  MangaCornerFlagStorage({required VoidCallback stateSetter}) {
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadUpdatedEvent>((ev) async {
      await queryAndStoreFlags(mangaIds: [ev.mangaId], queryShelves: false, queryFavorites: false, queryHistories: false);
      stateSetter();
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<ShelfCacheUpdatedEvent>((ev) async {
      await queryAndStoreFlags(mangaIds: [ev.mangaId], queryDownloads: false, queryFavorites: false, queryHistories: false);
      stateSetter();
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<FavoriteUpdatedEvent>((ev) async {
      await queryAndStoreFlags(mangaIds: [ev.mangaId], queryDownloads: false, queryShelves: false, queryHistories: false);
      stateSetter();
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<HistoryUpdatedEvent>((ev) async {
      await queryAndStoreFlags(mangaIds: [ev.mangaId], queryDownloads: false, queryShelves: false, queryFavorites: false);
      stateSetter();
    }));

    _cancelHandlers.add(AuthManager.instance.listen(() => _oldAuthData, (_) async {
      _oldAuthData = AuthManager.instance.authData;
      var allMangaIds = {..._downloadsMap.keys, ..._shelvesMap.keys, ..._favoritesMap.keys, ..._historiesMap.keys};
      await queryAndStoreFlags(mangaIds: allMangaIds, queryDownloads: false);
      stateSetter();
    }));
  }

  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _downloadsMap.clear();
    _shelvesMap.clear();
    _favoritesMap.clear();
    _historiesMap.clear();
  }

  final _downloadsMap = <int, bool>{};
  final _shelvesMap = <int, bool>{};
  final _favoritesMap = <int, bool>{};
  final _historiesMap = <int, bool>{};
  final _historiesReadMap = <int, bool>{};

  Future<void> queryAndStoreFlags({
    required Iterable<int> mangaIds,
    bool queryDownloads = true,
    bool queryShelves = true,
    bool queryFavorites = true,
    bool queryHistories = true,
  }) async {
    var futures = <Future>[];
    for (var mangaId in mangaIds) {
      var future = Future.microtask(() async {
        if (queryDownloads) {
          _downloadsMap[mangaId] = (await DownloadDao.checkMangaExistence(mid: mangaId)) ?? false;
        }
        if (queryShelves) {
          _shelvesMap[mangaId] = (await ShelfCacheDao.checkExistence(username: AuthManager.instance.username, mid: mangaId)) ?? false;
        }
        if (queryFavorites) {
          _favoritesMap[mangaId] = (await FavoriteDao.checkExistence(username: AuthManager.instance.username, mid: mangaId)) ?? false;
        }
        if (queryHistories) {
          var history = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: mangaId);
          _historiesMap[mangaId] = history != null;
          _historiesReadMap[mangaId] = history?.read == true;
        }
      });
      futures.add(future);
    }
    await Future.wait(futures);
  }

  MangaCornerFlags getFlags({
    required int mangaId,
    bool forceInDownload = false,
    bool forceInShelf = false,
    bool forceInFavorite = false,
    bool forceInHistory = false,
  }) {
    return MangaCornerFlags(
      inDownload: forceInDownload || (_downloadsMap[mangaId] ?? false),
      inShelf: forceInShelf || (_shelvesMap[mangaId] ?? false),
      inFavorite: forceInFavorite || (_favoritesMap[mangaId] ?? false),
      inHistory: forceInHistory || (_historiesMap[mangaId] ?? false),
      historyRead: _historiesReadMap[mangaId] ?? false,
    );
  }
}
