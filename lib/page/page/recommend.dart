import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/manga_column.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';

/// 首页推荐
/// Page for [HomepageMangaGroupList] / [MangaGroupList].
class RecommendSubPage extends StatefulWidget {
  const RecommendSubPage({
    Key key,
    this.action,
  }) : super(key: key);

  final ActionController action;

  @override
  _RecommendSubPageState createState() => _RecommendSubPageState();
}

class _RecommendSubPageState extends State<RecommendSubPage> with AutomaticKeepAliveClientMixin {
  ScrollMoreController _controller;
  ScrollFabController _fabController;
  GlobalKey<RefreshIndicatorState> _indicatorKey;
  var _loading = true;
  HomepageMangaGroupList _data;
  var _error = '';

  @override
  void initState() {
    super.initState();
    _controller = ScrollMoreController();
    _fabController = ScrollFabController();
    _indicatorKey = GlobalKey<RefreshIndicatorState>();
    widget.action?.addAction('', () => print('RecommendSubPage'));
    WidgetsBinding.instance.addPostFrameCallback((_) => _indicatorKey?.currentState?.show());
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() {
    _loading = true;
    if (mounted) setState(() {});

    var dio = DioManager.instance.dio;
    var client = RestClient(dio);
    return client.getHomepageMangas().then((r) async {
      _error = '';
      _data = null;
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _data = r.data;
    }).catchError((e) {
      _data = null;
      _error = wrapError(e).text;
    }).whenComplete(() {
      _loading = false;
      if (mounted) setState(() {});
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: RefreshIndicator(
        key: _indicatorKey,
        onRefresh: () => _loadData(),
        child: PlaceholderText.from(
          isLoading: _loading,
          errorText: _error,
          isEmpty: _data == null,
          setting: PlaceholderSetting().toChinese(),
          onRefresh: () => _loadData(),
          onChanged: (_, __) => _fabController.hide(),
          childBuilder: (c) => Scrollbar(
            child: ListView(
              controller: _controller,
              children: [
                MangaColumnView(group: _data.serial.topGroup, type: MangaGroupType.serial, showTopMargin: false), // 热门连载
                MangaColumnView(group: _data.finish.topGroup, type: MangaGroupType.finish), // 经典完结
                MangaColumnView(group: _data.latest.topGroup, type: MangaGroupType.latest), // 最新上架
                for (var group in _data.serial.groups) MangaColumnView(group: group, type: MangaGroupType.serial, small: true),
                for (var group in _data.finish.groups) MangaColumnView(group: group, type: MangaGroupType.finish, small: true),
                for (var group in _data.latest.groups) MangaColumnView(group: group, type: MangaGroupType.latest, small: true),
                for (var group in _data.serial.otherGroups) MangaColumnView(group: group, type: MangaGroupType.serial, small: true, singleLine: true),
                for (var group in _data.finish.otherGroups) MangaColumnView(group: group, type: MangaGroupType.finish, small: true, singleLine: true),
                for (var group in _data.latest.otherGroups) MangaColumnView(group: group, type: MangaGroupType.latest, small: true, singleLine: true),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: ScrollFloatingActionButton(
        scrollController: _controller,
        fabController: _fabController,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: 'RecommendSubPage',
          onPressed: () => _controller.scrollTop(),
        ),
      ),
    );
  }
}
