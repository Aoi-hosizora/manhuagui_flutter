import 'package:json_annotation/json_annotation.dart';

part 'result.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, genericArgumentFactories: true)
class Result<T> {
 final int code;
 final String message;
 final T data;

 const Result({required this.code, required this.message, required this.data});

 factory Result.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT) => _$ResultFromJson<T>(json, fromJsonT);

 Map<String, dynamic> toJson(Object? Function(T value) toJsonT) => _$ResultToJson(this, toJsonT);
}

@JsonSerializable(fieldRename: FieldRename.snake, genericArgumentFactories: true)
class ResultPage<T> {
  final int page;
  final int limit;
  final int total;
  final List<T> data;

 const ResultPage({required this.page, required this.limit, required this.total, required this.data});

  factory ResultPage.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT) => _$ResultPageFromJson<T>(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) => _$ResultPageToJson(this, toJsonT);
}
