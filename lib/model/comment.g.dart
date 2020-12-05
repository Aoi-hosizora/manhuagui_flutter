// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) {
  return Comment(
    cid: json['cid'] as int,
    uid: json['uid'] as int,
    username: json['username'] as String,
    avatar: json['avatar'] as String,
    gender: json['gender'] as int,
    content: json['content'] as String,
    likeCount: json['like_count'] as int,
    replyCount: json['reply_count'] as int,
    replyTimeline: (json['reply_timeline'] as List)
        ?.map((e) => e == null
            ? null
            : RepliedComment.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    commentTime: json['comment_time'] as String,
  );
}

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
      'cid': instance.cid,
      'uid': instance.uid,
      'username': instance.username,
      'avatar': instance.avatar,
      'gender': instance.gender,
      'content': instance.content,
      'like_count': instance.likeCount,
      'reply_count': instance.replyCount,
      'reply_timeline': instance.replyTimeline,
      'comment_time': instance.commentTime,
    };

RepliedComment _$RepliedCommentFromJson(Map<String, dynamic> json) {
  return RepliedComment(
    cid: json['cid'] as int,
    uid: json['uid'] as int,
    username: json['username'] as String,
    avatar: json['avatar'] as String,
    gender: json['gender'] as int,
    content: json['content'] as String,
    likeCount: json['like_count'] as int,
    replyCount: json['reply_count'] as int,
    commentTime: json['comment_time'] as String,
  );
}

Map<String, dynamic> _$RepliedCommentToJson(RepliedComment instance) =>
    <String, dynamic>{
      'cid': instance.cid,
      'uid': instance.uid,
      'username': instance.username,
      'avatar': instance.avatar,
      'gender': instance.gender,
      'content': instance.content,
      'like_count': instance.likeCount,
      'reply_count': instance.replyCount,
      'comment_time': instance.commentTime,
    };
