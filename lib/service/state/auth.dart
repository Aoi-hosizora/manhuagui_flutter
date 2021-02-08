import 'package:flutter_ahlib/util.dart';

class AuthState extends NotifiableData {
  AuthState._();

  static AuthState _instance;

  static AuthState get instance => _instance ??= AuthState._();

  /// 全局 token
  String token;

  /// 全局用户名
  String username;

  /// 是否登录
  bool get logined => token?.isNotEmpty == true;
}
