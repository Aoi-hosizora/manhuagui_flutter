import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/page/sep_genre.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';

/// 漫画剧情类别列表，在 [RecommendSubPage] 使用
class GenreChipListView extends StatelessWidget {
  const GenreChipListView({
    Key? key,
    required this.genres,
  }) : super(key: key);

  final List<TinyCategory> genres;

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
                    child: Text('#${genre.title}'),
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(width: 1, color: Colors.transparent),
                  ),
                ),
                highlightColor: null,
                splashColor: null,
                onTap: () => Navigator.of(context).push(
                  CustomPageRoute(
                    context: context,
                    builder: (c) => SepGenrePage(
                      genre: genre,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
