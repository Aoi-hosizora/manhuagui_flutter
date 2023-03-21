import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/page/comment.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/comment_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';

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
      ),
      drawer: AppDrawer(
        currentSelection: DrawerSelection.none,
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: PaginationListView<Comment>(
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
                comment: item,
              ),
            ),
          ),
          onLongPressed: () => showDialog(
            context: context,
            builder: (c) => SimpleDialog(
              title: Text(item.content, maxLines: 2, overflow: TextOverflow.ellipsis),
              children: [
                IconTextDialogOption(
                  icon: Icon(Icons.comment_outlined),
                  text: Text('查看评论详情'),
                  onPressed: () {
                    Navigator.of(c).pop();
                    Navigator.of(context).push(
                      CustomPageRoute(
                        context: context,
                        builder: (c) => CommentPage(
                          comment: item,
                        ),
                      ),
                    );
                  },
                ),
                IconTextDialogOption(
                  icon: Icon(Icons.copy),
                  text: Text('复制评论内容'),
                  onPressed: () {
                    Navigator.of(c).pop();
                    copyText(item.content, showToast: true);
                  },
                ),
              ],
            ),
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
