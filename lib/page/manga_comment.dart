import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/page/view/comment_line.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';

class MangaCommentPage extends StatefulWidget {
  const MangaCommentPage({
    Key? key,
    required this.mid,
  }) : super(key: key);

  final int mid;

  @override
  _MangaCommentPageState createState() => _MangaCommentPageState();
}

class _MangaCommentPageState extends State<MangaCommentPage> {
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
    var result = await client.getMangaComments(mid: widget.mid, page: page).onError((e, s) {
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
        title: Text('漫画评论 (共 $_total 条)'),
      ),
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
          placeholderSetting: PlaceholderSetting().copyWithChinese(),
          onPlaceholderStateChanged: (_, __) => _fabController.hide(),
          interactiveScrollbar: true,
          scrollbarCrossAxisMargin: 2,
          refreshFirst: true,
          clearWhenRefresh: false,
          clearWhenError: false,
          updateOnlyIfNotEmpty: false,
          onAppend: (l, _) {
            if (l.length > 0) {
              Fluttertoast.showToast(msg: '新添了 ${l.length} 条评论');
            }
          },
          onError: (e) {
            if (_data.isNotEmpty) {
              Fluttertoast.showToast(msg: e.toString());
            }
          },
        ),
        separator: Container(
          margin: EdgeInsets.only(left: 2.0 * 12 + 32),
          width: MediaQuery.of(context).size.width - 3 * 12 - 32,
          child: Divider(height: 1, thickness: 1),
        ),
        itemBuilder: (c, _, item) => CommentLineView(comment: item),
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
