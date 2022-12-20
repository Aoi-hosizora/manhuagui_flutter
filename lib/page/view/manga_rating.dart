import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

/// 漫画评分，在 [MangaPage] 使用
class MangaRatingView extends StatelessWidget {
  const MangaRatingView({
    Key? key,
    required this.averageScore,
    required this.scoreCount,
  }) : super(key: key);

  final double averageScore; // xxx/10.0
  final int scoreCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RatingBar.builder(
          itemCount: 5,
          itemBuilder: (c, i) => Icon(Icons.star, color: Colors.amber),
          initialRating: averageScore / 2.0,
          minRating: 0,
          itemSize: 32,
          itemPadding: EdgeInsets.symmetric(horizontal: 4),
          direction: Axis.horizontal,
          allowHalfRating: true,
          ignoreGestures: true,
          onRatingUpdate: (_) {},
        ),
        SizedBox(height: 4),
        Text('平均分数: $averageScore / 10.0，共 $scoreCount 人评分'),
      ],
    );
  }
}

class MangaRatingDetailView extends StatelessWidget {
  const MangaRatingDetailView({
    Key? key,
    required this.averageScore,
    required this.scoreCount,
    required this.perScores,
  }) : super(key: key);

  final double averageScore; // xxx/10.0
  final int scoreCount;
  final List<String> perScores;

  @override
  Widget build(BuildContext context) {
    final barWidth = getDialogMaxWidth(context) * 0.6;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RatingBar.builder(
              itemCount: 5,
              itemBuilder: (c, i) => Icon(Icons.star, color: Colors.amber),
              initialRating: averageScore / 2.0,
              itemSize: 32,
              itemPadding: EdgeInsets.symmetric(horizontal: 2),
              allowHalfRating: true,
              ignoreGestures: true,
              onRatingUpdate: (_) {},
            ),
            SizedBox(width: 10),
            Text(
              averageScore.toString(),
              style: Theme.of(context).textTheme.bodyText1?.copyWith(
                    fontSize: 28,
                    color: Colors.orangeAccent,
                  ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '共 $scoreCount 人评分',
            style: Theme.of(context).textTheme.bodyText2,
          ),
        ),
        Divider(height: 16, thickness: 1),
        for (var i = 4; i >= 0; i--)
          Padding(
            padding: EdgeInsets.only(bottom: i == 0 ? 0 : 5),
            child: Row(
              children: [
                RatingBar.builder(
                  itemCount: 5,
                  itemBuilder: (c, i) => Icon(Icons.star, color: Colors.amber),
                  initialRating: (i + 1).toDouble(),
                  itemSize: 16,
                  allowHalfRating: false,
                  ignoreGestures: true,
                  onRatingUpdate: (_) {},
                ),
                Container(
                  width: barWidth * (double.tryParse(perScores[i + 1].replaceAll('%', '')) ?? 0) / 100,
                  height: 16,
                  color: Colors.amber,
                  margin: EdgeInsets.only(left: 4, right: 6),
                ),
                Text(
                  perScores[i + 1],
                  style: Theme.of(context).textTheme.bodyText2,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
