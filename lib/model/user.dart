import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Token {
  final String token;

  const Token({required this.token});

  factory Token.fromJson(Map<String, dynamic> json) => _$TokenFromJson(json);

  Map<String, dynamic> toJson() => _$TokenToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  final String username;
  final String avatar;
  @JsonKey(name: 'class')
  final String className;
  final int score;
  final int accountPoint;
  final int unreadMessageCount;
  final String loginIp;
  final String lastLoginIp;
  final String registerTime;
  final String lastLoginTime;
  final int cumulativeDayCount;
  final int totalCommentCount;

  const User({required this.username, required this.avatar, required this.className, required this.score, required this.accountPoint, required this.unreadMessageCount, required this.loginIp, required this.lastLoginIp, required this.registerTime, required this.lastLoginTime, required this.cumulativeDayCount, required this.totalCommentCount});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class LoginCheckResult {
  final String username;

  const LoginCheckResult({required this.username});

  factory LoginCheckResult.fromJson(Map<String, dynamic> json) => _$LoginCheckResultFromJson(json);

  Map<String, dynamic> toJson() => _$LoginCheckResultToJson(this);
}
