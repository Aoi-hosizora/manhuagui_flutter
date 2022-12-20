import 'package:json_annotation/json_annotation.dart';

enum MangaOrder {
  /// 人气最旺
  @JsonValue('popular')
  byPopular,

  /// 最新发布
  @JsonValue('new')
  byNew,

  /// 最近更新
  @JsonValue('update')
  byUpdate,
}

enum AuthorOrder {
  /// 人气最旺
  @JsonValue('popular')
  byPopular,

  /// 作品最多
  @JsonValue('comic')
  byComic,

  /// 最新收录
  @JsonValue('update') // "update" 表示 "最新收录" 为后端命名原因
  byNew,
}

extension MangaOrderExtension on MangaOrder {
  String toJson() {
    switch (this) {
      case MangaOrder.byPopular:
        return 'popular';
      case MangaOrder.byNew:
        return 'new';
      case MangaOrder.byUpdate:
        return 'update';
    }
  }

  String toTitle() {
    switch (this) {
      case MangaOrder.byPopular:
        return '人气最旺';
      case MangaOrder.byNew:
        return '最新发布';
      case MangaOrder.byUpdate:
        return '最近更新';
    }
  }

  int toInt() {
    switch (this) {
      case MangaOrder.byPopular:
        return 0;
      case MangaOrder.byNew:
        return 1;
      case MangaOrder.byUpdate:
        return 2;
    }
  }

  static MangaOrder fromInt(int i) {
    switch (i) {
      case 0:
        return MangaOrder.byPopular;
      case 1:
        return MangaOrder.byNew;
      case 2:
        return MangaOrder.byUpdate;
    }
    return MangaOrder.byPopular;
  }
}

extension AuthorOrderExtension on AuthorOrder {
  String toJson() {
    switch (this) {
      case AuthorOrder.byPopular:
        return 'popular';
      case AuthorOrder.byComic:
        return 'comic';
      case AuthorOrder.byNew:
        return 'update'; // "update" 表示 "最新收录" 为后端命名原因
    }
  }

  String toTitle() {
    switch (this) {
      case AuthorOrder.byPopular:
        return '人气最旺';
      case AuthorOrder.byComic:
        return '作品最多';
      case AuthorOrder.byNew:
        return '最新收录';
    }
  }

  int toInt() {
    switch (this) {
      case AuthorOrder.byPopular:
        return 0;
      case AuthorOrder.byComic:
        return 1;
      case AuthorOrder.byNew:
        return 2;
    }
  }

  static AuthorOrder fromInt(int i) {
    switch (i) {
      case 0:
        return AuthorOrder.byPopular;
      case 1:
        return AuthorOrder.byComic;
      case 2:
        return AuthorOrder.byNew;
    }
    return AuthorOrder.byPopular;
  }
}
