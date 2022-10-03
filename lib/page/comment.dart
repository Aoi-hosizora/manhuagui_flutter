import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/page/view/comment_line.dart';

/// 漫画评论详情页，展示所给 [Comment] 信息
class CommentPage extends StatefulWidget {
  const CommentPage({
    Key? key,
    required this.comment,
  }) : super(key: key);

  final Comment comment;

  @override
  _CommentPageState createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
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
            CommentLineView(
              comment: widget.comment,
              style: CommentLineViewStyle.large,
            ),
            if (widget.comment.replyTimeline.isNotEmpty) ...[
              Container(height: 12),
              for (var i = 0; i < widget.comment.replyTimeline.length - 1; i++) ...[
                CommentLineView(
                  comment: widget.comment.replyTimeline[i].toComment(),
                  index: i + 1,
                  style: CommentLineViewStyle.large,
                ),
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.only(left: 2.0 * 15 + 40),
                  width: MediaQuery.of(context).size.width - 3 * 15 - 40,
                  child: Divider(height: 1, thickness: 1),
                ),
              ],
              CommentLineView(
                comment: widget.comment.replyTimeline.last.toComment(),
                index: widget.comment.replyTimeline.length,
                style: CommentLineViewStyle.large,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
