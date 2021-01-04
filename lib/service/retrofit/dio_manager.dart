import 'package:dio/dio.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/result.dart';

class DioManager {
  DioManager._();

  static DioManager _instance;

  static DioManager get instance {
    if (_instance == null) {
      _instance = DioManager._();
      _instance._initDio();
    }
    return _instance;
  }

  Dio _dio;

  /// A global dio instance.
  Dio get dio => _dio;

  void _initDio() {
    _dio = Dio();
    _dio.options.baseUrl = BASE_API_URL;
    _dio.options.connectTimeout = CONNECT_TIMEOUT;
    _dio.options.sendTimeout = SEND_TIMEOUT;
    _dio.options.receiveTimeout = RECEIVE_TIMEOUT;
    _dio.interceptors.add(LogInterceptor());
  }
}

class LogInterceptor extends Interceptor {
  @override
  Future onRequest(RequestOptions options) async {
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
  }

  @override
  Future onError(DioError err) async {
    print('┌─────────────────── DioError ────────────────────┐');
    print('date: ${DateTime.now().toIso8601String()}');
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
    print('date: ${DateTime.now().toIso8601String()}');
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

enum ErrorType {
  NETWORK_ERROR,
  RESULT_ERROR,
  STATUS_ERROR,
  OTHER_ERROR,
}

class ErrorMessage {
  ErrorType type;
  dynamic error;
  String text;
  int httpCode;
  int serviceCode;

  ErrorMessage({this.type, this.error, this.text, this.httpCode, this.serviceCode});
}

/// Wrap error to [ErrorMessage].
ErrorMessage wrapError(dynamic e, {bool isResult = true}) {
  print('┌─────────────────── WrapError ───────────────────┐');
  print('date: ${DateTime.now().toIso8601String()}');

  if (e is DioError) {
    assert(isResult != null);

    print('uri: ${e.request.uri}');
    print('method: ${e.request.method}');

    // ======================================================================================================================
    // NETWORK_ERROR
    if (e.response == null) {
      // DioError [DioErrorType.DEFAULT]: SocketException: Connection failed (OS Error: Network is unreachable, errno = 101)
      // DioError [DioErrorType.DEFAULT]: SocketException: OS Error: Connection refused
      // DioError [DioErrorType.DEFAULT]: HandshakeException: Handshake error in client (OS Error)
      // DioError [DioErrorType.CONNECT_TIMEOUT]: Connecting timed out
      var text = 'Unknown error';
      switch (e.type) {
        case DioErrorType.DEFAULT:
        case DioErrorType.CANCEL:
          text = 'Network error';
          if (!e.toString().contains('unreachable')) {
            text = 'Server unreachable';
          }
          break;
        case DioErrorType.CONNECT_TIMEOUT:
        case DioErrorType.SEND_TIMEOUT:
        case DioErrorType.RECEIVE_TIMEOUT:
          text = 'Timeout error';
          break;
        case DioErrorType.RESPONSE: // x
          text = 'Response unknown error';
          break;
      }
      print('type: ${ErrorType.NETWORK_ERROR}');
      print('error: $e');
      print('text: $text');
      print('└─────────────────── WrapError ───────────────────┘');
      return ErrorMessage(type: ErrorType.NETWORK_ERROR, error: e, text: text);
    }

    // ======================================================================================================================
    // STATUS_ERROR
    if (!isResult) {
      var err = '${e.response.statusCode}: ${e.response.statusMessage}';
      var text = 'Respond $err';
      print('type: ${ErrorType.STATUS_ERROR}');
      print('error: $err');
      print('text: $text');
      print('└─────────────────── WrapError ───────────────────┘');
      return ErrorMessage(type: ErrorType.STATUS_ERROR, error: err, text: text, httpCode: e.response.statusCode);
    }

    // ======================================================================================================================
    // RESULT_ERROR
    try {
      var r = Result.fromJson(e.response.data);
      r.message = '${r.message[0].toUpperCase()}${r.message.substring(1)}';
      var err = '${e.response.statusCode}: ${r.code} ${r.message}';
      var text = r.message;
      var data = e.response.data as Map<String, dynamic>;
      var detail = data != null && data['error'] is Map<String, dynamic> ? data['error']['detail'] : null;
      print('type: ${ErrorType.RESULT_ERROR}');
      print('error: $err');
      print('text: $text');
      print('detail: $detail');
      print('└─────────────────── WrapError ───────────────────┘');
      return ErrorMessage(type: ErrorType.RESULT_ERROR, error: err, text: text, httpCode: e.response.statusCode, serviceCode: r.code);
    } catch (e) {
      // non DioError
      return wrapError(e, isResult: isResult);
    }
  }

  // ======================================================================================================================
  // OTHER_ERROR
  var text = 'Some strange error.';
  if (DEBUG) {
    // _CastError: type 'xxx' is not a subtype of type 'yyy' in type cast
    text = '${e.runtimeType}: ${e.toString()}';
  }
  print('type: ${ErrorType.OTHER_ERROR}');
  print('error: $e');
  print('text: $text');
  print('└─────────────────── WrapError ───────────────────┘');
  return ErrorMessage(type: ErrorType.OTHER_ERROR, error: e, text: text);
}
