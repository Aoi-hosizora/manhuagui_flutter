import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Category {
  String name;
  String title;
  String url;

  Category({this.name, this.title, this.url});

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  static const fields = <String>['name', 'title', 'url'];

  TinyCategory toTiny() {
    return TinyCategory(name: name, title: title);
  }
}

/*
zone:   (all|japan|hongkong|other|europe|china|korea)
age:    (all|shaonv|shaonian|qingnian|ertong|tongyong)
status: (all|lianzai|wanjie)
genre:  (all|...)
*/

class TinyCategory {
  String name;
  String title;

  TinyCategory({this.name, this.title});
}

// 按地区
var zones = <TinyCategory>[
  TinyCategory(title: '全部', name: 'all'),
  TinyCategory(title: '日本', name: 'japan'),
  TinyCategory(title: '港台', name: 'hongkong'),
  TinyCategory(title: '其它', name: 'other'),
  TinyCategory(title: '欧美', name: 'europe'),
  TinyCategory(title: '内地', name: 'china'),
  TinyCategory(title: '韩国', name: 'korea'),
];

// 按受众
var ages = <TinyCategory>[
  TinyCategory(title: '全部', name: 'all'),
  TinyCategory(title: '少女', name: 'shaonv'),
  TinyCategory(title: '少年', name: 'shaonian'),
  TinyCategory(title: '青年', name: 'qingnian'),
  TinyCategory(title: '儿童', name: 'ertong'),
  TinyCategory(title: '通用', name: 'tongyong'),
];

// 按进度
var status = <TinyCategory>[
  TinyCategory(title: '全部', name: 'all'),
  TinyCategory(title: '连载', name: 'lianzai'),
  TinyCategory(title: '完结', name: 'wanjie'),
];
