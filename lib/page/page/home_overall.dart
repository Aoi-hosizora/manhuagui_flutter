import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/corner_icons.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/small_manga_line.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';

/// 首页-全部
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
  final _pdvKey = GlobalKey<PaginationDataViewState>();
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
    _flagStorage.dispose();
    super.dispose();
  }

  final _data = <SmallerManga>[];
  var _total = 0;
  var _needTotal = true;
  late final _flagStorage = MangaCornerFlagStorage(stateSetter: () => mountedSetState(() {}));

  Future<PagedList<SmallerManga>> _getData({required int page}) async {
    if (page == 1) {
      _needTotal = true; // refresh, reset need total flag
    }
    final client = RestClient(DioManager.instance.dio);
    var result = await client.getRecentPublishedMangasV2(page: page, needTotal: _needTotal).onError((e, s) {
      return Future.error(wrapError(e, s).text);
    });
    _total = _needTotal ? result.data.total : _total;
    _needTotal = false; // only get total once
    if (mounted) setState(() {});
    _flagStorage.queryAndStoreFlags(mangaIds: result.data.data.map((e) => e.mid)).then((_) => mountedSetState(() {}));
    return PagedList(list: result.data.data, next: result.data.page + 1);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: PaginationDataView<SmallerManga>(
        key: _pdvKey,
        style: !AppSetting.instance.ui.showTwoColumns ? UpdatableDataViewStyle.listView : UpdatableDataViewStyle.gridView,
        data: _data,
        getData: ({indicator}) => _getData(page: indicator),
        scrollController: _controller,
        paginationSetting: PaginationSetting(
          initialIndicator: 1,
          nothingIndicator: 0,
        ),
        setting: UpdatableDataViewSetting(
          padding: EdgeInsets.symmetric(vertical: 0),
          interactiveScrollbar: true,
          scrollbarMainAxisMargin: 2,
          scrollbarCrossAxisMargin: 2,
          placeholderSetting: PlaceholderSetting().copyWithChinese(),
          onPlaceholderStateChanged: (_, __) => _fabController.hide(),
          refreshFirst: true /* <<< refresh first */,
          clearWhenRefresh: false,
          clearWhenError: false,
          updateOnlyIfNotEmpty: false,
          onError: (e) {
            if (_data.isNotEmpty) {
              Fluttertoast.showToast(msg: e.toString());
            }
          },
        ),
        separator: Divider(height: 0, thickness: 1),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 0.0,
          mainAxisSpacing: 0.0,
          childAspectRatio: GeneralLineView.getChildAspectRatioForTwoColumns(context),
        ),
        itemBuilder: (c, _, item) => SmallMangaLineView(
          manga: item,
          history: _flagStorage.getHistory(mangaId: item.mid),
          flags: _flagStorage.getFlags(mangaId: item.mid),
          twoColumns: AppSetting.instance.ui.showTwoColumns,
          highlightRecent: AppSetting.instance.ui.highlightRecentMangas,
        ),
        extra: UpdatableDataViewExtraWidgets(
          innerTopWidgets: [
            ListHintView.textText(
              leftText: '全部漫画 (按收录时间排序)',
              rightText: '共 $_total 部',
            ),
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
