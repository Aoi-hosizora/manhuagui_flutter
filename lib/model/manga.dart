import 'package:flutter_ahlib/util.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/chapter.dart';

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
  final String alias;
  final String aliasTitle;
  final bool finished;
  final String newestChapter;
  final String newestDate;
  final String briefIntroduction;
  final String introduction;
  final String mangaRank;
  final double averageScore;
  final int scoreCount;
  final List<String> perScores;
  final bool banned;
  final bool copyright;
  final List<MangaChapterGroup> chapterGroups;

  const Manga({required this.mid, required this.title, required this.cover, required this.url, required this.publishYear, required this.mangaZone, required this.genres, required this.authors, required this.alias, required this.aliasTitle, required this.finished, required this.newestChapter, required this.newestDate, required this.briefIntroduction, required this.introduction, required this.mangaRank, required this.averageScore, required this.scoreCount, required this.perScores, required this.banned, required this.copyright, required this.chapterGroups});

  factory Manga.fromJson(Map<String, dynamic> json) => _$MangaFromJson(json);

  Map<String, dynamic> toJson() => _$MangaToJson(this);
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

  TinyManga toTiny() {
    return TinyManga(mid: mid, title: title, cover: cover, url: url, finished: finished, newestChapter: newestChapter, newestDate: newestDate);
  }
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

  TinyManga({required this.mid, required this.title, required this.cover, required this.url, required this.finished, required this.newestChapter, required this.newestDate});

  factory TinyManga.fromJson(Map<String, dynamic> json) => _$TinyMangaFromJson(json);

  Map<String, dynamic> toJson() => _$TinyMangaToJson(this);
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
    return hash2(mid, title);
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaGroup {
  // 1. X (#12)
  // 2. 少女/爱情; 少年/热血; 竞技/体育; 武侠/格斗 (#10)
  // 3. 推理/恐怖/悬疑; 百合/后宫/治愈; 社会/历史/战争; 校园/励志/冒险 (#15)
  final String title;
  final List<TinyBlockManga> mangas;

  const MangaGroup({required this.title, required this.mangas});

  factory MangaGroup.fromJson(Map<String, dynamic> json) => _$MangaGroupFromJson(json);

  Map<String, dynamic> toJson() => _$MangaGroupToJson(this);
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
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaGroupList {
  // 1. 热门连载: top_group, groups (#4), other_groups (#4)
  // 2. 经典完结: top_group, groups (#4), other_groups (#4)
  // 3. 最新上架: top_group, groups (#4)
  final String title;
  final MangaGroup topGroup;
  final List<MangaGroup> groups;
  final List<MangaGroup> otherGroups;

  const MangaGroupList({required this.title, required this.topGroup, required this.groups, required this.otherGroups});

  factory MangaGroupList.fromJson(Map<String, dynamic> json) => _$MangaGroupListFromJson(json);

  Map<String, dynamic> toJson() => _$MangaGroupListToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class HomepageMangaGroupList {
  final MangaGroupList serial; // 热门连载
  final MangaGroupList finish; // 经典完结
  final MangaGroupList latest; // 最新上架

  const HomepageMangaGroupList({required this.serial, required this.finish, required this.latest});

  factory HomepageMangaGroupList.fromJson(Map<String, dynamic> json) => _$HomepageMangaGroupListFromJson(json);

  Map<String, dynamic> toJson() => _$HomepageMangaGroupListToJson(this);

  List<TinyBlockManga> get carouselMangas {
    var p1 = serial.topGroup.mangas.sublist(0, 4);
    var p2 = serial.groups.map((e) => e.mangas.first);
    var p3 = serial.otherGroups.map((e) => e.mangas.first);
    return [
      ...{...p1, ...p2, ...p3}
    ];
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaRank {
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

  const MangaRank({required this.mid, required this.title, required this.cover, required this.url, required this.finished, required this.authors, required this.newestChapter, required this.newestDate, required this.order, required this.score, required this.trend});

  factory MangaRank.fromJson(Map<String, dynamic> json) => _$MangaRankFromJson(json);

  Map<String, dynamic> toJson() => _$MangaRankToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ShelfManga {
  final int mid;
  final String title;
  final String cover;
  final String url;
  final String newestChapter;
  final String newestDuration;
  final String lastChapter;
  final String lastDuration;

  const ShelfManga({required this.mid, required this.title, required this.cover, required this.url, required this.newestChapter, required this.newestDuration, required this.lastChapter, required this.lastDuration});

  factory ShelfManga.fromJson(Map<String, dynamic> json) => _$ShelfMangaFromJson(json);

  Map<String, dynamic> toJson() => _$ShelfMangaToJson(this);
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

class MangaHistory {
  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final int chapterId; // 0 表示还没开始阅读（点进漫画页），非0 表示开始阅读（点进章节页）
  final String chapterTitle;
  final int chapterPage;
  final DateTime lastTime;

  const MangaHistory({required this.mangaId, required this.mangaTitle, required this.mangaCover, required this.mangaUrl, required this.chapterId, required this.chapterTitle, required this.chapterPage, required this.lastTime});

  bool get read => chapterId != 0;

  MangaHistory copyWith({
    int? mangaId,
    String? mangaTitle,
    String? mangaCover,
    String? mangaUrl,
    int? chapterId,
    String? chapterTitle,
    int? chapterPage,
    DateTime? lastTime,
  }) {
    return MangaHistory(
      mangaId: mangaId ?? this.mangaId,
      mangaTitle: mangaTitle ?? this.mangaTitle,
      mangaCover: mangaCover ?? this.mangaCover,
      mangaUrl: mangaUrl ?? this.mangaUrl,
      chapterId: chapterId ?? this.chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      chapterPage: chapterPage ?? this.chapterPage,
      lastTime: lastTime ?? this.lastTime,
    );
  }

  bool equals(MangaHistory o) {
    return mangaId == o.mangaId && mangaTitle == o.mangaTitle && mangaCover == o.mangaCover && mangaUrl == o.mangaUrl && chapterId == o.chapterId && chapterTitle == o.chapterTitle && chapterPage == o.chapterPage && lastTime == o.lastTime;
  }
}

class DownloadedManga {
  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final int totalChaptersCount;
  final int successChaptersCount;
  final DateTime updatedAt;

  const DownloadedManga({required this.mangaId, required this.mangaTitle, required this.mangaCover, required this.totalChaptersCount, required this.successChaptersCount, required this.updatedAt});
}

class DownloadedChapter {
  final int mangaId;
  final int chapterId;
  final String chapterTitle;
  final String chapterGroup;
  final int? totalPagesCount;
  final int? successPagesCount;

  const DownloadedChapter({required this.mangaId, required this.chapterId, required this.chapterTitle, required this.chapterGroup, required this.totalPagesCount, required this.successPagesCount});
}
