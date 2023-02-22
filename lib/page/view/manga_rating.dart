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
        Text(
          '平均评分: $averageScore，共 $scoreCount 人评分',
          style: Theme.of(context).textTheme.bodyText2,
        ),
      ],
    );
  }
}

/// 漫画评分细节，在 [MangaPage] 的评分投票对话框使用
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

  double _textWidth(BuildContext context, String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.width;
  }

  @override
  Widget build(BuildContext context) {
    var scores = [for (var i = 0; i < 5; i++) (double.tryParse(perScores[i + 1].replaceAll('%', '')) ?? 0) / 100]; // [0,1,2,3,4] => star_1,2,3,4,5
    var maxScore = scores.reduce((value, element) => value > element ? value : element);
    var maxWidth = getDialogContentMaxWidth(context) - (18 * 5 + 6 + 8 + _textWidth(context, '88.8%', Theme.of(context).textTheme.bodyText2!));
    var scoreWidths = [for (var i = 0; i < 5; i++) maxScore == 0 ? 1.0 : (maxWidth / maxScore * scores[i]).clamp(1.0, maxWidth)];
    var scoreTexts = [for (var i = 0; i < 5; i++) perScores[i + 1]];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RatingBar.builder(
              itemCount: 5,
              itemBuilder: (c, i) => Icon(Icons.grade, color: Colors.amber),
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
        SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '共 $scoreCount 人评分',
            style: Theme.of(context).textTheme.bodyText2,
          ),
        ),
        Divider(height: 24, thickness: 1),
        for (var i = 4; i >= 0; i--)
          Padding(
            padding: EdgeInsets.only(bottom: i == 0 ? 0 : 5),
            child: Row(
              children: [
                RatingBar.builder(
                  itemCount: 5,
                  itemBuilder: (c, i) => Icon(Icons.grade, color: Colors.amber),
                  initialRating: (i + 1).toDouble(),
                  itemSize: 18,
                  allowHalfRating: false,
                  ignoreGestures: true,
                  onRatingUpdate: (_) {},
                ),
                Container(
                  width: scoreWidths[i],
                  height: 16,
                  color: Colors.amber,
                  margin: EdgeInsets.only(left: 6, right: 8),
                ),
                Text(
                  scoreTexts[i],
                  style: Theme.of(context).textTheme.bodyText2,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
