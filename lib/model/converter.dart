import 'package:json_annotation/json_annotation.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/model/result.dart';

bool _matchJson(List<String> fields, Map<String, dynamic> json) {
  for (var f in fields) {
    if (!json.containsKey(f)) {
      return false;
    }
  }
  return true;
}

bool _matchPageJson<TItem, TPage>(Map<String, dynamic> json) {
  if (!_matchJson(ResultPage.fields, json)) {
    return false;
  }
  if ((json['data'] as List).length == 0) {
    return ResultPage<TItem>() is TPage;
  }
  return _jsonMapType(json['data'][0]) == TItem;
}

Type _jsonMapType(Map<String, dynamic> json) {
  if (_matchJson(Manga.fields, json)) {
    return Manga;
  } else if (_matchJson(SmallManga.fields, json)) {
    return SmallManga;
  } else if (_matchJson(TinyManga.fields, json)) {
    return TinyManga;
  } else if (_matchJson(ShelfManga.fields, json)) {
    return ShelfManga;
  } else if (_matchJson(MangaRank.fields, json)) {
    return MangaRank;
  } else if (_matchJson(MangaChapter.fields, json)) {
    return MangaChapter;
  } else if (_matchJson(TinyMangaChapter.fields, json)) {
    return TinyMangaChapter;
  } else if (_matchJson(Comment.fields, json)) {
    return Comment;
  } else if (_matchJson(RepliedComment.fields, json)) {
    return RepliedComment;
  } else if (_matchJson(Category.fields, json)) {
    return Category;
  } else if (_matchJson(Author.fields, json)) {
    return Author;
  } else if (_matchJson(SmallAuthor.fields, json)) {
    return SmallAuthor;
  } else if (_matchJson(TinyAuthor.fields, json)) {
    return TinyAuthor;
  } else if (_matchJson(MangaGroup.fields, json)) {
    return MangaGroup;
  } else if (_matchJson(MangaChapterGroup.fields, json)) {
    return MangaChapterGroup;
  } else if (_matchJson(MangaGroupList.fields, json)) {
    return MangaGroupList;
  }
  return null;
}

class GenericConverter<T> implements JsonConverter<T, Object> {
  const GenericConverter();

  @override
  T fromJson(Object json) {
    if (json is Map<String, dynamic>) {
      // Result<?>
      if (_matchJson(Manga.fields, json)) {
        return Manga.fromJson(json) as T; // Manga
      } else if (_matchJson(SmallManga.fields, json)) {
        return SmallManga.fromJson(json) as T; // SmallManga
      } else if (_matchJson(TinyManga.fields, json)) {
        return TinyManga.fromJson(json) as T; // TinyManga
      } else if (_matchJson(ShelfManga.fields, json)) {
        return ShelfManga.fromJson(json) as T; // ShelfManga
      } else if (_matchJson(MangaRank.fields, json)) {
        return MangaRank.fromJson(json) as T; // MangaRank
      } else if (_matchJson(MangaChapter.fields, json)) {
        return MangaChapter.fromJson(json) as T; // MangaChapter
      } else if (_matchJson(TinyMangaChapter.fields, json)) {
        return TinyMangaChapter.fromJson(json) as T; // TinyMangaChapter
      } else if (_matchJson(Comment.fields, json)) {
        return Comment.fromJson(json) as T; // Comment
      } else if (_matchJson(RepliedComment.fields, json)) {
        return RepliedComment.fromJson(json) as T; // RepliedComment
      } else if (_matchJson(Category.fields, json)) {
        return Category.fromJson(json) as T; // Category
      } else if (_matchJson(Author.fields, json)) {
        return Author.fromJson(json) as T; // Author
      } else if (_matchJson(SmallAuthor.fields, json)) {
        return SmallAuthor.fromJson(json) as T; // SmallAuthor
      } else if (_matchJson(TinyAuthor.fields, json)) {
        return TinyAuthor.fromJson(json) as T; // TinyAuthor
      } else if (_matchJson(MangaGroup.fields, json)) {
        return MangaGroup.fromJson(json) as T; // MangaGroup
      } else if (_matchJson(MangaChapterGroup.fields, json)) {
        return MangaChapterGroup.fromJson(json) as T; // MangaChapterGroup
      } else if (_matchJson(MangaGroupList.fields, json)) {
        return MangaGroupList.fromJson(json) as T; // MangaGroupList
      }
      // Result<ResultPage<?>>
      if (_matchPageJson<Manga, T>(json)) {
        return ResultPage.fromJson(json, Manga()) as T; // Manga
      } else if (_matchPageJson<SmallManga, T>(json)) {
        return ResultPage.fromJson(json, SmallManga()) as T; // SmallManga
      } else if (_matchPageJson<TinyManga, T>(json)) {
        return ResultPage.fromJson(json, TinyManga()) as T; // TinyManga
      } else if (_matchPageJson<ShelfManga, T>(json)) {
        return ResultPage.fromJson(json, ShelfManga()) as T; // ShelfManga
      } else if (_matchPageJson<MangaRank, T>(json)) {
        return ResultPage.fromJson(json, MangaRank()) as T; // MangaRank
      } else if (_matchPageJson<MangaChapter, T>(json)) {
        return ResultPage.fromJson(json, MangaChapter()) as T; // MangaChapter
      } else if (_matchPageJson<TinyMangaChapter, T>(json)) {
        return ResultPage.fromJson(json, TinyMangaChapter()) as T; // TinyMangaChapter
      } else if (_matchPageJson<Category, T>(json)) {
        return ResultPage.fromJson(json, Category()) as T; // Category
      } else if (_matchPageJson<Comment, T>(json)) {
        return ResultPage.fromJson(json, Comment()) as T; // Comment
      } else if (_matchPageJson<RepliedComment, T>(json)) {
        return ResultPage.fromJson(json, RepliedComment()) as T; // RepliedComment
      } else if (_matchPageJson<Author, T>(json)) {
        return ResultPage.fromJson(json, Author()) as T; // Author
      } else if (_matchPageJson<SmallAuthor, T>(json)) {
        return ResultPage.fromJson(json, SmallAuthor()) as T; // SmallAuthor
      } else if (_matchPageJson<TinyAuthor, T>(json)) {
        return ResultPage.fromJson(json, TinyAuthor()) as T; // TinyAuthor
      } else if (_matchPageJson<MangaGroup, T>(json)) {
        return ResultPage.fromJson(json, MangaGroup()) as T; // MangaGroup
      } else if (_matchPageJson<MangaChapterGroup, T>(json)) {
        return ResultPage.fromJson(json, MangaChapterGroup()) as T; // MangaChapterGroup
      } else if (_matchPageJson<MangaGroupList, T>(json)) {
        return ResultPage.fromJson(json, MangaGroupList()) as T; // MangaGroupList
      }
    }
    return json as T;
  }

  @override
  Object toJson(T object) {
    return object;
  }
}
