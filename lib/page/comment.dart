import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
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
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('评论详情'),
        leading: AppBarActionButton.leading(context: context),
      ),
      body: ScrollbarWithMore(
        controller: _controller,
        interactive: true,
        crossAxisMargin: 2,
        child: ListView(
          controller: _controller,
          padding: EdgeInsets.zero,
          physics: AlwaysScrollableScrollPhysics(),
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
                  child: Divider(height: 0, thickness: 1, indent: 40 + 2.0 * 15),
                )
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
      floatingActionButton: ScrollAnimatedFab(
        controller: _fabController,
        scrollController: _controller,
        condition: ScrollAnimatedCondition.direction,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: null,
          onPressed: () => _controller.scrollToTop(),
        ),
      ),
    );
  }
}
