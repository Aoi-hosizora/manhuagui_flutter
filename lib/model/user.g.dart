// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Token _$TokenFromJson(Map<String, dynamic> json) {
  return Token(
    token: json['token'] as String,
  );
}

Map<String, dynamic> _$TokenToJson(Token instance) => <String, dynamic>{
      'token': instance.token,
    };

User _$UserFromJson(Map<String, dynamic> json) {
  return User(
    username: json['username'] as String,
    avatar: json['avatar'] as String,
    className: json['class'] as String,
    score: json['score'] as int,
    loginIp: json['login_ip'] as String,
    lastLoginIp: json['last_login_ip'] as String,
    registerTime: json['register_time'] as String,
    lastLoginTime: json['last_login_time'] as String,
  );
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'username': instance.username,
      'avatar': instance.avatar,
      'class': instance.className,
      'score': instance.score,
      'login_ip': instance.loginIp,
      'last_login_ip': instance.lastLoginIp,
      'register_time': instance.registerTime,
      'last_login_time': instance.lastLoginTime,
    };


LoginCheckResult _$LoginCheckResultFromJson(Map<String, dynamic> json) {
  return LoginCheckResult(
    username: json['username'] as String,
  );
}

Map<String, dynamic> _$LoginCheckResultToJson(LoginCheckResult instance) => <String, dynamic>{
  'username': instance.username,
};