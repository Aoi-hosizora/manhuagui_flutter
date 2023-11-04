import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/db/later_manga.dart';
import 'package:manhuagui_flutter/service/db/shelf_cache.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 构建用于各类漫画行和作者行的 Corner 图标列表，在各个列表和列表项使用

class MangaCornerFlags {
  const MangaCornerFlags({
    required this.inDownload,
    required this.inShelf,
    required this.inFavorite,
    required this.inLater,
    required this.inHistory,
    required this.historyRead,
  });

  final bool inDownload;
  final bool inShelf;
  final bool inFavorite;
  final bool inLater;
  final bool inHistory;
  final bool historyRead;

  List<IconData> buildIcons() {
    if (!AppSetting.instance.ui.enableCornerIcons) {
      return [];
    }
    return [
      if (inDownload) Icons.download,
      if (inShelf) Icons.star,
      if (inFavorite) Icons.bookmark,
      if (inLater) Icons.watch_later, // TODO add later but updatable flag and icon (for "可能有更新" hint)
      if (inHistory && AppSetting.instance.ui.showMangaReadIcon) ...[
        if (!historyRead) CustomIcons.opened_left_star_book,
        if (historyRead) CustomIcons.opened_blank_book, // icon offset is little higher than origin Icons.import_contacts
      ],
    ];
  }
}

class MangaCornerFlagStorage {
  final _cancelHandlers = <VoidCallback>[];

  MangaCornerFlagStorage({
    required VoidCallback stateSetter,
    bool ignoreDownloads = false,
    bool ignoreShelves = false,
    bool ignoreFavorites = false,
    bool ignoreLaters = false,
    bool ignoreHistories = false,
  }) {
    if (!ignoreDownloads) {
      _cancelHandlers.add(EventBusManager.instance.listen<DownloadUpdatedEvent>((ev) async {
        await queryAndStoreFlags(mangaIds: [ev.mangaId], queryShelves: false, queryFavorites: false, queryLaters: false, queryHistories: false);
        stateSetter();
      }));
    }
    if (!ignoreShelves) {
      _cancelHandlers.add(EventBusManager.instance.listen<ShelfCacheUpdatedEvent>((ev) async {
        await queryAndStoreFlags(mangaIds: [ev.mangaId], queryDownloads: false, queryFavorites: false, queryLaters: false, queryHistories: false);
        stateSetter();
      }));
    }
    if (!ignoreFavorites) {
      _cancelHandlers.add(EventBusManager.instance.listen<FavoriteUpdatedEvent>((ev) async {
        await queryAndStoreFlags(mangaIds: [ev.mangaId], queryDownloads: false, queryShelves: false, queryLaters: false, queryHistories: false);
        stateSetter();
      }));
    }
    if (!ignoreLaters) {
      _cancelHandlers.add(EventBusManager.instance.listen<LaterUpdatedEvent>((ev) async {
        await queryAndStoreFlags(mangaIds: [ev.mangaId], queryDownloads: false, queryShelves: false, queryFavorites: false, queryHistories: false);
        stateSetter();
      }));
    }
    if (!ignoreHistories) {
      _cancelHandlers.add(EventBusManager.instance.listen<HistoryUpdatedEvent>((ev) async {
        await queryAndStoreFlags(mangaIds: [ev.mangaId], queryDownloads: false, queryShelves: false, queryLaters: false, queryFavorites: false);
        stateSetter();
      }));
    }

    // called when authorization changed
    _cancelHandlers.add(AuthManager.instance.listenOnlyWhen(Tuple1(AuthManager.instance.authData), (_) async {
      var allMangaIds = {..._downloadsMap.keys, ..._shelvesMap.keys, ..._favoritesMap.keys, ..._latersMap.keys, ..._historiesMap.keys};
      await queryAndStoreFlags(
        mangaIds: allMangaIds,
        queryDownloads: false,
        queryShelves: !ignoreShelves,
        queryFavorites: !ignoreFavorites,
        queryLaters: !ignoreLaters,
        queryHistories: !ignoreHistories,
      );
      stateSetter();
    }));
  }

  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _downloadsMap.clear();
    _shelvesMap.clear();
    _favoritesMap.clear();
    _latersMap.clear();
    _historiesMap.clear();
  }

  final _downloadsMap = <int, bool>{};
  final _shelvesMap = <int, bool>{};
  final _favoritesMap = <int, bool>{};
  final _latersMap = <int, bool>{};
  final _historiesMap = <int, MangaHistory?>{};

  Future<void> queryAndStoreFlags({
    required Iterable<int> mangaIds,
    bool queryDownloads = true,
    bool queryShelves = true,
    bool queryFavorites = true,
    bool queryLaters = true,
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
        if (queryLaters) {
          _latersMap[mangaId] = (await LaterMangaDao.checkExistence(username: AuthManager.instance.username, mid: mangaId)) ?? false;
        }
        if (queryHistories) {
          _historiesMap[mangaId] = await HistoryDao.getHistory(username: AuthManager.instance.username, mid: mangaId);
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
    bool forceInLater = false,
    bool forceInHistory = false,
  }) {
    return MangaCornerFlags(
      inDownload: forceInDownload || (_downloadsMap[mangaId] ?? false),
      inShelf: forceInShelf || (_shelvesMap[mangaId] ?? false),
      inFavorite: forceInFavorite || (_favoritesMap[mangaId] ?? false),
      inLater: forceInLater || (_latersMap[mangaId] ?? false),
      inHistory: forceInHistory || (_historiesMap[mangaId] != null),
      historyRead: _historiesMap[mangaId]?.read == true,
    );
  }

  MangaHistory? getHistory({required int mangaId}) {
    return _historiesMap[mangaId];
  }
}

