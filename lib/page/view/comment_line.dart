import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/page/comment.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

enum CommentLineViewStyle {
  normal, // used in list view, will also show reply lines of given comment
  large, // used in detail view, will also be used to display replied comment
}

/// 漫画评论行，在 [MangaPage] / [CommentsPage] / [CommentPage] 使用
class CommentLineView extends StatelessWidget {
  const CommentLineView({
    Key? key,
    required this.comment,
    this.index,
    required this.style,
    required this.onPressed,
    this.onLongPressed,
  }) : super(key: key);

  /// 在 [MangaPage] / [CommentsPage] 使用
  const CommentLineView.normalWithReplies({
    Key? key,
    required Comment comment,
    required void Function() onPressed,
    void Function()? onLongPressed,
  }) : this(
          key: key,
          comment: comment,
          style: CommentLineViewStyle.normal,
          onPressed: onPressed,
          onLongPressed: onLongPressed,
        );

  /// 在 [CommentPage] 使用
  const CommentLineView.largeWithoutReplies({
    Key? key,
    required Comment comment,
    required void Function() onPressed,
    void Function()? onLongPressed,
  }) : this(
          key: key,
          comment: comment,
          style: CommentLineViewStyle.large,
          onPressed: onPressed,
          onLongPressed: onLongPressed,
        );

  /// 在 [CommentPage] 使用
  const CommentLineView.largeForReply({
    Key? key,
    required Comment comment,
    required int index,
    required void Function() onPressed,
    void Function()? onLongPressed,
  }) : this(
          key: key,
          comment: comment,
          index: index,
          style: CommentLineViewStyle.large,
          onPressed: onPressed,
          onLongPressed: onLongPressed,
        );

  final Comment comment;
  final int? index; // only for large style and replied comment
  final CommentLineViewStyle style;
  final void Function() onPressed;
  final void Function()? onLongPressed;

  bool get large => style == CommentLineViewStyle.large;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.white,
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.symmetric(horizontal: !large ? 12 : 15, vertical: !large ? 8 : 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ****************************************************************
              // 头像
              // ****************************************************************
              ClipOval(
                child: NetworkImageView(
                  url: comment.avatar,
                  height: !large ? 32 : 40,
                  width: !large ? 32 : 40,
                ),
              ),
              SizedBox(width: !large ? 12 : 15),
              SizedBox(
                width: !large
                    ? MediaQuery.of(context).size.width - 3 * 12 - 32 // | ▢ ▢▢ |
                    : MediaQuery.of(context).size.width - 3 * 15 - 40, // | ▢ ▢▢ |
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ****************************************************************
                        // 用户名 性别
                        // ****************************************************************
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  comment.username == '-' ? '匿名用户' : comment.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: !large ? Theme.of(context).textTheme.bodyText2 : Theme.of(context).textTheme.subtitle1,
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: comment.gender == 1 ? Colors.blue[300] : (comment.gender == 2 ? Colors.red[400] : Colors.transparent),
                                  borderRadius: BorderRadius.all(Radius.circular(3)),
                                ),
                                height: 18,
                                width: 18,
                                child: Center(
                                  child: Icon(
                                    comment.gender == 1 ? Icons.male : (comment.gender == 2 ? Icons.female : null),
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ****************************************************************
                        // 楼层数
                        // ****************************************************************
                        if (large /* large => always show */ || comment.replyTimeline.isNotEmpty /* normal => only show when timeline is not empty */)
                          Container(
                            margin: EdgeInsets.only(right: !large ? 8 : 0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.all(Radius.circular(3)),
                            ),
                            height: !large ? 15 : 18,
                            width: !large ? 15 : 26,
                            child: Center(
                              child: Text(
                                !large
                                    ? '${index ?? comment.replyTimeline.length + 1}' //
                                    : '#${index ?? comment.replyTimeline.length + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: !large ? 11 : 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: !large ? 8 : 15),
                    // ****************************************************************
                    // 回复评论 (only for normal style)
                    // ****************************************************************
                    if (!large && comment.replyTimeline.isNotEmpty) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        padding: EdgeInsets.only(left: 8, right: 8, top: 6, bottom: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ****************************************************************
                            // 每一楼评论
                            // ****************************************************************
                            for (var line in comment.replyTimeline.sublist(0, comment.replyTimeline.length.clamp(0, 3)))
                              Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      "${line.username == '-' ? '匿名用户' : line.username}: ",
                                      style: Theme.of(context).textTheme.bodyText2?.copyWith(color: Theme.of(context).primaryColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Expanded(
                                      child: Text(
                                        line.content,
                                        style: Theme.of(context).textTheme.bodyText2,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(left: 6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.all(Radius.circular(3)),
                                      ),
                                      height: 15,
                                      width: 15,
                                      child: Center(
                                        child: Text(
                                          (comment.replyTimeline.indexOf(line) + 1).toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (comment.replyTimeline.length > 3)
                              Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '共 ${comment.replyTimeline.length} 条评论，点击查看回复楼层',
                                  style: Theme.of(context).textTheme.bodyText2?.copyWith(color: Theme.of(context).primaryColor),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: !large ? 8 : 15),
                    ],
                    // ****************************************************************
                    // 评论内容
                    // ****************************************************************
                    Text(
                      comment.content,
                      style: !large ? Theme.of(context).textTheme.bodyText2 : Theme.of(context).textTheme.subtitle1,
                    ),
                    SizedBox(height: !large ? 8 : 15),
                    // ****************************************************************
                    // 评论数据
                    // ****************************************************************
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          comment.formattedCommentTime,
                          style: TextStyle(color: Colors.grey),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.thumb_up,
                              color: Colors.grey[400],
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(comment.likeCount.toString()),
                            SizedBox(width: 10),
                            Icon(
                              Icons.mode_comment,
                              color: Colors.grey[400],
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(comment.replyCount.toString()),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              onLongPress: onLongPressed,
            ),
          ),
        ),
      ],
    );
  }
}
