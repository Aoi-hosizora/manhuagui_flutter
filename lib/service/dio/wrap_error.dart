import 'dart:async';
import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/result.dart';
import 'package:stack_trace/stack_trace.dart';

enum ErrorType { networkError, statusError, resultError, otherError }

class ErrorMessage {
  const ErrorMessage(this.type, this.error, this.stack, this.text, [this.response, this.serviceCode, this.detail, this.casting, this.special, this.function]);

  const ErrorMessage.network(dynamic error, StackTrace stack, String text) //
      : this(ErrorType.networkError, error, stack, text);

  const ErrorMessage.status(dynamic error, StackTrace stack, String text, {Response? response}) //
      : this(ErrorType.statusError, error, stack, text, response);

  const ErrorMessage.result(dynamic error, StackTrace stack, String text, {Response? response, int? serviceCode, dynamic detail}) //
      : this(ErrorType.resultError, error, stack, text, response, serviceCode, detail);

  const ErrorMessage.other(dynamic error, StackTrace stack, String text, {bool? casting, bool? special, String? function}) //
      : this(ErrorType.otherError, error, stack, text, null, null, null, casting, special, function);

  final ErrorType type;
  final dynamic error;
  final StackTrace stack;
  final String text;

  final Response? response;
  final int? serviceCode;
  final dynamic detail;
  final bool? casting;
  final bool? special;
  final String? function;

  @override
  String toString() => 'ErrorMessage [$type]: $text\n    Error: $error\n    Trace: $stack';
}

class SpecialException implements Exception {
  const SpecialException([this.message]);

  final String? message;

  @override
  String toString() => //
      message == null ? 'Exception' : 'Exception: $message';
}

