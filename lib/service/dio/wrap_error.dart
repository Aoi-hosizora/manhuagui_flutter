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
  // DioError [DioErrorType.other]: HandshakeException: Handshake error in client (OS Error: SSLV3_ALERT_HANDSHAKE_FAILURE)
  // DioError [DioErrorType.connectTimeout]: Connecting timed out [1ms]
  // DioError [DioErrorType.response]: Http status error [502]
  // _CastError: type 'String' is not a subtype of type 'Map<String, dynamic>?' in type cast
  // _CastError: type 'Null' is not a subtype of type 'Map<String, dynamic>' in type cast
  // _CastError: Null check operator used on a null value

  if (e is DioError) {
    var response = e.response;
    print('===> uri: ${e.requestOptions.uri}');
    print('===> method: ${e.requestOptions.method}');

    // ======================================================================================================================
    // ErrorType.networkError
    if (response == null) {
      var text = 'Unknown error';
      switch (e.type) {
        case DioErrorType.other:
          var msg = e.error.toString().toLowerCase();
          if (msg.contains('unreachable') || msg.contains('failed host lookup')) {
            text = 'Network is unavailable';
          } else if (msg.contains('connection refused')) {
            text = 'Bad server (Connection refused)';
          } else if (msg.contains('broken pipe')) {
            text = 'Bad server (Broken pipe)'; // TODO => Network is unavailable
          } else if (msg.contains('connection reset')) {
            text = 'Bad server (Connection reset)'; // TODO => Network is unavailable
          } else if (msg.contains('connection closed')) {
            text = 'Bad server (Connection closed)'; // TODO => Network is unavailable
          } else if (msg.contains('handshake') && msg.contains('ssl')) {
            text = 'Bad server (HTTPS error)';
          } else if (DEBUG) {
            text = '[DEBUG] ${e.error.toString()}';
          } else {
            text = 'Unknown error';
          }
          break;
        case DioErrorType.connectTimeout:
        case DioErrorType.sendTimeout:
        case DioErrorType.receiveTimeout:
          text = 'Timed out';
          break;
        case DioErrorType.cancel:
          text = 'Request is cancelled';
          break;
        case DioErrorType.response:
          break; // unreachable
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
      var err = '${response.statusCode!} ${StringUtils.capitalize(response.statusMessage!, allWords: true)}';
      var text = response.statusCode! < 500 ? 'Bad request ($err)' : 'Bad server ($err)';
      print('===> type: ${ErrorType.statusError}');
      print('===> text: $text');
      print('===> error: $err');
      print('└─────────────────── WrapError ───────────────────┘');
      return ErrorMessage.status(err, s, text, response: response);
    }

    // ======================================================================================================================
    // ErrorType.resultError
    try {
      var r = Result<dynamic>.fromJson(response.data, (_) => null); // <<<
      var msg = StringUtils.capitalize(r.message, allWords: true);
      var err = '${r.code} $msg (${response.statusCode!} ${StringUtils.capitalize(response.statusMessage!, allWords: true)})';
      var text = r.code < 50000 ? msg : '${r.code} $msg';
      var detail = response.data['error'] is Map<String, dynamic> ? response.data['error']['detail'] : null;
      print('===> type: ${ErrorType.resultError}');
      print('===> text: $text');
      print('===> detail: $detail');
      print('===> error: $err');
      print('└─────────────────── WrapError ───────────────────┘');
      return ErrorMessage.result(err, s, text, response: response, serviceCode: r.code, detail: detail);
    } catch (e, s) {
      // never be DioError, must goto ErrorType.otherError
      return wrapError(e, s);
    }
  }

  // ======================================================================================================================
  // ErrorType.otherError
  String text;
  if (!DEBUG) {
    text = 'Something went wrong.\nIf this error occurs frequently, please send feedback to the developer.';
  } else {
    text = '[DEBUG] ${e.runtimeType}: $e'; // [DEBUG] _CastError: type 'xxx' is not a subtype of type 'yyy' in type cast
  }
  var cast = e.runtimeType.toString() == '_CastError';
  if (cast) {
    var newText = '';
    if (e.toString().contains('Null check operator used on a null value')) {
      newText = '[DEBUG] Got unexpected null value';
    } else {
      var match = RegExp("type '(.+)' is not a subtype of type '(.+)' in type cast").firstMatch(e.toString());
      if (match != null) {
        newText = '[DEBUG] Want "${match.group(2)}" but got "${match.group(1)}" when typecasting';
      }
    }
    if (newText.isNotEmpty) {
      var top = RegExp('#0\\s*(.+) \\(package:.+').firstMatch(s.toString())?.group(1); // #0      _$LoginCheckResultFromJson (package:manhuagui_flutter/model/user.g.dart:41:35)
      if (top != null) {
        newText = '$newText, in $top';
      }
    }
    text = newText;
  }
  print('===> type: ${ErrorType.otherError}');
  print('===> text: $text');
  print('===> error: ${e.runtimeType}: $e');
  print('===> trace:\n$s');
  print('└─────────────────── WrapError ───────────────────┘');
  return ErrorMessage.other(e, s, text, castError: cast);
}
