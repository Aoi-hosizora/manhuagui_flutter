import 'package:json_annotation/json_annotation.dart';
import 'package:manhuagui_flutter/model/common.dart';

part 'author.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Author {
  final int aid;
  final String name;
  final String alias;
  final String zone;
  final String cover;
  final String url;
  final int mangaCount;
  final int newestMangaId;
  final String newestMangaTitle;
  final String newestMangaUrl;
  final String newestDate;
  final int highestMangaId;
  final String highestMangaTitle;
  final String highestMangaUrl;
  final double highestScore;
  final double averageScore;
  final int popularity;
  final String introduction;
  final List<SmallerAuthor> relatedAuthors;

  const Author({required this.aid, required this.name, required this.alias, required this.zone, required this.cover, required this.url, required this.mangaCount, required this.newestMangaId, required this.newestMangaTitle, required this.newestMangaUrl, required this.newestDate, required this.highestMangaId, required this.highestMangaTitle, required this.highestMangaUrl, required this.highestScore, required this.averageScore, required this.popularity, required this.introduction, required this.relatedAuthors});

  factory Author.fromJson(Map<String, dynamic> json) => _$AuthorFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorToJson(this);

  String get formattedNewestDate => newestDate.replaceAll('-', '/');
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SmallAuthor {
  final int aid;
  final String name;
  final String zone;
  final String cover;
  final String url;
  final int mangaCount;
  final String newestDate;

  const SmallAuthor({required this.aid, required this.name, required this.zone, required this.cover, required this.url, required this.mangaCount, required this.newestDate});

  factory SmallAuthor.fromJson(Map<String, dynamic> json) => _$SmallAuthorFromJson(json);

  Map<String, dynamic> toJson() => _$SmallAuthorToJson(this);

  String get formattedNewestDate => newestDate.replaceAll('-', '/');

  String get formattedNewestDateWithDuration {
    var result = parseDurationOrDateString(formattedNewestDate);
    if (result.duration == null) {
      return result.date;
    }
    return '${result.duration} (${result.date})';
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SmallerAuthor {
  final int aid;
  final String name;
  final String url;
  final String zone;

  const SmallerAuthor({required this.aid, required this.name, required this.url, required this.zone});

  factory SmallerAuthor.fromJson(Map<String, dynamic> json) => _$SmallerAuthorFromJson(json);

  Map<String, dynamic> toJson() => _$SmallerAuthorToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TinyAuthor {
  final int aid;
  final String name;
  final String url;

  const TinyAuthor({required this.aid, required this.name, required this.url});

  factory TinyAuthor.fromJson(Map<String, dynamic> json) => _$TinyAuthorFromJson(json);

  Map<String, dynamic> toJson() => _$TinyAuthorToJson(this);
}
