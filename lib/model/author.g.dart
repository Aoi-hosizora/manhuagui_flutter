// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'author.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Author _$AuthorFromJson(Map<String, dynamic> json) => Author(
      aid: json['aid'] as int,
      name: json['name'] as String,
      alias: json['alias'] as String,
      zone: json['zone'] as String,
      cover: json['cover'] as String,
      url: json['url'] as String,
      mangaCount: json['manga_count'] as int,
      newestMangaId: json['newest_manga_id'] as int,
      newestMangaTitle: json['newest_manga_title'] as String,
      newestMangaUrl: json['newest_manga_url'] as String,
      newestDate: json['newest_date'] as String,
      highestMangaId: json['highest_manga_id'] as int,
      highestMangaTitle: json['highest_manga_title'] as String,
      highestMangaUrl: json['highest_manga_url'] as String,
      highestScore: (json['highest_score'] as num).toDouble(),
      averageScore: (json['average_score'] as num).toDouble(),
      popularity: json['popularity'] as int,
      introduction: json['introduction'] as String,
      relatedAuthors: (json['related_authors'] as List<dynamic>)
          .map((e) => TinyZonedAuthor.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AuthorToJson(Author instance) => <String, dynamic>{
      'aid': instance.aid,
      'name': instance.name,
      'alias': instance.alias,
      'zone': instance.zone,
      'cover': instance.cover,
      'url': instance.url,
      'manga_count': instance.mangaCount,
      'newest_manga_id': instance.newestMangaId,
      'newest_manga_title': instance.newestMangaTitle,
      'newest_manga_url': instance.newestMangaUrl,
      'newest_date': instance.newestDate,
      'highest_manga_id': instance.highestMangaId,
      'highest_manga_title': instance.highestMangaTitle,
      'highest_manga_url': instance.highestMangaUrl,
      'highest_score': instance.highestScore,
      'average_score': instance.averageScore,
      'popularity': instance.popularity,
      'introduction': instance.introduction,
      'related_authors': instance.relatedAuthors,
    };

SmallAuthor _$SmallAuthorFromJson(Map<String, dynamic> json) => SmallAuthor(
      aid: json['aid'] as int,
      name: json['name'] as String,
      zone: json['zone'] as String,
      cover: json['cover'] as String,
      url: json['url'] as String,
      mangaCount: json['manga_count'] as int,
      newestDate: json['newest_date'] as String,
    );

Map<String, dynamic> _$SmallAuthorToJson(SmallAuthor instance) =>
    <String, dynamic>{
      'aid': instance.aid,
      'name': instance.name,
      'zone': instance.zone,
      'cover': instance.cover,
      'url': instance.url,
      'manga_count': instance.mangaCount,
      'newest_date': instance.newestDate,
    };

TinyAuthor _$TinyAuthorFromJson(Map<String, dynamic> json) => TinyAuthor(
      aid: json['aid'] as int,
      name: json['name'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$TinyAuthorToJson(TinyAuthor instance) =>
    <String, dynamic>{
      'aid': instance.aid,
      'name': instance.name,
      'url': instance.url,
    };

TinyZonedAuthor _$TinyZonedAuthorFromJson(Map<String, dynamic> json) =>
    TinyZonedAuthor(
      aid: json['aid'] as int,
      name: json['name'] as String,
      url: json['url'] as String,
      zone: json['zone'] as String,
    );

Map<String, dynamic> _$TinyZonedAuthorToJson(TinyZonedAuthor instance) =>
    <String, dynamic>{
      'aid': instance.aid,
      'name': instance.name,
      'url': instance.url,
      'zone': instance.zone,
    };
