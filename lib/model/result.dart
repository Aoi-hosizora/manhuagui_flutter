import 'package:json_annotation/json_annotation.dart';
import 'package:manhuagui_flutter/model/converter.dart';

part 'result.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Result<T> {
  int code;
  String message;
  @GenericConverter()
  T data;

  Result({this.code, this.message, this.data});

  factory Result.fromJson(Map<String, dynamic> json) => _$ResultFromJson<T>(json);

  Map<String, dynamic> toJson() => _$ResultToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ResultPage<T> {
  int page;
  int limit;
  int total;
  @GenericConverter()
  List<T> data;

  ResultPage({this.page, this.limit, this.total, this.data});

  factory ResultPage.fromJson(Map<String, dynamic> json, T t) => _$ResultPageFromJson<T>(json);

  Map<String, dynamic> toJson() => _$ResultPageToJson(this);

  static const fields = <String>['page', 'limit', 'total', 'data'];
}
