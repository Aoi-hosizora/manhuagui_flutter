import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/page/comment.dart';
import 'package:manhuagui_flutter/page/image_viewer.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';

/// 漫画页/评论列表页/论详情页-漫画评论弹出对话框 [showCommentPopupMenuForListAndPage]
/// 漫画页/评论列表页/评论详情页-发表评论对话框 [showCommentDialogForAddingComment]
/// 漫画页/评论列表页/评论详情页-回复评论对话框 [showCommentDialogForReplyingComment]

void showCommentPopupMenuForListAndPage({
  required BuildContext context,
  required int mangaId,
  required Comment comment,
  required bool forCommentList,
  void Function(AddedComment)? onReplied,
  void Function(Future<void> Function() navigate)? pushNavigateWrapper,
}) {
  showDialog(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text(
        comment.content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      children: [
        if (forCommentList)
          IconTextDialogOption(
            icon: Icon(Icons.comment_outlined),
            text: Text('查看评论详情'),
            onPressed: () {
              if (!AuthManager.instance.logined) {
                Fluttertoast.showToast(msg: '用户未登录');
                return;
              }
              Navigator.of(c).pop();
              var f = () => Navigator.of(context).push(
                    CustomPageRoute(
                      context: context,
                      builder: (c) => CommentPage(
                        mangaId: mangaId,
                        comment: comment,
                      ),
                    ),
                  );
              if (pushNavigateWrapper == null) {
                f();
              } else {
                pushNavigateWrapper.call(f);
              }
            },
          ),
        IconTextDialogOption(
          icon: Icon(Icons.thumb_up_alt),
          text: Text('点赞评论'),
          onPressed: () async {
            Navigator.of(c).pop();
            final client = RestClient(DioManager.instance.dio);
            try {
              await client.likeComment(cid: comment.cid);
              Fluttertoast.showToast(msg: '点赞成功，点赞结果需要等待几分钟才会显示');
            } catch (e, s) {
              var we = wrapError(e, s);
              Fluttertoast.showToast(msg: '点赞失败：${we.text}');
            }
          },
        ),
        IconTextDialogOption(
          icon: Icon(Icons.reply),
          text: Text('回复评论'),
          onPressed: () async {
            Navigator.of(c).pop();
            var added = await showCommentDialogForReplyingComment(context: context, mangaId: mangaId, commentId: comment.cid);
            if (added != null) {
              onReplied?.call(added);
            } else {
              Fluttertoast.showToast(msg: '评论回复成功');
            }
          },
        ),
        Divider(height: 16, thickness: 1),
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
                  ignoreSystemUI: pushNavigateWrapper != null,
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}

Future<AddedComment?> showCommentDialogForAddingComment({
  required BuildContext context,
  required int mangaId,
}) async {
  return await _showCommentDialog(
    context: context,
    title: '发表评论',
    mangaId: mangaId,
    commentId: 0,
  );
}

Future<AddedComment?> showCommentDialogForReplyingComment({
  required BuildContext context,
  required int mangaId,
  required int commentId,
}) async {
  return await _showCommentDialog(
    context: context,
    title: '回复评论',
    mangaId: mangaId,
    commentId: commentId,
  );
}

Future<AddedComment?> _showCommentDialog({
  required BuildContext context,
  required String title,
  required int mangaId,
  required int commentId,
}) async {
  var controller = TextEditingController()..text;
  var ok = await showDialog<bool>(
    context: context,
    builder: (c) => WillPopScope(
      onWillPop: () async {
        if (controller.text.trim() == '') {
          return true;
        }
        var ok = await showYesNoAlertDialog(
          context: context,
          title: Text(title),
          content: Text('是否放弃当前的输入？'),
          yesText: Text('放弃'),
          noText: Text('继续编辑'),
          reverseYesNoOrder: true,
        );
        return ok == true;
      },
      child: AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: getDialogContentMaxWidth(context),
          child: TextField(
            controller: controller,
            maxLines: null,
            autofocus: true,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 5),
              labelText: '评论内容',
              icon: Icon(Icons.comment_outlined),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text('确定'),
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                Fluttertoast.showToast(msg: '不允许发表空评论');
              } else {
                Navigator.of(c).pop(true);
              }
            },
          ),
          TextButton(
            child: Text('取消'),
            onPressed: () => Navigator.of(c).maybePop(false),
          ),
        ],
      ),
    ),
  );
  if (ok != true) {
    return null;
  }

  var content = controller.text.trim();
  if (content == '') {
    return null;
  }
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (c) => WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: CircularProgressDialogOption(
          progress: CircularProgressIndicator(),
          child: Text('发表评论中...\n\n$content'),
        ),
      ),
    ),
  );

  final client = RestClient(DioManager.instance.dio);
  try {
    var r = commentId == 0 //
        ? await client.addComment(token: AuthManager.instance.token, mid: mangaId, text: content)
        : await client.replyComment(token: AuthManager.instance.token, mid: mangaId, cid: commentId, text: content);
    return r.data;
  } catch (e, s) {
    var we = wrapError(e, s);
    Fluttertoast.showToast(msg: '评论发表失败：${we.text}');
    return null;
  } finally {
    Navigator.of(context).pop();
  }
}
