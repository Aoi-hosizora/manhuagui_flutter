import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/download_manga_line.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/service/db/download.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({
    Key? key,
  }) : super(key: key);

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();

  @override
  void dispose() {
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  final _data = <DownloadedManga>[];
  var _total = 0;

  Future<List<DownloadedManga>> _getData() async {
    var data = await DownloadDao.getMangas() ?? [];
    _total = await DownloadDao.getMangaCount() ?? 0;
    if (mounted) setState(() {});
    return data;
  }

  // var _downloading1 = false;
  // var _downloading2 = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('下载列表'),
      ),
      body: RefreshableListView<DownloadedManga>(
        data: _data,
        getData: () => _getData(),
        scrollController: _controller,
        setting: UpdatableDataViewSetting(
          padding: EdgeInsets.symmetric(vertical: 0),
          interactiveScrollbar: true,
          scrollbarCrossAxisMargin: 2,
          placeholderSetting: PlaceholderSetting().copyWithChinese(),
          onPlaceholderStateChanged: (_, __) => _fabController.hide(),
          refreshFirst: true,
          clearWhenRefresh: false,
          clearWhenError: false,
        ),
        separator: Divider(height: 0, thickness: 1),
        itemBuilder: (c, _, item) => DownloadMangaLineView(
          mangaTitle: item.mangaTitle,
          mangaCover: item.mangaCover,
          startedChaptersCount: item.startedChaptersCount,
          totalChaptersCountInTask: item.totalChaptersCount,
          lastDownloadTime: item.updatedAt,
          downloadStatus: null /* TODO */,
          downloadingChapterTitle: null /* TODO */,
          downloadProgress: null /* TODO */,
          onActionPressed: () {} /* TODO */,
          onLinePressed: () {} /* TODO */,
        ),
        extra: UpdatableDataViewExtraWidgets(
          innerTopWidgets: [
            ListHintView.textText(
              leftText: '',
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

    /*
    return Scaffold(
      appBar: AppBar(
        title: Text('下载列表'),
      ),
      body: ListView(
        children: [
          DownloadMangaLineView(
            mangaTitle: '辉夜姬想让人告白~天才们的恋爱头脑战~',
            mangaCover: 'https://cf.hamreus.com/cpic/b/17332.jpg',
            finishedChapterCount: 3,
            chapterCountInTask: 20,
            lastDownloadTime: DateTime.now(),
            downloadStatus: _downloading1 ? DownloadStatus.downloading : DownloadStatus.finished,
            downloadingChapterTitle: '第x话',
            downloadProgress: DownloadProgress(preparing: false, current: 5, total: 15),
            onActionPressed: () => mountedSetState(() => _downloading1 = !_downloading1),
            onLinePressed: () => Fluttertoast.showToast(msg: '1'),
          ),
          Divider(height: 0, thickness: 1),
          DownloadMangaLineView(
            mangaTitle: '和歌酱今天也很腹黑',
            mangaCover: 'https://cf.hamreus.com/cpic/m/37124.jpg',
            finishedChapterCount: 10,
            chapterCountInTask: 10,
            lastDownloadTime: DateTime.now(),
            downloadStatus: _downloading2 ? DownloadStatus.downloading : DownloadStatus.pausing,
            downloadingChapterTitle: '第x话',
            downloadProgress: DownloadProgress(preparing: true, current: 0, total: 0),
            onActionPressed: () => mountedSetState(() => _downloading2 = !_downloading2),
            onLinePressed: () => Fluttertoast.showToast(msg: '2'),
          ),
          Divider(height: 0, thickness: 1),
        ],
      ),
    );
    */
  }
}
