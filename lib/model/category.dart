import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Category {
  final String name;
  final String title;
  final String url;
  final String cover;

  const Category({required this.name, required this.title, required this.url, required this.cover});

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  TinyCategory toTiny() {
    return TinyCategory(name: name, title: title);
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CategoryList {
  final List<Category> genres;
  final List<Category> ages;
  final List<Category> zones;

  const CategoryList({required this.genres, required this.ages, required this.zones});

  factory CategoryList.fromJson(Map<String, dynamic> json) => _$CategoryListFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryListToJson(this);
}

class TinyCategory {
  final String name;
  final String title;

  const TinyCategory({required this.name, required this.title});

  @override
  bool operator ==(Object other) {
    return other is TinyCategory && other.name == name;
  }

  @override
  int get hashCode => hashValues(name, title);

  Category toCategory({String? cover}) {
    return Category(
      name: name,
      title: title,
      url: 'https://www.manhuagui.com/list/$name/',
      cover: cover ?? '',
    );
  }

  bool isAll() {
    return name == 'all';
  }
}

/*
  genre:  (all|...)
  age:    (all|shaonv|shaonian|qingnian|ertong|tongyong)
  zone:   (all|japan|hongkong|other|europe|china|korea)
  status: (all|lianzai|wanjie)

  ranking_durations: (day|week|month|total)
  ranking_type:      (all|...zones|...ages|...genres)
*/

// 全局的漫画类别，不包括 all
CategoryList? globalCategoryList; // genres, ages, zones

// 按剧情
final allGenres = <TinyCategory>[
  const TinyCategory(title: '全部', name: 'all'),
  // ...
];

// 按受众 (顺序已调整)
final allAges = <TinyCategory>[
  const TinyCategory(title: '全部', name: 'all'), // 0
  const TinyCategory(title: '少年', name: 'shaonian'), // 1
  const TinyCategory(title: '少女', name: 'shaonv'), // 2
  const TinyCategory(title: '青年', name: 'qingnian'), // 3
  const TinyCategory(title: '儿童', name: 'ertong'), // 4
  const TinyCategory(title: '通用', name: 'tongyong'), // 5
];

final allAgeCategory = allAges[0]; // all
final qingnianAgeCategory = allAges[3]; // qingnian
final shaonvAgeCategory = allAges[2]; // shaonv

// 按地区 (顺序已调整)
final allZones = <TinyCategory>[
  const TinyCategory(title: '全部', name: 'all'),
  const TinyCategory(title: '日本', name: 'japan'),
  const TinyCategory(title: '内地', name: 'china'),
  const TinyCategory(title: '港台', name: 'hongkong'),
  const TinyCategory(title: '欧美', name: 'europe'),
  const TinyCategory(title: '韩国', name: 'korea'),
  const TinyCategory(title: '其它', name: 'other'),
];

// 按进度
final allStatuses = <TinyCategory>[
  const TinyCategory(title: '全部', name: 'all'),
  const TinyCategory(title: '连载', name: 'lianzai'),
  const TinyCategory(title: '完结', name: 'wanjie'),
];

// 排行榜周期
final allRankingDurations = <TinyCategory>[
  const TinyCategory(title: '日排行', name: 'day'),
  const TinyCategory(title: '周排行', name: 'week'),
  const TinyCategory(title: '月排行', name: 'month'),
  const TinyCategory(title: '总排行', name: 'total'),
];

// 排行榜类型
final allRankingTypes = <TinyCategory>[
  const TinyCategory(title: '全部', name: 'all'),
  // 按地区
  for (var i = 1; i < allZones.length; i++) allZones[i],
  // 按受众
  for (var i = 1; i < allAges.length; i++) allAges[i],
  // 按剧情
  // ...
];
