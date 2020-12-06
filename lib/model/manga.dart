import 'package:json_annotation/json_annotation.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/chapter.dart';

part 'manga.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Manga {
  int mid;
  String title;
  String cover;
  String url;
  String publishYear;
  String mangaZone;
  List<Category> genres;
  List<TinyAuthor> authors;
  String alias;
  bool finished;
  String newestChapter;
  String newestDate;
  String briefIntroduction;
  String introduction;
  String mangaRank;
  double averageScore;
  int scoreCount;
  List<double> perScores;
  List<MangaChapterGroup> chapterGroups;

  Manga({this.mid, this.title, this.cover, this.url, this.publishYear, this.mangaZone, this.genres, this.authors, this.alias, this.finished, this.newestChapter, this.newestDate, this.briefIntroduction, this.introduction, this.mangaRank, this.averageScore, this.scoreCount, this.perScores, this.chapterGroups});

  factory Manga.fromJson(Map<String, dynamic> json) => _$MangaFromJson(json);

  Map<String, dynamic> toJson() => _$MangaToJson(this);

  static const fields = <String>['mid', 'title', 'cover', 'url', 'publish_year', 'manga_zone', 'genres', 'authors', 'alias', 'finished', 'newest_chapter', 'newest_date', 'brief_introduction', 'introduction', 'manga_rank', 'average_score', 'score_count', 'per_scores', 'chapter_groups'];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SmallManga {
  int mid;
  String title;
  String cover;
  String url;
  String publishYear;
  String mangaZone;
  List<Category> genres;
  List<TinyAuthor> authors;
  bool finished;
  String newestChapter;
  String newestDate;
  String briefIntroduction;

  SmallManga({this.mid, this.title, this.cover, this.url, this.publishYear, this.mangaZone, this.genres, this.authors, this.finished, this.newestChapter, this.newestDate, this.briefIntroduction});

  factory SmallManga.fromJson(Map<String, dynamic> json) => _$SmallMangaFromJson(json);

  Map<String, dynamic> toJson() => _$SmallMangaToJson(this);

  static const fields = <String>['mid', 'title', 'cover', 'url', 'publish_year', 'manga_zone', 'genres', 'authors', 'finished', 'newest_chapter', 'newest_date', 'brief_introduction'];

  TinyManga toTiny() {
    return TinyManga(mid: this.mid, title: this.title, cover: this.cover, url: this.url, finished: this.finished, newestChapter: this.newestChapter, newestDate: this.newestDate);
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TinyManga {
  int mid;
  String title;
  String cover;
  String url;
  bool finished;
  String newestChapter;
  String newestDate;

  TinyManga({this.mid, this.title, this.cover, this.url, this.finished, this.newestChapter, this.newestDate});

  factory TinyManga.fromJson(Map<String, dynamic> json) => _$TinyMangaFromJson(json);

  Map<String, dynamic> toJson() => _$TinyMangaToJson(this);

  static const fields = <String>['mid', 'title', 'cover', 'url', 'finished', 'newest_chapter', 'newest_date'];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaGroup {
  String title;
  List<TinyManga> mangas;

  MangaGroup({this.title, this.mangas});

  factory MangaGroup.fromJson(Map<String, dynamic> json) => _$MangaGroupFromJson(json);

  Map<String, dynamic> toJson() => _$MangaGroupToJson(this);

  static const fields = <String>['title', 'mangas'];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaGroupList {
  String title;
  MangaGroup topGroup;
  List<MangaGroup> groups;
  List<MangaGroup> otherGroups;

  MangaGroupList({this.title, this.topGroup, this.groups, this.otherGroups});

  factory MangaGroupList.fromJson(Map<String, dynamic> json) => _$MangaGroupListFromJson(json);

  Map<String, dynamic> toJson() => _$MangaGroupListToJson(this);

  static const fields = <String>['title', 'top_group', 'groups', 'other_groups'];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaRank {
  int mid;
  String title;
  String url;
  bool finished;
  List<TinyAuthor> authors;
  String newestChapter;
  String newestDate;
  int order;
  double score;
  int trend;

  MangaRank({this.mid, this.title, this.url, this.finished, this.authors, this.newestChapter, this.newestDate, this.order, this.score, this.trend});

  factory MangaRank.fromJson(Map<String, dynamic> json) => _$MangaRankFromJson(json);

  Map<String, dynamic> toJson() => _$MangaRankToJson(this);

  static const fields = <String>['mid', 'title', 'url', 'finished', 'authors', 'newest_chapter', 'newest_date', 'order', 'score', 'trend'];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ShelfManga {
  int mid;
  String title;
  String cover;
  String url;
  String newestChapter;
  String newestDuration;
  String lastChapter;
  String lastDuration;

  ShelfManga({this.mid, this.title, this.cover, this.url, this.newestChapter, this.newestDuration, this.lastChapter, this.lastDuration});

  factory ShelfManga.fromJson(Map<String, dynamic> json) => _$ShelfMangaFromJson(json);

  Map<String, dynamic> toJson() => _$ShelfMangaToJson(this);

  static const fields = <String>['mid', 'title', 'cover', 'url', 'newest_chapter', 'newest_duration', 'last_chapter', 'last_duration'];
}
