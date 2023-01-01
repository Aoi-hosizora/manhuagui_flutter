import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/favorite_reorder_line.dart';
import 'package:manhuagui_flutter/service/db/favorite.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';

/// 收藏分组页，展示所给 [FavoriteGroup] 并允许编辑和排序，以及保存到数据库
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
  late var _groups = widget.groups.toList();
  final _operations = <_GroupOperation>[];
  var _reordered = false;
  var _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addGroup() async {
    bool add(String newGroupName) {
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
        content: Container(
          width: getDialogMaxWidth(context),
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

    bool add(String newName) {
      if (newName == group.groupName) {
        Fluttertoast.showToast(msg: '分组名没有变更');
        return false;
      }
      if (newName.isEmpty) {
        Fluttertoast.showToast(msg: '分组名不能为空');
        return false;
      }
      if (FavoriteGroup.isDefaultName(newName)) {
        Fluttertoast.showToast(msg: '不可重命名为默认分组');
        return false;
      }
      if (_groups.where((g) => g.groupName == newName).isNotEmpty) {
        Fluttertoast.showToast(msg: '"$newName" 已存在');
        return false;
      }

      var newGroup = group.copyWith(
        groupName: newName,
        order: -1, // 最后再统一修改
      );
      _groups[index] = newGroup;
      _operations.add(_RenameGroupOp(group.groupName, newGroup));
      if (mounted) setState(() {});
      return true;
    }

    var controller = TextEditingController();
    controller.text = group.groupName;
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('重命名 "${group.groupName}" 分组'),
        content: Container(
          width: getDialogMaxWidth(context),
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

  Future<void> _deleteGroup(FavoriteGroup group, int index) async {
    if (group.groupName == '') {
      return; // 不可删除默认分组
    }

    bool? ok;
    var cnt = await FavoriteDao.getFavoriteCount(username: AuthManager.instance.username, groupName: group.groupName);
    if (cnt != null && cnt > 0) {
      ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('删除分组'),
          content: Text('"${group.groupName}" 分组内仍存有 $cnt 部漫画，这些漫画将被移至默认分组，确定继续删除 "${group.groupName}" 分组？'),
          actions: [
            TextButton(child: Text('确定'), onPressed: () => Navigator.of(c).pop(true)),
            TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
          ],
        ),
      );
    } else {
      ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('删除分组'),
          content: Text('是否删除 "${group.groupName}" 分组'),
          actions: [
            TextButton(child: Text('确定'), onPressed: () => Navigator.of(c).pop(true)),
            TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
          ],
        ),
      );
    }
    if (ok != true) {
      return;
    }

    _groups.removeAt(index);
    _operations.add(_DeleteGroupOp(group.groupName));
    if (mounted) setState(() {});
  }

  void _restore() {
    _groups = widget.groups.toList();
    _operations.clear();
    _reordered = false;
    if (mounted) setState(() {});
  }

  Future<void> _saveGroups() async {
    _saving = true;
    if (mounted) setState(() {});

    try {
      for (var op in _operations) {
        if (op is _CreateGroupOp) {
          // print('Create ${op.newGroup.groupName}');
          await FavoriteDao.addOrUpdateGroup(username: AuthManager.instance.username, group: op.newGroup, testGroupName: op.newGroup.groupName);
        } else if (op is _RenameGroupOp) {
          // print('Rename ${op.oldName} ${op.group.groupName}');
          await FavoriteDao.addOrUpdateGroup(username: AuthManager.instance.username, group: op.group, testGroupName: op.oldName);
        } else if (op is _DeleteGroupOp) {
          // print('Delete ${op.deletedGroupName}');
          await FavoriteDao.deleteGroup(username: AuthManager.instance.username, groupName: op.deletedGroupName);
        }
      }

      for (var i = 0; i < _groups.length; i++) {
        var group = _groups[i].copyWith(order: i + 1);
        // print('Reorder ${group.groupName} ${i + 1}');
        await FavoriteDao.addOrUpdateGroup(username: AuthManager.instance.username, group: group, testGroupName: group.groupName);
      }

      Navigator.of(context).pop(true);
    } catch (e, s) {
      // unreachable
      globalLogger.e('_saveGroup', e, s);
      Fluttertoast.showToast(msg: '无法保存收藏分组的修改');
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
        var ok = await showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: Text('离开分组管理'),
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
          title: Text('收藏分组'),
          leading: AppBarActionButton.leading(context: context),
          actions: [
            AppBarActionButton(
              icon: Icon(Icons.add),
              tooltip: '创建新分组',
              onPressed: _saving ? null : () => _addGroup(),
            ),
            AppBarActionButton(
              icon: Icon(Icons.replay),
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
          crossAxisMargin: 2,
          interactive: false, // <<<
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
                      ? BorderSide.none
                      : BorderSide(
                          width: 1,
                          color: Theme.of(context).dividerColor,
                        ),
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
