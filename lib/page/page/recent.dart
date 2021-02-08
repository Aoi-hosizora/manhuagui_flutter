import 'package:flutter/material.dart';
import 'package:flutter_ahlib/list.dart';
import 'package:flutter_ahlib/widget.dart';
import 'package:flutter_ahlib/util.dart';
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
  ScrollController _controller;
  AnimatedFabController _fabController;
  var _data = <TinyManga>[];

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _fabController = AnimatedFabController();
    widget.action?.addAction('', () => _controller.scrollToTop());
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<PagedList<TinyManga>> _getData({int page}) async {
    var dio = DioManager.instance.dio;
    var client = RestClient(dio);
    ErrorMessage err;
    var result = await client.getRecentUpdatedMangas(page: page).catchError((e) {
      err = wrapError(e);
    });
    if (err != null) {
      return Future.error(err.text);
    }
    return PagedList(list: result.data.data, next: result.data.page + 1);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: PaginationListView<TinyManga>(
        data: _data,
        getData: ({indicator}) => _getData(page: indicator),
        scrollController: _controller,
        paginationSetting: PaginationSetting(
          initialIndicator: 1,
          nothingIndicator: 0,
        ),
        setting: UpdatableDataViewSetting(
          padding: EdgeInsets.zero,
          placeholderSetting: PlaceholderSetting().toChinese(),
          refreshFirst: true,
          clearWhenRefresh: false,
          clearWhenError: false,
          updateOnlyIfNotEmpty: false,
          onStateChanged: (_, __) => _fabController.hide(),
          onAppend: (l) {
            if (l.length > 0) {
              Fluttertoast.showToast(msg: '新添了 ${l.length} 部漫画');
            }
          },
          onError: (e) => Fluttertoast.showToast(msg: e.toString()),
        ),
        separator: Divider(height: 1),
        itemBuilder: (c, item) => TinyMangaLineView(manga: item),
      ),
      floatingActionButton: ScrollAnimatedFab(
        controller: _fabController,
        scrollController: _controller,
        condition: ScrollAnimatedCondition.direction,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: 'RecentSubPage',
          onPressed: () => _controller.scrollToTop(),
        ),
      ),
    );
  }
}
