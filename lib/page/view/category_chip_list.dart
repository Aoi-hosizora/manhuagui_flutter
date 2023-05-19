import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';

/// 漫画类别Chip列表，在 [RecommendSubPage] 使用
class CategoryChipListView extends StatelessWidget {
  const CategoryChipListView({
    Key? key,
    required this.genres,
    this.markedCategoryNames,
    required this.onPressed,
    this.onLongPressed,
  }) : super(key: key);

  final List<TinyCategory> genres;
  final List<String>? markedCategoryNames;
  final void Function(TinyCategory) onPressed;
  final void Function(TinyCategory)? onLongPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.horizontal,
      spacing: 10.0,
      runSpacing: 10.0,
      children: [
        for (var genre in genres)
          Container(
            decoration: ShapeDecoration(
              shape: StadiumBorder(),
            ),
            child: ClipPath.shape(
              shape: StadiumBorder(),
              child: FullRippleWidget(
                child: Chip(
                  backgroundColor: Colors.deepOrange[50],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Padding(
                    padding: EdgeInsets.only(left: 1, right: 1, bottom: 1),
                    child: Text(
                      '#${genre.title}',
                      style: TextStyle(
                        color: markedCategoryNames?.any((el) => genre.name == el) == true ? Colors.deepOrange[600] : null,
                      ),
                    ),
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(width: 1, color: Colors.transparent),
                  ),
                ),
                highlightColor: null,
                splashColor: null,
                onTap: () => onPressed.call(genre),
                onLongPress: onLongPressed == null ? null : () => onLongPressed?.call(genre),
              ),
            ),
          ),
      ],
    );
  }
}
