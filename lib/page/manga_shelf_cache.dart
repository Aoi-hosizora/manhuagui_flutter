import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/shelf_cache_line.dart';
import 'package:manhuagui_flutter/service/db/shelf_cache.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 已同步的书架记录页，展示所给 [ShelfCache] 列表信息，并提供删除功能以及**同步书架缓存**功能
class MangaShelfCachePage extends StatefulWidget {
  const MangaShelfCachePage({Key? key}) : super(key: key);

  @override
  State<MangaShelfCachePage> createState() => _MangaShelfCachePageState();

  /// 同步书架缓存，在 [ShelfSubPage] 使用
  static Future<void> syncShelfCaches(BuildContext context) async {
    var caches = <ShelfCache>[];
    var currPage = 1;
    int? totalPages;
    var canceled = false;
    String? error;

    var ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => WillPopScope(
        onWillPop: () async => false,
        child: StatefulWidgetWithCallback.builder(
          postFrameCallbackForInitState: (_, _setState) => Future.microtask(
            () async {
              // !!!
              try {
                final client = RestClient(DioManager.instance.dio);
                while (!canceled) {
                  var result = await client.getShelfMangas(token: AuthManager.instance.token, page: currPage);
                  for (var item in result.data.data) {
                    if (canceled) {
                      break; // Concurrent modification during iteration: Instance(length:40) of '_GrowableList'
                    }
                    caches.add(ShelfCache(mangaId: item.mid, mangaTitle: item.title, mangaCover: item.cover, mangaUrl: item.url, cachedAt: DateTime.now()));
                  }

                  totalPages = (result.data.total / result.data.limit).ceil();
                  if (currPage >= totalPages!) {
                    break;
                  }
                  currPage++;
                  _setState(() {});
                  await Future.delayed(Duration(milliseconds: 500)); // 额外等待 0.5s
                  continue;
                }
              } catch (e, s) {
                error = wrapError(e, s).text; // 记录错误，但不等价于操作被取消
              } finally {
                if (!canceled) {
                  Navigator.of(c).pop(true); // 循环非被结束则需关闭"正在处理"对话框
                }
              }
            },
          ),
          builder: (_, _setState) => AlertDialog(
            title: Text('同步书架记录'),
            contentPadding: EdgeInsets.zero,
            content: SizedBox(
              width: getDialogMaxWidth(context),
              child: CircularProgressDialogOption(
                progress: CircularProgressIndicator(),
                child: Text('正在处理第 $currPage/${totalPages ?? '?'} 页 (已获得 ${caches.length} 项)...'),
              ),
            ),
            actions: [
              TextButton(
                child: Text('结束'),
                onPressed: () {
                  canceled = true;
                  Navigator.of(c).pop(true); // 操作被请求结束，同时结束处理循环
                },
              ),
              TextButton(
                child: Text('取消'),
                onPressed: () {
                  canceled = true;
                  Navigator.of(c).pop(false); // 操作被取消，同时结束处理循环
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (ok != true) {
      Fluttertoast.showToast(msg: '操作已取消');
      return;
    }
    if (error != null) {
      var ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('同步书架记录'),
          content: Text('同步过程中发生错误：$error。' + //
              (caches.isEmpty ? '' : '\n是否继续执行已获得的 ${caches.length} 项记录的同步？')),
          actions: [
            if (caches.isNotEmpty) TextButton(child: Text('继续'), onPressed: () => Navigator.of(c).pop(true)),
            TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
          ],
        ),
      );
      if (ok != true) {
        if (caches.isNotEmpty) {
          Fluttertoast.showToast(msg: '操作已取消'); // 操作被取消，选择不继续
        }
        return;
      }
    }

    var newCaches = caches.toList(); // 拷贝一份，防止在更新数据库中途，列表被修改
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Text('同步书架记录'),
          contentPadding: EdgeInsets.zero,
          content: CircularProgressDialogOption(
            progress: CircularProgressIndicator(),
            child: Text('共获得 ${newCaches.length} 项记录，正在处理...'),
          ),
        ),
      ),
    );

    // !!!
    for (var i = newCaches.length - 1; i >= 0; i--) {
      newCaches[i] = newCaches[i].copyWith(cachedAt: DateTime.now()); // 书架上越老更新的漫画同步时间设置得越先
    }
    var oldCaches = await ShelfCacheDao.getShelfCaches(username: AuthManager.instance.username) ?? [];
    var canDelete = !canceled && error == null; // 如果非取消且非错误，则删除已被移出书架的记录
    if (canDelete) {
      // >>> 删除不存在的记录
      var toDelete = oldCaches.where((el) => newCaches.where((el2) => el2.mangaId == el.mangaId).isEmpty).toList();
      for (var item in toDelete) {
        await ShelfCacheDao.deleteShelfCache(username: AuthManager.instance.username, mangaId: item.mangaId);
        EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: item.mangaId, added: false));
      }
    }
    // >>> 更新所有新记录
    for (var item in newCaches) {
      await ShelfCacheDao.addOrUpdateShelfCache(username: AuthManager.instance.username, cache: item);
      EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: item.mangaId, added: true));
    }
    Navigator.of(context).pop(); // 关闭"正在处理"对话框
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('同步书架记录'),
        content: Text('已完成 ${newCaches.length} 项书架记录的同步' + (!canDelete ? '。' : '，且已删除所有被移出书架的漫画。')),
        actions: [
          TextButton(
            child: Text('确定'),
            onPressed: () => Navigator.of(c).pop(),
          ),
        ],
      ),
    );
  }
}

