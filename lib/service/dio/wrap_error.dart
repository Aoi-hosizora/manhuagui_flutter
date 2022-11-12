import 'dart:async';
import 'dart:io';

import 'package:flutter_ahlib/flutter_ahlib.dart';
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
  globalLogger.e('wrapError (${e.runtimeType})', e, s);

  print('┌─────────────────── WrapError ───────────────────┐');
  print('===> date: ${DateTime.now().toIso8601String()}');

  // DioError [DioErrorType.other]: SocketException: Network error (OS Error: Network is unreachable, errno = 101)
  // DioError [DioErrorType.other]: SocketException: Failed host lookup: '...' (OS Error: No address associated with hostname, errno = 7)
  // DioError [DioErrorType.other]: SocketException: Connection refused (OS Error: Connection refused, errno = 111)
  // DioError [DioErrorType.other]: SocketException: Software caused connection abort (OS Error: Software caused connection abort, errno = 103)
  // DioError [DioErrorType.other]: SocketException: Connection reset by peer (OS Error: Connection reset by peer, errno = 104)
  // DioError [DioErrorType.other]: SocketException: Write failed (OS Error: Broken pipe, errno = 32)
  // DioError [DioErrorType.other]: HttpException: Software caused connection abort, uri = ...
  // DioError [DioErrorType.other]: HttpException: Connection reset by peer, uri = ...
  // DioError [DioErrorType.other]: HttpException: Connection closed before full header was received, uri = ...
  // DioError [DioErrorType.other]: HttpException: Connection closed while received data, uri = ...
  // DioError [DioErrorType.other]: HandshakeException: Connection terminated during handshake
  //
  // DioError [DioErrorType.connectTimeout]: Connecting timed out [1ms]
  // DioError [DioErrorType.response]: Http status error [502]
  //
  // TimeoutException: TimeoutException after 0:00:12.000000: No stream event
  //
  // TlsException: HandshakeException: Connection terminated during handshake
  // TlsException: HandshakeException: Handshake error in client (OS Error: SSLV3_ALERT_HANDSHAKE_FAILURE)
  //
  // ClientException: Connection closed before full header was received
  // ClientException: Connection closed while received data
  //
  // _ClientSocketException: Failed host lookup: '...'
  // _ClientSocketException: Connection reset by peer
  // _ClientSocketException: Connection failed
  // _ClientSocketException: Broken pipe
  // _ClientSocketException: Software caused connection abort
  // _ClientSocketException: Invalid argument
  //
  // _CastError: type 'String' is not a subtype of type 'Map<String, dynamic>?' in type cast
  // _CastError: type 'Null' is not a subtype of type 'Map<String, dynamic>' in type cast
  // _CastError: Null check operator used on a null value

  String _translate(String s, String runtimeType) {
    String text;
    var msg = s.toLowerCase();
    if (msg.contains('unreachable') || msg.contains('failed host lookup')) {
      text = '网络不可用'; // Network is unavailable
    } else if (msg.contains('connection refused')) {
      text = '网络连接异常 (Connection refused)'; // Network error
    } else if (msg.contains('connection abort')) {
      text = '网络连接异常 (Connection abort)';
    } else if (msg.contains('connection reset')) {
      text = '网络连接异常 (Connection reset)';
    } else if (msg.contains('broken pipe')) {
      text = '网络连接异常 (Broken pipe)';
    } else if (msg.contains('connection closed')) {
      text = '网络连接异常 (Connection closed)';
    } else if (msg.contains('connection terminated')) {
      text = '网络连接异常 (Connection terminated)';
    } else if (msg.contains('connection failed')) {
      text = '网络连接异常 (Connection failed)';
    } else if (msg.contains('handshake error')) {
      text = '网络连接异常 (HTTPS error)';
    } else if (msg.contains('invalid argument')) {
      text = '网络连接异常 (Invalid argument)';
    } else if (DEBUG_ERROR) {
      text = '网络连接异常 ([DEBUG] $runtimeType: $s)';
    } else {
      text = '网络连接异常 (未知错误)'; // Unknown network error
    }
    return text;
  }

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
          text = _translate(e.error.toString(), 'DioError (${e.error.runtimeType})'); // ...
          break;
        case DioErrorType.connectTimeout:
          text = '连接超时'; // Connection timed out
          break;
        case DioErrorType.sendTimeout:
          text = '发送请求超时'; // Request timed out
          break;
        case DioErrorType.receiveTimeout:
          text = '获取响应超时'; // Response timed out
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
        text = '请求有误 ($err)'; // Bad request
      } else {
        text = '服务器出错 ($err)'; // Bad server
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
        text = '服务器出错 (${r.code} $msg)'; // Bad server
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
  // ErrorType.networkError (TimeoutException)
  if (e is TimeoutException) {
    var text = '网络请求超时'; // Network timed out
    print('===> uri: ?');
    print('===> method: ?');
    print('===> type: ${ErrorType.networkError}');
    print('===> text: $text');
    print('===> error: TimeoutException: after ${e.duration}: ${e.message}');
    print('===> trace:\n$s');
    print('└─────────────────── WrapError ───────────────────┘');
    return ErrorMessage.network(e, s, text);
  }

  // ======================================================================================================================
  // ErrorType.networkError (TlsException => HandshakeException / CertificateException)
  if (e is TlsException) {
    var text = _translate(e.message, 'TlsException (${e.type})'); // ...
    print('===> uri: ?');
    print('===> method: ?');
    print('===> type: ${ErrorType.networkError}');
    print('===> text: $text');
    print('===> error: TlsException: ${e.type}: ${e.message}${e.osError == null ? '' : ' ${e.osError}'}');
    print('===> trace:\n$s');
    print('└─────────────────── WrapError ───────────────────┘');
    return ErrorMessage.network(e, s, text);
  }

  // ======================================================================================================================
  // ErrorType.networkError (ClientException / _ClientSocketException)
  if (e.runtimeType.toString() == 'ClientException' || e.runtimeType.toString() == '_ClientSocketException') {
    var text = _translate(e.message, e.runtimeType.toString()); // ...
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
  if (!DEBUG_ERROR) {
    text = '程序发生错误 (${e.runtimeType})\n如果该错误反复出现，请向开发者反馈'; // Something went wrong
  } else {
    text = '程序发生错误 ([DEBUG] ${e.runtimeType}: $e)';
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
    text = '程序发生错误 ($newText)'; // Something went wrong
  }
  print('===> type: ${ErrorType.otherError}');
  print('===> text: $text');
  print('===> error: ${e.runtimeType}: $e');
  print('===> trace:\n$s');
  print('└─────────────────── WrapError ───────────────────┘');
  return ErrorMessage.other(e, s, text, castError: cast);
}
