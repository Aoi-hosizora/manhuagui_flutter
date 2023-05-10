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

  NanoTinyMangaChapter toNanoTiny() {
    return NanoTinyMangaChapter(
      cid: cid,
      title: title,
      group: group,
      moreInfo: this,
    );
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

class NanoTinyMangaChapter {
  final int cid;
  final String title;
  final String group;
  final TinyMangaChapter? moreInfo;

  const NanoTinyMangaChapter({required this.cid, required this.title, required this.group, this.moreInfo});
}

class MangaChapterNeighbor {
  final bool notLoaded;
  final NanoTinyMangaChapter? prevChapter;
  final NanoTinyMangaChapter? prevSameGroupChapter;
  final NanoTinyMangaChapter? prevDiffGroupChapter;
  final NanoTinyMangaChapter? nextChapter;
  final NanoTinyMangaChapter? nextSameGroupChapter;
  final NanoTinyMangaChapter? nextDiffGroupChapter;

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

  List<NanoTinyMangaChapter> getAvailableChapters({required bool previous}) {
    if (notLoaded) {
      return [];
    }
    List<NanoTinyMangaChapter> chapters;
    if (previous) {
      chapters = [
        if (prevSameGroupChapter == null && prevDiffGroupChapter == null && prevChapter != null) prevChapter!,
        if (prevSameGroupChapter != null) prevSameGroupChapter!,
        if (prevDiffGroupChapter != null) prevDiffGroupChapter!,
      ];
    } else {
      chapters = [
        if (nextSameGroupChapter == null && nextDiffGroupChapter == null && nextChapter != null) nextChapter!,
        if (nextSameGroupChapter != null) nextSameGroupChapter!,
        if (nextDiffGroupChapter != null) nextDiffGroupChapter!,
      ];
    }
    return chapters;
  }

  MangaChapterNeighbor copyWith({
    bool? notLoaded,
    NanoTinyMangaChapter? prevChapter,
    NanoTinyMangaChapter? prevSameGroupChapter,
    NanoTinyMangaChapter? prevDiffGroupChapter,
    NanoTinyMangaChapter? nextChapter,
    NanoTinyMangaChapter? nextSameGroupChapter,
    NanoTinyMangaChapter? nextDiffGroupChapter,
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
    var out = expand((group) => group.chapters).toList();
    out.sort((a, b) => a.cid.compareTo(b.cid)); // sort through comparing with cid rather than number
    return out;
  }

  List<int> get allChapterIds {
    var out = expand((group) => group.chapters.map((chapter) => chapter.cid)).toList();
    out.sort((a, b) => a.compareTo(b));
    return out;
  }

  MangaChapterNeighbor? findChapterNeighbor(int cid, {bool prev = false, bool next = false}) {
    var chapter = findChapter(cid);
    if (chapter == null) {
      return null;
    }

    // 对**所有分组**中的漫画章节排序
    // TODO change to use number to sort
    var prevChapters = !prev
        ? null
        : (allChapters.where((el) => el.group == chapter.group ? el.number < chapter.number : el.cid < cid).toList() //
          ..sort((a, b) => a.group == b.group ? b.number.compareTo(a.number) : b.cid.compareTo(a.cid))); // cid 从大到小排序
    var nextChapters = !next
        ? null
        : (allChapters.where((el) => el.group == chapter.group ? el.number > chapter.number : el.cid > cid).toList() //
          ..sort((a, b) => a.group == b.group ? a.number.compareTo(b.number) : a.cid.compareTo(b.cid))); // cid 从小到大排序

    // 从**所有分组**中找上一个章节
    TinyMangaChapter? prevDiffGroupChapter, prevSameGroupChapter;
    if (prev) {
      for (var prevChapter in prevChapters!) {
        if (prevChapter.group != chapter.group) {
          prevDiffGroupChapter ??= prevChapter; // 找到的章节不属于同一分组，且该章节的编号肯定小于当前章节的编号
          continue;
        }
        prevSameGroupChapter ??= prevChapter; // 找到的章节属于同一分组，且该章节的顺序肯定小于当前章节的顺序
        break;
      }
      if (prevDiffGroupChapter != null && prevSameGroupChapter != null && prevDiffGroupChapter.cid < prevSameGroupChapter.cid) {
        prevDiffGroupChapter = null; // 不同分组的章节出现得比同一分组的章节还要更前，舍弃
      }
    }

    // 从**所有分组**中找下一个章节
    TinyMangaChapter? nextDiffGroupChapter, nextSameGroupChapter;
    if (next) {
      for (var nextChapter in nextChapters!) {
        if (nextChapter.group != chapter.group) {
          nextDiffGroupChapter ??= nextChapter; // 找到的章节不属于同一分组，且该章节的编号肯定大于当前章节的编号
          continue;
        }
        nextSameGroupChapter ??= nextChapter; // 找到的章节属于同一分组，且该章节的顺序肯定大于当前章节的顺序
        break;
      }
      if (nextDiffGroupChapter != null && nextSameGroupChapter != null && nextDiffGroupChapter.cid > nextSameGroupChapter.cid) {
        nextDiffGroupChapter = null; // 不同分组的章节出现得比同一分组的章节还要更后，舍弃
      }
    }

    TinyMangaChapter? max(TinyMangaChapter? a, TinyMangaChapter? b) => a == null ? b : (b == null ? a : (a.cid > b.cid ? a : b));
    TinyMangaChapter? min(TinyMangaChapter? a, TinyMangaChapter? b) => a == null ? b : (b == null ? a : (a.cid < b.cid ? a : b));
    return MangaChapterNeighbor(
      notLoaded: false,
      prevChapter: max(prevDiffGroupChapter, prevSameGroupChapter)?.toNanoTiny(),
      nextChapter: min(nextDiffGroupChapter, nextSameGroupChapter)?.toNanoTiny(),
      prevSameGroupChapter: prevSameGroupChapter?.toNanoTiny(),
      prevDiffGroupChapter: prevDiffGroupChapter?.toNanoTiny(),
      nextSameGroupChapter: nextSameGroupChapter?.toNanoTiny(),
      nextDiffGroupChapter: nextDiffGroupChapter?.toNanoTiny(),
    );
  }

  MangaChapterNeighbor? findNextChapter(int cid) {
    return findChapterNeighbor(cid, next: true, prev: false);
  }

  MangaChapterNeighbor? findPrevChapter(int cid) {
    return findChapterNeighbor(cid, prev: true, next: false);
  }
}
