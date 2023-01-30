import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/download.dart';
import 'package:manhuagui_flutter/page/download_manga.dart';
import 'package:manhuagui_flutter/page/page/dl_setting.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/storage/download_task.dart';

/// 选择下载章节页，展示所给 [MangaChapterGroup] 列表信息，并提供章节选择功能
class DownloadChoosePage extends StatefulWidget {
  const DownloadChoosePage({
    Key? key,
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.groups,
  }) : super(key: key);

  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final List<MangaChapterGroup> groups;

  @override
  State<DownloadChoosePage> createState() => _DownloadChoosePageState();
}

class _DownloadChoosePageState extends State<DownloadChoosePage> {
  final _controller = ScrollController();
  var _loading = true; // fake loading flag
  VoidCallback? _cancelHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _loadDownloadedChapters(); // get in async
      await Future.delayed(Duration(milliseconds: 400));
      _loading = false;
      if (mounted) setState(() {});
    });
    _cancelHandler = EventBusManager.instance.listen<DownloadUpdatedEvent>((ev) async {
      if (ev.mangaId == widget.mangaId) {
        await _loadDownloadedChapters();
      }
    });
  }

  @override
  void dispose() {
    _cancelHandler?.call();
    _controller.dispose();
    super.dispose();
  }

  final _selected = <int>[];
  final _downloadedChapters = <DownloadedChapter>[];

  Future<void> _loadDownloadedChapters() async {
    var entity = await DownloadDao.getManga(mid: widget.mangaId);
    _downloadedChapters.clear();
    _downloadedChapters.addAll(entity?.downloadedChapters ?? []);
    if (mounted) setState(() {});
  }

  Future<void> _downloadManga() async {
    // 1. 获取需要下载的章节
    if (_selected.isEmpty) {
      Fluttertoast.showToast(msg: '请选择需要下载的章节');
      return;
    }
    var chapterIds = filterNeedDownloadChapterIds(chapterIds: _selected, downloadedChapters: _downloadedChapters);
    if (chapterIds.isEmpty) {
      Fluttertoast.showToast(msg: '所选章节均已下载完毕');
      return;
    }

    // 2. 显示下载确认
    var ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('下载确认'),
        content: Text('确定下载所选的 ${chapterIds.length} 个章节吗？'),
        actions: [
          TextButton(child: Text('下载'), onPressed: () => Navigator.of(c).pop(true)),
          TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
        ],
      ),
    );
    if (ok != true) {
      return;
    }

    // 3. 快速构造下载任务，同步更新数据库，并入队异步等待执行
    await quickBuildDownloadMangaQueueTask(
      mangaId: widget.mangaId,
      mangaTitle: widget.mangaTitle,
      mangaCover: widget.mangaCover,
      mangaUrl: widget.mangaUrl,
      chapterIds: chapterIds.toList(),
      alsoAddTask: true,
      throughGroupList: widget.groups,
      throughChapterList: null,
    );

    // 4. 更新界面，并显示提示
    // await _loadDownloadedChapters(); => 由事件通知更新章节信息
    _selected.clear();
    if (mounted) setState(() {});
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已添加 ${chapterIds.length} 个章节至漫画下载任务'),
        action: SnackBarAction(
          label: '查看',
          onPressed: () => Navigator.of(context).push(
            CustomPageRoute(
              context: context,
              builder: (c) => DownloadMangaPage(
                mangaId: widget.mangaId,
                gotoDownloading: true,
              ),
              settings: DownloadMangaPage.buildRouteSetting(
                mangaId: widget.mangaId,
              ),
            ),
          ),
        ),
      ),
    );
  }

  var _isAllSelected = false;

  void _selectChapter(int cid) {
    if (!_selected.contains(cid)) {
      _selected.add(cid);
    } else {
      _selected.remove(cid);
    }
    _isAllSelected = _selected.length == widget.groups.expand((group) => group.chapters.map((chapter) => chapter.cid)).length;
    if (mounted) setState(() {});
  }

  void _selectAllOrUnselectAll() {
    var allChapterIds = widget.groups.expand((group) => group.chapters.map((chapter) => chapter.cid));
    if (_selected.length == allChapterIds.length) {
      _selected.clear(); // unselect all
      _isAllSelected = false;
    } else {
      _selected.clear();
      _selected.addAll(allChapterIds); // select all
      _isAllSelected = true;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('下载 ${widget.mangaTitle}'),
        leading: AppBarActionButton.leading(context: context),
        actions: [
          AppBarActionButton(
            icon: Icon(!_isAllSelected ? Icons.select_all : Icons.deselect),
            tooltip: !_isAllSelected ? '全选' : '取消全选',
            onPressed: _selectAllOrUnselectAll,
          ),
          PopupMenuButton(
            child: Builder(
              builder: (c) => AppBarActionButton(
                icon: Icon(Icons.more_vert),
                tooltip: '更多选项',
                onPressed: () => c.findAncestorStateOfType<PopupMenuButtonState>()?.showButtonMenu(),
              ),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                child: Text('漫画下载设置'),
                onTap: () => WidgetsBinding.instance?.addPostFrameCallback(
                  (_) => showDlSettingDialog(context: context),
                ),
              ),
              PopupMenuItem(
                child: Text('查看下载列表'),
                onTap: () => WidgetsBinding.instance?.addPostFrameCallback(
                  (_) => Navigator.of(context).push(
                    CustomPageRoute(
                      context: context,
                      builder: (c) => DownloadPage(),
                    ),
                  ),
                ),
              ),
              PopupMenuItem(
                child: Text('查看下载任务详情'),
                onTap: () => WidgetsBinding.instance?.addPostFrameCallback(
                  (_) => Navigator.of(context).push(
                    CustomPageRoute(
                      context: context,
                      builder: (c) => DownloadMangaPage(
                        mangaId: widget.mangaId,
                      ),
                      settings: DownloadMangaPage.buildRouteSetting(
                        mangaId: widget.mangaId,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: PlaceholderText(
        state: _loading ? PlaceholderState.loading : PlaceholderState.normal,
        setting: PlaceholderSetting().copyWithChinese(),
        childBuilder: (c) => Container(
          color: Colors.white,
          child: ExtendedScrollbar(
            controller: _controller,
            interactive: true,
            mainAxisMargin: 2,
            crossAxisMargin: 2,
            child: ListView(
              controller: _controller,
              padding: EdgeInsets.zero,
              physics: AlwaysScrollableScrollPhysics(),
              children: [
                WarningTextView(
                  text: '本应用为第三方漫画柜客户端，请不要连续下载过多章节，避免因短时间内的频繁访问而导致当前IP被漫画柜封禁。',
                  isWarning: true,
                ),
                MangaTocView(
                  groups: widget.groups,
                  full: true,
                  highlightColor: Theme.of(context).primaryColor.withOpacity(0.5),
                  highlightedChapters: _selected,
                  customBadgeBuilder: (cid) => DownloadBadge.fromEntity(
                    entity: _downloadedChapters.where((el) => el.chapterId == cid).firstOrNull,
                  ),
                  onChapterPressed: _selectChapter,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_loading)
            ScrollAnimatedFab(
              scrollController: _controller,
              condition: ScrollAnimatedCondition.direction,
              fab: FloatingActionButton(
                child: Icon(Icons.vertical_align_top),
                heroTag: null,
                onPressed: () => _controller.scrollToTop(),
              ),
            ),
          SizedBox(height: kFloatingActionButtonMargin),
          FloatingActionButton(
            child: Icon(Icons.download),
            heroTag: null,
            onPressed: () => _downloadManga(),
          ),
        ],
      ),
    );
  }
}
