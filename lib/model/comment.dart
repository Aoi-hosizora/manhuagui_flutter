import 'package:json_annotation/json_annotation.dart';

part 'comment.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Comment {
  int cid;
  int uid;
  String username;
  String avatar;
  int gender;
  String content;
  int likeCount;
  int replyCount;
  String commentTime;
  List<RepliedComment> replyTimeline;

  Comment({this.cid, this.uid, this.username, this.avatar, this.gender, this.content, this.likeCount, this.replyCount, this.commentTime, this.replyTimeline});

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);

  Map<String, dynamic> toJson() => _$CommentToJson(this);

  static const fields = <String>['cid', 'uid', 'username', 'avatar', 'gender', 'content', 'like_count', 'reply_count', 'comment_time', 'reply_timeline'];

  RepliedComment toRepliedComment() {
    return RepliedComment(cid: cid, uid: uid, username: username, avatar: avatar, gender: gender, content: content, likeCount: likeCount, replyCount: replyCount, commentTime: commentTime);
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RepliedComment {
  int cid;
  int uid;
  String username;
  String avatar;
  int gender;
  String content;
  int likeCount;
  int replyCount;
  String commentTime;

  RepliedComment({this.cid, this.uid, this.username, this.avatar, this.gender, this.content, this.likeCount, this.replyCount, this.commentTime});

  factory RepliedComment.fromJson(Map<String, dynamic> json) => _$RepliedCommentFromJson(json);

  Map<String, dynamic> toJson() => _$RepliedCommentToJson(this);

  static const fields = <String>['cid', 'uid', 'username', 'avatar', 'gender', 'content', 'like_count', 'reply_count', 'comment_time'];
}
