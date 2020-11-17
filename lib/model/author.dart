import 'package:json_annotation/json_annotation.dart';

part 'author.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Author {
  int aid;
  String name;
  String alias;
  String zone;
  String url;
  int mangaCount;
  int newestMangaId;
  String newestMangaTitle;
  String newestDate;
  double averageScore;
  String introduction;

  Author({this.aid, this.name, this.alias, this.zone, this.url, this.mangaCount, this.newestMangaId, this.newestMangaTitle, this.newestDate, this.averageScore, this.introduction});

  factory Author.fromJson(Map<String, dynamic> json) => _$AuthorFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorToJson(this);

  static const fields = <String>['aid', 'name', 'alias', 'zone', 'url', 'manga_count', 'newest_manga_id', 'newest_manga_title', 'newest_date', 'average_score', 'introduction'];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SmallAuthor {
  int aid;
  String name;
  String zone;
  String url;
  int mangaCount;
  String newestDate;

  SmallAuthor({this.aid, this.name, this.zone, this.url, this.mangaCount, this.newestDate});

  factory SmallAuthor.fromJson(Map<String, dynamic> json) => _$SmallAuthorFromJson(json);

  Map<String, dynamic> toJson() => _$SmallAuthorToJson(this);

  static const fields = <String>['aid', 'name', 'zone', 'url', 'manga_count', 'newest_date'];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TinyAuthor {
  int aid;
  String name;
  String url;

  TinyAuthor({this.aid, this.name, this.url});

  factory TinyAuthor.fromJson(Map<String, dynamic> json) => _$TinyAuthorFromJson(json);

  Map<String, dynamic> toJson() => _$TinyAuthorToJson(this);

  static const fields = <String>['aid', 'name', 'url'];
}
