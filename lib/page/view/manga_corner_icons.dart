import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/db/shelf_cache.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 构建用于各类漫画行的 Corner 图标列表，在 [TinyMangaLineView] / [ShelfMangaLineView] / [MangaHistoryLineView] / [MangaRankingLineView] 使用

List<IconData> buildMangaCornerIcons({
  required bool inDownload,
  required bool inShelf,
  required bool inFavorite,
  required bool inHistory,
}) {
  if (!AppSetting.instance.other.enableMangaFlags) {
    return [];
  }
  return [
    if (inDownload) Icons.download,
    if (inShelf) Icons.star,
    if (inFavorite) Icons.bookmark,
    if (inHistory) Icons.import_contacts,
  ];
}

class MangaCornerFlagsStorage {
  MangaCornerFlagsStorage({required VoidCallback stateSetter}) {
    _cancelHandlers.add(EventBusManager.instance.listen<HistoryUpdatedEvent>((event) async {
      await queryAndStoreFlags(mangaIds: [event.mangaId], toQueryDownloads: false, toQueryShelves: false, toQueryFavorites: false);
      stateSetter();
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<ShelfCacheUpdatedEvent>((event) async {
      await queryAndStoreFlags(mangaIds: [event.mangaId], toQueryDownloads: false, toQueryFavorites: false, toQueryHistories: false);
      stateSetter();
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<SubscribeUpdatedEvent>((event) async {
      if (event.inFavorite != null) {
        await queryAndStoreFlags(mangaIds: [event.mangaId], toQueryDownloads: false, toQueryShelves: false, toQueryHistories: false);
      }
      stateSetter();
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<DownloadedMangaEntityChangedEvent>((event) async {
      await queryAndStoreFlags(mangaIds: [event.mangaId], toQueryShelves: false, toQueryFavorites: false, toQueryHistories: false);
      stateSetter();
    }));

    _cancelHandlers.add(AuthManager.instance.listen(() => _oldAuthData, (_) async {
      _oldAuthData = AuthManager.instance.authData;
      var allMangaIds = {..._downloadsMap.keys, ..._shelvesMap.keys, ..._favoritesMap.keys, ..._historiesMap.keys};
      await queryAndStoreFlags(mangaIds: allMangaIds, toQueryDownloads: false);
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

  AuthData? _oldAuthData;
  final _cancelHandlers = <VoidCallback>[];
  final _downloadsMap = <int, bool>{};
  final _shelvesMap = <int, bool>{};
  final _favoritesMap = <int, bool>{};
  final _historiesMap = <int, bool>{};

  Future<void> queryAndStoreFlags({
    required Iterable<int> mangaIds,
    bool toQueryDownloads = true,
    bool toQueryShelves = true,
    bool toQueryFavorites = true,
    bool toQueryHistories = true,
  }) async {
    var futures = <Future>[];
    for (var mangaId in mangaIds) {
      var future = Future.microtask(() async {
        if (toQueryDownloads) {
          _downloadsMap[mangaId] = (await DownloadDao.checkMangaExistence(mid: mangaId)) ?? false;
        }
        if (toQueryShelves) {
          _shelvesMap[mangaId] = (await ShelfCacheDao.checkExistence(username: AuthManager.instance.username, mid: mangaId)) ?? false;
        }
        if (toQueryFavorites) {
          _favoritesMap[mangaId] = (await FavoriteDao.checkExistence(username: AuthManager.instance.username, mid: mangaId)) ?? false;
        }
        if (toQueryHistories) {
          _historiesMap[mangaId] = (await HistoryDao.checkExistence(username: AuthManager.instance.username, mid: mangaId)) ?? false;
        }
      });
      futures.add(future);
    }
    await Future.wait(futures);
  }

  bool isInDownload({required int mangaId}) {
    return _downloadsMap[mangaId] ?? false;
  }

  bool isInShelf({required int mangaId}) {
    return _shelvesMap[mangaId] ?? false;
  }

  bool isInFavorite({required int mangaId}) {
    return _favoritesMap[mangaId] ?? false;
  }

  bool isInHistory({required int mangaId}) {
    return _historiesMap[mangaId] ?? false;
  }
}
