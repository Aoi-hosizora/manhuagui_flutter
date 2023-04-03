import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

/// 用于排序的收藏漫画和收藏分组行，在 [FavoriteReorderPage] / [FavoriteGroupPage] 使用

class FavoriteMangaReorderLineView extends StatelessWidget {
  const FavoriteMangaReorderLineView({
    Key? key,
    required this.favorite,
    required this.originIndex,
    required this.dragger,
    required this.onLinePressed,
  }) : super(key: key);

  final FavoriteManga favorite;
  final int originIndex;
  final Widget? dragger;
  final VoidCallback onLinePressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(favorite.mangaTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${favorite.checkedGroupName}・备注 ${favorite.remark.trim().isEmpty ? '暂无' : favorite.remark.trim()}\n'
        '#${originIndex + 1}・收藏于 ${favorite.formattedCreatedAt}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NetworkImageView(
            url: favorite.mangaCover,
            height: 48,
            width: 48,
            radius: BorderRadius.circular(12),
          ),
        ],
      ),
      trailing: dragger == null
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [dragger!],
            ),
      onTap: onLinePressed,
    );
  }
}

class FavoriteGroupReorderLineView extends StatelessWidget {
  const FavoriteGroupReorderLineView({
    Key? key,
    required this.group,
    required this.originGroup,
    required this.dragger,
    this.canDelete = true,
    required this.onDeletePressed,
    required this.onLinePressed,
  }) : super(key: key);

  final FavoriteGroup group;
  final FavoriteGroup? originGroup;
  final Widget? dragger;
  final bool canDelete;
  final VoidCallback? onDeletePressed;
  final VoidCallback onLinePressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(group.checkedGroupName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        (group.groupName == ''
                ? '不可修改'
                : originGroup == null
                    ? '新增的分组'
                    : (originGroup!.groupName == group.groupName ? '未变更' : '原为 "${originGroup!.checkedGroupName}"')) + //
            '・创建于 ${group.formattedCreatedAt}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkResponse(
            child: Icon(!canDelete ? Icons.disabled_by_default_rounded : Icons.delete),
            onTap: !canDelete ? null : onDeletePressed,
            radius: 22,
          ),
        ],
      ),
      trailing: dragger == null
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [dragger!],
            ),
      onTap: onLinePressed,
    );
  }
}
