import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/category.dart';

class CategoryGridView extends StatefulWidget {
  const CategoryGridView({
    Key key,
    @required this.categories,
    @required this.onCategoryClicked,
  })  : assert(categories != null),
        assert(onCategoryClicked != null),
        super(key: key);

  final List<TinyCategory> categories;
  final void Function(TinyCategory) onCategoryClicked;

  @override
  _CategoryGridViewState createState() => _CategoryGridViewState();
}

class _CategoryGridViewState extends State<CategoryGridView> {
  Widget _buildCategoryGrid(TinyCategory category, int index, {double padding, double height, double width}) {
    return Container(
      height: height,
      width: width,
      margin: index == 0
          ? EdgeInsets.only(right: padding)
          : index == 3
              ? EdgeInsets.only(left: padding)
              : EdgeInsets.symmetric(horizontal: padding),
      child: OutlineButton(
        child: Text(
          category.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        onPressed: () => widget.onCategoryClicked(category),
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      child: Column(
        children: [
          ...categoriesView,
        ],
      ),
    );
  }
}
