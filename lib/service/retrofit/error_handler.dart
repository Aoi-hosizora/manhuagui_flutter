import 'package:dio/dio.dart';
import 'package:manhuagui_flutter/model/result.dart';

class ErrorMessage {
  String text;
  dynamic e;

  ErrorMessage({this.text, this.e});
}

ErrorMessage wrapError(dynamic e) {
  if (e is DioError) {
    if (e.response == null) {
      // DioError [DioErrorType.DEFAULT]: SocketException: OS Error
      print('1-------------------- network: $e');
      return ErrorMessage(text: 'Network error', e: e);
    }

    try {
      var r = Result.fromJson(e.response.data);
      print('2-------------------- result: ${e.response.data}');
      var msg = '${r.code}: ${r.message}';
      return ErrorMessage(text: msg, e: r.message);
    } catch (_) {
      print('3-------------------- server: $e');
      var msg = '${e?.response?.statusCode}: ${e?.response?.statusMessage}';
      return ErrorMessage(text: msg, e: e);
    }
  }

  //  _CastError: type 'xxx' is not a subtype of type 'yyy' in type cast
  print('4-------------------- other: $e');
  var msg = '${e.runtimeType}: ${e.toString()}';
  return ErrorMessage(text: msg, e: e);
}