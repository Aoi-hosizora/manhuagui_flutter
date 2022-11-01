import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/page/comment.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';

enum CommentLineViewStyle {
  normal, // used in list view, will also show reply lines of given comment
  large, // used in detail view, will also be used to display replied comment
}

/// 漫画评论行，在 [MangaPage] / [MangaCommentsPage] / [CommentPage] 使用
class CommentLineView extends StatelessWidget {
  const CommentLineView({
    Key? key,
    required this.comment,
    this.replies,
    this.index,
    required this.style,
  }) : super(key: key);

  final Comment comment;
  final List<RepliedComment>? replies; // only for normal
  final int? index; // only for large replied comment
  final CommentLineViewStyle style;

  bool get large => style == CommentLineViewStyle.large;

  Widget _buildReplyLines({required BuildContext context}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.all(Radius.circular(1.5)),
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
                '共 ${comment.replyTimeline.length} 条评论，点击查看该楼层...',
                style: Theme.of(context).textTheme.bodyText2?.copyWith(color: Theme.of(context).primaryColor),
              ),
            ),
        ],
      ),
    );
  }

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
                                  color: comment.gender == 1 ? Colors.blue[300] : Colors.red[400],
                                  borderRadius: BorderRadius.all(Radius.circular(3)),
                                ),
                                height: 18,
                                width: 18,
                                child: Center(
                                  child: Text(
                                    comment.gender == 1 ? '♂' : '♀',
                                    style: TextStyle(fontSize: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ****************************************************************
                        // 楼层数
                        // ****************************************************************
                        if (comment.replyTimeline.isNotEmpty)
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
                    // 评论内容
                    // ****************************************************************
                    Text(
                      comment.content,
                      style: !large ? Theme.of(context).textTheme.bodyText2 : Theme.of(context).textTheme.subtitle1,
                    ),
                    SizedBox(height: !large ? 8 : 15),
                    // ****************************************************************
                    // 回复评论
                    // ****************************************************************
                    if (!large && comment.replyTimeline.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: _buildReplyLines(context: context),
                      ),
                    // ****************************************************************
                    // 评论数据
                    // ****************************************************************
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          comment.commentTime,
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
                              Icons.chat_bubble,
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
              onTap: !large
                  ? () => Navigator.of(context).push(
                        CustomMaterialPageRoute(
                          context: context,
                          builder: (c) => CommentPage(
                            comment: comment,
                          ),
                        ),
                      )
                  : () => copyText(comment.content),
            ),
          ),
        ),
      ],
    );
  }
}
