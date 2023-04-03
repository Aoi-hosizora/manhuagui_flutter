import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

enum CategoryGridViewStyle {
  threeColumns,
  fourColumns,
}

/// 漫画类别方格，在 [GenreSubPage] 使用
class CategoryGridView extends StatelessWidget {
  const CategoryGridView({
    Key? key,
    required this.categories,
    required this.onSelected,
    this.style = CategoryGridViewStyle.threeColumns,
  }) : super(key: key);

  final List<Category> categories;
  final void Function(Category category) onSelected;
  final CategoryGridViewStyle style;

  Widget _buildItem({required BuildContext context, required Category category, required double width, required double imgHeight}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
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
                  height: imgHeight,
                  quality: FilterQuality.high,
                  radius: BorderRadius.only(topLeft: Radius.circular(6.0), topRight: Radius.circular(6.0)),
                ),
              if (category.cover.isEmpty)
                Container(
                  width: width,
                  height: imgHeight,
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
                child: Text(
                  category.title == '全部' ? '全部漫画' : category.title,
                  style: Theme.of(context).textTheme.bodyText1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        onTap: () => onSelected.call(category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const hSpace = 15.0;
    const vSpace = 15.0;
    var width = style == CategoryGridViewStyle.threeColumns
        ? (MediaQuery.of(context).size.width - hSpace * 4) / 3 // | ▢ ▢ ▢ |
        : (MediaQuery.of(context).size.width - hSpace * 5) / 4; // | ▢ ▢ ▢ ▢ |

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hSpace),
      child: Wrap(
        spacing: hSpace,
        runSpacing: vSpace,
        children: [
          for (var category in categories)
            _buildItem(
              context: context,
              category: category,
              width: width,
              imgHeight: width,
            ),
        ],
      ),
    );
  }
}
