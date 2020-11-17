import 'package:json_annotation/json_annotation.dart';

part 'chapter.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaChapter {
  int cid;
  String title;
  int mid;
  String mangaTitle;
  String url;
  List<String> pages;
  int pageCount;
  int nextCid;
  int prevCid;

  MangaChapter({this.cid, this.title, this.mid, this.mangaTitle, this.url, this.pages, this.pageCount, this.nextCid, this.prevCid});

  factory MangaChapter.fromJson(Map<String, dynamic> json) => _$MangaChapterFromJson(json);

  Map<String, dynamic> toJson() => _$MangaChapterToJson(this);

  static const fields = <String>['cid', 'title', 'mid', 'manga_title', 'url', 'pages', 'page_count', 'next_cid', 'prev_cid'];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TinyMangaChapter {
  int cid;
  String title;
  int mid;
  String url;
  int pageCount;
  bool isNew;

  TinyMangaChapter({this.cid, this.title, this.mid, this.url, this.pageCount});

  factory TinyMangaChapter.fromJson(Map<String, dynamic> json) => _$TinyMangaChapterFromJson(json);

  Map<String, dynamic> toJson() => _$TinyMangaChapterToJson(this);

  static const fields = <String>['cid', 'title', 'mid', 'url', 'page_count', 'is_new'];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaChapterGroup {
  String title;
  List<TinyMangaChapter> chapters;

  MangaChapterGroup({this.title, this.chapters});

  factory MangaChapterGroup.fromJson(Map<String, dynamic> json) => _$MangaChapterGroupFromJson(json);

  Map<String, dynamic> toJson() => _$MangaChapterGroupToJson(this);

  static const fields = <String>['title', 'chapters'];
}
