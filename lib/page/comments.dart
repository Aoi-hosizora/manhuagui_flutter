import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/page/comment.dart';
import 'package:manhuagui_flutter/page/dlg/comment_dialog.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/comment_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';

/// 漫画评论列表页，网络请求并展示 [Comment] 列表信息
class CommentsPage extends StatefulWidget {
  const CommentsPage({
    Key? key,
    required this.mangaId,
    required this.mangaTitle,
  }) : super(key: key);

  final int mangaId;
  final String mangaTitle;

  @override
  _CommentsPageState createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final _pdvKey = GlobalKey<PaginationDataViewState>();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();

  @override
  void dispose() {
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  final _data = <Comment>[];
  var _total = 0;

  Future<PagedList<Comment>> _getData({required int page}) async {
    final client = RestClient(DioManager.instance.dio);
    var result = await client.getMangaComments(mid: widget.mangaId, page: page).onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
    _total = result.data.total;
    if (mounted) setState(() {});
    return PagedList(list: result.data.data, next: result.data.page + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('漫画评论'),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: false),
        actions: [
          AppBarActionButton(
            icon: Icon(Icons.add_comment),
            tooltip: '发表评论',
            onPressed: () async {
              var added = await showCommentDialogForAddingComment(context: context, mangaId: widget.mangaId);
              if (added != null) {
                var ok = await showYesNoAlertDialog(
                  context: context,
                  title: Text('发表评论'),
                  content: Text('评论发表成功，是否刷新评论列表？'),
                  yesText: Text('刷新'),
                  noText: Text('取消'),
                );
                if (ok == true) {
                  _pdvKey.currentState?.refresh();
                }
              }
            },
          ),
        ],
      ),
      drawer: AppDrawer(
        currentSelection: DrawerSelection.none,
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: PaginationListView<Comment>(
        key: _pdvKey,
        data: _data,
        getData: ({indicator}) => _getData(page: indicator),
        scrollController: _controller,
        paginationSetting: PaginationSetting(
          initialIndicator: 1,
          nothingIndicator: 0,
        ),
        setting: UpdatableDataViewSetting(
          padding: EdgeInsets.symmetric(vertical: 0),
          interactiveScrollbar: true,
          scrollbarMainAxisMargin: 2,
          scrollbarCrossAxisMargin: 2,
          placeholderSetting: PlaceholderSetting().copyWithChinese(),
          onPlaceholderStateChanged: (_, __) => _fabController.hide(),
          refreshFirst: true /* <<< refresh first */,
          clearWhenRefresh: false,
          clearWhenError: false,
          updateOnlyIfNotEmpty: false,
          onError: (e) {
            if (_data.isNotEmpty) {
              Fluttertoast.showToast(msg: e.toString());
            }
          },
        ),
        separator: Container(
          color: Colors.white,
          child: Divider(height: 0, thickness: 1, indent: 2.0 * 12 + 32),
        ),
        itemBuilder: (c, _, item) => CommentLineView.normalWithReplies(
          comment: item,
          onPressed: () => Navigator.of(context).push(
            CustomPageRoute(
              context: context,
              builder: (c) => CommentPage(
                mangaId: widget.mangaId,
                comment: item,
              ),
            ),
          ),
          onLongPressed: () => showCommentPopupMenuForListAndPage(
            context: context,
            mangaId: widget.mangaId,
            forCommentList: true,
            comment: item,
          ),
        ),
        extra: UpdatableDataViewExtraWidgets(
          innerTopWidgets: [
            ListHintView.textText(
              leftText: '《${widget.mangaTitle}》',
              rightText: '共 $_total 条评论',
            ),
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
