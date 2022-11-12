import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Category {
  final String name;
  final String title;
  final String url;

  const Category({required this.name, required this.title, required this.url});

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  TinyCategory toTiny() {
    return TinyCategory(name: name, title: title);
  }
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

  bool isAll() {
    return name == 'all';
  }
}

/*
  genre:  (all|...)
  age:    (all|shaonv|shaonian|qingnian|ertong|tongyong)
  zone:   (all|japan|hongkong|other|europe|china|korea)
  status: (all|lianzai|wanjie)
  rank:   (all|zone|age|genre)
*/

// 按剧情
final allGenres = <TinyCategory>[
  const TinyCategory(title: '全部', name: 'all'),
  // ...
];

// 按受众
final allAges = <TinyCategory>[
  const TinyCategory(title: '全部', name: 'all'),
  const TinyCategory(title: '少女', name: 'shaonv'),
  const TinyCategory(title: '少年', name: 'shaonian'),
  const TinyCategory(title: '青年', name: 'qingnian'),
  const TinyCategory(title: '儿童', name: 'ertong'),
  const TinyCategory(title: '通用', name: 'tongyong'),
];

// 按地区
final allZones = <TinyCategory>[
  const TinyCategory(title: '全部', name: 'all'),
  const TinyCategory(title: '日本', name: 'japan'),
  const TinyCategory(title: '港台', name: 'hongkong'),
  const TinyCategory(title: '其它', name: 'other'),
  const TinyCategory(title: '欧美', name: 'europe'),
  const TinyCategory(title: '内地', name: 'china'),
  const TinyCategory(title: '韩国', name: 'korea'),
];

// 按进度
final allStatuses = <TinyCategory>[
  const TinyCategory(title: '全部', name: 'all'),
  const TinyCategory(title: '连载', name: 'lianzai'),
  const TinyCategory(title: '完结', name: 'wanjie'),
];

// 排行榜周期
final allRankDurations = <TinyCategory>[
  const TinyCategory(title: '日排行', name: 'day'),
  const TinyCategory(title: '周排行', name: 'week'),
  const TinyCategory(title: '月排行', name: 'month'),
  const TinyCategory(title: '总排行', name: 'total'),
];

// 排行榜类型
final allRankTypes = <TinyCategory>[
  const TinyCategory(title: '全部', name: 'all'),
  // 按地区
  for (var i = 1; i < allZones.length; i++) allZones[i],
  // 按受众
  for (var i = 1; i < allAges.length; i++) allAges[i],
  // 按剧情
  // ...
];
