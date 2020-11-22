import 'package:dio/dio.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/result.dart';

class DioManager {
  DioManager._();

  static DioManager _instance;

  static DioManager getInstance() {
    if (_instance == null) {
      _instance = DioManager._();
      _instance._initDio();
    }
    return _instance;
  }

  Dio _dio;

  /// Global dio from [DioManager].
  Dio get dio => _dio;

  void _initDio() {
    _dio = Dio();
    _dio.options.baseUrl = BASE_API_URL;
    _dio.options.connectTimeout = 10000; // 10s
    _dio.options.receiveTimeout = 6000; // 6s
    _dio.interceptors.add(LogInterceptor());
  }
}

class LogInterceptor extends Interceptor {
  @override
  Future onRequest(RequestOptions options) async {
    print('┌─────────────────── Request ─────────────────────┐');
    print('uri: ${options.uri}');
    print('method: ${options.method}');
    if (options.extra.isNotEmpty) {
      print('extra: ${options.extra}');
    }
    print('headers:');
    options.headers.forEach((key, v) => print('    $key: $v'));
    print('└─────────────────── Request ─────────────────────┘');
  }

  @override
  Future onError(DioError err) async {
    print('┌─────────────────── DioError ────────────────────┐');
    print('uri: ${err.request.uri}');
    print('method: ${err.request.method}');
    print('error: $err');
    if (err.response != null) {
      _printResponse(err.response);
    }
    print('└─────────────────── DioError ────────────────────┘');
  }

  @override
  Future onResponse(Response response) async {
    print('┌─────────────────── Response ────────────────────┐');
    _printResponse(response);
    print('└─────────────────── Response ────────────────────┘');
  }

  void _printResponse(Response response) {
    print('uri: ${response.request.uri}');
    print('method: ${response.request.method}');
    print('statusCode: ${response.statusCode}');
    if (response.headers != null) {
      print('headers:');
      response.headers.forEach((key, v) => print('    $key: ${v.join(',')}'));
    }
  }
}

/// Return type of [wrapError].
class ErrorMessage {
  String text;
  dynamic e;

  ErrorMessage({this.text, this.e});
}

/// Wrap error from dio to [ErrorMessage].
ErrorMessage wrapError(dynamic e) {
  print('┌─────────────────── WrapError ───────────────────┐');

  if (e is DioError) {
    print('uri: ${e.request.uri}');
    print('method: ${e.request.method}');

    if (e.response == null) {
      // DioError [DioErrorType.DEFAULT]: SocketException: OS Error
      // DioError [DioErrorType.DEFAULT]: HandshakeException: Handshake error in client (OS Error)
      // DioError [DioErrorType.CONNECT_TIMEOUT]: Connecting timed out
      var text = 'Network error'; // DioErrorType.DEFAULT || DioErrorType.CANCEL
      if (e.type == DioErrorType.CONNECT_TIMEOUT || e.type == DioErrorType.SEND_TIMEOUT || e.type == DioErrorType.RECEIVE_TIMEOUT) {
        text = 'Network timeout'; // DioErrorType.XXX_TIMEOUT
      }
      print('type: network');
      print('error: $text ==> $e');
      print('└─────────────────── WrapError ───────────────────┘');
      return ErrorMessage(text: text, e: e);
    }

    // DioErrorType.RESPONSE
    try {
      var r = Result.fromJson(e.response.data);
      print('type: result');
      print('error: ${e.response.statusCode} ${r.code} ${r.message}');
      print('└─────────────────── WrapError ───────────────────┘');
      var msg = r.code < 50000 ? r.message : '${r.code}: ${r.message}';
      return ErrorMessage(text: '${msg[0].toUpperCase()}${msg.substring(1)}', e: '${r.code}: ${r.message}'); // !!!
    } catch (_) {
      var msg = '${e.response.statusCode}: ${e.response.statusMessage}';
      print('type: server');
      print('error: $msg');
      print('└─────────────────── WrapError ───────────────────┘');
      return ErrorMessage(text: msg, e: e);
    }
  }

  //  _CastError: type 'xxx' is not a subtype of type 'yyy' in type cast
  print('type: other');
  print('error: $e');
  print('└─────────────────── WrapError ───────────────────┘');
  var msg = '${e.runtimeType}: ${e.toString()}';
  return ErrorMessage(text: msg, e: e);
}
