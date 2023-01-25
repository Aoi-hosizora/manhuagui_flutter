import 'package:intl/intl.dart';
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

  static DateTime? stringToDateTime(String s) {
    if (s.isEmpty) {
      return null;
    }
    var df = DateFormat('yyyy/M/d HH:mm:ss');
    try {
      return df.parse(s);
    } catch (_) {
      return null;
    }
  }

  static String formatDateTime(DateTime dt) {
    var df = DateFormat('yyyy-MM-dd HH:mm:ss');
    return df.format(dt);
  }

  static String formatDuration(DateTime old) {
    var now = DateTime.now();
    now = DateTime(now.year, now.month, now.day);
    old = DateTime(old.year, old.month, old.day);
    var du = now.difference(old);
    if (du.inDays == 0) {
      return '今天';
    }
    return '${du.inDays}天前';
  }

  String get formattedRegisterDateTime {
    var dt = stringToDateTime(registerTime);
    if (dt == null) {
      return registerTime;
    }
    return formatDateTime(dt);
  }

  String get formattedLastLoginDateTimeWithDuration {
    var dt = stringToDateTime(lastLoginTime);
    if (dt == null) {
      return lastLoginTime;
    }
    return '${formatDateTime(dt)} (${formatDuration(dt)})';
  }

  String formattedCurrLoginDateTimeWithDuration(DateTime? currLoginTime) {
    var dt = currLoginTime;
    if (dt == null) {
      return '未知';
    }
    return '${formatDateTime(dt)} (${formatDuration(dt)})';
  }

  bool isTodayLogined(DateTime? currLoginTime) {
    var last = stringToDateTime(lastLoginTime);
    var curr = currLoginTime;
    var now = DateTime.now();
    var logined = false;
    logined = logined || (last != null && last.year == now.year && last.month == now.month && last.day == now.day);
    logined = logined || (curr != null && curr.year == now.year && curr.month == now.month && curr.day == now.day);
    return logined;
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class LoginCheckResult {
  final String username;

  const LoginCheckResult({required this.username});

  factory LoginCheckResult.fromJson(Map<String, dynamic> json) => _$LoginCheckResultFromJson(json);

  Map<String, dynamic> toJson() => _$LoginCheckResultToJson(this);
}
