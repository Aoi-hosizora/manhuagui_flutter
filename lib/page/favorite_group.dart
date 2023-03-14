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

  late var _groups = widget.groups.map((g) => _FavoriteGroupWithOrigin(group: g, origin: g)).toList();
  final _operations = <_GroupOperation>[];
  var _reordered = false;
  var _saving = false;

  void _restore() {
    _groups = widget.groups.map((g) => _FavoriteGroupWithOrigin(group: g, origin: g)).toList();
    _operations.clear();
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
      if (!FavoriteGroup.isValidName(newGroupName)) {
        Fluttertoast.showToast(msg: '不允许使用 "$newGroupName" 作为分组名');
        return false;
      }
      if (_groups.where((g) => g.group.groupName == newGroupName).isNotEmpty) {
        Fluttertoast.showToast(msg: '"$newGroupName" 已存在');
        return false;
      }

      var group = FavoriteGroup(groupName: newGroupName, order: -1, createdAt: DateTime.now()); // 最后再统一修改顺序
      _groups.add(_FavoriteGroupWithOrigin(group: group, origin: null /* 新增的分组没有原始分组 */));
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

  Future<void> _renameGroup(_FavoriteGroupWithOrigin group, int index) async {
    if (group.group.groupName == '') {
      Fluttertoast.showToast(msg: '不可编辑默认分组');
      return;
    }

    bool rename(String newGroupName) {
      newGroupName = newGroupName.trim();
      if (newGroupName == group.group.groupName) {
        Fluttertoast.showToast(msg: '分组名没有变更');
        return false;
      }
      if (newGroupName.isEmpty) {
        Fluttertoast.showToast(msg: '分组名不能为空');
        return false;
      }
      if (!FavoriteGroup.isValidName(newGroupName)) {
        Fluttertoast.showToast(msg: '不允许使用 "$newGroupName" 作为分组名');
        return false;
      }
      if (_groups.where((g) => g.group.groupName == newGroupName).isNotEmpty) {
        Fluttertoast.showToast(msg: '"$newGroupName" 已存在');
        return false;
      }

      var oldGroupName = group.group.groupName;
      var newGroup = group.group.copyWith(groupName: newGroupName, order: -1); // 最后再统一修改顺序
      _groups[index] = _FavoriteGroupWithOrigin(group: newGroup, origin: group.origin /* 被重命名的分组需要记录原始分组 */);
      _operations.add(_RenameGroupOp(oldGroupName, newGroup));
      if (mounted) setState(() {});
      return true;
    }

    var controller = TextEditingController();
    controller.text = group.group.groupName;
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('重命名 "${group.group.groupName}" 分组'),
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

  Future<void> _deleteGroup(_FavoriteGroupWithOrigin group, int index) async {
    if (group.group.groupName == '') {
      return; // 不可删除默认分组
    }

    int? mangaCount;
    if (group.origin != null) {
      mangaCount = await FavoriteDao.getFavoriteCount(username: AuthManager.instance.username, groupName: group.origin!.groupName); // 查询原始分组的漫画数量
    }
    var isEmptyGroup = mangaCount == null || mangaCount == 0;

    bool? ok;
    var moveMangas = true;
    ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('删除分组'),
        content: isEmptyGroup
            ? Text('是否删除 "${group.group.groupName}" 分组？') //
            : Text('"${group.group.groupName}" 分组' + //
                (group.group.groupName == group.origin!.groupName ? '' : ' (原为 "${group.origin!.groupName}" 分组) ') +
                '内仍存有 $mangaCount 部漫画，这些漫画将被移至默认分组或被删除，确定继续删除该分组？'),
        actions: [
          if (isEmptyGroup) TextButton(child: Text('确定'), onPressed: () => Navigator.of(c).pop(true)),
          if (!isEmptyGroup) ...[
            TextButton(child: Text('移动漫画后删除'), onPressed: () => callAll([() => moveMangas = true, () => Navigator.of(c).pop(true)])),
            TextButton(child: Text('删除漫画后删除'), onPressed: () => callAll([() => moveMangas = false, () => Navigator.of(c).pop(true)])),
          ],
          TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
        ],
      ),
    );
    if (ok != true) {
      return;
    }

    _groups.removeAt(index); // 记录着的原始分组随着分组被删除而删除
    _operations.add(_DeleteGroupOp(group.group.groupName, moveMangas));
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
          await FavoriteDao.deleteGroup(username: AuthManager.instance.username, groupName: op.deletedGroupName, moveMangasIfExisted: op.moveMangas);
        }
      }

      // 2. 保存新的分组顺序到数据库
      for (var i = 0; i < _groups.length; i++) {
        var group = _groups[i].group.copyWith(order: i + 1);
        await FavoriteDao.addOrUpdateGroup(username: AuthManager.instance.username, group: group, testGroupName: group.groupName);
      }

      // 3. 将老分组名映射到新分组名
      var oldToNewGroupMap = <String, String>{}; // 并非所有的原始分组都包含在这个映射中，原始分组被删除则不包含在该映射中
      for (var group in _groups) {
        if (group.origin != null) {
          oldToNewGroupMap[group.origin!.groupName] = group.group.groupName;
        }
      }
      var changedNames = <String, String?>{}; // <<< 所有原始分组的变更记录 (老到新)，包括被重命名和被删除的分组
      for (var oldGroup in widget.groups) {
        var oldGroupName = oldGroup.groupName;
        var newGroupName = oldToNewGroupMap[oldGroupName];
        if (newGroupName != null) {
          changedNames[oldGroupName] = newGroupName; // 分组未被删除 (可能被重命名过)
        } else {
          changedNames[oldGroupName] = null; // 分组被删除
        }
      }

      // 4. 记录新增分组的分组名
      var newNames = <String>[]; // <<< 所有新增分组的最新分组名
      for (var g in _groups) {
        if (g.origin == null) {
          newNames.add(g.group.groupName); // 新增的分组
        }
      }

      // 5. 发送通知
      EventBusManager.instance.fire(FavoriteGroupUpdatedEvent(changedGroups: changedNames, newGroups: newNames));
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
                group: _groups[i].group,
                originGroup: _groups[i].origin,
                canDelete: _groups[i].group.groupName != '',
                dragger: _groups[i].group.groupName == ''
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

class _FavoriteGroupWithOrigin {
  const _FavoriteGroupWithOrigin({required this.group, required this.origin});

  final FavoriteGroup group;
  final FavoriteGroup? origin; // 记录原始分组用于溯源
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
  const _DeleteGroupOp(this.deletedGroupName, this.moveMangas) : super();

  final String deletedGroupName;
  final bool moveMangas;
}
