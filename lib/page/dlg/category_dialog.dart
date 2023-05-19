import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/prefs/marked_category.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 漫画类别页/漫画排行页-漫画类别弹出菜单 [showCategoryPopupMenu]

// => called by RankingSubPage / MangaCategorySubPage / RecommendSubPage
Future<void> showCategoryPopupMenu({
  required BuildContext context,
  required TinyCategory category,
  required void Function(TinyCategory) onSelected,
  void Function(TinyCategory, bool marked)? onMarkedChanged,
}) async {
  var marked = await MarkedCategoryPrefs.isCategoryMarked(name: category.name);
  showDialog(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text('#${category.title}'),
      children: [
        IconTextDialogOption(
          icon: Icon(Icons.category),
          text: Text('选择类别'),
          popWhenPress: c,
          onPressed: () => onSelected.call(category),
        ),
        if (!marked)
        IconTextDialogOption(
          icon: Icon(MdiIcons.flagPlus),
          text: Text('标记类别'),
          popWhenPress: c,
          onPressed: () async {
            await MarkedCategoryPrefs.markCategory(name: category.name);
            EventBusManager.instance.fire(MarkedCategoryUpdatedEvent(categoryName: category.name, added: true));
            onMarkedChanged?.call(category, true);
          },
        ),
        if (marked)
        IconTextDialogOption(
          icon: Icon(MdiIcons.flagMinus),
          text: Text('取消标记类别'),
          popWhenPress: c,
          onPressed: () async {
            await MarkedCategoryPrefs.unmarkCategory(name: category.name);
            EventBusManager.instance.fire(MarkedCategoryUpdatedEvent(categoryName: category.name, added: false));
            onMarkedChanged?.call(category, false);
          },
        ),
      ],
    ),
  );
}
