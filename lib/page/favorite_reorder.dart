import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/favorite_reorder_line.dart';
import 'package:manhuagui_flutter/page/view/fit_system_screenshot.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 调整收藏顺序页，根据所给分组名查询 [FavoriteManga] 列表并进行排序，以及保存到数据库
class FavoriteReorderPage extends StatefulWidget {
  const FavoriteReorderPage({
    Key? key,
    required this.groupName,
  }) : super(key: key);

  final String groupName;

  @override
  State<FavoriteReorderPage> createState() => _FavoriteReorderPageState();
}

class _FavoriteReorderPageState extends State<FavoriteReorderPage> with FitSystemScreenshotMixin {
  final _listViewKey = GlobalKey();
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  var _loading = true; // initialize to true
  final _favorites = <FavoriteManga>[];
  final _originIndex = <int, int>{};
  var _reordered = false;
  var _saving = false;

  Future<void> _loadData() async {
    _loading = true;
    _favorites.clear();
    _originIndex.clear();
    if (mounted) setState(() {});

    try {
      var data = await FavoriteDao.getFavorites(username: AuthManager.instance.username, groupName: widget.groupName, page: null) ?? [];
      _favorites.addAll(data);
      for (var i = 0; i < data.length; i++) {
        _originIndex[data[i].mangaId] = i;
      }
    } finally {
      _loading = false;
      _reordered = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _saveData() async {
    _saving = true;
    if (mounted) setState(() {});

    try {
      for (var i = 0; i < _favorites.length; i++) {
        var favorite = _favorites[i].copyWith(order: i + 1);
        await FavoriteDao.addOrUpdateFavorite(username: AuthManager.instance.username, favorite: favorite);
      }
      // 无需发送 FavoriteUpdatedEvent 通知，变化的仅是 order
      EventBusManager.instance.fire(FavoriteOrderUpdatedEvent(groupName: widget.groupName));
      Navigator.of(context).pop();
    } catch (e, s) {
      // unreachable
      globalLogger.e('_saveData (FavoriteReorderPage)', e, s);
      Fluttertoast.showToast(msg: '无法保存对收藏漫画的修改');
    } finally {
      _saving = false;
      if (mounted) setState(() {});
    }
  }

  @override
  FitSystemScreenshotData get fitSystemScreenshotData => FitSystemScreenshotData(
        scrollViewKey: _listViewKey,
        scrollController: _controller,
      );

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_reordered) {
          return true;
        }
        var ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text('离开确认'),
            content: Text('当前顺序调整尚未保存，是否离开？'),
            actions: [
              TextButton(child: Text('离开'), onPressed: () => Navigator.of(c).pop(true)),
              TextButton(child: Text('去保存'), onPressed: () => Navigator.of(c).pop(false)),
            ],
          ),
        );
        if (ok != true) {
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('调整收藏顺序'),
          leading: AppBarActionButton.leading(context: context),
          actions: [
            AppBarActionButton(
              icon: Icon(MdiIcons.restore),
              tooltip: '还原修改',
              onPressed: _saving ? null : () => _loadData(),
            ),
            AppBarActionButton(
              icon: Icon(Icons.check),
              tooltip: '保存修改',
              onPressed: _saving ? null : () => _saveData(),
            ),
          ],
        ),
        body: Column(
          children: [
            ListHintView.textText(
              leftText: (AuthManager.instance.logined ? '${AuthManager.instance.username} 的本地收藏' : '本地收藏') + //
                  (widget.groupName == '' ? '' : ' - ${widget.groupName}'),
              rightText: '共 ${_favorites.length} 部',
            ),
            Expanded(
              child: PlaceholderText.from(
                isEmpty: _favorites.isEmpty,
                isLoading: _loading,
                onRefresh: () => _loadData(),
                setting: PlaceholderSetting().copyWithChinese(),
                childBuilder: (c) => ExtendedScrollbar(
                  controller: _controller,
                  interactive: false /* <<< be helpful for reorder dragging */,
                  mainAxisMargin: 2,
                  crossAxisMargin: 2,
                  child: ReorderableListView.builder(
                    key: _listViewKey,
                    scrollController: _controller,
                    padding: EdgeInsets.zero,
                    physics: AlwaysScrollableScrollPhysics(),
                    itemCount: _favorites.length,
                    itemBuilder: (c, i) => DecoratedBox(
                      key: Key('$i'),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: i == _favorites.length - 1
                              ? BorderSide.none //
                              : BorderSide(width: 1, color: Theme.of(context).dividerColor),
                        ),
                      ),
                      child: FavoriteMangaReorderLineView(
                        favorite: _favorites[i],
                        originIndex: _originIndex[_favorites[i].mangaId] ?? 0,
                        dragger: ReorderableDragStartListener(
                          index: i,
                          child: Icon(Icons.drag_handle),
                        ),
                        onLinePressed: () => _saving
                            ? null
                            : showDialog(
                                context: context,
                                builder: (c) => SimpleDialog(
                                  title: Text('调整《${_favorites[i].mangaTitle}》顺序'),
                                  children: [
                                    TextDialogOption(
                                      text: Text('移至顶部'),
                                      onPressed: () {
                                        Navigator.of(c).pop();
                                        var data = _favorites[i];
                                        _favorites.removeAt(i);
                                        _favorites.insert(0, data);
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                    TextDialogOption(
                                      text: Text('移至底部'),
                                      onPressed: () {
                                        Navigator.of(c).pop();
                                        var data = _favorites[i];
                                        _favorites.removeAt(i);
                                        _favorites.add(data);
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    buildDefaultDragHandles: false,
                    proxyDecorator: (child, idx, anim) => AnimatedBuilder(
                      animation: anim,
                      child: child,
                      builder: (context, child) => Curves.easeInOut.transform(anim.value).let(
                            (animValue) => Material(
                              elevation: lerpDouble(0, 6, animValue)!,
                              color: Color.lerp(Theme.of(context).scaffoldBackgroundColor, Theme.of(context).primaryColorLight, animValue)!,
                              child: child,
                            ),
                          ),
                    ),
                    onReorder: (oldIndex, newIndex) {
                      if (_saving) {
                        return; // ignore when saving
                      }
                      _reordered = true;
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      var item = _favorites.removeAt(oldIndex);
                      _favorites.insert(newIndex, item);
                      if (mounted) setState(() {});
                    },
                  ).fitSystemScreenshot(this),
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
      ),
    );
  }
}
