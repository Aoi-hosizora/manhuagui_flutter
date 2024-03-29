import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/service/db/db_manager.dart';
import 'package:manhuagui_flutter/service/db/query_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/utils/utils.dart';

class FavoriteDao {
  FavoriteDao._();

  static const _tblFavorite = 'tbl_favorite';
  static const _colUsername = 'username';
  static const _colMangaId = 'id';
  static const _colMangaTitle = 'manga_title';
  static const _colMangaCover = 'manga_cover';
  static const _colMangaUrl = 'manga_url';
  static const _colRemark = 'remark';
  static const _colGroupName = 'group_name';
  static const _colListOrder = 'list_order';
  static const _colCreatedAt = 'created_at';

  static const favoriteMetadata = TableMetadata(
    tableName: _tblFavorite,
    primaryKeys: [_colUsername, _colMangaId],
    columns: [_colUsername, _colMangaId, _colMangaTitle, _colMangaCover, _colMangaUrl, _colRemark, _colGroupName, _colListOrder, _colCreatedAt],
  );

  static const _tblFavoriteGroup = 'tbl_favorite_group';
  static const _colGUsername = 'username';
  static const _colGGroupName = 'group_name';
  static const _colGGroupOrder = 'group_order';
  static const _colGCreatedAt = 'created_at';

  static const groupMetadata = TableMetadata(
    tableName: _tblFavoriteGroup,
    primaryKeys: [_colGUsername, _colGGroupName],
    columns: [_colGUsername, _colGGroupName, _colGGroupOrder, _colGCreatedAt],
  );

  static const _tblFavoriteAuthor = 'tbl_favorite_author';
  static const _colAUsername = 'username';
  static const _colAAuthorId = 'id';
  static const _colAAuthorName = 'author_name';
  static const _colAAuthorCover = 'author_cover';
  static const _colAAuthorUrl = 'author_url';
  static const _colAAuthorZone = 'author_zone';
  static const _colARemark = 'remark';
  static const _colACreatedAt = 'created_at';

  static const authorMetadata = TableMetadata(
    tableName: _tblFavoriteAuthor,
    primaryKeys: [_colAUsername, _colAAuthorId],
    columns: [_colAUsername, _colAAuthorId, _colAAuthorName, _colAAuthorCover, _colAAuthorUrl, _colAAuthorZone, _colARemark, _colACreatedAt],
  );

  static Future<void> createForVer1(Database db) async {
    // pass
  }

  static Future<void> upgradeFromVer1To2(Database db) async {
    // pass
  }

  static Future<void> upgradeFromVer2To3(Database db) async {
    // pass
  }

  static Future<void> upgradeFromVer3To4(Database db) async {
    await db.safeExecute('''
      CREATE TABLE $_tblFavorite(
        $_colUsername VARCHAR(1023),
        $_colMangaId INTEGER,
        $_colMangaTitle VARCHAR(1023),
        $_colMangaCover VARCHAR(1023),
        $_colMangaUrl VARCHAR(1023),
        $_colRemark VARCHAR(1023),
        $_colGroupName VARCHAR(1023),
        $_colListOrder INTEGER,
        $_colCreatedAt DATETIME,
        PRIMARY KEY ($_colUsername, $_colMangaId)
      )''');
    await db.safeExecute('''
      CREATE TABLE $_tblFavoriteGroup(
        $_colGUsername VARCHAR(1023),
        $_colGGroupName VARCHAR(1023),
        $_colGGroupOrder INTEGER,
        $_colGCreatedAt DATETIME,
        PRIMARY KEY ($_colGUsername, $_colGGroupName)
      )''');
    await db.safeExecute('''
      CREATE TABLE $_tblFavoriteAuthor(
        $_colAUsername VARCHAR(1023),
        $_colAAuthorId INTEGER,
        $_colAAuthorName VARCHAR(1023),
        $_colAAuthorCover VARCHAR(1023),
        $_colAAuthorUrl VARCHAR(1023),
        $_colAAuthorZone VARCHAR(1023),
        $_colARemark VARCHAR(1023),
        $_colACreatedAt DATETIME,
        PRIMARY KEY ($_colAUsername, $_colAAuthorId)
      )''');
  }