class _MangaShelfCachePageState extends State<MangaShelfCachePage> {
  final _controller = ScrollController();
  final _fabControllers = [AnimatedFabController(), AnimatedFabController()];

  @override
  void initState() {
    super.initState();
    // EventBusManager.instance.listen<ShelfCacheUpdatedEvent>((ev) { }); // => 本页的列表不自动刷新
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabControllers[0].dispose();
    _fabControllers[1].dispose();
    super.dispose();
  }

  final _data = <ShelfCache>[];
  var _total = 0;

  Future<List<ShelfCache>> _getData() async {
    var data = await ShelfCacheDao.getShelfCaches(username: AuthManager.instance.username) ?? [];
    _total = data.length;
    if (mounted) setState(() {});
    return data;
  }

  Future<void> _deleteCache({required int mangaId}) async {
    // 更新数据库、更新界面、发送通知
    await ShelfCacheDao.deleteShelfCache(username: AuthManager.instance.username, mangaId: mangaId);
    _data.removeWhere((el) => el.mangaId == mangaId);
    _total--;
    EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: mangaId, added: false));
    if (mounted) setState(() {});
  }

  Future<void> _clearCaches() async {
    if (_data.isEmpty) {
      return;
    }
    var ok = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('清空确认'),
        content: Text('是否清空所有已同步的书架记录？'),
        actions: [
          TextButton(child: Text('清空'), onPressed: () => Navigator.of(c).pop(true)),
          TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
        ],
      ),
    );
    if (ok != true) {
      return;
    }

    // 更新数据库、更新界面、发送通知
    await ShelfCacheDao.clearShelfCaches(username: AuthManager.instance.username);
    var mangaIds = _data.map((el) => el.mangaId).toList();
    _data.clear();
    _total = 0;
    for (var mangaId in mangaIds) {
      EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: mangaId, added: false));
    }
    if (mounted) setState(() {});
  }

  void _showPopupMenu(ShelfCache cache) {
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(cache.mangaTitle),
        children: [
          IconTextDialogOption(
            icon: Icon(Icons.description_outlined),
            text: Text('查看该漫画'),
            onPressed: () {
              Navigator.of(c).pop();
              Navigator.of(context).push(
                CustomPageRoute(
                  context: context,
                  builder: (c) => MangaPage(
                    id: cache.mangaId,
                    title: cache.mangaTitle,
                    url: cache.mangaUrl,
                  ),
                ),
              );
            },
          ),
          IconTextDialogOption(
            icon: Icon(Icons.delete),
            text: Text('删除该记录'),
            onPressed: () async {
              Navigator.of(c).pop();
              await _deleteCache(mangaId: cache.mangaId);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('已同步的书架记录'),
        leading: AppBarActionButton.leading(context: context),
        actions: [
          AppBarActionButton(
            icon: Icon(Icons.delete),
            tooltip: '清空记录',
            onPressed: () => _clearCaches(),
          ),
        ],
      ),
      body: RefreshableListView<ShelfCache>(
        data: _data,
        getData: () => _getData(),
        scrollController: _controller,
        setting: UpdatableDataViewSetting(
          padding: EdgeInsets.symmetric(vertical: 0),
          interactiveScrollbar: true,
          scrollbarMainAxisMargin: 2,
          scrollbarCrossAxisMargin: 2,
          placeholderSetting: PlaceholderSetting().copyWithChinese(),
          onPlaceholderStateChanged: (_, __) => _fabControllers.forEach((c) => c.hide()),
          refreshFirst: true,
          clearWhenRefresh: false,
          clearWhenError: false,
        ),
        separator: Divider(height: 0, thickness: 1),
        itemBuilder: (c, _, item) => ShelfCacheLineView(
          manga: item,
          onPressed: () => _showPopupMenu(item),
          onLongPressed: () => _showPopupMenu(item),
        ),
        extra: UpdatableDataViewExtraWidgets(
          outerTopWidgets: [
            ListHintView.textWidget(
              leftText: '${AuthManager.instance.username} 的书架记录',
              rightWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('共 $_total 部'),
                  SizedBox(width: 5),
                  HelpIconView.forListHint(
                    title: '已同步的书架记录',
                    hint: '书架记录同步功能仅用于判断漫画是否在书架上，并用于显示漫画列表右下角的书架图标。',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: [
          ScrollAnimatedFab(
            controller: _fabControllers[0],
            scrollController: _controller,
            condition: ScrollAnimatedCondition.direction,
            fab: FloatingActionButton(
              child: Icon(Icons.vertical_align_top),
              heroTag: null,
              onPressed: () => _controller.scrollToTop(),
            ),
          ),
          ScrollAnimatedFab(
            controller: _fabControllers[1],
            scrollController: _controller,
            condition: ScrollAnimatedCondition.reverseDirection,
            fab: FloatingActionButton(
              child: Icon(Icons.vertical_align_bottom),
              heroTag: null,
              onPressed: () => _controller.scrollToBottom(),
            ),
          ),
        ],
      ),
    );
  }
}
