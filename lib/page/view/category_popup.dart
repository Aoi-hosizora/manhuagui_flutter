import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/page/dlg/category_dialog.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';

/// 可弹出类别选项的按钮，在 [RankingSubPage] / [MangaCategorySubPage] / [AuthorCategorySubPage] 使用
class CategoryPopupView extends StatelessWidget {
  const CategoryPopupView({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    this.markedCategoryNames,
    this.defaultName = '分类',
    this.enable = true,
    this.allowLongPressCategory = true,
    required this.onSelected,
    this.onLongPressed,
  }) : super(key: key);

  final List<TinyCategory> categories;
  final TinyCategory selectedCategory;
  final List<String>? markedCategoryNames;
  final String defaultName;
  final bool enable;
  final bool allowLongPressCategory;
  final void Function(TinyCategory) onSelected;
  final void Function()? onLongPressed;

  @override
  Widget build(BuildContext context) {
    return OptionPopupView<TinyCategory>(
      items: categories,
      value: selectedCategory,
      titleBuilder: (c, v) => v.isAll() ? defaultName : v.title,
      enable: enable,
      onSelected: (g) {
        if (g != selectedCategory) {
          onSelected.call(g);
        }
      },
      onLongPressed: onLongPressed,
      ifNeedHighlight: (category) => markedCategoryNames?.any((el) => category.name == el) == true,
      onOptionLongPressed: !allowLongPressCategory
          ? null
          : // set handler to showCategoryPopupMenu directly in order to keep the caller simple
          (category, selectAndPop, _setState) => showCategoryPopupMenu(
                context: context,
                category: category,
                onSelected: (category) {
                  selectAndPop(category);
                },
                onMarkedChanged: (genre, marked) {
                  if (markedCategoryNames != null) {
                    (marked ? markedCategoryNames!.add : markedCategoryNames!.remove)(genre.name);
                    _setState(() {});
                  }
                },
              ),
    );
  }
}
