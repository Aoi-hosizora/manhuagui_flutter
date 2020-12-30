import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/chapter_group.dart';
import 'package:manhuagui_flutter/service/database/history.dart';
import 'package:manhuagui_flutter/service/natives/browser.dart';
import 'package:manhuagui_flutter/service/state/auth.dart';

/// 漫画章节目录
/// Page for [MangaChapterGroup].
class MangaTocPage extends StatefulWidget {
  const MangaTocPage({
    Key key,
    this.action,
    @required this.mid,
    @required this.title,
    @required this.cover,
    @required this.url,
    @required this.groups,
    this.highlightChapter,
  })  : assert(mid != null),
        assert(title != null),
        assert(cover != null),
        assert(url != null),
        assert(groups != null),
        super(key: key);

  final ActionController action;
  final int mid;
  final String title;
  final String cover;
  final String url;
  final List<MangaChapterGroup> groups;
  final int highlightChapter;

  @override
  _MangaTocPageState createState() => _MangaTocPageState();
}

class _MangaTocPageState extends State<MangaTocPage> {
  MangaHistory _history;

  @override
  void initState() {
    super.initState();
    getHistory(username: AuthState.instance.username, mid: widget.mid).then((r) => _history = r).catchError((_) {});
    widget?.action?.addAction('history_toc', () async {
      _history = await getHistory(username: AuthState.instance.username, mid: widget.mid).catchError((_) {});
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    widget?.action?.removeAction('history_toc');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: Text(widget.title),
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
      body: Container(
        color: Colors.white,
        child: Scrollbar(
          child: ListView(
            children: [
              ChapterGroupView(
                action: widget.action,
                groups: widget.groups,
                complete: true,
                highlightChapter: _history?.chapterId ?? widget.highlightChapter,
                mangaId: widget.mid,
                mangaTitle: widget.title,
                mangaCover: widget.cover,
                mangaUrl: widget.url,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
