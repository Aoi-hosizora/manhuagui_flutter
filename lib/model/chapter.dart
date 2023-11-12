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

  TinierMangaChapter toTinier() {
    return TinierMangaChapter(cid: cid, title: title, group: group);
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MangaChapterGroup {
  final String title;
  final List<TinyMangaChapter> chapters;

  const MangaChapterGroup({required this.title, required this.chapters});

  factory MangaChapterGroup.fromJson(Map<String, dynamic> json) => _$MangaChapterGroupFromJson(json);

  Map<String, dynamic> toJson() => _$MangaChapterGroupToJson(this);
}

class TinierMangaChapter {
  final int cid;
  final String title;
  final String group;

  const TinierMangaChapter({required this.cid, required this.title, required this.group});
}

class MangaChapterNeighbor {
  final bool notLoaded; // 表示是否已获取到漫画章节列表，主要在 MangaViewerPage 被使用，与离线阅读状态相关
  final TinierMangaChapter? prevChapter; // 章节分组间cid较小的上一章节
  final TinierMangaChapter? prevSameGroupChapter; // 相同分组的上一章节
  final TinierMangaChapter? prevDiffGroupChapter; // 不同分组的上一章节
  final TinierMangaChapter? nextChapter; // 章节分组间cid较小的下一章节
  final TinierMangaChapter? nextSameGroupChapter; // 相同分组的下一章节
  final TinierMangaChapter? nextDiffGroupChapter; // 不同分组的下一章节

  const MangaChapterNeighbor({
    this.notLoaded = true,
    this.prevChapter,
    this.prevSameGroupChapter,
    this.prevDiffGroupChapter,
    this.nextChapter,
    this.nextSameGroupChapter,
    this.nextDiffGroupChapter,
  });

  bool get hasPrevChapter => !notLoaded && (prevChapter != null || prevSameGroupChapter != null || prevDiffGroupChapter != null);

  bool get hasNextChapter => !notLoaded && (nextChapter != null || nextSameGroupChapter != null || nextDiffGroupChapter != null);

  List<TinierMangaChapter> getAvailableNeighbors({required bool previous}) {
    if (notLoaded) {
      return []; // 当前处于离线模式，但未在下载列表获取到章节跳转信息
    }
    return previous
        ? [
            if (prevSameGroupChapter == null && prevDiffGroupChapter == null && prevChapter != null) prevChapter!,
            if (prevSameGroupChapter != null) prevSameGroupChapter!,
            if (prevDiffGroupChapter != null) prevDiffGroupChapter!,
          ]
        : [
            if (nextSameGroupChapter == null && nextDiffGroupChapter == null && nextChapter != null) nextChapter!,
            if (nextSameGroupChapter != null) nextSameGroupChapter!,
            if (nextDiffGroupChapter != null) nextDiffGroupChapter!,
          ];
  }

  MangaChapterNeighbor copyWith({
    bool? notLoaded,
    TinierMangaChapter? prevChapter,
    TinierMangaChapter? prevSameGroupChapter,
    TinierMangaChapter? prevDiffGroupChapter,
    TinierMangaChapter? nextChapter,
    TinierMangaChapter? nextSameGroupChapter,
    TinierMangaChapter? nextDiffGroupChapter,
  }) {
    return MangaChapterNeighbor(
      notLoaded: notLoaded ?? this.notLoaded,
      prevChapter: prevChapter ?? this.prevChapter,
      prevSameGroupChapter: prevSameGroupChapter ?? this.prevSameGroupChapter,
      prevDiffGroupChapter: prevDiffGroupChapter ?? this.prevDiffGroupChapter,
      nextChapter: nextChapter ?? this.nextChapter,
      nextSameGroupChapter: nextSameGroupChapter ?? this.nextSameGroupChapter,
      nextDiffGroupChapter: nextDiffGroupChapter ?? this.nextDiffGroupChapter,
    );
  }
}

extension MangaChapterGroupListExtension on List<MangaChapterGroup> {
  MangaChapterGroup? get regularGroup {
    return where((g) => g.title == '单话').firstOrNull;
  }

  List<MangaChapterGroup> makeSureRegularGroupIsFirst() {
    // 保证【单话】为首个章节分组
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
    // 首要选【单话】分组，否则选首个拥有非空章节的分组
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
    var out = expand((group) => group.chapters).toList();
    out.sort((a, b) => a.cid.compareTo(b.cid)); // sort through comparing with cid rather than number
    return out;
  }

  List<int> get allChapterIds {
    var out = expand((group) => group.chapters.map((chapter) => chapter.cid)).toList();
    out.sort((a, b) => a.compareTo(b));
    return out;
  }
}
