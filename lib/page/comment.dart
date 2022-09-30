import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/service/natives/clipboard.dart';

/// 评论详情页
class CommentPage extends StatefulWidget {
  const CommentPage({
    Key? key,
    required this.comment,
  })  : assert(comment != null),
        super(key: key);

  final Comment comment;

  @override
  _CommentPageState createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  Widget _buildLine({required RepliedComment comment, required int idx}) {
    assert(comment != null);
    assert(idx != null);
    return Stack(
      children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.only(top: 15, bottom: 15, left: 15, right: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: NetworkImageView(
                  url: comment.avatar,
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ****************************************************************
                  // 第一行
                  // ****************************************************************
                  Container(
                    width: MediaQuery.of(context).size.width - 3 * 15 - 40, // | ▢▢ ▢▢▢▢▢ |
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
                                  comment.username == '-' ? '匿名用户' : comment.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.subtitle1,
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
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.all(Radius.circular(3)),
                          ),
                          height: 18,
                          width: 26,
                          child: Center(
                            child: Text(
                              '#$idx',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  // ****************************************************************
                  // 评论内容
                  // ****************************************************************
                  Container(
                    width: MediaQuery.of(context).size.width - 3 * 15 - 40,
                    child: Text(
                      comment.content,
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  SizedBox(height: 15),
                  // ****************************************************************
                  // 评论数据
                  // ****************************************************************
                  Container(
                    width: MediaQuery.of(context).size.width - 3 * 15 - 40,
                    child: Row(
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
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => copyText(comment.content),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('评论详情'),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        child: ListView(
          children: [
            _buildLine(
              comment: widget.comment.toRepliedComment(),
              idx: widget.comment.replyTimeline.length + 1,
            ),
            Container(height: 12),
            if (widget.comment.replyTimeline.length > 0)
              for (var i = 0; i < widget.comment.replyTimeline.length - 1; i++) ...[
                _buildLine(
                  comment: widget.comment.replyTimeline[i],
                  idx: i + 1,
                ),
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.only(left: 2.0 * 15 + 40),
                  width: MediaQuery.of(context).size.width - 3 * 15 - 40,
                  child: Divider(height: 1, thickness: 1),
                ),
              ],
            if (widget.comment.replyTimeline.length > 0)
              _buildLine(
                comment: widget.comment.replyTimeline.last,
                idx: widget.comment.replyTimeline.length,
              ),
          ],
        ),
      ),
    );
  }
}
