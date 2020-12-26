import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/tiny_manga_line.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';

/// 首页更新
class RecentSubPage extends StatefulWidget {
  const RecentSubPage({
    Key key,
    this.action,
  }) : super(key: key);

  final ActionController action;

  @override
  _RecentSubPageState createState() => _RecentSubPageState();
}

class _RecentSubPageState extends State<RecentSubPage> with AutomaticKeepAliveClientMixin {
  ScrollMoreController _controller;
  ScrollFabController _fabController;
  var _data = <TinyManga>[];

  @override
  void initState() {
    super.initState();
    _controller = ScrollMoreController();
    _fabController = ScrollFabController();
    widget.action?.addAction('', () => _controller.scrollTop());
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<List<TinyManga>> _getData({int page}) async {
    var dio = DioManager.instance.dio;
    var client = RestClient(dio);
    ErrorMessage err;
    var result = await client.getRecentUpdatedMangas(page: page).catchError((e) {
      err = wrapError(e);
    });
    if (err != null) {
      return Future.error(err.text);
    }
    return result.data.data;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: PaginationListView<TinyManga>(
        controller: _controller,
        data: _data,
        strategy: PaginationStrategy.offsetBased,
        getDataByOffset: _getData,
        initialPage: 1,
        onAppend: (l) => doIf(l.length > 0, () => Fluttertoast.showToast(msg: '新添了 ${l.length} 部漫画')),
        onError: (e) => Fluttertoast.showToast(msg: e.toString()),
        clearWhenRefreshing: false,
        clearWhenError: false,
        updateOnlyIfNotEmpty: false,
        refreshFirst: true,
        placeholderSetting: PlaceholderSetting().toChinese(),
        onStateChanged: (_, __) => _fabController.hide(),
        padding: EdgeInsets.zero,
        physics: AlwaysScrollableScrollPhysics(),
        separator: Divider(height: 1),
        itemBuilder: (c, item) => TinyMangaLineView(manga: item),
      ),
      floatingActionButton: ScrollFloatingActionButton(
        scrollController: _controller,
        fabController: _fabController,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: 'RecentSubPage',
          onPressed: () => _controller.scrollTop(),
        ),
      ),
    );
  }
}
