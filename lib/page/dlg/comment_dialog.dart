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
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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
              if (onReplied != null) {
                onReplied.call(added);
              } else {
                Fluttertoast.showToast(msg: '评论回复成功');
              }
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
          icon: Icon(MdiIcons.selectCompare),
          text: Text('选择评论内容'),
          onPressed: () {
            Navigator.of(c).pop();
            showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: Text((comment.username == '-' ? '匿名用户' : '"${comment.username}" ') + '的评论内容'),
                content: SelectableText(comment.content),
                actions: [
                  TextButton(
                    child: Text('提取链接'),
                    onPressed: () {}, // TODO
                  ),
                  TextButton(
                    child: Text('复制内容'),
                    onPressed: () => copyText(comment.content, showToast: true),
                  ),
                  TextButton(
                    child: Text('确定'),
                    onPressed: () => Navigator.of(c).pop(),
                  ),
                ],
              ),
            );
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
  var content = await _showCreatingCommentDialog(context: context, title: '发表评论', mangaId: mangaId);
  if (content == null || content.isEmpty) {
    return null;
  }
  _showCommentProgressDialog(context: context, content: content);

  final client = RestClient(DioManager.instance.dio);
  try {
    var r = await client.addComment(token: AuthManager.instance.token, mid: mangaId, text: content);
    return r.data;
  } catch (e, s) {
    var we = wrapError(e, s);
    Fluttertoast.showToast(msg: '评论发表失败：${we.text}');
    return null;
  } finally {
    Navigator.of(context).pop(); // pop progress
  }
}

Future<AddedComment?> showCommentDialogForReplyingComment({
  required BuildContext context,
  required int mangaId,
  required int commentId,
}) async {
  var content = await _showCreatingCommentDialog(context: context, title: '回复评论', mangaId: mangaId);
  if (content == null || content.isEmpty) {
    return null;
  }
  _showCommentProgressDialog(context: context, content: content);

  final client = RestClient(DioManager.instance.dio);
  try {
    var r = await client.replyComment(token: AuthManager.instance.token, mid: mangaId, cid: commentId, text: content);
    return r.data;
  } catch (e, s) {
    var we = wrapError(e, s);
    Fluttertoast.showToast(msg: '评论回复失败：${we.text}');
    return null;
  } finally {
    Navigator.of(context).pop(); // pop progress
  }
}

Future<String?> _showCreatingCommentDialog({
  required BuildContext context,
  required String title,
  required int mangaId,
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
  return content;
}

void _showCommentProgressDialog({
  required BuildContext context,
  required String content,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (c) => WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: CircularProgressDialogOption(
          progress: CircularProgressIndicator(),
          child: Text('评论发送中...\n\n$content'),
        ),
      ),
    ),
  );
}
