import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/page/view/category_grid.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';

/// 漫画类别Grid列表，在 [MangaCategorySubPage] / [RankingSubPage] 使用
class CategoryGridListView extends StatelessWidget {
  const CategoryGridListView({
    Key? key,
    this.title,
    required this.controller,
    required this.genres,
    this.markedCategoryNames,
    required this.onChoose,
    this.onLongPressed,
    this.showGenres = true,
    this.showAges = true,
    this.showZones = true,
  }) : super(key: key);

  final String? title;
  final List<TinyCategory> genres;
  final ScrollController controller;
  final List<String>? markedCategoryNames;
  final Function({TinyCategory? genre, TinyCategory? age, TinyCategory? zone}) onChoose;
  final Function({TinyCategory? genre, TinyCategory? age, TinyCategory? zone})? onLongPressed;
  final bool showGenres;
  final bool showAges;
  final bool showZones;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (title != null)
          ListHintView.textText(
            leftText: title!,
            rightText: '',
          ),
        Expanded(
          child: ExtendedScrollbar(
            controller: controller,
            interactive: true,
            mainAxisMargin: 2,
            crossAxisMargin: 2,
            child: ListView(
              controller: controller,
              padding: EdgeInsets.zero,
              physics: AlwaysScrollableScrollPhysics(),
              cacheExtent: 999999 /* <<< keep states in ListView */,
              children: [
                if (showGenres) ...[
                  Padding(
                    padding: EdgeInsets.only(top: 9, bottom: 10),
                    child: Text('・漫画剧情・', textAlign: TextAlign.center, style: Theme.of(context).textTheme.subtitle1),
                  ),
                  CategoryGridView(
                    categories: genres.map((g) => g.toCategory(cover: globalCategoryList!.genres.where((el) => el.name == g.name).firstOrNull?.cover)).toList(),
                    onPressed: (c) => onChoose.call(genre: c.toTiny()),
                    onLongPressed: onLongPressed == null ? null : (c) => onLongPressed?.call(genre: c.toTiny()),
                    ifNeedHighlight: (c) => markedCategoryNames?.any((el) => c.name == el) == true,
                    style: CategoryGridViewStyle.threeColumns,
                  ),
                ],
                if (showAges) ...[
                  Padding(
                    padding: EdgeInsets.only(top: 9, bottom: 10),
                    child: Text('・漫画受众・', textAlign: TextAlign.center, style: Theme.of(context).textTheme.subtitle1),
                  ),
                  CategoryGridView(
                    categories: allAges.sublist(1).map((g) => g.toCategory(cover: globalCategoryList!.ages.where((el) => el.name == g.name).firstOrNull?.cover)).toList(),
                    onPressed: (c) => onChoose.call(age: c.toTiny()),
                    onLongPressed: onLongPressed == null ? null : (c) => onLongPressed?.call(age: c.toTiny()),
                    ifNeedHighlight: (c) => markedCategoryNames?.any((el) => c.name == el) == true,
                    style: CategoryGridViewStyle.fourColumns,
                  ),
                ],
                if (showZones) ...[
                  Padding(
                    padding: EdgeInsets.only(top: 9, bottom: 10),
                    child: Text('・漫画地区・', textAlign: TextAlign.center, style: Theme.of(context).textTheme.subtitle1),
                  ),
                  CategoryGridView(
                    categories: allZones.sublist(1).map((g) => g.toCategory(cover: globalCategoryList!.zones.where((el) => el.name == g.name).firstOrNull?.cover)).toList(),
                    onPressed: (c) => onChoose.call(zone: c.toTiny()),
                    onLongPressed: onLongPressed == null ? null : (c) => onLongPressed?.call(zone: c.toTiny()),
                    ifNeedHighlight: (c) => markedCategoryNames?.any((el) => c.name == el) == true,
                    style: CategoryGridViewStyle.fourColumns,
                  ),
                ],
                SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
