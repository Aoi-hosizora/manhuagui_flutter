import 'package:flutter/material.dart';
import 'package:flutter_ahlib/list.dart';
import 'package:flutter_ahlib/widget.dart';
import 'package:flutter_ahlib/util.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/page/view/tiny_manga_line.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';

/// 首页全部
class OverallSubPage extends StatefulWidget {
  const OverallSubPage({
    Key key,
    this.action,
  }) : super(key: key);

  final ActionController action;

  @override
  _OverallSubPageState createState() => _OverallSubPageState();
}

class _OverallSubPageState extends State<OverallSubPage> with AutomaticKeepAliveClientMixin {
  ScrollController _controller;
  UpdatableDataViewController _udvController;
  AnimatedFabController _fabController;
  var _data = <TinyManga>[];
  int _total;
  var _order = MangaOrder.byNew;
  var _lastOrder = MangaOrder.byNew;
  var _disableOption = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _udvController = UpdatableDataViewController();
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
    var result = await client.getAllMangas(page: page, order: _order).catchError((e) {
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
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: PaginationListView<TinyManga>(
        data: _data,
        getData: ({indicator}) => _getData(page: indicator),
        controller: _udvController,
        scrollController: _controller,
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
        ),
        separator: Divider(height: 1),
        itemBuilder: (c, item) => TinyMangaLineView(manga: item),
        extra: UpdatableDataViewExtraWidgets(
          innerTopWidget: Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 26,
                  padding: EdgeInsets.only(left: 5),
                  child: Center(
                    child: Text('全部漫画 (共 ${_total == null ? '?' : _total.toString()} 部)'),
                  ),
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
                      _udvController.refresh();
                    }
                  },
                  optionBuilder: (c, v) => v.toTitle(),
                  enable: !_disableOption,
                ),
              ],
            ),
          ),
          innerTopDivider: Divider(height: 1, thickness: 1),
        ),
      ),
      floatingActionButton: ScrollAnimatedFab(
        controller: _fabController,
        scrollController: _controller,
        condition: ScrollAnimatedCondition.direction,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: 'OverallSubPage',
          onPressed: () => _controller.scrollToTop(),
        ),
      ),
    );
  }
}
