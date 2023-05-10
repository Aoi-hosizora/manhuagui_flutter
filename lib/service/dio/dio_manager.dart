import 'package:dio/dio.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/config.dart';

class DioManager {
  DioManager._();

  static DioManager? _instance;

  static DioManager get instance {
    _instance ??= DioManager._();
    return _instance!;
  }

  // global Dio instances
  Dio? _dio;
  Dio? _longDio;
  Dio? _longLongDio;
  Dio? _noTimeoutDio;

  Dio get dio {
    if (_dio == null) {
      _dio = Dio();
      _dio!.options.connectTimeout = Duration(milliseconds: CONNECT_TIMEOUT);
      _dio!.options.sendTimeout = Duration(milliseconds: SEND_TIMEOUT);
      _dio!.options.receiveTimeout = Duration(milliseconds: RECEIVE_TIMEOUT);
      _dio!.interceptors.add(LogInterceptor());
    }
    if (_longDio == null) {
      _longDio = Dio();
      _longDio!.options.connectTimeout = Duration(milliseconds: CONNECT_LTIMEOUT);
      _longDio!.options.sendTimeout = Duration(milliseconds: SEND_LTIMEOUT);
      _longDio!.options.receiveTimeout = Duration(milliseconds: RECEIVE_LTIMEOUT);
      _longDio!.interceptors.add(LogInterceptor());
    }
    if (_longLongDio == null) {
      _longLongDio = Dio();
      _longLongDio!.options.connectTimeout = Duration(milliseconds: CONNECT_LLTIMEOUT);
      _longLongDio!.options.sendTimeout = Duration(milliseconds: SEND_LLTIMEOUT);
      _longLongDio!.options.receiveTimeout = Duration(milliseconds: RECEIVE_LLTIMEOUT);
      _longLongDio!.interceptors.add(LogInterceptor());
    }
    if (_noTimeoutDio == null) {
      _noTimeoutDio = Dio();
      _noTimeoutDio!.interceptors.add(LogInterceptor());
    }
    return AppSetting.instance.other.timeoutBehavior.determineValue(
      normal: _dio!,
      long: _longDio!,
      longLong: _longLongDio!,
      disable: _noTimeoutDio!,
    )!;
  }
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
