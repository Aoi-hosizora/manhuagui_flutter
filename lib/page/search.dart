import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

/// 搜索
class SearchPage extends StatefulWidget {
  const SearchPage({Key key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  FloatingSearchBarController _controller;
  String _q;
  var _data = <SmallManga>[];
  int _total;

  List<String> _getHistories({String keyword}) {
    if (keyword?.isNotEmpty != true) {
      return List.generate(20, (num) => 'Item ${num + 1}');
    }
    return List.generate(5, (num) => '$keyword ${num + 1}');
  }

  void _search() {
    var text = _controller?.query?.trim();
    if (text == null || text == '') {
      Fluttertoast.showToast(msg: '请输入搜索内容');
      return;
    }

    _controller.close();
    if (_q != text) {
      _q = text;
      if (mounted) setState(() {});
      print('search $_q when ${DateTime.now()}');
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = FloatingSearchBarController();
    WidgetsBinding.instance.addPostFrameCallback((_) => Future.delayed(Duration(milliseconds: 200), () => _controller.open()));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_q?.isNotEmpty == true) {
          _controller.clear(); // 清空搜索以及搜索框
          _q = null;
          if (mounted) setState(() {});
          _controller.open(); // 重新打开搜索框
          return false;
        }
        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).padding.top + 36 + 4 * 2 + 1, // 45
                child: AppBar(),
              ),
            ),
            Positioned.fill(
              top: MediaQuery.of(context).padding.top + 45,
              child: PlaceholderText(
                state: _q?.isNotEmpty == true ? PlaceholderState.normal : PlaceholderState.nothing,
                setting: PlaceholderSetting().toChinese(),
                childBuilder: (_) => Center(
                  child: Text('search result about "$_q"'),
                ),
              ),
            ),
            Scrollbar(
              child: FloatingSearchBar(
                controller: _controller,
                height: 36,
                hint: 'Search',
                textInputType: TextInputType.text,
                textInputAction: TextInputAction.search,
                hintStyle: Theme.of(context).textTheme.bodyText2.copyWith(color: Theme.of(context).hintColor),
                queryStyle: Theme.of(context).textTheme.bodyText2,
                elevation: 3.0,
                iconColor: Colors.black54,
                margins: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 4),
                insets: EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.symmetric(horizontal: 3),
                scrollPadding: EdgeInsets.only(top: 0, bottom: 32),
                maxWidth: MediaQuery.of(context).size.width - 8 * 2,
                openMaxWidth: MediaQuery.of(context).size.width - 8 * 2,
                borderRadius: _controller.isClosed ? BorderRadius.circular(3) : BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
                clearQueryOnClose: false,
                closeOnBackdropTap: false,
                automaticallyImplyDrawerHamburger: false,
                automaticallyImplyBackButton: false,
                transitionDuration: Duration(milliseconds: 500),
                transitionCurve: Curves.easeInOut,
                transition: CircularFloatingSearchBarTransition(),
                leadingActions: [
                  FloatingSearchBarAction.icon(
                    icon: Icon(Icons.arrow_back, size: 18),
                    size: 18,
                    showIfOpened: true,
                    showIfClosed: true,
                    onTap: () {
                      if (_controller.isOpen) {
                        // 返回搜索列表
                        _controller.query = _q;
                        _controller.close();
                        if (mounted) setState(() {});
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                ],
                actions: [
                  FloatingSearchBarAction.icon(
                    icon: Icon(Icons.close, size: 18),
                    size: 18,
                    showIfOpened: true,
                    showIfClosed: false,
                    onTap: () {
                      // 清空
                      _controller.clear();
                      if (mounted) setState(() {});
                    },
                  ),
                  FloatingSearchBarAction.icon(
                    icon: Icon(Icons.search, size: 18),
                    size: 18,
                    showIfOpened: true,
                    showIfClosed: true,
                    onTap: () => _search(), // 搜索
                  ),
                ],
                debounceDelay: Duration.zero,
                onQueryChanged: (q) {
                  if (mounted) setState(() {});
                  print('onQueryChanged: $q');
                },
                onFocusChanged: (q) {
                  if (q) {
                    if (mounted) setState(() {});
                  }
                  print('onFocusChanged: $q');
                },
                onSubmitted: (_) => _search(),
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(3), bottomRight: Radius.circular(3)),
                  child: Container(
                    color: Colors.white,
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_controller.query?.isNotEmpty == true && _controller.query != _q)
                            ListTile(
                              // 搜索
                              title: Text('搜索 "${_controller.query}"'),
                              leading: Icon(Icons.search),
                              onTap: () => _search(),
                            ),
                          if (_q?.isNotEmpty == true)
                            ListTile(
                              title: Text('返回 "$_q" 的搜索结果'),
                              leading: Icon(Icons.search),
                              onTap: () {
                                // 返回搜索列表
                                _controller.query = _q;
                                _controller.close();
                                if (mounted) setState(() {});
                              },
                            ),
                          ..._getHistories(keyword: _controller.query).map(
                            (h) => ListTile(
                              title: Text(h),
                              leading: Icon(Icons.history),
                              trailing: IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () => Fluttertoast.showToast(msg: 'TODO'),
                              ),
                              onTap: () => _controller.query = h, // 候选关键字
                            ),
                          ),
                          if (_controller.query?.isNotEmpty != true)
                            ListTile(
                              title: Center(
                                child: Text('清空历史记录'),
                              ),
                              onTap: () => Fluttertoast.showToast(msg: 'TODO'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
