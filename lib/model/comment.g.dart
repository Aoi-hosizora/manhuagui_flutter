// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
      cid: json['cid'] as int,
      uid: json['uid'] as int,
      username: json['username'] as String,
      avatar: json['avatar'] as String,
      gender: json['gender'] as int,
      content: json['content'] as String,
      likeCount: json['like_count'] as int,
      replyCount: json['reply_count'] as int,
      commentTime: json['comment_time'] as String,
      replyTimeline: (json['reply_timeline'] as List<dynamic>)
          .map((e) => RepliedComment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
      'cid': instance.cid,
      'uid': instance.uid,
      'username': instance.username,
      'avatar': instance.avatar,
      'gender': instance.gender,
      'content': instance.content,
      'like_count': instance.likeCount,
      'reply_count': instance.replyCount,
      'comment_time': instance.commentTime,
      'reply_timeline': instance.replyTimeline,
    };

RepliedComment _$RepliedCommentFromJson(Map<String, dynamic> json) =>
    RepliedComment(
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

AddedComment _$AddedCommentFromJson(Map<String, dynamic> json) => AddedComment(
      cid: json['cid'] as int,
      mid: json['mid'] as int,
      repliedCid: json['replied_cid'] as int,
      content: json['content'] as String,
    );

Map<String, dynamic> _$AddedCommentToJson(AddedComment instance) =>
    <String, dynamic>{
      'cid': instance.cid,
      'mid': instance.mid,
      'replied_cid': instance.repliedCid,
      'content': instance.content,
    };