class AuthorCornerFlags {
  const AuthorCornerFlags({
    required this.inFavorite,
  });

  final bool inFavorite;

  List<IconData> buildIcons() {
    if (!AppSetting.instance.ui.enableCornerIcons) {
      return [];
    }
    return [
      if (inFavorite) Icons.bookmark,
    ];
  }
}

class AuthorCornerFlagStorage {
  final _cancelHandlers = <VoidCallback>[];

  AuthorCornerFlagStorage({
    required VoidCallback stateSetter,
    bool ignoreFavorites = false,
  }) {
    if (!ignoreFavorites) {
      _cancelHandlers.add(EventBusManager.instance.listen<FavoriteAuthorUpdatedEvent>((ev) async {
        await queryAndStoreFlags(authorIds: [ev.authorId]);
        stateSetter();
      }));
    }

    // called when authorization changed
    _cancelHandlers.add(AuthManager.instance.listenOnlyWhen(Tuple1(AuthManager.instance.authData), (_) async {
      var allAuthorIds = {..._favoritesMap.keys};
      await queryAndStoreFlags(
        authorIds: allAuthorIds,
        queryFavorites: !ignoreFavorites,
      );
      stateSetter();
    }));
  }

  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    _favoritesMap.clear();
  }

  final _favoritesMap = <int, bool>{};

  Future<void> queryAndStoreFlags({
    required Iterable<int> authorIds,
    bool queryFavorites = true,
  }) async {
    var futures = <Future>[];
    for (var authorId in authorIds) {
      var future = Future.microtask(() async {
        if (queryFavorites) {
          _favoritesMap[authorId] = (await FavoriteDao.checkAuthorExistence(username: AuthManager.instance.username, aid: authorId)) ?? false;
        }
      });
      futures.add(future);
    }
    await Future.wait(futures);
  }

  AuthorCornerFlags getFlags({
    required int mangaId,
    bool forceInFavorite = false,
  }) {
    return AuthorCornerFlags(
      inFavorite: forceInFavorite || (_favoritesMap[mangaId] ?? false),
    );
  }
}
