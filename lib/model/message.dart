import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Message {
  final int mid;
  final String title;
  final NotificationContent? notification;
  final NewVersionContent? newVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Message({required this.mid, required this.title, required this.notification, required this.newVersion, required this.createdAt, required this.updatedAt});

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class NotificationContent {
  final String content;
  final bool dismissible;
  final String link;

  const NotificationContent({required this.content, required this.dismissible, required this.link});

  factory NotificationContent.fromJson(Map<String, dynamic> json) => _$NotificationContentFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationContentToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class NewVersionContent {
  final String version;
  final bool mustUpgrade;
  final String changeLogs;
  final String releasePage;

  const NewVersionContent({required this.version, required this.mustUpgrade, required this.changeLogs, required this.releasePage});

  factory NewVersionContent.fromJson(Map<String, dynamic> json) => _$NewVersionContentFromJson(json);

  Map<String, dynamic> toJson() => _$NewVersionContentToJson(this);
}