/// Wraps given error to [ErrorMessage].
ErrorMessage wrapError(dynamic e, StackTrace s, {bool useResult = true}) {
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
  // TimeoutException: after 0:00:12.000000: No stream event
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

  bool _networkRelated(dynamic e, [Tuple1<String?>? message]) {
    if (e is SocketException || e is HttpException) {
      message?.item = e.toString();
      return true;
    }
    if (e is TlsException /* CertificateException / HandshakeException */) {
      message?.item = 'TlsException: ${e.toString()}';
      return true;
    }
    if (e.runtimeType.toString() == 'ClientException' || e.runtimeType.toString() == '_ClientSocketException') {
      message?.item = '${e.runtimeType}: $e';
      return true;
    }
    return false;
  }

  String _translate(String s, String runtimeType) {
    const map = <String, String>{
      'unreachable': '网络不可用', // Network is unavailable
      'failed host lookup': '网络不可用',
      'connection refused': '网络连接异常 (Connection refused)', // Network error
      'connection abort': '网络连接异常 (Connection abort)',
      'connection reset': '网络连接异常 (Connection reset)',
      'connection closed': '网络连接异常 (Connection closed)',
      'connection terminated': '网络连接异常 (Connection terminated)',
      'connection failed': '网络连接异常 (Connection failed)',
      'broken pipe': '网络连接异常 (Broken pipe)',
      'handshake error': '网络连接异常 (HTTPS error)',
      'invalid argument': '网络连接异常 (Invalid argument)',
    };

    final msg = s.toLowerCase();
    for (var kv in map.entries) {
      if (msg.contains(kv.key)) {
        return kv.value;
      }
    }
    if (AppSetting.instance.other.showDebugErrorMsg) {
      return '网络连接异常: [DEBUG] $runtimeType: $s'; // Network error
    }
    return '网络连接异常 ($runtimeType)\n如果该错误反复出现，请向开发者反馈'; // Unknown network error
  }

  print('┌─────────────────── WrapError ───────────────────┐');
  print('===> date: ${DateTime.now().toIso8601String()}');

  void _logForConsole(List<String> lines) {
    var message = [
      '┌─────────────────── WrapError ───────────────────┐',
      '===> date: ${DateTime.now().toIso8601String()}',
      for (var l in lines)
        l.split('\n').length > 10 //
            ? (l.split('\n').sublist(0, 10 /* #0~#8 */).join('\n') + '\n...')
            : l,
      '└─────────────────── WrapError ───────────────────┘',
    ].join('\n');
    globalLogger.e(
      message,
      null, // error
      null, // stackTrace
      true, // ignoreOutput
    );
  }

  if (e is DioError && e.type == DioErrorType.other && !_networkRelated(e.error)) {
    s = e.stackTrace ?? StackTrace.empty;
    e = e.error;
  }
  if (e is DioError) {
    var response = e.response;
    print('===> uri: ${e.requestOptions.uri}');
    print('===> method: ${e.requestOptions.method}');

    // ======================================================================================================================
    // ErrorType.networkError (DioError)
    if (response == null) {
      String text;
      switch (e.type) {
        case DioErrorType.other:
          text = _translate(e.error.toString(), 'DioError_${e.error.runtimeType}'); // ...
          break;
        case DioErrorType.connectTimeout:
          text = '连接超时 [${e.requestOptions.connectTimeout / 1000}s]'; // Connection timed out
          break;
        case DioErrorType.sendTimeout:
          text = '发送请求超时 [${e.requestOptions.sendTimeout / 1000}s]'; // Request timed out
          break;
        case DioErrorType.receiveTimeout:
          text = '获取响应超时 [${e.requestOptions.receiveTimeout / 1000}s]'; // Response timed out
          break;
        case DioErrorType.cancel:
          text = '请求被取消'; // Request is cancelled
          break;
        case DioErrorType.response:
          text = '响应错误'; // Response error // x
          break;
      }
      print('===> type: ${ErrorType.networkError}');
      print('===> text: $text');
      print('===> error: DioError [${e.type}]: ${e.error.toString()}');
      print('===> trace:\n${e.stackTrace}');
      print('└─────────────────── WrapError ───────────────────┘');
      _logForConsole([
        '===> uri: ${e.requestOptions.uri}',
        '===> method: ${e.requestOptions.method}',
        '===> type: ${ErrorType.networkError}',
        '===> text: $text',
        '===> error: DioError [${e.type}]: ${e.error.toString()}',
        '===> trace:\n${e.stackTrace}',
      ]);
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
        text = '服务器出错 ($err)'; // Server error
      }
      print('===> type: ${ErrorType.statusError}');
      print('===> text: $text');
      print('===> code: ${response.statusCode}');
      print('===> error: $err');
      print('===> trace:\n${e.stackTrace}');
      print('└─────────────────── WrapError ───────────────────┘');
      _logForConsole([
        '===> uri: ${e.requestOptions.uri}',
        '===> method: ${e.requestOptions.method}',
        '===> type: ${ErrorType.statusError}',
        '===> text: $text',
        '===> code: ${response.statusCode}',
        '===> error: $err',
        '===> trace:\n${e.stackTrace}',
      ]);
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
        text = '服务器出错 (${r.code} $msg)'; // Server error
      }
      var detail = response.data['error'] is Map<String, dynamic> ? response.data['error']['detail'] : null;
      print('===> type: ${ErrorType.resultError}');
      print('===> text: $text');
      print('===> code: ${response.statusCode} ${r.code}');
      print('===> detail: $detail');
      print('===> error: $err');
      print('===> trace:\n${e.stackTrace}');
      print('└─────────────────── WrapError ───────────────────┘');
      _logForConsole([
        '===> uri: ${e.requestOptions.uri}',
        '===> method: ${e.requestOptions.method}',
        '===> type: ${ErrorType.resultError}',
        '===> text: $text',
        '===> code: ${response.statusCode} ${r.code}',
        '===> error: $err',
        '===> detail: $detail',
        '===> trace:\n${e.stackTrace}',
      ]);
      return ErrorMessage.result(err, e.stackTrace!, text, response: response, serviceCode: r.code, detail: detail);
    } catch (e, s) {
      // must goto ErrorType.otherError
      return wrapError(e, s);
    }
  }

  // ======================================================================================================================
  // ErrorType.networkError (TimeoutException)
  if (e is TimeoutException) {
    var text = '访问网络超时 [${(e.duration?.inMilliseconds ?? 0) / 1000}s]'; // Network timed out
    print('===> uri: ?');
    print('===> method: ?');
    print('===> type: ${ErrorType.networkError}');
    print('===> text: $text');
    print('===> error: TimeoutException: after ${e.duration}: ${e.message}');
    print('===> trace:\n$s');
    print('└─────────────────── WrapError ───────────────────┘');
    _logForConsole([
      '===> uri: ?',
      '===> method: ?',
      '===> type: ${ErrorType.networkError}',
      '===> text: $text',
      '===> error: TimeoutException: after ${e.duration}: ${e.message}',
      '===> trace:\n$s',
    ]);
    return ErrorMessage.network(e, s, text);
  }

  // ======================================================================================================================
  // ErrorType.networkError (network related exception)
  var message = Tuple1<String?>(null);
  if (_networkRelated(e, message)) {
    var text = _translate(e.toString(), e.runtimeType.toString()); // ...
    print('===> uri: ?');
    print('===> method: ?');
    print('===> type: ${ErrorType.networkError}');
    print('===> text: $text');
    print('===> error: ${message.item ?? "${e.runtimeType}: $e"}');
    print('===> trace:\n$s');
    print('└─────────────────── WrapError ───────────────────┘');
    _logForConsole([
      '===> uri: ?',
      '===> method: ?',
      '===> type: ${ErrorType.networkError}',
      '===> text: $text',
      '===> error: ${message.item ?? "${e.runtimeType}: $e"}',
      '===> trace:\n$s',
    ]);
    return ErrorMessage.network(e, s, text);
  }

  // ======================================================================================================================
  // ErrorType.otherError (_CastError, UnknownException, ...)
  String? readable;
  var casting = e.runtimeType.toString() == '_CastError';
  var special = e is SpecialException;
  if (casting) {
    if (e.toString().contains('Null check operator used on a null value')) {
      readable = 'Got unexpected null value';
    } else {
      // type 'String' is not a subtype of type 'Map<String, dynamic>?' in type cast
      var match = RegExp("type '(.+)' is not a subtype of type '(.+)' in type cast").firstMatch(e.toString());
      if (match != null) {
        readable = 'Want "${match.group(2)}" but got "${match.group(1)}"';
      }
    }
  } else if (special) {
    readable = e.message ?? e.toString();
  }
  String? function;
  var frames = Trace.from(s).frames;
  if (frames.isNotEmpty) {
    var line = frames[0].member?.contains('DioMixin.fetch') == false ? 0 : 1;
    if (frames.length > line && frames[line].member?.isNotEmpty == true) {
      function = '${frames[line].member}:${frames[line].line ?? 0}:${frames[line].column ?? 0}';
    }
  }
  String text;
  if (AppSetting.instance.other.showDebugErrorMsg) {
    readable ??= '${e.runtimeType}: $e';
    text = '应用发生错误: [DEBUG] $readable' + (special ? '' : ', ${function ?? '<line: ?>'}'); // Application error
  } else {
    readable ??= e.runtimeType.toString();
    text = '应用发生错误 ($readable)\n如果该错误反复出现，请向开发者反馈'; // Application error
  }
  print('===> type: ${ErrorType.otherError}');
  print('===> text: $text');
  print('===> error: ${e.runtimeType}: $e');
  print('===> trace:\n$s');
  print('└─────────────────── WrapError ───────────────────┘');
  _logForConsole([
    '===> type: ${ErrorType.otherError}',
    '===> text: $text',
    '===> error: ${e.runtimeType}: $e',
    '===> trace:\n$s',
  ]);
  return ErrorMessage.other(e, s, text, casting: casting, special: special, function: function);
}
