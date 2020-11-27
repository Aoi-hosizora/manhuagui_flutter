import 'package:json_annotation/json_annotation.dart';

enum MangaOrder {
  /// 人气最旺
  @JsonValue('popular')
  POPULAR,

  /// 最新发布
  @JsonValue('new')
  NEW,

  /// 最新更新
  @JsonValue('update')
  UPDATE,
}

enum AuthorOrder {
  /// 人气最旺
  @JsonValue('popular')
  POPULAR,

  /// 作品最多
  @JsonValue('comic')
  COMIC,

  /// 最新收录
  @JsonValue('update')
  UPDATE
}

extension MangaOrderExtension on MangaOrder {
  String toJson() {
    switch (this) {
      case MangaOrder.POPULAR:
        return 'popular';
      case MangaOrder.NEW:
        return 'new';
      case MangaOrder.UPDATE:
        return 'update';
      default:
        return '?';
    }
  }
}

extension AuthorOrderExtension on AuthorOrder {
  String toJson() {
    switch (this) {
      case AuthorOrder.POPULAR:
        return 'popular';
      case AuthorOrder.COMIC:
        return 'comic';
      case AuthorOrder.UPDATE:
        return 'update';
      default:
        return '?';
    }
  }
}
