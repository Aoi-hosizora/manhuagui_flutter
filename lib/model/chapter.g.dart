// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MangaChapter _$MangaChapterFromJson(Map<String, dynamic> json) {
  return MangaChapter(
    cid: json['cid'] as int,
    title: json['title'] as String,
    mid: json['mid'] as int,
    mangaTitle: json['manga_title'] as String,
    url: json['url'] as String,
    pages: (json['pages'] as List)?.map((e) => e as String)?.toList(),
    pageCount: json['page_count'] as int,
    nextCid: json['next_cid'] as int,
    prevCid: json['prev_cid'] as int,
  );
}

Map<String, dynamic> _$MangaChapterToJson(MangaChapter instance) =>
    <String, dynamic>{
      'cid': instance.cid,
      'title': instance.title,
      'mid': instance.mid,
      'manga_title': instance.mangaTitle,
      'url': instance.url,
      'pages': instance.pages,
      'page_count': instance.pageCount,
      'next_cid': instance.nextCid,
      'prev_cid': instance.prevCid,
    };

TinyMangaChapter _$TinyMangaChapterFromJson(Map<String, dynamic> json) {
  return TinyMangaChapter(
    cid: json['cid'] as int,
    title: json['title'] as String,
    mid: json['mid'] as int,
    url: json['url'] as String,
    pageCount: json['page_count'] as int,
  )..isNew = json['is_new'] as bool;
}

Map<String, dynamic> _$TinyMangaChapterToJson(TinyMangaChapter instance) =>
    <String, dynamic>{
      'cid': instance.cid,
      'title': instance.title,
      'mid': instance.mid,
      'url': instance.url,
      'page_count': instance.pageCount,
      'is_new': instance.isNew,
    };

MangaChapterGroup _$MangaChapterGroupFromJson(Map<String, dynamic> json) {
  return MangaChapterGroup(
    title: json['title'] as String,
    chapters: (json['chapters'] as List)
        ?.map((e) => e == null
            ? null
            : TinyMangaChapter.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$MangaChapterGroupToJson(MangaChapterGroup instance) =>
    <String, dynamic>{
      'title': instance.title,
      'chapters': instance.chapters,
    };
