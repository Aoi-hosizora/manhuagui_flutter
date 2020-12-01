import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/enums.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/tiny_manga_line.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';

/// 首页全部
class OverallSubPage extends StatefulWidget {
  const OverallSubPage({Key key}) : super(key: key);

  @override
  _OverallSubPageState createState() => _OverallSubPageState();
}

class _OverallSubPageState extends State<OverallSubPage> with AutomaticKeepAliveClientMixin {
  ScrollMoreController _controller;
  ScrollFabController _fabController;
  var _data = <TinyManga>[];
  int _total;
  var _order = MangaOrder.byNew;

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

  Future<List<TinyManga>> _getData({int page}) async {
    var dio = DioManager.getInstance().dio;
    var client = RestClient(dio);
    ErrorMessage err;
    var result = await client.getAllMangas(page: page, order: _order).catchError((e) {
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
        refreshFirst: true,
        updateOnlyIfNotEmpty: true,
        padding: EdgeInsets.symmetric(vertical: 3),
        placeholderSetting: PlaceholderSetting(
          showProgress: true,
          loadingText: '加载中',
          retryText: '重试',
        ),
        onStateChanged: (_) => _fabController.hide(),
        separator: Divider(height: 1),
        itemBuilder: (c, item) => TinyMangaLineView(manga: item),
        topWidget: Container(
          color: Colors.white,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: Text('全部漫画 (共 ${_total == null ? '?' : _total.toString()} 部)'),
                    ),
                    Container(
                      height: 26,
                      width: 75,
                      child: DropdownButton<MangaOrder>(
                        // TODO
                        isExpanded: true,
                        style: Theme.of(context).textTheme.bodyText1,
                        underline: Container(color: Colors.white),
                        value: _order,
                        items: [MangaOrder.byPopular, MangaOrder.byNew, MangaOrder.byUpdate]
                            .map(
                              (o) => DropdownMenuItem(
                                value: o,
                                child: Text(o.toTitle()),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != _order) {
                            _order = v;
                            if (mounted) setState(() {});
                            _controller.refresh();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1.5),
            ],
          ),
        ),
      ),
      floatingActionButton: ScrollFloatingActionButton(
        scrollController: _controller,
        fabController: _fabController,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: 'OverallSubPage',
          onPressed: () => _controller.scrollTop(),
        ),
      ),
    );
  }
}
