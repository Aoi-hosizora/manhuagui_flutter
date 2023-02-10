import 'package:dio/dio.dart';

Future<Response<String>> request(Dio dio, String baseUrl, String method, String path, {Map<String, dynamic>? headers, Map<String, dynamic>? queries, dynamic data}) async {
  var opt = Options(
    method: method.toUpperCase(),
    headers: headers,
    responseType: ResponseType.plain,
  );
  var ropt = opt.compose(
    dio.options,
    path,
    queryParameters: queries,
    data: data,
  );
  ropt = ropt.copyWith(baseUrl: baseUrl);
  return await dio.fetch<String>(ropt);
}
