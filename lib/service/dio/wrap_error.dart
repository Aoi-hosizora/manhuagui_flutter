import 'dart:io';

import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/result.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:dio/dio.dart';

enum ErrorType {
  networkError,
  statusError,
  resultError,
  otherError,
}

class ErrorMessage {
  const ErrorMessage({required this.type, required this.error, required this.stack, required this.text, this.response, this.serviceCode, this.detail, this.castError});

  const ErrorMessage.network(this.error, this.stack, this.text)
      : type = ErrorType.networkError,
        response = null,
        serviceCode = null,
        detail = null,
        castError = null;

  const ErrorMessage.status(this.error, this.stack, this.text, {this.response})
      : type = ErrorType.statusError,
        serviceCode = null,
        detail = null,
        castError = null;

  const ErrorMessage.result(this.error, this.stack, this.text, {this.response, this.serviceCode, this.detail})
      : type = ErrorType.resultError,
        castError = null;

  const ErrorMessage.other(this.error, this.stack, this.text, {this.castError})
      : type = ErrorType.otherError,
        response = null,
        serviceCode = null,
        detail = null;

  final ErrorType type;
  final dynamic error;
  final StackTrace stack;
  final String text;

  final Response? response;
  final int? serviceCode;
  final dynamic detail;
  final bool? castError;
}

