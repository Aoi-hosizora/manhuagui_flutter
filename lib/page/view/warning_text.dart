import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

/// 警告提醒文字，在 [RecommendSubPage] / [DownloadChoosePage] 使用
class WarningTextView extends StatefulWidget {
  const WarningTextView({
    Key? key,
    required this.text,
    required this.isWarning,
  }) : super(key: key);

  final String text;
  final bool isWarning;

  @override
  State<WarningTextView> createState() => _WarningTextViewState();
}

class _WarningTextViewState extends State<WarningTextView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      decoration: BoxDecoration(color: Colors.yellow),
      alignment: Alignment.center,
      child: TextGroup.normal(
        texts: [
          PlainTextItem(text: '【'),
          PlainTextItem(
            text: widget.isWarning ? '注意' : '提示',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SpanItem(
            span: WidgetSpan(
              child: Icon(
                Icons.warning_amber,
                color: Colors.grey[800],
                size: 22,
              ),
            ),
          ),
          PlainTextItem(text: '】${widget.text}'),
        ],
      ),
    );
  }
}
