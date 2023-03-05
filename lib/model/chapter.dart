import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chapter.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaChapter {
  final int cid;
  final String title;
  final int mid;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final String url;
  final List<String> pages;
  final int pageCount;
  final int nextCid;
  final int prevCid;

  const MangaChapter({required this.cid, required this.title, required this.mid, required this.mangaTitle, required this.mangaCover, required this.mangaUrl, required this.url, required this.pages, required this.pageCount, required this.nextCid, required this.prevCid});

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
  final String group;
  final int number;

  const TinyMangaChapter({required this.cid, required this.title, required this.mid, required this.url, required this.pageCount, required this.isNew, required this.group, required this.number});

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
    if (group?.chapters.isNotEmpty == true) {
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

  List<TinyMangaChapter> get allChapters {
    var out = <TinyMangaChapter>[];
    for (var group in this) {
      out.addAll(group.chapters);
    }
    out.sort((a, b) => a.cid.compareTo(b.cid)); // sort through comparing with cid rather than number
    return out;
  }

  TinyMangaChapter? findNextChapter(int cid) {
    var chapter = findChapter(cid);
    if (chapter == null) {
      return null;
    }

    // 从**所有分组**中找下一个章节
    var nextChapters = allChapters.where((el) => el.cid > cid).toList()..sort((a, b) => a.cid.compareTo(b.cid)); // cid 从小到大排序
    for (var nextChapter in nextChapters) {
      if (nextChapter.group != chapter.group) {
        return nextChapter; // 找到的章节不属于同一分组
      }
      if (nextChapter.number > chapter.number) {
        return nextChapter; // 找到的章节属于同一分组，且分组内顺序大于当前顺序
      }

      // 找到的章节属于同一分组，且分组内顺序小于等于当前顺序 (很少见，当章节列表内的章节顺序被调整时可能会出现)
      continue; // 继续检查
    }

    // 未找到合适的章节作为下一个章节 (即 cid 最大或 number 最大)
    return null;
  }
}
