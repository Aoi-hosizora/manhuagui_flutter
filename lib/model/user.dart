import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:manhuagui_flutter/model/common.dart';

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

  static DateTime? _parseDateTime(String s) {
    try {
      return DateFormat('yyyy/M/d HH:mm:ss').parse(s);
    } catch (_) {
      return null;
    }
  }

  static String _formatDateTime(DateTime dt) => formatDatetimeAndDuration(dt, FormatPattern.datetime);

  static String _formatDuration(DateTime dt) => formatDatetimeAndDuration(dt, FormatPattern.durationOnlyDate);

  String get formattedRegisterTime {
    var dt = _parseDateTime(registerTime);
    if (dt == null) {
      return registerTime;
    }
    return _formatDateTime(dt); // "2023/02/02 22:24:59"
  }

  String get formattedLastLoginTimeWithDuration {
    var dt = _parseDateTime(lastLoginTime);
    if (dt == null) {
      return lastLoginTime;
    }
    return '${_formatDateTime(dt)} (${_formatDuration(dt)})'; // "2023/02/02 22:24:59 (xxx天前)" or "2023/02/02 22:24:59 (今天)"
  }

  String formattedCurrLoginTimeWithDuration(DateTime? currLoginTime) {
    var dt = currLoginTime;
    if (dt == null) {
      return '未知时间';
    }
    return '${_formatDateTime(dt)} (${_formatDuration(dt)})'; // "2023/02/02 22:24:59 (xxx天前)" or "2023/02/02 22:24:59 (今天)"
  }

  bool isTodayLogined(DateTime? currLoginTime) {
    var last = _parseDateTime(lastLoginTime);
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