  static Tuple2<String, List<String>>? _buildFavoriteLikeStatement({String? keyword, bool pureSearch = false, bool includeWHERE = false, bool includeAND = false}) {
    return QueryHelper.buildLikeStatement(
      [_colMangaTitle, if (!pureSearch) _colMangaId, if (!pureSearch) _colRemark],
      keyword,
      includeWHERE: includeWHERE,
      includeAND: includeAND,
    );
  }

  static Tuple2<String, List<String>>? _buildAuthorLikeStatement({String? keyword, bool pureSearch = false, bool includeWHERE = false, bool includeAND = false}) {
    return QueryHelper.buildLikeStatement(
      [_colAAuthorName, if (!pureSearch) _colAAuthorId, if (!pureSearch) _colARemark],
      keyword,
      includeWHERE: includeWHERE,
      includeAND: includeAND,
    );
  }

  static String _buildFavoriteOrderByStatement({required SortMethod sortMethod, bool includeORDERBY = false}) {
    return QueryHelper.buildOrderByStatement(
          sortMethod,
          idColumn: _colMangaId,
          nameColumn: _colMangaTitle,
          timeColumn: _colCreatedAt,
          orderColumn: _colListOrder,
          includeORDERBY: includeORDERBY,
        ) ??
        '';
  }

  static String _buildAuthorOrderByStatement({required SortMethod sortMethod, bool includeORDERBY = false}) {
    return QueryHelper.buildOrderByStatement(
          sortMethod,
          idColumn: _colAAuthorId,
          nameColumn: _colAAuthorName,
          timeColumn: _colACreatedAt,
          orderColumn: null,
          includeORDERBY: includeORDERBY,
        ) ??
        '';
  }

  static Future<int?> getFavoriteCount({required String username, required String? groupName, String? keyword, bool pureSearch = false}) async {
    final db = await DBManager.instance.getDB();
    var like = _buildFavoriteLikeStatement(keyword: keyword, pureSearch: pureSearch, includeAND: true);
    List<Map<String, Object?>>? results;
    if (groupName == null) {
      results = await db.safeRawQuery(
        '''SELECT COUNT(*)
           FROM $_tblFavorite
           WHERE $_colUsername = ? ${like?.item1 ?? ''}''',
        [username, ...(like?.item2 ?? [])],
      );
    } else {
      results = await db.safeRawQuery(
        '''SELECT COUNT(*)
           FROM $_tblFavorite
           WHERE $_colUsername = ? AND $_colGroupName = ? ${like?.item1 ?? ''}''',
        [username, groupName, ...(like?.item2 ?? [])],
      );
    }
    if (results == null) {
      return null;
    }
    return firstIntValue(results);
  }

  static Future<bool?> checkExistence({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT($_colMangaId)
         FROM $_tblFavorite
         WHERE $_colUsername = ? AND $_colMangaId = ?''',
      [username, mid],
    );
    if (results == null || results.isEmpty) {
      return null;
    }
    return firstIntValue(results)! > 0;
  }

  static Future<FavoriteManga?> getFavorite({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colRemark, $_colGroupName, $_colListOrder, $_colCreatedAt
         FROM $_tblFavorite
         WHERE $_colUsername = ? AND $_colMangaId = ?
         ORDER BY $_colListOrder ASC, $_colCreatedAt DESC
         LIMIT 1''',
      [username, mid],
    );
    if (results == null || results.isEmpty) {
      return null;
    }
    var r = results.first;
    return FavoriteManga(
      mangaId: mid,
      mangaTitle: r[_colMangaTitle]! as String,
      mangaCover: r[_colMangaCover]! as String,
      mangaUrl: r[_colMangaUrl]! as String,
      remark: r[_colRemark]! as String,
      groupName: r[_colGroupName]! as String,
      order: r[_colListOrder]! as int,
      createdAt: DateTime.parse(r[_colCreatedAt]! as String),
    );
  }

