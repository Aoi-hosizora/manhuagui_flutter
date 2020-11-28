import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/category.dart';

class CategoryGridView extends StatefulWidget {
  const CategoryGridView({
    Key key,
    @required this.categories,
    @required this.selectedCategory,
    @required this.onCategoryClicked,
  })  : assert(categories != null),
        assert(onCategoryClicked != null),
        super(key: key);

  final List<TinyCategory> categories;
  final TinyCategory selectedCategory;
  final void Function(TinyCategory) onCategoryClicked;

  @override
  _CategoryGridViewState createState() => _CategoryGridViewState();
}

class _CategoryGridViewState extends State<CategoryGridView> {
  Widget _buildCategoryGrid(TinyCategory category, int index, {double padding, double height, double width}) {
    var selected = widget.selectedCategory != null && widget.selectedCategory.name == category.name;
    return Container(
      height: height,
      width: width,
      margin: index == 0
          ? EdgeInsets.only(right: padding)
          : index == 3
              ? EdgeInsets.only(left: padding)
              : EdgeInsets.symmetric(horizontal: padding),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).primaryColor : Colors.white,
          border: selected ? null : Border.all(color: Colors.grey[300]),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onCategoryClicked(category),
            child: Center(
              child: Text(
                category.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var hPadding = 12.0;
    var vPadding = 10.0;
    var padding = 3.0;
    var width = (MediaQuery.of(context).size.width - 2 * hPadding - 6 * padding) / 4;
    var height = 36.0;

    var categoriesView = <Widget>[];
    var rows = (widget.categories.length.toDouble() / 4).ceil();
    for (var r = 0; r < rows; r++) {
      var columns = <TinyCategory>[
        for (var i = 4 * r; i < 4 * (r + 1) && i < widget.categories.length; i++) widget.categories[i],
      ];
      categoriesView.add(
        Row(
          children: [
            for (var i = 0; i < columns.length; i++)
              _buildCategoryGrid(
                columns[i],
                i,
                padding: padding,
                width: width,
                height: height,
              ),
          ],
        ),
      );
      if (r != rows - 1) {
        categoriesView.add(
          SizedBox(height: padding * 2),
        );
      }
    }

    return Container(
      color: Colors.white,
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...categoriesView,
              ],
            ),
          ),
          Divider(height: 1, thickness: 1),
        ],
      ),
    );
  }
}
