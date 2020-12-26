// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'author.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Author _$AuthorFromJson(Map<String, dynamic> json) {
  return Author(
    aid: json['aid'] as int,
    name: json['name'] as String,
    alias: json['alias'] as String,
    zone: json['zone'] as String,
    cover: json['cover'] as String,
    url: json['url'] as String,
    mangaCount: json['manga_count'] as int,
    newestMangaId: json['newest_manga_id'] as int,
    newestMangaTitle: json['newest_manga_title'] as String,
    newestDate: json['newest_date'] as String,
    averageScore: (json['average_score'] as num)?.toDouble(),
    introduction: json['introduction'] as String,
  );
}

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
      'newest_date': instance.newestDate,
      'average_score': instance.averageScore,
      'introduction': instance.introduction,
    };

SmallAuthor _$SmallAuthorFromJson(Map<String, dynamic> json) {
  return SmallAuthor(
    aid: json['aid'] as int,
    name: json['name'] as String,
    zone: json['zone'] as String,
    cover: json['cover'] as String,
    url: json['url'] as String,
    mangaCount: json['manga_count'] as int,
    newestDate: json['newest_date'] as String,
  );
}

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

TinyAuthor _$TinyAuthorFromJson(Map<String, dynamic> json) {
  return TinyAuthor(
    aid: json['aid'] as int,
    name: json['name'] as String,
    url: json['url'] as String,
  );
}

Map<String, dynamic> _$TinyAuthorToJson(TinyAuthor instance) =>
    <String, dynamic>{
      'aid': instance.aid,
      'name': instance.name,
      'url': instance.url,
    };
