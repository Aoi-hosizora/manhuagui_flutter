import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/page/view/category_chip_list.dart';
import 'package:manhuagui_flutter/page/view/manga_aud_ranking.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/prefs/marked_category.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 漫画类别页/漫画排行页-漫画类别弹出菜单 [showCategoryPopupMenu]
/// 推荐页-漫画受众排行榜类别修改弹出菜单 [showAudCategoryRemapPopupMenu]

// => called by RankingSubPage / MangaCategorySubPage / RecommendSubPage / CategoryPopupView
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

// => called by MangaAudRankingView
Future<void> showAudCategoryRemapPopupMenu({
  required BuildContext context,
  void Function(MangaAudRankingType)? onRemapped,
}) async {
  if (globalCategoryList == null) {
    Fluttertoast.showToast(msg: '漫画类别列表尚未加载完成，无法修改受众排行榜默认类别');
    return;
  }

  var markedCategories = await MarkedCategoryPrefs.getMarkedCategories();
  var remappedQingnianName = await MarkedCategoryPrefs.getRemappedQingnianCategoryName();
  var remappedShaonvName = await MarkedCategoryPrefs.getRemappedShaonvCategoryName();
  var allCategories = globalCategoryList!.allCategories.map((c) => c.toTiny()).toList();
  var remappedQingnianCat = allCategories.where((el) => el.name == remappedQingnianName).firstOrNull;
  var remappedShaonvCat = allCategories.where((el) => el.name == remappedShaonvName).firstOrNull;

  var selected = await showDialog<MangaAudRankingType>(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text('修改受众排行榜默认类别'),
      children: [
        IconTextDialogOption(
          icon: Icon(Icons.category),
          text: remappedQingnianCat == null ? Text('青年漫画') : Text('青年漫画 → ${remappedQingnianCat.title}漫画'),
          onPressed: () => Navigator.of(c).pop(MangaAudRankingType.qingnian),
        ),
        IconTextDialogOption(
          icon: Icon(Icons.category),
          text: remappedShaonvCat == null ? Text('少女漫画') : Text('少女漫画 → ${remappedShaonvCat.title}漫画'),
          onPressed: () => Navigator.of(c).pop(MangaAudRankingType.shaonv),
        ),
      ],
    ),
  );
  if (selected == null || selected == MangaAudRankingType.all) {
    return;
  }

  var selectedTitle = selected == MangaAudRankingType.qingnian //
      ? (remappedQingnianCat?.title ?? '青年') + '漫画'
      : (remappedShaonvCat?.title ?? '少女') + '漫画';
  var newCategory = await showDialog<TinyCategory>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('修改 "$selectedTitle" 受众排行榜'),
      content: Center(
        heightFactor: 1.0,
        child: CategoryChipListView(
          categories: allCategories,
          markedCategoryNames: markedCategories,
          onPressed: (category) {
            if (category.isAll()) {
              Fluttertoast.showToast(msg: '不允许修改为 "全部" 类别');
            } else {
              Navigator.of(c).pop(category);
            }
          },
        ),
      ),
    ),
  );
  if (newCategory == null || newCategory.isAll()) {
    return;
  }

  if (selected == MangaAudRankingType.qingnian) {
    if (newCategory.name != (remappedQingnianCat?.name ?? qingnianAgeCategory.name)) {
      await MarkedCategoryPrefs.setRemappedQingnianCategoryName(remappedName: newCategory.name);
      onRemapped?.call(selected);
    }
  } else if (selected == MangaAudRankingType.shaonv) {
    if (newCategory.name != (remappedShaonvCat?.name ?? shaonvAgeCategory.name)) {
      await MarkedCategoryPrefs.setRemappedShaonvCategoryName(remappedName: newCategory.name);
      onRemapped?.call(selected);
    }
  }
}
