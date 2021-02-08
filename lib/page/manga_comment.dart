import 'package:flutter/material.dart';
import 'package:flutter_ahlib/list.dart';
import 'package:flutter_ahlib/widget.dart';
import 'package:flutter_ahlib/util.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/page/view/comment_line.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';

class MangaCommentPage extends StatefulWidget {
  const MangaCommentPage({
    Key key,
    @required this.mid,
  })  : assert(mid != null),
        super(key: key);

  final int mid;

  @override
  _MangaCommentPageState createState() => _MangaCommentPageState();
}

class _MangaCommentPageState extends State<MangaCommentPage> {
  ScrollController _controller;
  UpdatableDataViewController _udvController;
  AnimatedFabController _fabController;
  var _data = <Comment>[];
  int _total;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _udvController = UpdatableDataViewController();
    _fabController = AnimatedFabController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<PagedList<Comment>> _getData({int page}) async {
    var dio = DioManager.instance.dio;
    var client = RestClient(dio);
    ErrorMessage err;
    var result = await client.getMangaComments(mid: widget.mid, page: page).catchError((e) {
      err = wrapError(e);
    });
    if (err != null) {
      return Future.error(err.text);
    }
    _total = result.data.total;
    if (mounted) setState(() {});
    return PagedList(list: result.data.data, next: result.data.page + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: Text('漫画评论${_total == null ? '' : ' (共 $_total 条)'}'),
      ),
      body: PaginationListView<Comment>(
        data: _data,
        getData: ({indicator}) => _getData(page: indicator),
        scrollController: _controller,
        controller: _udvController,
        paginationSetting: PaginationSetting(
          initialIndicator: 1,
          nothingIndicator: 0,
        ),
        setting: UpdatableDataViewSetting(
          padding: EdgeInsets.zero,
          placeholderSetting: PlaceholderSetting().toChinese(),
          refreshFirst: true,
          clearWhenError: false,
          clearWhenRefresh: false,
          updateOnlyIfNotEmpty: false,
          onStateChanged: (_, __) => _fabController.hide(),
          onAppend: (l) {
            if (l.length > 0) {
              Fluttertoast.showToast(msg: '新添了 ${l.length} 条评论');
            }
          },
          onError: (e) => Fluttertoast.showToast(msg: e.toString()),
        ),
        separator: Container(
          margin: EdgeInsets.only(left: 2.0 * 12 + 32),
          width: MediaQuery.of(context).size.width - 3 * 12 - 32,
          child: Divider(height: 1, thickness: 1),
        ),
        itemBuilder: (c, item) => CommentLineView(comment: item),
      ),
      floatingActionButton: ScrollAnimatedFab(
        controller: _fabController,
        scrollController: _controller,
        condition: ScrollAnimatedCondition.direction,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: 'MangaCommentPage',
          onPressed: () => _controller.scrollToTop(),
        ),
      ),
    );
  }
}
