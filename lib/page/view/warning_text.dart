import 'package:flutter/material.dart';

/// 警告提醒文字，在 [RecommendSubPage] / [DownloadSelectPage] 使用
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
      child: widget.isWarning
          ? Text('【注意】${widget.text}') //
          : Text('【提醒】${widget.text}'),
    );
  }
}
