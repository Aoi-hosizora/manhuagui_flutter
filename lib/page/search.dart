import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';

/// 搜索
class SearchPage extends StatefulWidget {
  const SearchPage({Key key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

enum _SearchState {
  none, // _q == null && _text == null
  inputting, // _q == null && _text != null
  searching, // _q != null && (_text == _q && !_textChanging)
  searchInputting, // _q != null && (_text != _q || _textChanging)
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _textController;
  ScrollMoreController _scrollController;
  ScrollFabController _fabController;

  String get _text => _textController?.text?.isNotEmpty == false ? null : _textController.text;
  String _q;
  var _textChanging = false;
  var _data = <SmallManga>[];
  int _total;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollMoreController();
    _fabController = ScrollFabController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  _SearchState get _currentState {
    if (_q == null && _text == null) {
      return _SearchState.none;
    }
    if (_q == null && _text != null) {
      return _SearchState.inputting;
    }
    if (_q != null && (_text == _q && !_textChanging)) {
      return _SearchState.searching;
    }
    if (_q != null && (_text != _q || _textChanging)) {
      return _SearchState.searchInputting;
    }
    return null; // unreachable
  }

  List<String> _getHistories({String keyword}) {
    if (keyword?.isNotEmpty != true) {
      return List.generate(20, (num) => 'Item ${num + 1}');
    }
    return List.generate(5, (num) => '$keyword ${num + 1}');
  }

  void _hideKeyboard() {
    var f = FocusScope.of(context);
    if (!f.hasPrimaryFocus && f.focusedChild != null) {
      f.focusedChild.unfocus();
    }
  }

  void _search() {
    var text = _textController?.text?.trim();
    if (text == null || text == '') {
      Fluttertoast.showToast(msg: '请输入搜索内容');
      return;
    }

    _q = text;
    _hideKeyboard();
    _textChanging = false;
    if (mounted) setState(() {});

    if (_q != text) {
      _scrollController.refresh();
      print('search $_q when ${DateTime.now()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentState == _SearchState.searchInputting) {
          // searchInputting -> searching
          _textController.text = _q;
          _textChanging = false;
          _hideKeyboard();
          if (mounted) setState(() {});
          return false;
        } else if (_currentState == _SearchState.searching) {
          // searching -> none
          _q = null;
          _textController.clear();
          if (mounted) setState(() {});
          return false;
        } else if (_currentState == _SearchState.inputting) {
          // inputting -> none
          _textController.clear();
          if (mounted) setState(() {});
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 45,
          title: TextField(
            controller: _textController,
            autofocus: true,
            onChanged: (_) => mountedSetState(() => _textChanging = true),
            onTap: () => mountedSetState(() => _textChanging = true),
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(hintText: '搜索...'),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            cursorColor: Colors.white,
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            tooltip: '返回',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.close),
              tooltip: '清空',
              onPressed: () {
                _textController.clear();
                if (mounted) setState(() {});
              },
            ),
            IconButton(
              icon: Icon(Icons.search),
              tooltip: '搜索',
              onPressed: () => _search(),
            ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
          child: _currentState != _SearchState.searching
              ? ListView(
                  children: [
                    if (_currentState == _SearchState.searchInputting)
                      ListTile(
                        title: Text('返回 "$_q" 的搜索结果'),
                        leading: Icon(Icons.search),
                        onTap: () {
                          // searchInputting -> searching
                          _textController.text = _q;
                          _textChanging = false;
                          _hideKeyboard();
                          if (mounted) setState(() {});
                        },
                      ),
                    if ((_currentState == _SearchState.inputting || _currentState == _SearchState.searchInputting) && _text != null && _text != _q)
                      ListTile(
                        title: Text('搜索 "$_text"'),
                        leading: Icon(Icons.search),
                        onTap: () => _search(), // inputting || searchInputting -> searching
                      ),
                    ..._getHistories(keyword: _text)
                        .map(
                          (h) => ListTile(
                            title: Text(h),
                            leading: Icon(Icons.history),
                            trailing: IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () => Fluttertoast.showToast(msg: 'TODO'),
                            ),
                            onTap: () {
                              _textController.text = h;
                              if (mounted) setState(() {});
                            },
                          ),
                        )
                        .toList(),
                    if (_text == null)
                      ListTile(
                        title: Center(
                          child: Text('清空历史纪录'),
                        ),
                        onTap: () => Fluttertoast.showToast(msg: 'TODO'),
                      ),
                  ],
                )
              : Center(
                  child: Text('search result about "$_q"'),
                ),
        ),
      ),
    );
  }
}
