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
  List<RepliedComment> replyTimeline;
  String commentTime;

  Comment({this.cid, this.uid, this.username, this.avatar, this.gender, this.content, this.likeCount, this.replyCount, this.replyTimeline, this.commentTime});

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);

  Map<String, dynamic> toJson() => _$CommentToJson(this);

  static const fields = <String>['cid', 'uid', 'username', 'avatar', 'gender', 'content', 'like_count', 'reply_count', 'reply_timeline', 'comment_time'];
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
