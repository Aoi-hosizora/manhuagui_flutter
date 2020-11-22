import 'package:json_annotation/json_annotation.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/model/category.dart';

part 'manga.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaPage {
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

  MangaPage({this.mid, this.title, this.cover, this.url, this.publishYear, this.mangaZone, this.genres, this.authors, this.alias, this.finished, this.newestChapter, this.newestDate, this.briefIntroduction, this.introduction, this.mangaRank, this.averageScore, this.scoreCount, this.perScores});

  factory MangaPage.fromJson(Map<String, dynamic> json) => _$MangaPageFromJson(json);

  Map<String, dynamic> toJson() => _$MangaPageToJson(this);

  static const fields = <String>['mid', 'title', 'cover', 'url', 'publish_year', 'manga_zone', 'genres', 'authors', 'alias', 'finished', 'newest_chapter', 'newest_date', 'brief_introduction', 'introduction', 'manga_rank', 'average_score', 'score_count', 'per_scores'];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SmallMangaPage {
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

  SmallMangaPage({this.mid, this.title, this.cover, this.url, this.publishYear, this.mangaZone, this.genres, this.authors, this.finished, this.newestChapter, this.newestDate, this.briefIntroduction});

  factory SmallMangaPage.fromJson(Map<String, dynamic> json) => _$SmallMangaPageFromJson(json);

  Map<String, dynamic> toJson() => _$SmallMangaPageToJson(this);

  static const fields = <String>['mid', 'title', 'cover', 'url', 'publish_year', 'manga_zone', 'genres', 'authors', 'finished', 'newest_chapter', 'newest_date', 'brief_introduction'];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TinyMangaPage {
  int mid;
  String title;
  String cover;
  String url;
  bool finished;
  String newestChapter;
  String newestDate;

  TinyMangaPage({this.mid, this.title, this.cover, this.url, this.finished, this.newestChapter, this.newestDate});

  factory TinyMangaPage.fromJson(Map<String, dynamic> json) => _$TinyMangaPageFromJson(json);

  Map<String, dynamic> toJson() => _$TinyMangaPageToJson(this);

  static const fields = <String>['mid', 'title', 'cover', 'url', 'finished', 'newest_chapter', 'newest_date'];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaPageGroup {
  String title;
  List<TinyMangaPage> mangas;

  MangaPageGroup({this.title, this.mangas});

  factory MangaPageGroup.fromJson(Map<String, dynamic> json) => _$MangaPageGroupFromJson(json);

  Map<String, dynamic> toJson() => _$MangaPageGroupToJson(this);

  static const fields = <String>['title', 'mangas'];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaPageGroupList {
  String title;
  MangaPageGroup topGroup;
  List<MangaPageGroup> groups;
  List<MangaPageGroup> otherGroups;

  MangaPageGroupList({this.title, this.topGroup, this.groups, this.otherGroups});

  factory MangaPageGroupList.fromJson(Map<String, dynamic> json) => _$MangaPageGroupListFromJson(json);

  Map<String, dynamic> toJson() => _$MangaPageGroupListToJson(this);

  static const fields = <String>['title', 'top_group', 'groups', 'other_groups'];
}
