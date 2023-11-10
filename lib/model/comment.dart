import 'package:json_annotation/json_annotation.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/common.dart';

part 'comment.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Comment {
  final int cid;
  final int uid;
  final String username;
  final String avatar;
  final int gender;
  final String content;
  final int likeCount;
  final int replyCount;
  final String commentTime;
  final List<RepliedComment> replyTimeline;

  const Comment({required this.cid, required this.uid, required this.username, required this.avatar, required this.gender, required this.content, required this.likeCount, required this.replyCount, required this.commentTime, required this.replyTimeline});

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);

  Map<String, dynamic> toJson() => _$CommentToJson(this);

  String get formattedCommentTime => // for comment line
      parseDatetimeStringAndTrimSecond(commentTime);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RepliedComment {
  final int cid;
  final int uid;
  final String username;
  final String avatar;
  final int gender;
  final String content;
  final int likeCount;
  final int replyCount;
  final String commentTime;

  const RepliedComment({required this.cid, required this.uid, required this.username, required this.avatar, required this.gender, required this.content, required this.likeCount, required this.replyCount, required this.commentTime});

  factory RepliedComment.fromJson(Map<String, dynamic> json) => _$RepliedCommentFromJson(json);

  Map<String, dynamic> toJson() => _$RepliedCommentToJson(this);

  Comment toComment() {
    return Comment(cid: cid, uid: uid, username: username, avatar: avatar, gender: gender, content: content, likeCount: likeCount, replyCount: replyCount, commentTime: commentTime, replyTimeline: []);
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class AddedComment {
  final int cid;
  final int mid;
  final int repliedCid;
  final String content;

  const AddedComment({required this.cid, required this.mid, required this.repliedCid, required this.content});

  factory AddedComment.fromJson(Map<String, dynamic> json) => _$AddedCommentFromJson(json);

  Map<String, dynamic> toJson() => _$AddedCommentToJson(this);

  RepliedComment toRepliedComment({required String username, required DateTime time}) {
    return RepliedComment(
      cid: cid,
      uid: -1 /* <<< useless */,
      username: username,
      avatar: DEFAULT_USER_AVATAR_URL,
      gender: -1 /* <<< do not show */,
      content: content,
      likeCount: 0,
      replyCount: 0,
      commentTime: formatDatetimeAndDuration(time, FormatPattern.datetime),
    );
  }
}
