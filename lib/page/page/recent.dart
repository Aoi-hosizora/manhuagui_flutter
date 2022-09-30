import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/tiny_manga_line.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';

/// 首页更新
class RecentSubPage extends StatefulWidget {
  const RecentSubPage({
    Key? key,
    this.action,
  }) : super(key: key);

  final ActionController? action;

  @override
  _RecentSubPageState createState() => _RecentSubPageState();
}

class _RecentSubPageState extends State<RecentSubPage> with AutomaticKeepAliveClientMixin {
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _controller.scrollToTop());
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  final _data = <TinyManga>[];

  Future<PagedList<TinyManga>> _getData({required int page}) async {
    final client = RestClient(DioManager.instance.dio);
    var result = await client.getRecentUpdatedMangas(page: page).onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
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
          placeholderSetting: PlaceholderSetting().copyWithChinese(),
          refreshFirst: true,
          clearWhenRefresh: false,
          clearWhenError: false,
          updateOnlyIfNotEmpty: false,
          onPlaceholderStateChanged: (_, __) => _fabController.hide(),
          onAppend: (l, _) {
            if (l.length > 0) {
              Fluttertoast.showToast(msg: '新添了 ${l.length} 部漫画');
            }
          },
          onError: (e) => Fluttertoast.showToast(msg: e.toString()),
        ),
        separator: Divider(height: 1),
        itemBuilder: (c, _, item) => TinyMangaLineView(manga: item),
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