  static Future<List<FavoriteManga>?> getFavorites({required String username, required String? groupName, String? keyword, bool pureSearch = false, SortMethod sortMethod = SortMethod.byOrderAsc, required int? page, int limit = 20, int offset = 0}) async {
    final db = await DBManager.instance.getDB();
    var like = _buildFavoriteLikeStatement(keyword: keyword, pureSearch: pureSearch, includeAND: true);
    var orderBy = _buildFavoriteOrderByStatement(sortMethod: sortMethod, includeORDERBY: false);
    List<Map<String, Object?>>? results;
    if (groupName == null) {
      // return in pagination (all groups)
      page ??= 1 /* unreachable */;
      offset = limit * (page - 1) - offset;
      if (offset < 0) {
        offset = 0;
      }
      results = await db.safeRawQuery(
        '''SELECT $_colMangaId, $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colRemark, $_colGroupName, $_colListOrder, $_colCreatedAt 
           FROM $_tblFavorite
           WHERE $_colUsername = ? ${like?.item1 ?? ''}
           ORDER BY $orderBy, $_colCreatedAt DESC
           LIMIT $limit OFFSET $offset''',
        [username, ...(like?.item2 ?? [])],
      );
    } else if (page != null && page > 0) {
      // return in pagination (single group)
      offset = limit * (page - 1) - offset;
      if (offset < 0) {
        offset = 0;
      }
      results = await db.safeRawQuery(
        '''SELECT $_colMangaId, $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colRemark, $_colListOrder, $_colCreatedAt 
           FROM $_tblFavorite
           WHERE $_colUsername = ? AND $_colGroupName = ? ${like?.item1 ?? ''}
           ORDER BY $orderBy, $_colCreatedAt DESC
           LIMIT $limit OFFSET $offset''',
        [username, groupName, ...(like?.item2 ?? [])],
      );
    } else {
      // return all
      results = await db.safeRawQuery(
        '''SELECT $_colMangaId, $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colRemark, $_colListOrder, $_colCreatedAt 
           FROM $_tblFavorite
           WHERE $_colUsername = ? AND $_colGroupName = ? ${like?.item1 ?? ''}
           ORDER BY $orderBy, $_colCreatedAt DESC''',
        [username, groupName, ...(like?.item2 ?? [])],
      );
    }
    if (results == null) {
      return null;
    }
    var out = <FavoriteManga>[];
    for (var r in results) {
      out.add(FavoriteManga(
        mangaId: r[_colMangaId]! as int,
        mangaTitle: r[_colMangaTitle]! as String,
        mangaCover: r[_colMangaCover]! as String,
        mangaUrl: r[_colMangaUrl]! as String,
        remark: r[_colRemark]! as String,
        groupName: groupName ?? r[_colGroupName]! as String,
        order: r[_colListOrder]! as int,
        createdAt: DateTime.parse(r[_colCreatedAt]! as String),
      ));
    }
    return out;
  }

