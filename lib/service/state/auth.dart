import 'package:manhuagui_flutter/service/state/notifiable.dart';

class AuthState extends NotifiableData {
  AuthState._();

  static AuthState _instance;

  static AuthState get instance => _instance ??= AuthState._();

  @override
  String get dataKey => 'AuthState';

  /// 全局 token
  String token;

  /// 是否登录
  bool get logined => token?.isNotEmpty == true;
}
