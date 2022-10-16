import 'package:json_annotation/json_annotation.dart';

part 'chapter.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaChapter {
  final int cid;
  final String title;
  final int mid;
  final String mangaTitle;
  final String url;
  final List<String> pages;
  final int pageCount;
  final int nextCid;
  final int prevCid;

  const MangaChapter({required this.cid, required this.title, required this.mid, required this.mangaTitle, required this.url, required this.pages, required this.pageCount, required this.nextCid, required this.prevCid});

  factory MangaChapter.fromJson(Map<String, dynamic> json) => _$MangaChapterFromJson(json);

  Map<String, dynamic> toJson() => _$MangaChapterToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TinyMangaChapter {
  final int cid;
  final String title;
  final int mid;
  final String url;
  final int pageCount;
  final bool isNew;

  const TinyMangaChapter({required this.cid, required this.title, required this.mid, required this.url, required this.pageCount, required this.isNew});

  factory TinyMangaChapter.fromJson(Map<String, dynamic> json) => _$TinyMangaChapterFromJson(json);

  Map<String, dynamic> toJson() => _$TinyMangaChapterToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaChapterGroup {
  final String title;
  final List<TinyMangaChapter> chapters;

  const MangaChapterGroup({required this.title, required this.chapters});

  factory MangaChapterGroup.fromJson(Map<String, dynamic> json) => _$MangaChapterGroupFromJson(json);

  Map<String, dynamic> toJson() => _$MangaChapterGroupToJson(this);
}

extension MangaChapterGroupListExtension on List<MangaChapterGroup> {
  String? findTitle(int cid) {
    for (var group in this) {
      for (var chapter in group.chapters) {
        if (chapter.cid == cid) {
          return chapter.title;
        }
      }
    }
    return null;
  }
}