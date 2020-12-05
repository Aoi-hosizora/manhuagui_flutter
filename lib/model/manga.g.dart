// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manga.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Manga _$MangaFromJson(Map<String, dynamic> json) {
  return Manga(
    mid: json['mid'] as int,
    title: json['title'] as String,
    cover: json['cover'] as String,
    url: json['url'] as String,
    publishYear: json['publish_year'] as String,
    mangaZone: json['manga_zone'] as String,
    genres: (json['genres'] as List)
        ?.map((e) =>
            e == null ? null : Category.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    authors: (json['authors'] as List)
        ?.map((e) =>
            e == null ? null : TinyAuthor.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    alias: json['alias'] as String,
    finished: json['finished'] as bool,
    newestChapter: json['newest_chapter'] as String,
    newestDate: json['newest_date'] as String,
    briefIntroduction: json['brief_introduction'] as String,
    introduction: json['introduction'] as String,
    mangaRank: json['manga_rank'] as String,
    averageScore: (json['average_score'] as num)?.toDouble(),
    scoreCount: json['score_count'] as int,
    perScores: (json['per_scores'] as List)
        ?.map((e) => (e as num)?.toDouble())
        ?.toList(),
    chapterGroups: (json['chapter_groups'] as List)
        ?.map((e) => e == null
            ? null
            : MangaChapterGroup.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$MangaToJson(Manga instance) => <String, dynamic>{
      'mid': instance.mid,
      'title': instance.title,
      'cover': instance.cover,
      'url': instance.url,
      'publish_year': instance.publishYear,
      'manga_zone': instance.mangaZone,
      'genres': instance.genres,
      'authors': instance.authors,
      'alias': instance.alias,
      'finished': instance.finished,
      'newest_chapter': instance.newestChapter,
      'newest_date': instance.newestDate,
      'brief_introduction': instance.briefIntroduction,
      'introduction': instance.introduction,
      'manga_rank': instance.mangaRank,
      'average_score': instance.averageScore,
      'score_count': instance.scoreCount,
      'per_scores': instance.perScores,
      'chapter_groups': instance.chapterGroups,
    };

SmallManga _$SmallMangaFromJson(Map<String, dynamic> json) {
  return SmallManga(
    mid: json['mid'] as int,
    title: json['title'] as String,
    cover: json['cover'] as String,
    url: json['url'] as String,
    publishYear: json['publish_year'] as String,
    mangaZone: json['manga_zone'] as String,
    genres: (json['genres'] as List)
        ?.map((e) =>
            e == null ? null : Category.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    authors: (json['authors'] as List)
        ?.map((e) =>
            e == null ? null : TinyAuthor.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    finished: json['finished'] as bool,
    newestChapter: json['newest_chapter'] as String,
    newestDate: json['newest_date'] as String,
    briefIntroduction: json['brief_introduction'] as String,
  );
}

Map<String, dynamic> _$SmallMangaToJson(SmallManga instance) =>
    <String, dynamic>{
      'mid': instance.mid,
      'title': instance.title,
      'cover': instance.cover,
      'url': instance.url,
      'publish_year': instance.publishYear,
      'manga_zone': instance.mangaZone,
      'genres': instance.genres,
      'authors': instance.authors,
      'finished': instance.finished,
      'newest_chapter': instance.newestChapter,
      'newest_date': instance.newestDate,
      'brief_introduction': instance.briefIntroduction,
    };

TinyManga _$TinyMangaFromJson(Map<String, dynamic> json) {
  return TinyManga(
    mid: json['mid'] as int,
    title: json['title'] as String,
    cover: json['cover'] as String,
    url: json['url'] as String,
    finished: json['finished'] as bool,
    newestChapter: json['newest_chapter'] as String,
    newestDate: json['newest_date'] as String,
  );
}

Map<String, dynamic> _$TinyMangaToJson(TinyManga instance) => <String, dynamic>{
      'mid': instance.mid,
      'title': instance.title,
      'cover': instance.cover,
      'url': instance.url,
      'finished': instance.finished,
      'newest_chapter': instance.newestChapter,
      'newest_date': instance.newestDate,
    };

MangaGroup _$MangaGroupFromJson(Map<String, dynamic> json) {
  return MangaGroup(
    title: json['title'] as String,
    mangas: (json['mangas'] as List)
        ?.map((e) =>
            e == null ? null : TinyManga.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$MangaGroupToJson(MangaGroup instance) =>
    <String, dynamic>{
      'title': instance.title,
      'mangas': instance.mangas,
    };

MangaGroupList _$MangaGroupListFromJson(Map<String, dynamic> json) {
  return MangaGroupList(
    title: json['title'] as String,
    topGroup: json['top_group'] == null
        ? null
        : MangaGroup.fromJson(json['top_group'] as Map<String, dynamic>),
    groups: (json['groups'] as List)
        ?.map((e) =>
            e == null ? null : MangaGroup.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    otherGroups: (json['other_groups'] as List)
        ?.map((e) =>
            e == null ? null : MangaGroup.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$MangaGroupListToJson(MangaGroupList instance) =>
    <String, dynamic>{
      'title': instance.title,
      'top_group': instance.topGroup,
      'groups': instance.groups,
      'other_groups': instance.otherGroups,
    };

MangaRank _$MangaRankFromJson(Map<String, dynamic> json) {
  return MangaRank(
    mid: json['mid'] as int,
    title: json['title'] as String,
    url: json['url'] as String,
    finished: json['finished'] as bool,
    authors: (json['authors'] as List)
        ?.map((e) =>
            e == null ? null : TinyAuthor.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    newestChapter: json['newest_chapter'] as String,
    newestDate: json['newest_date'] as String,
    order: json['order'] as int,
    score: (json['score'] as num)?.toDouble(),
    trend: json['trend'] as int,
  );
}

Map<String, dynamic> _$MangaRankToJson(MangaRank instance) => <String, dynamic>{
      'mid': instance.mid,
      'title': instance.title,
      'url': instance.url,
      'finished': instance.finished,
      'authors': instance.authors,
      'newest_chapter': instance.newestChapter,
      'newest_date': instance.newestDate,
      'order': instance.order,
      'score': instance.score,
      'trend': instance.trend,
    };

ShelfManga _$ShelfMangaFromJson(Map<String, dynamic> json) {
  return ShelfManga(
    mid: json['mid'] as int,
    title: json['title'] as String,
    cover: json['cover'] as String,
    url: json['url'] as String,
    newestChapter: json['newest_chapter'] as String,
    newestDuration: json['newest_duration'] as String,
    lastChapter: json['last_chapter'] as String,
    lastDuration: json['last_duration'] as String,
  );
}

Map<String, dynamic> _$ShelfMangaToJson(ShelfManga instance) =>
    <String, dynamic>{
      'mid': instance.mid,
      'title': instance.title,
      'cover': instance.cover,
      'url': instance.url,
      'newest_chapter': instance.newestChapter,
      'newest_duration': instance.newestDuration,
      'last_chapter': instance.lastChapter,
      'last_duration': instance.lastDuration,
    };
