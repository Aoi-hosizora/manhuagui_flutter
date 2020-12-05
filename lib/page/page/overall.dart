import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/enums.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
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
  var _lastOrder = MangaOrder.byNew;
  var _disableOption = false;

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
        onStartLoading: () => mountedSetState(() => _disableOption = true),
        onStopLoading: () => mountedSetState(() => _disableOption = false),
        onAppend: (l) {
          if (l.length > 0) {
            Fluttertoast.showToast(msg: '新添了 ${l.length} 部漫画');
          }
          _lastOrder = _order;
          if (mounted) setState(() {});
        },
        onError: (e) {
          Fluttertoast.showToast(msg: e.toString());
          _order = _lastOrder;
          if (mounted) setState(() {});
        },
        clearWhenRefreshing: false,
        clearWhenError: false,
        updateOnlyIfNotEmpty: false,
        refreshFirst: true,
        placeholderSetting: PlaceholderSetting().toChinese(),
        onStateChanged: (_, __) => _fabController.hide(),
        padding: EdgeInsets.symmetric(vertical: 3),
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
                    OptionPopupView<MangaOrder>(
                      title: _order.toTitle(),
                      top: 4,
                      value: _order,
                      items: [MangaOrder.byPopular, MangaOrder.byNew, MangaOrder.byUpdate],
                      onSelect: (o) {
                        if (_order != o) {
                          _lastOrder = _order;
                          _order = o;
                          if (mounted) setState(() {});
                          _controller.refresh();
                        }
                      },
                      optionBuilder: (c, v) => v.toTitle(),
                      enable: !_disableOption,
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
