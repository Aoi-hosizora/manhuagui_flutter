import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/page/dlg/comment_dialog.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/comment_line.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';

/// 漫画评论详情页，展示所给 [Comment] 信息
class CommentPage extends StatefulWidget {
  const CommentPage({
    Key? key,
    required this.mangaId,
    required this.comment,
  }) : super(key: key);

  final int mangaId;
  final Comment comment;

  @override
  _CommentPageState createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();

  List<RepliedComment> get _replied => widget.comment.replyTimeline;
  final _newReplied = <RepliedComment>[];

  void _showPopupMenu(Comment comment, {bool alsoAdd = false}) {
    showCommentPopupMenuForListAndPage(
      context: context,
      mangaId: widget.mangaId,
      forCommentList: false,
      comment: comment,
      onReplied: (added) {
        Fluttertoast.showToast(msg: '评论回复成功');
        if (alsoAdd) {
          _newReplied.add(
            added.toRepliedComment(
              username: AuthManager.instance.username,
              time: DateTime.now(),
            ),
          );
          if (mounted) setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('评论详情'),
        leading: AppBarActionButton.leading(context: context),
        actions: [
          AppBarActionButton(
            icon: Icon(Icons.reply),
            tooltip: '回复最新评论',
            onPressed: () async {
              var added = await showCommentDialogForReplyingComment(context: context, mangaId: widget.mangaId, commentId: widget.comment.cid);
              if (added != null) {
                Fluttertoast.showToast(msg: '评论回复成功');
                _newReplied.add(
                  added.toRepliedComment(
                    username: AuthManager.instance.username,
                    time: DateTime.now(),
                  ),
                );
                if (mounted) setState(() {});
              }
            },
          ),
        ],
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
              onPressed: () => _showPopupMenu(widget.comment, alsoAdd: true),
              onLongPressed: () => _showPopupMenu(widget.comment, alsoAdd: true),
            ),
            if (_newReplied.isEmpty && _replied.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    '该评论暂无回复',
                    style: Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.grey[600]),
                  ),
                ),
              ),
            if (_newReplied.isNotEmpty) ...[
              Container(height: 12),
              for (var i = 0; i < _newReplied.length; i++) ...[
                CommentLineView.largeForReply(
                  comment: _newReplied[i].toComment(),
                  index: _replied.length + 1 + i + 1,
                  onPressed: () => _showPopupMenu(_newReplied[i].toComment()),
                  onLongPressed: () => _showPopupMenu(_newReplied[i].toComment()),
                ),
                if (i != _newReplied.length - 1)
                  Container(
                    color: Colors.white,
                    child: Divider(height: 0, thickness: 1, indent: 40 + 2.0 * 15),
                  ),
              ],
            ],
            if (_replied.isNotEmpty) ...[
              Container(height: 12),
              for (var i = 0; i < _replied.length; i++) ...[
                CommentLineView.largeForReply(
                  comment: _replied[i].toComment(),
                  index: i + 1,
                  onPressed: () => _showPopupMenu(_replied[i].toComment()),
                  onLongPressed: () => _showPopupMenu(_replied[i].toComment()),
                ),
                if (i != _replied.length - 1)
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