/// Wraps given error to [ErrorMessage].
ErrorMessage wrapError(dynamic e, StackTrace s, {bool useResult = true}) {
  print('┌─────────────────── WrapError ───────────────────┐');
  print('===> date: ${DateTime.now().toIso8601String()}');

  // DioError [DioErrorType.other]: SocketException: Connection failed (OS Error: Network is unreachable, errno = 101)
  // DioError [DioErrorType.other]: SocketException: Failed host lookup: '...' (OS Error: No address associated with hostname, errno = 7)
  // DioError [DioErrorType.other]: SocketException: Connection refused (OS Error: Connection refused, errno = 111)
  // DioError [DioErrorType.other]: SocketException: Write failed (OS Error: Broken pipe, errno = 32), address = ...
  // DioError [DioErrorType.other]: HttpException: Connection reset by peer, uri = ...
  // DioError [DioErrorType.other]: HttpException: Connection closed before full header was received, uri = ...
  // DioError [DioErrorType.connectTimeout]: Connecting timed out [1ms]
  // DioError [DioErrorType.response]: Http status error [502]
  // TlsException [HandshakeException]: Handshake error in client (OS Error: SSLV3_ALERT_HANDSHAKE_FAILURE)
  // TlsException [HandshakeException]: Connection terminated during handshake
  // _CastError: type 'String' is not a subtype of type 'Map<String, dynamic>?' in type cast
  // _CastError: type 'Null' is not a subtype of type 'Map<String, dynamic>' in type cast
  // _CastError: Null check operator used on a null value

  if (e is DioError) {
    var response = e.response;
    print('===> uri: ${e.requestOptions.uri}');
    print('===> method: ${e.requestOptions.method}');

    // ======================================================================================================================
    // ErrorType.networkError (DioError)
    if (response == null) {
      var text = '网络连接异常 (未知错误)'; // Unknown network error
      switch (e.type) {
        case DioErrorType.other:
          var msg = e.error.toString().toLowerCase();
          if (msg.contains('unreachable') || msg.contains('failed host lookup')) {
            text = '网络不可用'; // Network is unavailable
          } else if (msg.contains('connection refused')) {
            text = '网络连接异常 (Connection refused)'; // Bad server (Connection refused)
          } else if (msg.contains('broken pipe')) {
            text = '网络连接异常 (Broken pipe)'; // Bad server (Broken pipe)
          } else if (msg.contains('connection reset')) {
            text = '网络连接异常 (Connection reset)'; // Bad server (Connection reset)
          } else if (msg.contains('connection closed')) {
            text = '网络连接异常 (Connection closed)'; // Bad server (Connection closed)
          } else if (msg.contains('handshake') && (msg.contains('error') || msg.contains('terminated'))) {
            text = '网络连接异常 (HTTPS error)'; // Bad server (HTTPS error)
          } else if (DEBUG) {
            text = '网络连接异常 ([DEBUG] DioError: ${e.error.toString()})'; // [DEBUG] DioError: ${e.error.toString()}
          }
          break;
        case DioErrorType.connectTimeout:
          text = '连接超时'; // Connection timed out
          break;
        case DioErrorType.sendTimeout:
        case DioErrorType.receiveTimeout:
          text = '请求超时'; // Timed out
          break;
        case DioErrorType.cancel:
          text = '请求被取消'; // Request is cancelled
          break;
        case DioErrorType.response:
          break;
      }
      print('===> type: ${ErrorType.networkError}');
      print('===> text: $text');
      print('===> error: DioError [${e.type}]: ${e.error.toString()}');
      print('===> trace:\n${e.stackTrace}');
      print('└─────────────────── WrapError ───────────────────┘');
      return ErrorMessage.network(e, e.stackTrace!, text);
    }

    // ======================================================================================================================
    // ErrorType.statusError
    if (!useResult || response.data is! Map<String, dynamic>) {
      var err = '${response.statusCode!} ${StringUtils.capitalize(response.statusMessage!, allWords: true)}'.trim();
      String text;
      if (response.statusCode! < 500) {
        text = '请求有误 ($err)'; // Bad request ($err)
      } else {
        text = '服务器出错 ($err)'; // Bad server ($err)
      }
      print('===> type: ${ErrorType.statusError}');
      print('===> text: $text');
      print('===> error: $err');
      print('└─────────────────── WrapError ───────────────────┘');
      return ErrorMessage.status(err, e.stackTrace!, text, response: response);
    }

    // ======================================================================================================================
    // ErrorType.resultError
    try {
      var r = Result<dynamic>.fromJson(response.data, (_) => null); // <<<
      var msg = StringUtils.capitalize(r.message, allWords: true);
      var err = '${r.code} $msg (${response.statusCode!} ${StringUtils.capitalize(response.statusMessage!, allWords: true)})'.trim();
      String text;
      if (r.code < 50000) {
        text = msg;
      } else {
        text = '服务器出错 (${r.code} $msg)'; // ${r.code} $msg
      }
      var detail = response.data['error'] is Map<String, dynamic> ? response.data['error']['detail'] : null;
      print('===> type: ${ErrorType.resultError}');
      print('===> text: $text');
      print('===> detail: $detail');
      print('===> error: $err');
      print('└─────────────────── WrapError ───────────────────┘');
      return ErrorMessage.result(err, e.stackTrace!, text, response: response, serviceCode: r.code, detail: detail);
    } catch (e, s) {
      // must goto ErrorType.otherError
      return wrapError(e, s);
    }
  }

  // ======================================================================================================================
  // ErrorType.networkError (TlsException)
  if (e is TlsException) {
    var text = '网络连接异常 (未知错误)'; // Unknown network error
    var msg = e.message.toLowerCase();
    if (msg.contains('handshake') && (msg.contains('error') || msg.contains('terminated'))) {
      text = '网络连接异常 (HTTPS error)'; // Bad server (HTTPS error)
    } else if (DEBUG) {
      // type: HandshakeException / CertificateException
      text = '网络连接异常 ([DEBUG] ${e.type}: ${e.message})'; // [DEBUG] ${e.type}: ${e.message}
    }

    print('===> uri: ?');
    print('===> method: ?');
    print('===> type: ${ErrorType.networkError}');
    print('===> text: $text');
    print('===> error: TlsException [${e.type}]: ${e.message}${e.osError == null ? '' : ' ${e.osError}'}');
    print('===> trace:\n$s');
    print('└─────────────────── WrapError ───────────────────┘');
    return ErrorMessage.network(e, s, text);
  }

  // ======================================================================================================================
  // ErrorType.networkError (_ClientSocketException)
  if (e.runtimeType.toString() == '_ClientSocketException') {
    var text = '网络连接异常 (未知错误)'; // Unknown network error
    var msg = e.message.toLowerCase();
    if (msg.contains('unreachable') || msg.contains('failed host lookup')) {
      text = '网络不可用'; // Network is unavailable
    } else if (DEBUG) {
      text = '网络连接异常 ([DEBUG] ${e.type}: ${e.message})'; // [DEBUG] ${e.type}: ${e.message}
    }

    print('===> uri: ?');
    print('===> method: ?');
    print('===> type: ${ErrorType.networkError}');
    print('===> text: $text');
    print('===> error: ${e.runtimeType}: $e');
    print('===> trace:\n$s');
    print('└─────────────────── WrapError ───────────────────┘');
    return ErrorMessage.network(e, s, text);
  }

  // ======================================================================================================================
  // ErrorType.otherError
  String text;
  if (!DEBUG) {
    text = '程序发生错误 (${e.runtimeType})\n如果该错误反复出现，请向开发者反馈';
    // text = 'Something went wrong (${e.runtimeType})\nIf this error occurs frequently, please send feedback to the developer';
  } else {
    // [DEBUG] _CastError: type 'xxx' is not a subtype of type 'yyy' in type cast
    text = '程序发生错误 ([DEBUG] ${e.runtimeType}: $e)'; // [DEBUG] ${e.runtimeType}: $e
  }
  var cast = e.runtimeType.toString() == '_CastError';
  if (cast) {
    var msg = e.toString();
    var newText = '';
    if (msg.contains('Null check operator used on a null value')) {
      newText = '[DEBUG] Got unexpected null value';
    } else {
      // type 'String' is not a subtype of type 'Map<String, dynamic>?' in type cast
      var match = RegExp("type '(.+)' is not a subtype of type '(.+)' in type cast").firstMatch(msg);
      if (match != null) {
        newText = '[DEBUG] Want "${match.group(2)}" type but got "${match.group(1)}" type';
      }
    }
    if (newText.isNotEmpty) {
      // #0      _$LoginCheckResultFromJson (package:manhuagui_flutter/model/user.g.dart:41:35)
      var top = RegExp('#0\\s*(.+) \\(package:.+').firstMatch(s.toString())?.group(1);
      if (top != null) {
        newText = '$newText, in $top';
      }
    }
    text = '程序发生错误 ($newText)'; // $newText
  }
  print('===> type: ${ErrorType.otherError}');
  print('===> text: $text');
  print('===> error: ${e.runtimeType}: $e');
  print('===> trace:\n$s');
  print('└─────────────────── WrapError ───────────────────┘');
  return ErrorMessage.other(e, s, text, castError: cast);
}
