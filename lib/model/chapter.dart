import 'package:flutter_ahlib/flutter_ahlib.dart';
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
  final String url; // useless
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
  MangaChapterGroup? get regularGroup {
    return where((g) => g.title == '单话').firstOrNull;
  }

  List<MangaChapterGroup> makeSureRegularGroupIsFirst() {
    var rGroup = regularGroup;
    if (rGroup == null) {
      return this;
    }
    return [
      rGroup,
      ...where((g) => g.title != '单话'),
    ];
  }

  MangaChapterGroup? getFirstNotEmptyGroup() {
    if (isEmpty) {
      return null;
    }
    var group = regularGroup;
    if (group == null || group.chapters.isNotEmpty) {
      return group;
    }
    return where((g) => g.chapters.isNotEmpty).firstOrNull;
  }

  TinyMangaChapter? findChapter(int cid) {
    for (var group in this) {
      for (var chapter in group.chapters) {
        if (chapter.cid == cid) {
          return chapter;
        }
      }
    }
    return null;
  }

  Tuple2<TinyMangaChapter, String>? findChapterAndGroupName(int cid) {
    for (var group in this) {
      for (var chapter in group.chapters) {
        if (chapter.cid == cid) {
          return Tuple2(chapter, group.title);
        }
      }
    }
    return null;
  }
}
