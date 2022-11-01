import 'package:flutter/material.dart';

class WarningBarView extends StatefulWidget {
  const WarningBarView({
    Key? key,
    required this.text,
    required this.isWarning,
  }) : super(key: key);

  final String text;
  final bool isWarning;

  @override
  State<WarningBarView> createState() => _WarningBarViewState();
}

class _WarningBarViewState extends State<WarningBarView> {
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
