import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/page/image_viewer.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/comment_line.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';

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

  void _showPopupMenu(Comment comment) {
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(
          comment.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          IconTextDialogOption(
            icon: Icon(Icons.copy),
            text: Text('复制评论内容'),
            onPressed: () {
              Navigator.of(c).pop();
              copyText(comment.content, showToast: true);
            },
          ),
          IconTextDialogOption(
            icon: Icon(Icons.copy),
            text: Text('复制用户名'),
            onPressed: () {
              Navigator.of(c).pop();
              copyText(comment.username == '-' ? '匿名用户' : comment.username, showToast: true);
            },
          ),
          IconTextDialogOption(
            icon: Icon(Icons.account_circle),
            text: Text('查看用户头像'),
            onPressed: () {
              Navigator.of(c).pop();
              Navigator.of(context).push(
                CustomPageRoute(
                  context: context,
                  builder: (c) => ImageViewerPage(
                    url: comment.avatar,
                    title: '用户头像',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('评论详情'),
        leading: AppBarActionButton.leading(context: context),
      ),
      drawer: AppDrawer(
        currentSelection: DrawerSelection.none,
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: ExtendedScrollbar(
        controller: _controller,
        interactive: true,
        mainAxisMargin: 2,
        crossAxisMargin: 2,
        child: ListView(
          controller: _controller,
          padding: EdgeInsets.zero,
          physics: AlwaysScrollableScrollPhysics(),
          children: [
            CommentLineView.largeWithoutReplies(
              comment: widget.comment,
              onPressed: () => _showPopupMenu(widget.comment),
              onLongPressed: () => _showPopupMenu(widget.comment),
            ),
            if (widget.comment.replyTimeline.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    '该评论暂无回复',
                    style: Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.grey[600]),
                  ),
                ),
              ),
            if (widget.comment.replyTimeline.isNotEmpty) ...[
              Container(height: 12),
              for (var i = 0; i < widget.comment.replyTimeline.length; i++) ...[
                CommentLineView.largeForReply(
                  comment: widget.comment.replyTimeline[i].toComment(),
                  index: i + 1,
                  onPressed: () => _showPopupMenu(widget.comment.replyTimeline[i].toComment()),
                  onLongPressed: () => _showPopupMenu(widget.comment.replyTimeline[i].toComment()),
                ),
                if (i != widget.comment.replyTimeline.length - 1)
                  Container(
                    color: Colors.white,
                    child: Divider(height: 0, thickness: 1, indent: 40 + 2.0 * 15),
                  ),
              ],
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
