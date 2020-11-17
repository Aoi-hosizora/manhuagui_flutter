import 'package:json_annotation/json_annotation.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
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

bool _matchPageJson<T>(Map<String, dynamic> json) {
  if (!_matchJson(ResultPage.fields, json)) {
    return false;
  }
  if ((json['data'] as List).length == 0) {
    return true;
  }
  return _jsonMapType(json['data'][0]) == T;
}

Type _jsonMapType(Map<String, dynamic> json) {
  if (_matchJson(MangaPage.fields, json)) {
    return MangaPage;
  } else if (_matchJson(SmallMangaPage.fields, json)) {
    return SmallMangaPage;
  } else if (_matchJson(TinyMangaPage.fields, json)) {
    return TinyMangaPage;
  } else if (_matchJson(MangaChapter.fields, json)) {
    return MangaChapter;
  } else if (_matchJson(TinyMangaChapter.fields, json)) {
    return TinyMangaChapter;
  } else if (_matchJson(Category.fields, json)) {
    return Category;
  } else if (_matchJson(Author.fields, json)) {
    return Author;
  } else if (_matchJson(SmallAuthor.fields, json)) {
    return SmallAuthor;
  } else if (_matchJson(TinyAuthor.fields, json)) {
    return TinyAuthor;
  } else if (_matchJson(MangaPageGroup.fields, json)) {
    return MangaPageGroup;
  } else if (_matchJson(MangaChapterGroup.fields, json)) {
    return MangaChapterGroup;
  } else if (_matchJson(MangaPageGroupList.fields, json)) {
    return MangaPageGroupList;
  }
  return null;
}

class GenericConverter<T> implements JsonConverter<T, Object> {
  const GenericConverter();

  @override
  T fromJson(Object json) {
    if (json is Map<String, dynamic>) {
      // Result<?>
      if (_matchJson(MangaPage.fields, json)) {
        return MangaPage.fromJson(json) as T; // MangaPage
      } else if (_matchJson(SmallMangaPage.fields, json)) {
        return SmallMangaPage.fromJson(json) as T; // SmallMangaPage
      } else if (_matchJson(TinyMangaPage.fields, json)) {
        return TinyMangaPage.fromJson(json) as T; // TinyMangaPage
      } else if (_matchJson(MangaChapter.fields, json)) {
        return MangaChapter.fromJson(json) as T; // MangaChapter
      } else if (_matchJson(TinyMangaChapter.fields, json)) {
        return TinyMangaChapter.fromJson(json) as T; // TinyMangaChapter
      } else if (_matchJson(Category.fields, json)) {
        return Category.fromJson(json) as T; // Category
      } else if (_matchJson(Author.fields, json)) {
        return Author.fromJson(json) as T; // Author
      } else if (_matchJson(SmallAuthor.fields, json)) {
        return SmallAuthor.fromJson(json) as T; // SmallAuthor
      } else if (_matchJson(TinyAuthor.fields, json)) {
        return TinyAuthor.fromJson(json) as T; // TinyAuthor
      } else if (_matchJson(MangaPageGroup.fields, json)) {
        return MangaPageGroup.fromJson(json) as T; // MangaPageGroup
      } else if (_matchJson(MangaChapterGroup.fields, json)) {
        return MangaChapterGroup.fromJson(json) as T; // MangaChapterGroup
      } else if (_matchJson(MangaPageGroupList.fields, json)) {
        return MangaPageGroupList.fromJson(json) as T; // MangaPageGroupList
      }
      // Result<ResultPage<?>>
      if (_matchPageJson<MangaPage>(json)) {
        return ResultPage.fromJson(json, MangaPage()) as T; // MangaPage
      } else if (_matchPageJson<SmallMangaPage>(json)) {
        return ResultPage.fromJson(json, SmallMangaPage()) as T; // SmallMangaPage
      } else if (_matchPageJson<TinyMangaPage>(json)) {
        return ResultPage.fromJson(json, TinyMangaPage()) as T; // TinyMangaPage
      } else if (_matchPageJson<MangaChapter>(json)) {
        return ResultPage.fromJson(json, MangaChapter()) as T; // MangaChapter
      } else if (_matchPageJson<TinyMangaChapter>(json)) {
        return ResultPage.fromJson(json, TinyMangaChapter()) as T; // TinyMangaChapter
      } else if (_matchPageJson<Category>(json)) {
        return ResultPage.fromJson(json, Category()) as T; // Category
      } else if (_matchPageJson<Author>(json)) {
        return ResultPage.fromJson(json, Author()) as T; // Author
      } else if (_matchPageJson<SmallAuthor>(json)) {
        return ResultPage.fromJson(json, SmallAuthor()) as T; // SmallAuthor
      } else if (_matchPageJson<TinyAuthor>(json)) {
        return ResultPage.fromJson(json, TinyAuthor()) as T; // TinyAuthor
      } else if (_matchPageJson<MangaPageGroup>(json)) {
        return ResultPage.fromJson(json, MangaPageGroup()) as T; // MangaPageGroup
      } else if (_matchPageJson<MangaChapterGroup>(json)) {
        return ResultPage.fromJson(json, MangaChapterGroup()) as T; // MangaChapterGroup
      } else if (_matchPageJson<MangaPageGroupList>(json)) {
        return ResultPage.fromJson(json, MangaPageGroupList()) as T; // MangaPageGroupList
      }
    }
    return json as T;
  }

  @override
  Object toJson(T object) {
    return object;
  }
}
