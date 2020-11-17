// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Result<T> _$ResultFromJson<T>(Map<String, dynamic> json) {
  return Result<T>(
    code: json['code'] as int,
    message: json['message'] as String,
    data: GenericConverter<T>().fromJson(json['data']),
  );
}

Map<String, dynamic> _$ResultToJson<T>(Result<T> instance) => <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': GenericConverter<T>().toJson(instance.data),
    };

ResultPage<T> _$ResultPageFromJson<T>(Map<String, dynamic> json) {
  return ResultPage<T>(
    page: json['page'] as int,
    limit: json['limit'] as int,
    total: json['total'] as int,
    data: (json['data'] as List)?.map(GenericConverter<T>().fromJson)?.toList(),
  );
}

Map<String, dynamic> _$ResultPageToJson<T>(ResultPage<T> instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'data': instance.data?.map(GenericConverter<T>().toJson)?.toList(),
    };
