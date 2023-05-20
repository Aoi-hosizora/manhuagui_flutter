import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/list_hint.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

/// 漫画类别方格列表，在 [MangaCategorySubPage] / [RankingSubPage] 使用
class CategoryGridListView extends StatelessWidget {
  const CategoryGridListView({
    Key? key,
    this.title,
    required this.genres, // need genre list only
    this.markedCategoryNames,
    required this.controller,
    required this.onChoose,
    this.onLongPressed,
    this.showGenres = true,
    this.showAges = true,
    this.showZones = true,
  }) : super(key: key);

  final String? title;
  final List<TinyCategory> genres;
  final List<String>? markedCategoryNames;
  final ScrollController controller;
  final Function({TinyCategory? genre, TinyCategory? age, TinyCategory? zone}) onChoose;
  final Function({TinyCategory? genre, TinyCategory? age, TinyCategory? zone})? onLongPressed;
  final bool showGenres;
  final bool showAges;
  final bool showZones;

  Widget _buildGridView({
    required BuildContext context,
    required List<Category> categories,
    bool Function(Category category)? ifNeedHighlight,
    bool fourColumns = false,
    required void Function(Category category) onPressed,
    void Function(Category category)? onLongPressed,
  }) {
    const hSpace = 15.0;
    const vSpace = 15.0;
    var width = !fourColumns
        ? (MediaQuery.of(context).size.width - hSpace * 4) / 3 // | ▢ ▢ ▢ |
        : (MediaQuery.of(context).size.width - hSpace * 5) / 4; // | ▢ ▢ ▢ ▢ |

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hSpace),
      child: Wrap(
        spacing: hSpace,
        runSpacing: vSpace,
        children: [
          for (var category in categories)
            (ifNeedHighlight?.call(category) == true).let(
              (highlighted) => Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
                elevation: highlighted ? 3.0 : 1.5,
                color: highlighted ? Colors.deepOrange[50] : null,
                shadowColor: highlighted ? Colors.deepOrange[600] : null,
                child: FullRippleWidget(
                  highlightColor: null,
                  splashColor: null,
                  radius: BorderRadius.circular(6.0),
                  child: SizedBox(
                    width: width,
                    child: Column(
                      children: [
                        if (category.cover.isNotEmpty)
                          NetworkImageView(
                            url: category.cover,
                            width: width,
                            height: width,
                            quality: FilterQuality.high,
                            radius: BorderRadius.only(topLeft: Radius.circular(6.0), topRight: Radius.circular(6.0)),
                          ),
                        if (category.cover.isEmpty)
                          Container(
                            width: width,
                            height: width,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                stops: const [0, 0.5, 1],
                                colors: [Colors.blue[100]!, Colors.orange[100]!, Colors.purple[100]!],
                              ),
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(6.0), topRight: Radius.circular(6.0)),
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.only(top: 3, bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (highlighted)
                                Padding(
                                  padding: EdgeInsets.only(right: 2),
                                  child: Icon(
                                    Icons.flag,
                                    color: Colors.deepOrange[400],
                                    size: 20,
                                  ),
                                ),
                              Text(
                                category.title == '全部' ? '全部漫画' : category.title,
                                style: Theme.of(context).textTheme.bodyText1?.copyWith(
                                      color: highlighted ? Colors.deepOrange : null,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () => onPressed.call(category),
                  onLongPress: onLongPressed == null ? null : () => onLongPressed.call(category),
                ),
              ),
            ),
        ],
      ),
    );
  }

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
                  _buildGridView(
                    context: context,
                    categories: genres.map((g) => g.toCategory(cover: globalCategoryList!.genres.where((el) => el.name == g.name).firstOrNull?.cover)).toList(),
                    ifNeedHighlight: (c) => markedCategoryNames?.any((el) => c.name == el) == true,
                    onPressed: (c) => onChoose.call(genre: c.toTiny()),
                    onLongPressed: onLongPressed == null ? null : (c) => onLongPressed?.call(genre: c.toTiny()),
                  ),
                ],
                if (showAges) ...[
                  Padding(
                    padding: EdgeInsets.only(top: 9, bottom: 10),
                    child: Text('・漫画受众・', textAlign: TextAlign.center, style: Theme.of(context).textTheme.subtitle1),
                  ),
                  _buildGridView(
                    context: context,
                    categories: allAges.sublist(1).map((g) => g.toCategory(cover: globalCategoryList!.ages.where((el) => el.name == g.name).firstOrNull?.cover)).toList(),
                    ifNeedHighlight: (c) => markedCategoryNames?.any((el) => c.name == el) == true,
                    fourColumns: true,
                    onPressed: (c) => onChoose.call(age: c.toTiny()),
                    onLongPressed: onLongPressed == null ? null : (c) => onLongPressed?.call(age: c.toTiny()),
                  ),
                ],
                if (showZones) ...[
                  Padding(
                    padding: EdgeInsets.only(top: 9, bottom: 10),
                    child: Text('・漫画地区・', textAlign: TextAlign.center, style: Theme.of(context).textTheme.subtitle1),
                  ),
                  _buildGridView(
                    context: context,
                    categories: allZones.sublist(1).map((g) => g.toCategory(cover: globalCategoryList!.zones.where((el) => el.name == g.name).firstOrNull?.cover)).toList(),
                    ifNeedHighlight: (c) => markedCategoryNames?.any((el) => c.name == el) == true,
                    fourColumns: true,
                    onPressed: (c) => onChoose.call(zone: c.toTiny()),
                    onLongPressed: onLongPressed == null ? null : (c) => onLongPressed?.call(zone: c.toTiny()),
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
