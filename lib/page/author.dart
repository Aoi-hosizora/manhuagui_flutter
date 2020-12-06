import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/service/natives/browser.dart';
import 'package:manhuagui_flutter/model/author.dart';

/// 漫画家
class AuthorPage extends StatefulWidget {
  const AuthorPage({
    Key key,
    @required this.id,
    @required this.name,
    @required this.url,
  })  : assert(id != null),
        assert(name != null),
        assert(url != null),
        super(key: key);

  final int id;
  final String name;
  final String url;

  @override
  _AuthorPageState createState() => _AuthorPageState();
}

class _AuthorPageState extends State<AuthorPage> {
  Author _data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: Text(_data?.name ?? widget.name),
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_browser),
            tooltip: '打开浏览器',
            onPressed: () => launchInBrowser(
              context: context,
              url: widget.url,
            ),
          ),
        ],
      ),
      body: Center(
        child: Text('${widget.id} ${widget.name}'),
      ),
    );
  }
}
