import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Token {
  String token;

  Token({this.token});

  factory Token.fromJson(Map<String, dynamic> json) => _$TokenFromJson(json);

  Map<String, dynamic> toJson() => _$TokenToJson(this);

  static const fields = <String>['token'];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  String username;
  String avatar;
  @JsonKey(name: 'class')
  String className;
  int score;
  String loginIp;
  String lastLoginIp;
  String registerTime;
  String lastLoginTime;

  User({this.username, this.avatar, this.className, this.score, this.loginIp, this.lastLoginIp, this.registerTime, this.lastLoginTime});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  static const fields = <String>['username', 'avatar', 'class', 'score', 'login_ip', 'last_login_ip', 'register_time', 'last_login_time'];
}
