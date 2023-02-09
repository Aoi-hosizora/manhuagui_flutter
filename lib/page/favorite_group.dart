import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/favorite_reorder_line.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 管理收藏分组页，展示所给 [FavoriteGroup] 并允许编辑和排序，以及保存到数据库
class FavoriteGroupPage extends StatefulWidget {
  const FavoriteGroupPage({
    Key? key,
    required this.groups,
  }) : super(key: key);

  final List<FavoriteGroup> groups;

  @override
  State<FavoriteGroupPage> createState() => _FavoriteGroupPageState();
}

class _FavoriteGroupPageState extends State<FavoriteGroupPage> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  late var _groups = widget.groups.toList();
  final _operations = <_GroupOperation>[];
  final _newToOlds = <String, String>{};
  final _oldToNews = <String, String?>{}; // TODO 逻辑有问题，待修复
  var _reordered = false;
  var _saving = false;

  void _restore() {
    _groups = widget.groups.toList();
    _operations.clear();
    _newToOlds.clear();
    _oldToNews.clear();
    _reordered = false;
    if (mounted) setState(() {});
  }

  Future<void> _addGroup() async {
    bool add(String newGroupName) {
      newGroupName = newGroupName.trim();
      if (newGroupName.isEmpty) {
        Fluttertoast.showToast(msg: '分组名不能为空');
        return false;
      }
      if (FavoriteGroup.isDefaultName(newGroupName)) {
        Fluttertoast.showToast(msg: '不可创建默认分组');
        return false;
      }
      if (_groups.where((g) => g.groupName == newGroupName).isNotEmpty) {
        Fluttertoast.showToast(msg: '"$newGroupName" 已存在');
        return false;
      }

      var group = FavoriteGroup(
        groupName: newGroupName,
        order: -1, // 最后再统一修改
        createdAt: DateTime.now(),
      );
      _groups.add(group);
      _operations.add(_CreateGroupOp(group));
      if (mounted) setState(() {});
      return true;
    }

    var controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('创建新分组'),
        content: SizedBox(
          width: getDialogContentMaxWidth(context),
          child: TextField(
            controller: controller,
            maxLines: 1,
            autofocus: true,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 5),
              labelText: '新分组名',
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text('确定'),
            onPressed: () {
              var ok = add(controller.text.trim());
              if (ok) {
                Navigator.of(c).pop();
              }
            },
          ),
          TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop()),
        ],
      ),
    );
  }

  Future<void> _renameGroup(FavoriteGroup group, int index) async {
    if (group.groupName == '') {
      Fluttertoast.showToast(msg: '不可编辑默认分组');
      return;
    }

    bool rename(String newGroupName) {
      newGroupName = newGroupName.trim();
      if (newGroupName == group.groupName) {
        Fluttertoast.showToast(msg: '分组名没有变更');
        return false;
      }
      if (newGroupName.isEmpty) {
        Fluttertoast.showToast(msg: '分组名不能为空');
        return false;
      }
      if (FavoriteGroup.isDefaultName(newGroupName)) {
        Fluttertoast.showToast(msg: '不可重命名为默认分组');
        return false;
      }
      if (_groups.where((g) => g.groupName == newGroupName).isNotEmpty) {
        Fluttertoast.showToast(msg: '"$newGroupName" 已存在');
        return false;
      }

      var oldGroupName = group.groupName;
      var newGroup = group.copyWith(groupName: newGroupName, order: -1); // 最后再统一修改顺序
      _groups[index] = newGroup;
      _operations.add(_RenameGroupOp(oldGroupName, newGroup));
      var originGroupName = _newToOlds[oldGroupName] ?? oldGroupName; // 溯源找到初始分组名
      _newToOlds[newGroupName] = originGroupName; // 更新映射
      _oldToNews[originGroupName] = newGroupName; // 更新映射
      if (mounted) setState(() {});
      return true;
    }

    var controller = TextEditingController();
    controller.text = group.groupName;
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('重命名 "${group.groupName}" 分组'),
        content: SizedBox(
          width: getDialogContentMaxWidth(context),
          child: TextField(
            controller: controller,
            maxLines: 1,
            autofocus: true,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 5),
              labelText: '新分组名',
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text('确定'),
            onPressed: () {
              var ok = rename(controller.text.trim());
              if (ok) {
                Navigator.of(c).pop();
              }
            },
          ),
          TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop()),
        ],
      ),
    );
  }

  Future<void> _deleteGroup(FavoriteGroup group, int index) async {
    if (group.groupName == '') {
      return; // 不可删除默认分组
    }

    bool? ok;
    var originGroupName = _newToOlds[group.groupName] ?? group.groupName; // 溯源找到初始分组名
    var cnt = await FavoriteDao.getFavoriteCount(username: AuthManager.instance.username, groupName: originGroupName);
    ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('删除分组'),
        content: cnt == null || cnt == 0
            ? Text('是否删除 "${group.groupName}" 分组') //
            : Text('"${group.groupName}" 分组内仍存有 $cnt 部漫画，这些漫画将被移至默认分组，确定继续删除该分组？') /* 实际由 FavoriteDao.deleteGroup 处理 */,
        actions: [
          TextButton(child: Text('确定'), onPressed: () => Navigator.of(c).pop(true)),
          TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
        ],
      ),
    );
    if (ok != true) {
      return;
    }

    _groups.removeAt(index);
    _operations.add(_DeleteGroupOp(group.groupName));
    _newToOlds.removeWhere((key, value) => key == group.groupName); // 更新映射
    _oldToNews[originGroupName] = null; // 更新映射
    if (mounted) setState(() {});
  }

  Future<void> _saveGroups() async {
    _saving = true;
    if (mounted) setState(() {});

    try {
      // 1. 保存新的分组信息到数据库
      for (var op in _operations) {
        if (op is _CreateGroupOp) {
          await FavoriteDao.addOrUpdateGroup(username: AuthManager.instance.username, group: op.newGroup, testGroupName: op.newGroup.groupName);
        } else if (op is _RenameGroupOp) {
          await FavoriteDao.addOrUpdateGroup(username: AuthManager.instance.username, group: op.group, testGroupName: op.oldName);
        } else if (op is _DeleteGroupOp) {
          await FavoriteDao.deleteGroup(username: AuthManager.instance.username, groupName: op.deletedGroupName);
        }
      }

      // 2. 保存新的分组顺序到数据库
      for (var i = 0; i < _groups.length; i++) {
        var group = _groups[i].copyWith(order: i + 1);
        await FavoriteDao.addOrUpdateGroup(username: AuthManager.instance.username, group: group, testGroupName: group.groupName);
      }

      // 3. 将老分组名映射到新分组名
      var nameMap = <String, String?>{}; // 包括被重命名和被删除的分组
      for (var oldGroup in widget.groups) {
        var oldGroupName = oldGroup.groupName;
        var newGroupName = _oldToNews[oldGroupName];
        if (newGroupName != null) {
          nameMap[oldGroupName] = newGroupName; // 被重命名过 (可能相同)
        } else if (!_oldToNews.containsKey(oldGroupName)) {
          nameMap[oldGroupName] = oldGroupName; // 未被重命名 (未被修改)
        } else {
          nameMap[oldGroupName] = null; // 分组被删除
        }
      }
      globalLogger.i('nameMap: ${nameMap.entries.map((i) => '"${i.key}" => "${i.value}"').join(', ')}');

      // 4. 记录新增分组的分组名
      var newNames = <String>[]; // 仅包括新增的分组
      var oldTargetNames = nameMap.values.toList();
      for (var g in _groups) {
        if (!oldTargetNames.contains(g.groupName)) {
          newNames.add(g.groupName); // 新增的分组
        }
      }
      globalLogger.i('newNames: ${newNames.map((i) => '"$i"').join(', ')}');

      // 5. 发送通知
      EventBusManager.instance.fire(FavoriteGroupUpdatedEvent(changedGroups: nameMap, newGroups: newNames));
      Navigator.of(context).pop();
    } catch (e, s) {
      // unreachable
      globalLogger.e('_saveGroup (FavoriteGroupPage)', e, s);
      Fluttertoast.showToast(msg: '无法保存对收藏分组的修改');
    } finally {
      _saving = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_reordered && _operations.isEmpty) {
          return true;
        }
        var ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text('离开确认'),
            content: Text('当前分组修改结果尚未保存，是否离开？'),
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
          title: Text('管理收藏分组'),
          leading: AppBarActionButton.leading(context: context),
          actions: [
            AppBarActionButton(
              icon: Icon(MdiIcons.folderPlusOutline),
              tooltip: '创建新分组',
              onPressed: _saving ? null : () => _addGroup(),
            ),
            AppBarActionButton(
              icon: Icon(Icons.settings_backup_restore),
              tooltip: '还原修改',
              onPressed: _saving ? null : () => _restore(),
            ),
            AppBarActionButton(
              icon: Icon(Icons.check),
              tooltip: '保存修改',
              onPressed: _saving ? null : () => _saveGroups(),
            ),
          ],
        ),
        body: ExtendedScrollbar(
          controller: _controller,
          interactive: false /* <<< be helpful for reorder dragging */,
          mainAxisMargin: 2,
          crossAxisMargin: 2,
          child: ReorderableListView.builder(
            scrollController: _controller,
            padding: EdgeInsets.zero,
            physics: AlwaysScrollableScrollPhysics(),
            itemCount: _groups.length,
            itemBuilder: (c, i) => DecoratedBox(
              key: Key('$i'),
              decoration: BoxDecoration(
                border: Border(
                  bottom: i == _groups.length - 1
                      ? BorderSide.none //
                      : BorderSide(width: 1, color: Theme.of(context).dividerColor),
                ),
              ),
              child: FavoriteGroupReorderLineView(
                group: _groups[i],
                canDelete: _groups[i].groupName != '',
                dragger: _groups[i].groupName == ''
                    ? null
                    : ReorderableDragStartListener(
                        index: i,
                        child: Icon(Icons.drag_handle),
                      ),
                onLinePressed: () => _saving ? null : _renameGroup(_groups[i], i),
                onDeletePressed: () => _saving ? null : _deleteGroup(_groups[i], i),
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
              if (newIndex == 0) {
                newIndex = 1;
              }
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              var item = _groups.removeAt(oldIndex);
              _groups.insert(newIndex, item);
              if (mounted) setState(() {});
            },
          ),
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

abstract class _GroupOperation {
  const _GroupOperation();
}

class _CreateGroupOp extends _GroupOperation {
  const _CreateGroupOp(this.newGroup) : super();

  final FavoriteGroup newGroup;
}

class _RenameGroupOp extends _GroupOperation {
  const _RenameGroupOp(this.oldName, this.group) : super();

  final String oldName;
  final FavoriteGroup group;
}

class _DeleteGroupOp extends _GroupOperation {
  const _DeleteGroupOp(this.deletedGroupName) : super();

  final String deletedGroupName;
}