  static Future<int> getFavoriteNewOrder({required String username, required String groupName, required bool addToTop}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT ${addToTop ? 'MIN' : 'MAX'}($_colListOrder)
         FROM $_tblFavorite
         WHERE $_colUsername = ? AND $_colGroupName = ?''',
      [username, groupName],
    );
    var count = results == null ? null : firstIntValue(results);

    int order; // default to 1
    if (addToTop) {
      order = (count ?? 2) - 1;
    } else {
      order = (count ?? 0) + 1;
    }
    return order;
  }

  static Future<int?> getGroupCount({required String username}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblFavoriteGroup
         WHERE $_colGUsername = ?''',
      [username],
    );
    if (results == null) {
      return null;
    }
    return firstIntValue(results);
  }

  static Future<bool?> checkGroupExistence({required String username, required String groupName}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT($_colGGroupName)
         FROM $_tblFavoriteGroup
         WHERE $_colGUsername = ? AND $_colGGroupName = ?''',
      [username, groupName],
    );
    if (results == null || results.isEmpty) {
      return null;
    }
    return firstIntValue(results)! > 0;
  }

  static Future<FavoriteGroup?> getGroup({required String username, required String groupName}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT $_colGGroupName, $_colGGroupOrder, $_colGCreatedAt
         FROM $_tblFavoriteGroup
         WHERE $_colGUsername = ? AND $_colGGroupName = ?
         ORDER BY $_colGGroupOrder ASC, $_colGCreatedAt DESC
         LIMIT 1''',
      [username, groupName],
    );
    if (results == null || results.isEmpty) {
      return null;
    }
    var r = results.first;
    return FavoriteGroup(
      groupName: r[_colGGroupName]! as String,
      order: r[_colGGroupOrder]! as int,
      createdAt: DateTime.parse(r[_colGCreatedAt]! as String),
    );
  }

  static Future<List<FavoriteGroup>?> getGroups({required String username}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT $_colGGroupName, $_colGGroupOrder, $_colGCreatedAt
         FROM $_tblFavoriteGroup
         WHERE $_colGUsername = ?
         ORDER BY $_colGGroupOrder ASC, $_colGCreatedAt DESC''',
      [username],
    );
    if (results == null) {
      return null;
    }
    if (results.isEmpty) {
      var group = FavoriteGroup(groupName: '', order: 1, createdAt: DateTime.now()); // add the default group if empty
      await addOrUpdateGroup(username: username, group: group, testGroupName: group.groupName);
      return [group];
    }

    var out = <FavoriteGroup>[];
    for (var r in results) {
      out.add(FavoriteGroup(
        groupName: r[_colGGroupName]! as String,
        order: r[_colGGroupOrder]! as int,
        createdAt: DateTime.parse(r[_colGCreatedAt]! as String),
      ));
    }
    return out;
  }

  static Future<int> getFavoriteGroupNewOrder({required String username, required bool addToTop}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT ${addToTop ? 'MIN' : 'MAX'}($_colGGroupOrder)
         FROM $_tblFavoriteGroup
         WHERE $_colGUsername = ?''',
      [username],
    );
    var count = results == null ? null : firstIntValue(results);

    int order; // default to 1
    if (addToTop) {
      order = (count ?? 2) - 1;
    } else {
      order = (count ?? 0) + 1;
    }
    return order;
  }

  static Future<Map<String, int>?> getGroupsLengths({required String username}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*) AS count, $_colGroupName
           FROM $_tblFavorite
           WHERE $_colUsername = ?
           GROUP BY $_colGroupName''',
      [username],
    );
    if (results == null) {
      return null;
    }

    var out = <String, int>{};
    for (var r in results) {
      var groupName = r[_colGroupName]! as String;
      var count = r['count']! as int;
      out[groupName] = count;
    }
    return out;
  }

  static Future<int?> getAuthorCount({required String username, String? keyword, bool pureSearch = false}) async {
    final db = await DBManager.instance.getDB();
    var like = _buildAuthorLikeStatement(keyword: keyword, pureSearch: pureSearch, includeAND: true);
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblFavoriteAuthor
         WHERE $_colAUsername = ? ${like?.item1 ?? ''}''',
      [username, ...(like?.item2 ?? [])],
    );
    if (results == null) {
      return null;
    }
    return firstIntValue(results);
  }

  static Future<bool?> checkAuthorExistence({required String username, required int aid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT($_colAAuthorId)
         FROM $_tblFavoriteAuthor
         WHERE $_colAUsername = ? AND $_colAAuthorId = ?''',
      [username, aid],
    );
    if (results == null || results.isEmpty) {
      return null;
    }
    return firstIntValue(results)! > 0;
  }

  static Future<FavoriteAuthor?> getAuthor({required String username, required int aid}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT $_colAAuthorName, $_colAAuthorCover, $_colAAuthorUrl, $_colAAuthorZone, $_colARemark, $_colACreatedAt
         FROM $_tblFavoriteAuthor
         WHERE $_colAUsername = ? AND $_colAAuthorId = ?
         ORDER BY $_colCreatedAt DESC
         LIMIT 1''',
      [username, aid],
    );
    if (results == null || results.isEmpty) {
      return null;
    }
    var r = results.first;
    return FavoriteAuthor(
      authorId: aid,
      authorName: r[_colAAuthorName]! as String,
      authorCover: r[_colAAuthorCover]! as String,
      authorUrl: r[_colAAuthorUrl]! as String,
      authorZone: r[_colAAuthorZone]! as String,
      remark: r[_colARemark]! as String,
      createdAt: DateTime.parse(r[_colACreatedAt]! as String),
    );
  }

  static Future<List<FavoriteAuthor>?> getAuthors({required String username, String? keyword, bool pureSearch = false, SortMethod sortMethod = SortMethod.byTimeDesc, required int page, int limit = 20, int offset = 0}) async {
    final db = await DBManager.instance.getDB();
    offset = limit * (page - 1) - offset;
    if (offset < 0) {
      offset = 0;
    }
    var like = _buildAuthorLikeStatement(keyword: keyword, pureSearch: pureSearch, includeAND: true);
    var orderBy = _buildAuthorOrderByStatement(sortMethod: sortMethod, includeORDERBY: false);
    var results = await db.safeRawQuery(
      '''SELECT $_colAAuthorId, $_colAAuthorName, $_colAAuthorCover, $_colAAuthorUrl, $_colAAuthorZone, $_colARemark, $_colACreatedAt 
           FROM $_tblFavoriteAuthor
           WHERE $_colAUsername = ? ${like?.item1 ?? ''}
           ORDER BY $orderBy
           LIMIT $limit OFFSET $offset''',
      [username, ...(like?.item2 ?? [])],
    );
    if (results == null) {
      return null;
    }
    var out = <FavoriteAuthor>[];
    for (var r in results) {
      out.add(FavoriteAuthor(
        authorId: r[_colAAuthorId]! as int,
        authorName: r[_colAAuthorName]! as String,
        authorCover: r[_colAAuthorCover]! as String,
        authorUrl: r[_colAAuthorUrl]! as String,
        authorZone: r[_colAAuthorZone]! as String,
        remark: r[_colARemark]! as String,
        createdAt: DateTime.parse(r[_colCreatedAt]! as String),
      ));
    }
    return out;
  }

  static Future<bool> addOrUpdateFavorite({required String username, required FavoriteManga favorite}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblFavorite
         WHERE $_colUsername = ? AND $_colMangaId = ?''',
      [username, favorite.mangaId],
    );
    if (results == null) {
      return false;
    }
    var count = firstIntValue(results);

    int? rows = 0;
    if (count == 0) {
      rows = await db.safeRawInsert(
        '''INSERT INTO $_tblFavorite ($_colUsername, $_colMangaId, $_colMangaTitle, $_colMangaCover, $_colMangaUrl, $_colRemark, $_colGroupName, $_colListOrder, $_colCreatedAt)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [username, favorite.mangaId, favorite.mangaTitle, favorite.mangaCover, favorite.mangaUrl, favorite.remark, favorite.groupName, favorite.order, favorite.createdAt.toIso8601String()],
      );
    } else {
      rows = await db.safeRawUpdate(
        '''UPDATE $_tblFavorite
           SET $_colMangaTitle = ?, $_colMangaCover = ?, $_colMangaUrl = ?, $_colRemark = ?, $_colGroupName = ?, $_colListOrder = ?, $_colCreatedAt = ?
           WHERE $_colUsername = ? AND $_colMangaId = ?''',
        [favorite.mangaTitle, favorite.mangaCover, favorite.mangaUrl, favorite.remark, favorite.groupName, favorite.order, favorite.createdAt.toIso8601String(), username, favorite.mangaId],
      );
    }
    return rows != null && rows >= 1;
  }

  static Future<bool> addOrUpdateGroup({required String username, required FavoriteGroup group, required String testGroupName}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblFavoriteGroup
         WHERE $_colGUsername = ? AND $_colGGroupName = ?''',
      [username, testGroupName],
    );
    if (results == null) {
      return false;
    }
    var count = firstIntValue(results);

    int? rows = 0;
    if (count == 0) {
      rows = await db.safeRawInsert(
        '''INSERT INTO $_tblFavoriteGroup ($_colGUsername, $_colGGroupName, $_colGGroupOrder, $_colGCreatedAt)
           VALUES (?, ?, ?, ?)''',
        [username, group.groupName, group.order, group.createdAt.toIso8601String()],
      );
    } else {
      if (testGroupName == '') {
        return false; // cannot update the default group
      }
      rows = await db.safeRawUpdate(
        '''UPDATE $_tblFavoriteGroup
           SET $_colGGroupName = ?, $_colGGroupOrder = ?, $_colGCreatedAt = ?
           WHERE $_colGUsername = ? AND $_colGGroupName = ?''',
        [group.groupName, group.order, group.createdAt.toIso8601String(), username, testGroupName],
      );
      await updateMangasGroupName(username: username, oldName: testGroupName, newName: group.groupName, addToTop: null); // 移动分组，不修改 order
    }
    return rows != null && rows >= 1;
  }

  static Future<bool> updateMangasGroupName({required String username, required String oldName, required String newName, bool? addToTop}) async {
    final db = await DBManager.instance.getDB();
    int? ok;
    if (addToTop == null) {
      ok = await db.safeRawUpdate(
        '''UPDATE $_tblFavorite
           SET $_colGroupName = ?
           WHERE $_colGUsername = ? AND $_colGroupName = ?''',
        [newName, username, oldName],
      );
    } else {
      var newOrder = await getFavoriteNewOrder(username: username, groupName: newName, addToTop: addToTop);
      ok = await db.safeRawUpdate(
        '''UPDATE $_tblFavorite
           SET $_colGroupName = ?, $_colListOrder = ?
           WHERE $_colGUsername = ? AND $_colGroupName = ?''',
        [newName, newOrder, username, oldName],
      );
    }
    return ok != null;
  }

  static Future<bool> addOrUpdateAuthor({required String username, required FavoriteAuthor author}) async {
    final db = await DBManager.instance.getDB();
    var results = await db.safeRawQuery(
      '''SELECT COUNT(*)
         FROM $_tblFavoriteAuthor
         WHERE $_colAUsername = ? AND $_colAAuthorId = ?''',
      [username, author.authorId],
    );
    if (results == null) {
      return false;
    }
    var count = firstIntValue(results);

    int? rows = 0;
    if (count == 0) {
      rows = await db.safeRawInsert(
        '''INSERT INTO $_tblFavoriteAuthor ($_colAUsername, $_colAAuthorId, $_colAAuthorName, $_colAAuthorCover, $_colAAuthorUrl, $_colAAuthorZone, $_colARemark, $_colACreatedAt)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        [username, author.authorId, author.authorName, author.authorCover, author.authorUrl, author.authorZone, author.remark, author.createdAt.toIso8601String()],
      );
    } else {
      rows = await db.safeRawUpdate(
        '''UPDATE $_tblFavoriteAuthor
           SET $_colAAuthorName = ?, $_colAAuthorCover = ?, $_colAAuthorUrl = ?, $_colAAuthorZone = ?, $_colARemark = ?, $_colACreatedAt = ?
           WHERE $_colAUsername = ? AND $_colAAuthorId = ?''',
        [author.authorName, author.authorCover, author.authorUrl, author.authorZone, author.remark, author.createdAt.toIso8601String(), username, author.authorId],
      );
    }
    return rows != null && rows >= 1;
  }

  static Future<bool> deleteFavorite({required String username, required int mid}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblFavorite
         WHERE $_colUsername = ? AND $_colMangaId = ?''',
      [username, mid],
    );
    return rows != null && rows >= 1;
  }

  static Future<bool> deleteGroup({required String username, required String groupName, bool moveMangasIfExisted = true}) async {
    if (groupName == '') {
      return false; // cannot delete the default group
    }
    final db = await DBManager.instance.getDB();
    if (moveMangasIfExisted) {
      await updateMangasGroupName(username: username, oldName: groupName, newName: '', addToTop: false); // 移动分组，默认添加到末尾
    } else {
      await db.safeRawDelete('DELETE FROM $_tblFavorite WHERE $_colUsername = ? AND $_colGroupName = ?', [username, groupName]); // 删除漫画
    }
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblFavoriteGroup
         WHERE $_colGUsername = ? AND $_colGGroupName = ?''',
      [username, groupName],
    );
    return rows != null && rows >= 1;
  }

  static Future<bool> deleteAuthor({required String username, required int aid}) async {
    final db = await DBManager.instance.getDB();
    var rows = await db.safeRawDelete(
      '''DELETE FROM $_tblFavoriteAuthor
         WHERE $_colAUsername = ? AND $_colAAuthorId = ?''',
      [username, aid],
    );
    return rows != null && rows >= 1;
  }
}
