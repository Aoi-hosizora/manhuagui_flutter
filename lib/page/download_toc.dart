import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/download_manga_line.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/storage/download_manga.dart';
import 'package:manhuagui_flutter/service/storage/queue_manager.dart';

/// 已下载章节页，查询数据库并展示 [DownloadedManga] 信息，以及展示 [DownloadMangaProgressChangedEvent] 进度信息
class DownloadTocPage extends StatefulWidget {
  const DownloadTocPage({
    Key? key,
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
  }) : super(key: key);

  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;

  @override
  State<DownloadTocPage> createState() => _DownloadTocPageState();
}

class _DownloadTocPageState extends State<DownloadTocPage> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _controller = ScrollController();
  final _fabController = AnimatedFabController();
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _refreshIndicatorKey.currentState?.show());
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      // progress related
      _cancelHandlers.add(EventBusManager.instance.listen<DownloadMangaProgressChangedEvent>((event) async {
        var mangaId = event.task.mangaId;
        if (mangaId == widget.mangaId) {
          return;
        }

        // <<<
        _task = !event.finished ? event.task : null;
        if (event.task.progress.stage == DownloadMangaProgressStage.waiting || event.task.progress.stage == DownloadMangaProgressStage.gotChapter) {
          // 只有在最开始等待、以及每次获得新章节数据时才遍历并获取文件大小
          _byte = await getDownloadedMangaBytes(mangaId: mangaId);
        }
        if (mounted) setState(() {});
      }));

      // entity related
      _cancelHandlers.add(EventBusManager.instance.listen<DownloadedMangaEntityChangedEvent>((event) async {
        var mangaId = event.mangaId;
        if (mangaId != widget.mangaId) {
          return;
        }

        // <<<
        var newEntity = await DownloadDao.getManga(mid: mangaId);
        if (newEntity != null) {
          _data = newEntity;
          _byte = await getDownloadedMangaBytes(mangaId: mangaId);
        } else {
          _error = '无法获取漫画下载信息';
        }
        if (mounted) setState(() {});
      }));
    });
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call);
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  var _loading = true;
  DownloadedManga? _data;
  DownloadMangaQueueTask? _task;
  var _byte = 0;
  var _error = '';

  Future<void> _getData() async {
    _loading = true;
    _data = null;
    _task = null;
    _byte = 0;
    if (mounted) setState(() {});

    var data = await DownloadDao.getManga(mid: widget.mangaId);
    if (data != null) {
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _data = data;
      _task = QueueManager.instance.tasks.whereType<DownloadMangaQueueTask>().where((el) => el.mangaId == widget.mangaId).firstOrNull;
      _byte = await getDownloadedMangaBytes(mangaId: widget.mangaId);
    } else {
      _error = '无法获取漫画下载信息';
    }
    _loading = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('已下载章节'),
        leading: AppBarActionButton.leading(context: context),
        actions: [
          AppBarActionButton(
            icon: Icon(Icons.play_arrow),
            tooltip: '全部开始',
            onPressed: () {},
          ),
          AppBarActionButton(
            icon: Icon(Icons.pause),
            tooltip: '全部暂停',
            onPressed: () {}, // TODO 单个漫画下载特定章节/按照特定顺序下载
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _getData,
        child: PlaceholderText.from(
          isLoading: _loading,
          errorText: _error,
          isEmpty: _data == null,
          setting: PlaceholderSetting().copyWithChinese(),
          onRefresh: () => _getData(),
          onChanged: (_, __) => _fabController.hide(),
          childBuilder: (c) => ListView(
            controller: _controller,
            children: [
              // ****************************************************************
              // 漫画下载信息头部
              // ****************************************************************
              Container(
                color: Colors.white,
                child: LargeDownloadMangaLineView(
                  mangaEntity: _data!,
                  downloadTask: _task,
                  downloadedBytes: _byte,
                ),
              ),
              Container(height: 12),
              // ****************************************************************
              // 正在下载的章节
              // ****************************************************************
              Container(
                color: Colors.white,
                child: SizedBox(height: 100), // TODO 采用 Toc 的风格，分组，长按弹出选项
              ),
              Container(height: 12),
              // ****************************************************************
              // 已下载的章节
              // ****************************************************************
              Container(
                color: Colors.white,
                child: SizedBox(height: 300), // TODO 采用 Line 的风格，加进度条，长按弹出选项
              ),
            ],
          ),
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
