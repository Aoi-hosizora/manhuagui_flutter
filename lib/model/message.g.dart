// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      mid: json['mid'] as int,
      title: json['title'] as String,
      notification: json['notification'] == null
          ? null
          : NotificationContent.fromJson(
              json['notification'] as Map<String, dynamic>),
      newVersion: json['new_version'] == null
          ? null
          : NewVersionContent.fromJson(
              json['new_version'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'mid': instance.mid,
      'title': instance.title,
      'notification': instance.notification,
      'new_version': instance.newVersion,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

NotificationContent _$NotificationContentFromJson(Map<String, dynamic> json) =>
    NotificationContent(
      content: json['content'] as String,
      dismissible: json['dismissible'] as bool,
      link: json['link'] as String,
    );

Map<String, dynamic> _$NotificationContentToJson(
        NotificationContent instance) =>
    <String, dynamic>{
      'content': instance.content,
      'dismissible': instance.dismissible,
      'link': instance.link,
    };

NewVersionContent _$NewVersionContentFromJson(Map<String, dynamic> json) =>
    NewVersionContent(
      version: json['version'] as String,
      mustUpgrade: json['must_upgrade'] as bool,
      changeLogs: json['change_logs'] as String,
      releasePage: json['release_page'] as String,
    );

Map<String, dynamic> _$NewVersionContentToJson(NewVersionContent instance) =>
    <String, dynamic>{
      'version': instance.version,
      'must_upgrade': instance.mustUpgrade,
      'change_logs': instance.changeLogs,
      'release_page': instance.releasePage,
    };

LatestMessage _$LatestMessageFromJson(Map<String, dynamic> json) =>
    LatestMessage(
      notification: json['notification'] == null
          ? null
          : Message.fromJson(json['notification'] as Map<String, dynamic>),
      newVersion: json['new_version'] == null
          ? null
          : Message.fromJson(json['new_version'] as Map<String, dynamic>),
      notDismissibleNotification: json['not_dismissible_notification'] == null
          ? null
          : Message.fromJson(
              json['not_dismissible_notification'] as Map<String, dynamic>),
      mustUpgradeNewVersion: json['must_upgrade_new_version'] == null
          ? null
          : Message.fromJson(
              json['must_upgrade_new_version'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LatestMessageToJson(LatestMessage instance) =>
    <String, dynamic>{
      'notification': instance.notification,
      'new_version': instance.newVersion,
      'not_dismissible_notification': instance.notDismissibleNotification,
      'must_upgrade_new_version': instance.mustUpgradeNewVersion,
    };
