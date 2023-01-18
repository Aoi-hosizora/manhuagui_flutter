import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/shelf_cache_line.dart';
import 'package:manhuagui_flutter/page/view/simple_widgets.dart';
import 'package:manhuagui_flutter/service/db/shelf_cache.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/system_ui.dart';

/// 订阅-书架-供"同步我的书架"弹出菜单使用
class ShelfCacheSubPage extends StatefulWidget {
  const ShelfCacheSubPage({
    Key? key,
    required this.caches,
  }) : super(key: key);

  final List<ShelfCache> caches;

  @override
  State<ShelfCacheSubPage> createState() => _ShelfCacheSubPageState();

  // ****************************************************************
  static Future<void> openShelfCachePage(BuildContext context) async {
    var data = await ShelfCacheDao.getShelfCaches(username: AuthManager.instance.username) ?? [];
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: Container(
          height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical - Theme.of(context).appBarTheme.toolbarHeight!,
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: ShelfCacheSubPage(caches: data),
        ),
      ),
    );
    await Future.delayed(kBottomSheetExitDuration + Duration(milliseconds: 10));
    setDefaultSystemUIOverlayStyle();
  }

  // ****************************************************************
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
    var canDelete = !canceled && error == null; // 如果非取消且非错误，则删除已被取消订阅的记录
    if (canDelete) {
      // >>> 删除不存在的记录
      var toDelete = oldCaches.where((el) => newCaches.where((el2) => el2.mangaId == el.mangaId).isEmpty).toList();
      for (var item in toDelete) {
        await ShelfCacheDao.deleteShelfCache(username: AuthManager.instance.username, mangaId: item.mangaId);
        EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: item.mangaId, inShelf: false));
      }
    }
    // >>> 更新所有新记录
    for (var item in newCaches) {
      await ShelfCacheDao.addOrUpdateShelfCache(username: AuthManager.instance.username, cache: item);
      EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: item.mangaId, inShelf: true));
    }
    Navigator.of(context).pop(); // 关闭"正在处理"对话框
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('同步书架记录'),
        content: Text('已完成 ${newCaches.length} 项书架记录的同步' + (!canDelete ? '' : '，且已删除所有被取消订阅的漫画。')),
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

class _ShelfCacheSubPageState extends State<ShelfCacheSubPage> {
  final _controller = ScrollController();
  late final _data = widget.caches.toList();

  void _showPopupMenu(ShelfCache cache) {
    showDialog(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(cache.mangaTitle),
        children: [
          IconTextDialogOption(
            icon: Icon(Icons.arrow_forward),
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
              var mid = cache.mangaId;
              await ShelfCacheDao.deleteShelfCache(username: AuthManager.instance.username, mangaId: mid);
              EventBusManager.instance.fire(ShelfCacheUpdatedEvent(mangaId: mid, inShelf: false));
              _data.removeWhere((el) => el.mangaId == mid);
              if (mounted) setState(() {});
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
      ),
      body: Column(
        children: [
          ListHintView.textWidget(
            leftText: '已同步的 ${AuthManager.instance.username} 的书架',
            rightWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('共 ${_data.length} 部'),
                SizedBox(width: 5),
                HelpIconView(
                  title: '已同步的书架记录',
                  hint: '注：书架记录同步功能仅用于显示列表中漫画右下角的书架图标。',
                  useRectangle: true,
                  padding: EdgeInsets.all(3),
                ),
              ],
            ),
          ),
          Expanded(
            child: PlaceholderText(
              state: _data.isEmpty ? PlaceholderState.nothing : PlaceholderState.normal,
              setting: PlaceholderSetting(showNothingRetry: false).copyWithChinese(),
              childBuilder: (c) => ExtendedScrollbar(
                controller: _controller,
                interactive: true,
                mainAxisMargin: 2,
                crossAxisMargin: 2,
                child: ListView.separated(
                  controller: _controller,
                  padding: EdgeInsets.symmetric(vertical: 0),
                  physics: AlwaysScrollableScrollPhysics(),
                  itemCount: _data.length,
                  separatorBuilder: (_, __) => Divider(height: 0, thickness: 1),
                  itemBuilder: (c, i) => ShelfCacheLineView(
                    manga: _data[i],
                    onPressed: () => _showPopupMenu(_data[i]),
                    onLongPressed: () => _showPopupMenu(_data[i]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          ScrollAnimatedFab(
            scrollController: _controller,
            condition: ScrollAnimatedCondition.direction,
            fab: FloatingActionButton(
              child: Icon(Icons.vertical_align_top),
              heroTag: null,
              onPressed: () => _controller.scrollToTop(),
            ),
          ),
          ScrollAnimatedFab(
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
