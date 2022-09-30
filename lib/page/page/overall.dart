import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/page/view/tiny_manga_line.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';

/// 首页全部
class OverallSubPage extends StatefulWidget {
  const OverallSubPage({
    Key? key,
    this.action,
  }) : super(key: key);

  final ActionController? action;

  @override
  _OverallSubPageState createState() => _OverallSubPageState();
}

class _OverallSubPageState extends State<OverallSubPage> with AutomaticKeepAliveClientMixin {
  final _controller = ScrollController();
  final _pdvKey = GlobalKey<PaginationDataViewState>();
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

  int _total = 0;
  final _data = <TinyManga>[];
  var _order = MangaOrder.byNew;
  var _lastOrder = MangaOrder.byNew;
  var _disableOption = false;

  Future<PagedList<TinyManga>> _getData({required int page}) async {
    final client = RestClient(DioManager.instance.dio);
    var result = await client.getAllMangas(page: page, order: _order).onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
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
        key: _pdvKey,
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
          clearWhenError: false,
          clearWhenRefresh: false,
          updateOnlyIfNotEmpty: false,
          onPlaceholderStateChanged: (_, __) => _fabController.hide(),
          onStartGettingData: () => mountedSetState(() => _disableOption = true),
          onStopGettingData: () => mountedSetState(() => _disableOption = false),
          onAppend: (l, _) {
            if (l.length > 0) {
              Fluttertoast.showToast(msg: '新添了 ${l.length} 部漫画');
            }
            _lastOrder = _order;
            if (mounted) setState(() {});
          },
          onError: (e) {
            Fluttertoast.showToast(msg: e.toString());
            _order = _lastOrder; // TODO ???
            if (mounted) setState(() {});
          },
        ),
        separator: Divider(height: 1),
        itemBuilder: (c, _, item) => TinyMangaLineView(manga: item),
        extra: UpdatableDataViewExtraWidgets(
          innerTopWidgets: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 26,
                    padding: EdgeInsets.only(left: 5),
                    child: Center(
                      child: Text('全部漫画 (共 $_total 部)'),
                    ),
                  ),
                  OptionPopupView<MangaOrder>(
                    title: _order.toTitle(),
                    top: 4,
                    value: _order,
                    items: const [MangaOrder.byPopular, MangaOrder.byNew, MangaOrder.byUpdate],
                    onSelect: (o) {
                      if (_order != o) {
                        _lastOrder = _order;
                        _order = o;
                        if (mounted) setState(() {});
                        _pdvKey.currentState?.refresh();
                      }
                    },
                    optionBuilder: (c, v) => v.toTitle(),
                    enable: !_disableOption,
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1),
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
