import 'package:json_annotation/json_annotation.dart';

enum MangaOrder {
  /// 人气最旺
  @JsonValue('popular')
  byPopular,

  /// 最新发布
  @JsonValue('new')
  byNew,

  /// 最新更新
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
  @JsonValue('update')
  byUpdate
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
      default:
        return '?';
    }
  }

  String toTitle() {
    switch (this) {
      case MangaOrder.byPopular:
        return '人气最旺';
      case MangaOrder.byNew:
        return '最新发布';
      case MangaOrder.byUpdate:
        return '最新更新';
      default:
        return '未知排序';
    }
  }
}

extension AuthorOrderExtension on AuthorOrder {
  String toJson() {
    switch (this) {
      case AuthorOrder.byPopular:
        return 'popular';
      case AuthorOrder.byComic:
        return 'comic';
      case AuthorOrder.byUpdate:
        return 'update';
      default:
        return '?';
    }
  }

  String toTitle() {
    switch (this) {
      case AuthorOrder.byPopular:
        return '人气最旺';
      case AuthorOrder.byComic:
        return '作品最多';
      case AuthorOrder.byUpdate:
        return '最新收录';
      default:
        return '未知排序';
    }
  }
}
