import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/page/comment.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

/// View for [Comment].
/// Used in [MangaPage] and [CommentPage].
class CommentLineView extends StatefulWidget {
  const CommentLineView({
    Key key,
    @required this.comment,
  })  : assert(comment != null),
        super(key: key);

  final Comment comment;

  @override
  _CommentLineViewState createState() => _CommentLineViewState();
}

class _CommentLineViewState extends State<CommentLineView> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.only(top: 10, bottom: 10, left: 12, right: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ****************************************************************
              // 头像
              // ****************************************************************
              ClipOval(
                child: NetworkImageView(
                  url: widget.comment.avatar,
                  height: 32,
                  width: 32,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ****************************************************************
                  // 第一行
                  // ****************************************************************
                  Container(
                    width: MediaQuery.of(context).size.width - 3 * 12 - 32, // | ▢▢ ▢▢▢▢▢ |
                    child: Row(
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
                                  widget.comment.username == '-' ? '匿名用户' : widget.comment.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: widget.comment.gender == 1 ? Colors.blue[300] : Colors.red[400],
                                  borderRadius: BorderRadius.all(Radius.circular(3)),
                                ),
                                height: 18,
                                width: 18,
                                child: Center(
                                  child: Text(
                                    widget.comment.gender == 1 ? '♂' : '♀',
                                    style: TextStyle(fontSize: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ****************************************************************
                        // 楼层
                        // ****************************************************************
                        if (widget.comment.replyTimeline.length > 0)
                          Container(
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.all(Radius.circular(3)),
                            ),
                            height: 15,
                            width: 15,
                            child: Center(
                              child: Text(
                                (widget.comment.replyTimeline.length + 1).toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  // ****************************************************************
                  // 评论内容
                  // ****************************************************************
                  Container(
                    width: MediaQuery.of(context).size.width - 3 * 12 - 32,
                    child: Text(
                      widget.comment.content,
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                  ),
                  if (widget.comment.replyTimeline.length > 0) SizedBox(height: 10),
                  // ****************************************************************
                  // 楼层
                  // ****************************************************************
                  if (widget.comment.replyTimeline.length > 0)
                    Container(
                      width: MediaQuery.of(context).size.width - 3 * 12 - 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.all(Radius.circular(1.5)),
                      ),
                      padding: EdgeInsets.only(left: 8, right: 8, top: 6, bottom: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ****************************************************************
                          // 每一楼
                          // ****************************************************************
                          for (var line in widget.comment.replyTimeline.sublist(0, widget.comment.replyTimeline.length <= 3 ? widget.comment.replyTimeline.length : 3))
                            Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Text(
                                    "${line.username == '-' ? '匿名用户' : line.username}: ",
                                    style: TextStyle(
                                      fontSize: Theme.of(context).textTheme.bodyText1.fontSize,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Expanded(
                                    child: Text(
                                      line.content,
                                      style: TextStyle(fontSize: Theme.of(context).textTheme.bodyText1.fontSize),
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
                                        (widget.comment.replyTimeline.indexOf(line) + 1).toString(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (widget.comment.replyTimeline.length > 3)
                            Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Text(
                                '点击查看该楼层... (共 ${widget.comment.replyTimeline.length} 条评论)',
                                style: Theme.of(context).textTheme.bodyText1.copyWith(color: Theme.of(context).primaryColor),
                              ),
                            ),
                        ],
                      ),
                    ),
                  SizedBox(height: 10),
                  // ****************************************************************
                  // 评论信息
                  // ****************************************************************
                  Container(
                    width: MediaQuery.of(context).size.width - 3 * 12 - 32,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.comment.commentTime,
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
                            Text(widget.comment.likeCount.toString()),
                            SizedBox(width: 10),
                            Icon(
                              Icons.chat_bubble,
                              color: Colors.grey[400],
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(widget.comment.replyCount.toString()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // ****************************************************************
        // 点击效果
        // ****************************************************************
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (c) => CommentPage(
                    comment: widget.comment,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
