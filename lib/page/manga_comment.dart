import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
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
  ScrollMoreController _controller;
  ScrollFabController _fabController;
  var _data = <Comment>[];
  int _total;

  @override
  void initState() {
    super.initState();
    _controller = ScrollMoreController();
    _fabController = ScrollFabController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<List<Comment>> _getData({int page}) async {
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
    return result.data.data;
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
        controller: _controller,
        data: _data,
        strategy: PaginationStrategy.offsetBased,
        getDataByOffset: _getData,
        initialPage: 1,
        onAppend: (l) => doIf(l.length > 0, () => Fluttertoast.showToast(msg: '新添了 ${l.length} 条评论')),
        onError: (e) => Fluttertoast.showToast(msg: e.toString()),
        clearWhenRefreshing: false,
        clearWhenError: false,
        updateOnlyIfNotEmpty: false,
        refreshFirst: true,
        placeholderSetting: PlaceholderSetting().toChinese(),
        onStateChanged: (_, __) => _fabController.hide(),
        padding: EdgeInsets.zero,
        physics: AlwaysScrollableScrollPhysics(),
        separator: Container(
          margin: EdgeInsets.only(left: 2.0 * 12 + 32),
          width: MediaQuery.of(context).size.width - 3 * 12 - 32,
          child: Divider(height: 1, thickness: 1),
        ),
        itemBuilder: (c, item) => CommentLineView(comment: item),
      ),
      floatingActionButton: ScrollFloatingActionButton(
        scrollController: _controller,
        fabController: _fabController,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: 'MangaCommentPage',
          onPressed: () => _controller.scrollTop(),
        ),
      ),
    );
  }
}
