import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
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
  List<String> perScores;
  bool banned;
  bool copyright;
  List<MangaChapterGroup> chapterGroups;

  Manga(
      {this.mid,
      this.title,
      this.cover,
      this.url,
      this.publishYear,
      this.mangaZone,
      this.genres,
      this.authors,
      this.alias,
      this.finished,
      this.newestChapter,
      this.newestDate,
      this.briefIntroduction,
      this.introduction,
      this.mangaRank,
      this.averageScore,
      this.scoreCount,
      this.perScores,
      this.banned,
      this.copyright,
      this.chapterGroups});

  factory Manga.fromJson(Map<String, dynamic> json) => _$MangaFromJson(json);

  Map<String, dynamic> toJson() => _$MangaToJson(this);

  static const fields = <String>['mid', 'title', 'cover', 'url', 'publish_year', 'manga_zone', 'genres', 'authors', 'alias', 'finished', 'newest_chapter', 'newest_date', 'brief_introduction', 'introduction', 'manga_rank', 'average_score', 'score_count', 'per_scores', 'banned', 'copyright', 'chapter_groups'];
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
class TinyBlockManga {
  int mid;
  String title;
  String cover;
  String url;
  bool finished;
  String newestChapter;

  TinyBlockManga({this.mid, this.title, this.cover, this.url, this.finished, this.newestChapter});

  factory TinyBlockManga.fromJson(Map<String, dynamic> json) => _$TinyBlockMangaFromJson(json);

  Map<String, dynamic> toJson() => _$TinyBlockMangaToJson(this);

  static const fields = <String>['mid', 'title', 'cover', 'url', 'finished', 'newest_chapter'];

  @override
  bool operator ==(Object other) {
    return other is TinyBlockManga && other.mid == this.mid;
  }

  @override
  int get hashCode {
    return hash2(mid, title);
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaGroup {
  // 1. X (#12)
  // 2. 少女/爱情; 少年/热血; 竞技/体育; 武侠/格斗 (#10)
  // 3. 推理/恐怖/悬疑; 百合/后宫/治愈; 社会/历史/战争; 校园/励志/冒险 (#15)
  String title;
  List<TinyBlockManga> mangas;

  MangaGroup({this.title, this.mangas});

  factory MangaGroup.fromJson(Map<String, dynamic> json) => _$MangaGroupFromJson(json);

  Map<String, dynamic> toJson() => _$MangaGroupToJson(this);

  static const fields = <String>['title', 'mangas'];
}

/// [MangaGroupList.title]
enum MangaGroupType {
  serial,
  finish,
  latest,
}

extension MangaGroupTitleExtension on MangaGroupType {
  String toTitle() {
    switch (this) {
      case MangaGroupType.serial:
        return '热门连载';
      case MangaGroupType.finish:
        return '经典完结';
      case MangaGroupType.latest:
        return '最新上架';
    }
    return '?';
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaGroupList {
  // 1. 热门连载: top_group, groups (#4), other_groups (#4)
  // 2. 经典完结: top_group, groups (#4), other_groups (#4)
  // 3. 最新上架: top_group, groups (#4)
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
class HomepageMangaGroupList {
  MangaGroupList serial; // 热门连载
  MangaGroupList finish; // 经典完结
  MangaGroupList latest; // 最新上架

  HomepageMangaGroupList({this.serial, this.finish, this.latest});

  factory HomepageMangaGroupList.fromJson(Map<String, dynamic> json) => _$HomepageMangaGroupListFromJson(json);

  Map<String, dynamic> toJson() => _$HomepageMangaGroupListToJson(this);

  static const fields = <String>['serial', 'finish', 'latest'];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaRank {
  int mid;
  String title;
  String cover;
  String url;
  bool finished;
  List<TinyAuthor> authors;
  String newestChapter;
  String newestDate;
  int order;
  double score;
  int trend;

  MangaRank({this.mid, this.title, this.cover, this.url, this.finished, this.authors, this.newestChapter, this.newestDate, this.order, this.score, this.trend});

  factory MangaRank.fromJson(Map<String, dynamic> json) => _$MangaRankFromJson(json);

  Map<String, dynamic> toJson() => _$MangaRankToJson(this);

  static const fields = <String>['mid', 'title', 'cover', 'url', 'finished', 'authors', 'newest_chapter', 'newest_date', 'order', 'score', 'trend'];
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

@JsonSerializable(fieldRename: FieldRename.snake)
class ShelfStatus {
  @JsonKey(name: 'in')
  bool isIn;
  int count;

  ShelfStatus({this.isIn, this.count});

  factory ShelfStatus.fromJson(Map<String, dynamic> json) => _$ShelfStatusFromJson(json);

  Map<String, dynamic> toJson() => _$ShelfStatusToJson(this);

  static const fields = <String>['in', 'count'];
}

class MangaHistory {
  int mangaId;
  String mangaTitle;
  String mangaCover;
  String mangaUrl;

  int chapterId;
  String chapterTitle;
  int chapterPage;

  DateTime lastTime;

  MangaHistory({this.mangaId, this.mangaTitle, this.mangaCover, this.mangaUrl, this.chapterId, this.chapterTitle, this.chapterPage, this.lastTime});
}
