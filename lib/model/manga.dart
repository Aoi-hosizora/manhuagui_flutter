import 'dart:ui';

import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/common.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/manga_viewer.dart';

part 'manga.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Manga {
  final int mid;
  final String title;
  final String cover;
  final String url;
  final String publishYear;
  final String mangaZone;
  final List<Category> genres;
  final List<TinyAuthor> authors;
  final List<String> aliases;
  final bool finished;
  final String newestChapter;
  final String newestDate;
  final String briefIntroduction;
  final String introduction;
  final String mangaRank;
  final double averageScore;
  final int scoreCount;
  final List<String> perScores;
  final bool downed;
  final bool copyright;
  final bool violent;
  final bool lawblocked;
  final List<MangaChapterGroup> chapterGroups;

  const Manga({required this.mid, required this.title, required this.cover, required this.url, required this.publishYear, required this.mangaZone, required this.genres, required this.authors, required this.aliases, required this.finished, required this.newestChapter, required this.newestDate, required this.briefIntroduction, required this.introduction, required this.mangaRank, required this.averageScore, required this.scoreCount, required this.perScores, required this.downed, required this.copyright, required this.violent, required this.lawblocked, required this.chapterGroups});

  factory Manga.fromJson(Map<String, dynamic> json) => _$MangaFromJson(json);

  Map<String, dynamic> toJson() => _$MangaToJson(this);

  String get formattedNewestDate => // for manga page, manga detail page, manga viewer page, and manga dialogs
      parseDurationOrDateString(newestDate).date;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SmallManga {
  final int mid;
  final String title;
  final String cover;
  final String url;
  final String publishYear;
  final String mangaZone;
  final List<Category> genres;
  final List<TinyAuthor> authors;
  final bool finished;
  final String newestChapter;
  final String newestDate;
  final String briefIntroduction;

  const SmallManga({required this.mid, required this.title, required this.cover, required this.url, required this.publishYear, required this.mangaZone, required this.genres, required this.authors, required this.finished, required this.newestChapter, required this.newestDate, required this.briefIntroduction});

  factory SmallManga.fromJson(Map<String, dynamic> json) => _$SmallMangaFromJson(json);

  Map<String, dynamic> toJson() => _$SmallMangaToJson(this);

  String get formattedNewestDate => // for manga dialogs
      parseDurationOrDateString(newestDate).date;

  SmallerManga toSmaller() {
    return SmallerManga(mid: mid, title: title, cover: cover, url: url, finished: finished, authors: authors.map((a) => a.name).toList(), genres: genres.map((g) => g.name).toList(), newestChapter: newestChapter, newestDate: newestDate);
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SmallerManga {
  final int mid;
  final String title;
  final String cover;
  final String url;
  final bool finished;
  final List<String> authors;
  final List<String> genres;
  final String newestChapter;
  final String newestDate;

  String get formattedNewestChapter => RegExp('^[0-9]').hasMatch(newestChapter) ? '第$newestChapter' : newestChapter;

  const SmallerManga({required this.mid, required this.title, required this.cover, required this.url, required this.finished, required this.authors, required this.genres, required this.newestChapter, required this.newestDate});

  factory SmallerManga.fromJson(Map<String, dynamic> json) => _$SmallerMangaFromJson(json);

  Map<String, dynamic> toJson() => _$SmallerMangaToJson(this);

  String get formattedNewestDate => // for manga dialogs
      parseDurationOrDateString(newestDate).date;

  String get formattedNewestDateWithDuration => // for small manga line
      parseDurationOrDateString(newestDate).durationDate;

  int? get newestDateDayDuration => // for small manga line's color
      parseDurationOrDateString(newestDate).dayDiff;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TinyManga {
  final int mid;
  final String title;
  final String cover;
  final String url;
  final bool finished;
  final String newestChapter;
  final String newestDate;

  String get formattedNewestChapter => RegExp('^[0-9]').hasMatch(newestChapter) ? '第$newestChapter' : newestChapter;

  const TinyManga({required this.mid, required this.title, required this.cover, required this.url, required this.finished, required this.newestChapter, required this.newestDate});

  factory TinyManga.fromJson(Map<String, dynamic> json) => _$TinyMangaFromJson(json);

  Map<String, dynamic> toJson() => _$TinyMangaToJson(this);

  String get formattedNewestDate => // for manga dialogs
      parseDurationOrDateString(newestDate).date;

  String get formattedNewestDateWithDuration => // for tiny manga line
      parseDurationOrDateString(newestDate).durationDate;

  int? get newestDateDayDuration => // for tiny manga line's color
      parseDurationOrDateString(newestDate).dayDiff;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RandomMangaInfo {
  final int mid;
  final String url;

  const RandomMangaInfo({required this.mid, required this.url});

  factory RandomMangaInfo.fromJson(Map<String, dynamic> json) => _$RandomMangaInfoFromJson(json);

  Map<String, dynamic> toJson() => _$RandomMangaInfoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TinyBlockManga {
  final int mid;
  final String title;
  final String cover;
  final String url;
  final bool finished;
  final String newestChapter;

  const TinyBlockManga({required this.mid, required this.title, required this.cover, required this.url, required this.finished, required this.newestChapter});

  factory TinyBlockManga.fromJson(Map<String, dynamic> json) => _$TinyBlockMangaFromJson(json);

  Map<String, dynamic> toJson() => _$TinyBlockMangaToJson(this);

  @override
  bool operator ==(Object other) {
    return other is TinyBlockManga && other.mid == mid;
  }

  @override
  int get hashCode {
    return hashValues(mid, title);
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaGroup {
  // title = "", #manga = 12 (topGroup)
  // title = "少女/爱情", #manga = 10 (groups1)
  // title = "少年/热血", #manga = 10 (groups1)
  // title = "竞技/体育", #manga = 10 (groups1)
  // title = "武侠/格斗", #manga = 10 (groups1)
  // title = "推理/恐怖/悬疑", #manga = 15 (groups2)
  // title = "百合/后宫/治愈", #manga = 15 (groups2)
  // title = "社会/历史/战争", #manga = 15 (groups2)
  // title = "校园/励志/冒险", #manga = 15 (groups2)

  final String title;
  final List<TinyBlockManga> mangas;

  const MangaGroup({required this.title, required this.mangas});

  factory MangaGroup.fromJson(Map<String, dynamic> json) => _$MangaGroupFromJson(json);

  Map<String, dynamic> toJson() => _$MangaGroupToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaGroupList {
  // serial => title = "热门连载", #topGroup = 1, #groups1 = 4, #groups2 = 4
  // finish => title = "经典完结", #topGroup = 1, #groups1 = 4, #groups2 = 4
  // latest => title = "最新上架", #topGroup = 1, #groups1 = 4, #groups2 = 4 (groups2 is fake)

  final String title;
  @JsonKey(name: 'top_group')
  final MangaGroup topGroup;
  @JsonKey(name: 'groups')
  final List<MangaGroup> groups1;
  @JsonKey(name: 'other_groups')
  final List<MangaGroup> groups2;

  const MangaGroupList({required this.title, required this.topGroup, required this.groups1, required this.groups2});

  factory MangaGroupList.fromJson(Map<String, dynamic> json) => _$MangaGroupListFromJson(json);

  Map<String, dynamic> toJson() => _$MangaGroupListToJson(this);

  bool get isSerial => title == '热门连载';

  bool get isFinish => title == '经典完结';

  bool get isLatest => title == '最新上架';
}

@JsonSerializable(fieldRename: FieldRename.snake)
class HomepageMangaGroupList {
  // 0. "" => 热门连载 | 经典完结 | 最新上架
  // 1. "热门连载" => 少女/爱情 | 少年/热血 | 竞技/体育 | 武侠/格斗
  // 2. "经典完结" => 少女/爱情 | 少年/热血 | 竞技/体育 | 武侠/格斗
  // 3. "最新上架" => 少女/爱情 | 少年/热血 | 竞技/体育 | 武侠/格斗
  // 4. "热门连载" => 推理/恐怖/悬疑 | 百合/后宫/治愈 | 社会/历史/战争 | 校园/励志/冒险
  // 5. "经典完结" => 推理/恐怖/悬疑 | 百合/后宫/治愈 | 社会/历史/战争 | 校园/励志/冒险
  // 6. "最新上架" => 推理/恐怖/悬疑 | 百合/后宫/治愈 | 社会/历史/战争 | 校园/励志/冒险 (all four tabs are fake)

  final MangaGroupList serial; // 热门连载
  final MangaGroupList finish; // 经典完结
  final MangaGroupList latest; // 最新上架
  final List<MangaRanking> daily; // 日排行榜
  final List<Category> genres; // 漫画类别-剧情
  final List<Category> ages; // 漫画类别-受众
  final List<Category> zones; // 漫画类别-地区

  const HomepageMangaGroupList({required this.serial, required this.finish, required this.latest, required this.daily, required this.genres, required this.ages, required this.zones});

  factory HomepageMangaGroupList.fromJson(Map<String, dynamic> json) => _$HomepageMangaGroupListFromJson(json);

  Map<String, dynamic> toJson() => _$HomepageMangaGroupListToJson(this);

  List<TinyBlockManga> get carouselMangas {
    var p1 = daily.sublist(0, 8.clamp(0, daily.length)).map((e) => e.toTinyBlock()).toList(); // # = 8
    var p2 = serial.topGroup.mangas.sublist(0, 4.clamp(0, serial.topGroup.mangas.length)); // # = 4
    return [
      ...{
        if (p1.isNotEmpty) p1[0],
        if (p1.length >= 2) p1[1],
        if (p2.isNotEmpty) p2[0],
        if (p1.length >= 3) p1[2],
        if (p1.length >= 4) p1[3],
        if (p2.length >= 2) p2[1],
        if (p1.length >= 5) p1[4],
        if (p1.length >= 6) p1[5],
        if (p2.length >= 3) p2[2],
        if (p1.length >= 7) p1[6],
        if (p1.length >= 8) p1[7],
        if (p2.length >= 4) p2[3],
      }, // # ≒ 12
    ];
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaRanking {
  final int mid;
  final String title;
  final String cover;
  final String url;
  final bool finished;
  final List<TinyAuthor> authors;
  final String newestChapter;
  final String newestDate;
  final int order;
  final double score;
  final int trend;

  const MangaRanking({required this.mid, required this.title, required this.cover, required this.url, required this.finished, required this.authors, required this.newestChapter, required this.newestDate, required this.order, required this.score, required this.trend});

  factory MangaRanking.fromJson(Map<String, dynamic> json) => _$MangaRankingFromJson(json);

  Map<String, dynamic> toJson() => _$MangaRankingToJson(this);

  String get formattedNewestDate => // for manga dialogs
      parseDurationOrDateString(newestDate).date;

  String get formattedNewestDateWithDuration => // for manga ranking line
      parseDurationOrDateString(newestDate).durationDate;

  String get formattedNewestDurationOrDate => // for manga aud-ranking line
      parseDurationOrDateString(newestDate).let((r) => r.duration ?? r.date);

  int? get newestDateDayDuration => // for manga ranking line and manga aud-ranking line's color
      parseDurationOrDateString(newestDate).dayDiff;

  TinyBlockManga toTinyBlock() {
    return TinyBlockManga(
      mid: mid,
      title: title,
      cover: cover,
      url: url,
      finished: finished,
      newestChapter: newestChapter,
    );
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ShelfManga {
  final int mid;
  final String title;
  final String cover;
  final String url;
  final String newestChapter;
  final String newestDuration; // duration or date
  final String lastChapter;
  final String lastDuration; // duration or date

  const ShelfManga({required this.mid, required this.title, required this.cover, required this.url, required this.newestChapter, required this.newestDuration, required this.lastChapter, required this.lastDuration});

  factory ShelfManga.fromJson(Map<String, dynamic> json) => _$ShelfMangaFromJson(json);

  Map<String, dynamic> toJson() => _$ShelfMangaToJson(this);

  String get formattedNewestDate => // for manga dialogs
      parseDurationOrDateString(lastDuration).date; // "2023/02/02"

  String get formattedLastDurationOrDate => // for shelf magna line
      parseDurationOrDateString(lastDuration).let((r) => r.duration ?? r.date); // "xxx天前" or "2023/02/02"

  String get formattedNewestDurationOrDate => // for manga collection view
      parseDurationOrDateString(newestDuration).let((r) => r.duration ?? r.date); // "xxx天前" or "2023/02/02"

  String get formattedNewestDateWithDuration => // for shelf magna line
      parseDurationOrDateString(newestDuration).durationDate; // "xxx天前 (2023/02/02)" or "2023-02-02"

  int? get newestDateDayDuration => // for shelf magna line's color
      parseDurationOrDateString(newestDuration).dayDiff;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ShelfStatus {
  @JsonKey(name: 'in')
  final bool isIn;
  final int count;

  const ShelfStatus({required this.isIn, required this.count});

  factory ShelfStatus.fromJson(Map<String, dynamic> json) => _$ShelfStatusFromJson(json);

  Map<String, dynamic> toJson() => _$ShelfStatusToJson(this);
}

/// 漫画弹出菜单所需的一些额外的漫画数据，在 [manga_dialog.dart] 中使用
class MangaExtraDataForDialog {
  const MangaExtraDataForDialog({this.mangaAuthors, this.newestChapter, this.newestDate});

  final List<String>? mangaAuthors;
  final String? newestChapter;
  final String? newestDate;

  factory MangaExtraDataForDialog.fromManga(Manga manga) => //
      MangaExtraDataForDialog(mangaAuthors: manga.authors.map((a) => a.name).toList(), newestChapter: manga.newestChapter, newestDate: manga.formattedNewestDate);

  factory MangaExtraDataForDialog.fromMangaViewer(MangaViewerPageData manga) => //
      MangaExtraDataForDialog(mangaAuthors: manga.mangaAuthors?.map((a) => a.name).toList(), newestChapter: manga.newestChapter, newestDate: manga.newestDate);

  factory MangaExtraDataForDialog.fromSmallManga(SmallManga manga) => //
      MangaExtraDataForDialog(mangaAuthors: manga.authors.map((a) => a.name).toList(), newestChapter: manga.newestChapter, newestDate: manga.formattedNewestDate);

  factory MangaExtraDataForDialog.fromSmallerManga(SmallerManga manga) => //
      MangaExtraDataForDialog(mangaAuthors: manga.authors, newestChapter: manga.newestChapter, newestDate: manga.formattedNewestDate);

  factory MangaExtraDataForDialog.fromTinyManga(TinyManga manga) => //
      MangaExtraDataForDialog(newestChapter: manga.newestChapter, newestDate: manga.formattedNewestDate);

  factory MangaExtraDataForDialog.fromMangaRanking(MangaRanking manga) => //
      MangaExtraDataForDialog(mangaAuthors: manga.authors.map((a) => a.name).toList(), newestChapter: manga.newestChapter, newestDate: manga.formattedNewestDate);

  factory MangaExtraDataForDialog.fromShelfManga(ShelfManga manga) => //
      MangaExtraDataForDialog(newestChapter: manga.newestChapter, newestDate: manga.formattedNewestDate);

  factory MangaExtraDataForDialog.fromLaterManga(LaterManga manga) => //
      MangaExtraDataForDialog(newestChapter: manga.newestChapter, newestDate: manga.newestDate);
}

/// 漫画章节阅读页所需的一些额外的漫画数据，字段均来自 [Manga]，在 [MangaViewerPage] 使用
class MangaExtraDataForViewer {
  const MangaExtraDataForViewer({
    required this.chapterGroups,
    required this.mangaAuthors,
    required this.newestChapter,
    required this.newestDate,
    required this.isMangaFinished,
  });

  final List<MangaChapterGroup> chapterGroups;
  final List<TinyAuthor> mangaAuthors;
  final String newestChapter;
  final String newestDate;
  final bool isMangaFinished;

  MangaExtraDataForDialog toExtraDataForDialog() {
    return MangaExtraDataForDialog(
      mangaAuthors: mangaAuthors.map((a) => a.name).toList(),
      newestChapter: newestChapter,
      newestDate: newestDate,
    );
  }

  static MangaExtraDataForViewer fromMangaData(Manga manga) {
    return MangaExtraDataForViewer(
      chapterGroups: manga.chapterGroups,
      mangaAuthors: manga.authors,
      newestChapter: manga.newestChapter,
      newestDate: manga.formattedNewestDate,
      isMangaFinished: manga.finished,
    );
  }

  static MangaExtraDataForViewer? fromNullableMangaData(Manga? manga) {
    if (manga == null) {
      return null;
    }
    return fromMangaData(manga);
  }
}
