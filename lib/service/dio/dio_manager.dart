import 'package:dio/dio.dart';
import 'package:manhuagui_flutter/config.dart';

class DioManager {
  DioManager._();

  static DioManager? _instance;

  static DioManager get instance {
    _instance ??= DioManager._();
    return _instance!;
  }

  Dio? _dio; // global Dio instance

  Dio get dio {
    if (_dio == null) {
      _dio = Dio();
      _dio!.options.connectTimeout = CONNECT_TIMEOUT;
      _dio!.options.sendTimeout = SEND_TIMEOUT;
      _dio!.options.receiveTimeout = RECEIVE_TIMEOUT;
      _dio!.interceptors.add(LogInterceptor());
    }
    return _dio!;
  }

  // TODO add long dio and setting
}

class LogInterceptor extends Interceptor {
  @override
  Future onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    print('┌─────────────────── Request ─────────────────────┐');
    print('date: ${DateTime.now().toIso8601String()}');
    print('uri: ${options.uri}');
    print('method: ${options.method}');
    if (options.extra.isNotEmpty) {
      print('extra: ${options.extra}');
    }
    print('headers:');
    options.headers.forEach((key, v) => print('    $key: $v'));
    print('└─────────────────── Request ─────────────────────┘');
    return super.onRequest(options, handler);
  }

  @override
  Future onError(DioError err, ErrorInterceptorHandler handler) async {
    print('┌─────────────────── DioError ────────────────────┐');
    print('date: ${DateTime.now().toIso8601String()}');
    print('uri: ${err.requestOptions.uri}');
    print('method: ${err.requestOptions.method}');
    print('error: $err');
    if (err.response != null) {
      _printResponse(err.response!);
    }
    print('└─────────────────── DioError ────────────────────┘');
    return super.onError(err, handler);
  }

  @override
  Future onResponse(Response response, ResponseInterceptorHandler handler) async {
    print('┌─────────────────── Response ────────────────────┐');
    print('date: ${DateTime.now().toIso8601String()}');
    _printResponse(response);
    print('└─────────────────── Response ────────────────────┘');
    return super.onResponse(response, handler);
  }

  void _printResponse(Response response) {
    print('uri: ${response.requestOptions.uri}');
    print('method: ${response.requestOptions.method}');
    print('statusCode: ${response.statusCode}');
    if (!response.headers.isEmpty) {
      print('headers:');
      response.headers.forEach((key, v) => print('    $key: ${v.join(',')}'));
    }
  }
}
